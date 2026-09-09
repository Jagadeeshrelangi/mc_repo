"""Unit tests for FCM Notification orchestration and Mechanic Booking triggers."""

from datetime import datetime, timezone
from typing import Any, List, Optional
import uuid
import pytest

from app.models.device_token import DeviceToken
from app.models.mechanic_booking import MechanicBooking
from app.models.mechanic_status import BookingStatus
from app.models.notification_setting import NotificationSetting
from app.repositories.device_token import DeviceTokenRepository
from app.repositories.notification_setting import NotificationSettingRepository
from app.services.fcm_adapter import (
    FCMDeliveryReport,
    MockFCMAdapter,
    NotificationPayload,
)
from app.services.notification_service import (
    BOOKING_NOTIFICATION_CONTENT,
    NotificationService,
)


class FakeNotificationSession:
    """In-memory async session for testing NotificationService."""

    def __init__(self) -> None:
        self.device_tokens: List[DeviceToken] = []
        self.notification_settings: List[NotificationSetting] = []
        self.flushes = 0
        self.commits = 0

    async def execute(self, stmt: Any) -> Any:
        stmt_str = str(stmt).lower()

        # Handle notification_settings SELECT
        if "notification_settings" in stmt_str and "select" in stmt_str:
            target_user = None
            if hasattr(stmt, "compile"):
                compiled = stmt.compile()
                for col, val in compiled.params.items():
                    if "user_id" in col:
                        target_user = str(val)

            matched = [s for s in self.notification_settings if str(s.user_id) == target_user]

            class SettingResult:
                def scalar_one_or_none(self):
                    return matched[0] if matched else None

            return SettingResult()

        # Handle device_tokens SELECT
        if "device_tokens" in stmt_str and "select" in stmt_str:
            target_user = None
            if hasattr(stmt, "compile"):
                compiled = stmt.compile()
                for col, val in compiled.params.items():
                    if "user_id" in col:
                        target_user = str(val)

            matched = [
                dt.fcm_token
                for dt in self.device_tokens
                if str(dt.user_id) == target_user and dt.is_active
            ]

            class TokenResult:
                def scalars(self):
                    class Scal:
                        def all(self):
                            return matched
                    return Scal()

            return TokenResult()

        # Handle DELETE FROM device_tokens WHERE fcm_token = ...
        if "delete from device_tokens" in stmt_str:
            target_fcm = None
            if hasattr(stmt, "compile"):
                compiled = stmt.compile()
                for col, val in compiled.params.items():
                    if "fcm_token" in col:
                        target_fcm = str(val)

            if target_fcm:
                self.device_tokens = [dt for dt in self.device_tokens if dt.fcm_token != target_fcm]

            class DeleteResult:
                rowcount = 1

            return DeleteResult()

        class GenericResult:
            rowcount = 0
            def scalar_one_or_none(self):
                return None
            def scalars(self):
                class EmptyScalars:
                    def all(self):
                        return []
                return EmptyScalars()

        return GenericResult()

    def add(self, entity: Any) -> None:
        if isinstance(entity, NotificationSetting):
            self.notification_settings.append(entity)
        elif isinstance(entity, DeviceToken):
            self.device_tokens.append(entity)

    async def flush(self) -> None:
        self.flushes += 1

    async def commit(self) -> None:
        self.commits += 1

    async def refresh(self, entity: Any) -> None:
        pass


@pytest.mark.asyncio
async def test_dispatch_notification_success() -> None:
    session = FakeNotificationSession()
    user_id = uuid.uuid4()

    # User preference is push=True
    session.notification_settings.append(NotificationSetting(user_id=user_id, push=True))

    # User has 2 active device tokens
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="tok-1", platform="android", is_active=True)
    )
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="tok-2", platform="android", is_active=True)
    )

    mock_fcm = MockFCMAdapter()
    service = NotificationService(session=session, fcm_adapter=mock_fcm)

    payload = NotificationPayload(
        title="Mechanic Assigned",
        body="Rajesh Kumar has been assigned to your booking.",
        notification_type="booking.status_changed",
        entity_type="booking",
        entity_id="booking-123",
        deep_link="mecha://mechanic/booking/booking-123/tracking",
        metadata={"status": "mechanicAssigned"},
    )

    report = await service.dispatch_notification(user_id, payload)
    assert report is not None
    assert report.total_tokens == 2
    assert report.success_count == 2
    assert report.failure_count == 0
    assert len(mock_fcm.sent_messages) == 1
    assert mock_fcm.sent_messages[0]["tokens"] == ["tok-1", "tok-2"]


@pytest.mark.asyncio
async def test_dispatch_skipped_when_push_disabled() -> None:
    session = FakeNotificationSession()
    user_id = uuid.uuid4()

    # User preference: push = False
    session.notification_settings.append(NotificationSetting(user_id=user_id, push=False))
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="tok-1", platform="android", is_active=True)
    )

    mock_fcm = MockFCMAdapter()
    service = NotificationService(session=session, fcm_adapter=mock_fcm)

    payload = NotificationPayload(
        title="Booking Accepted",
        body="Your service request has been accepted.",
        notification_type="booking.status_changed",
        entity_type="booking",
        entity_id="b-1",
        deep_link="mecha://booking/b-1",
    )

    report = await service.dispatch_notification(user_id, payload)
    assert report is None
    # Verify FCM was never invoked
    assert len(mock_fcm.sent_messages) == 0


@pytest.mark.asyncio
async def test_dispatch_skipped_when_no_active_tokens() -> None:
    session = FakeNotificationSession()
    user_id = uuid.uuid4()

    # User has push enabled, but zero registered devices
    session.notification_settings.append(NotificationSetting(user_id=user_id, push=True))

    mock_fcm = MockFCMAdapter()
    service = NotificationService(session=session, fcm_adapter=mock_fcm)

    payload = NotificationPayload(
        title="Booking Accepted",
        body="Test",
        notification_type="booking.status_changed",
        entity_type="booking",
        entity_id="b-1",
        deep_link="mecha://booking/b-1",
    )

    report = await service.dispatch_notification(user_id, payload)
    assert report is None
    assert len(mock_fcm.sent_messages) == 0


@pytest.mark.asyncio
async def test_invalid_token_cleanup() -> None:
    session = FakeNotificationSession()
    user_id = uuid.uuid4()

    session.notification_settings.append(NotificationSetting(user_id=user_id, push=True))
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="valid-token", platform="android", is_active=True)
    )
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="dead-token-unregistered", platform="android", is_active=True)
    )

    # Mock adapter configured to flag dead-token-unregistered as invalid
    mock_fcm = MockFCMAdapter(invalid_tokens=["dead-token-unregistered"])
    service = NotificationService(session=session, fcm_adapter=mock_fcm)

    payload = NotificationPayload(
        title="En Route",
        body="Mechanic is on the way.",
        notification_type="booking.status_changed",
        entity_type="booking",
        entity_id="b-1",
        deep_link="mecha://booking/b-1",
    )

    report = await service.dispatch_notification(user_id, payload)
    assert report is not None
    assert report.total_tokens == 2
    assert report.success_count == 1
    assert report.failure_count == 1
    assert report.invalid_tokens == ["dead-token-unregistered"]

    # Invalid token must be purged from session
    remaining_tokens = [dt.fcm_token for dt in session.device_tokens]
    assert "dead-token-unregistered" not in remaining_tokens
    assert "valid-token" in remaining_tokens


@pytest.mark.asyncio
async def test_firebase_failure_isolation() -> None:
    session = FakeNotificationSession()
    user_id = uuid.uuid4()

    session.notification_settings.append(NotificationSetting(user_id=user_id, push=True))
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="tok-1", platform="android", is_active=True)
    )

    # Adapter simulates network crash / exception
    mock_fcm = MockFCMAdapter(should_raise=RuntimeError("Google FCM servers unreachable"))
    service = NotificationService(session=session, fcm_adapter=mock_fcm)

    payload = NotificationPayload(
        title="Booking Cancelled",
        body="Your booking has been cancelled.",
        notification_type="booking.status_changed",
        entity_type="booking",
        entity_id="b-1",
        deep_link="mecha://booking/b-1",
    )

    # Must NOT raise exception: caught, logged, returns None
    report = await service.dispatch_notification(user_id, payload)
    assert report is None


@pytest.mark.asyncio
async def test_dispatch_booking_notification_templates() -> None:
    session = FakeNotificationSession()
    user_id = uuid.uuid4()
    session.notification_settings.append(NotificationSetting(user_id=user_id, push=True))
    session.device_tokens.append(
        DeviceToken(user_id=user_id, fcm_token="token-android", platform="android", is_active=True)
    )

    mock_fcm = MockFCMAdapter()
    service = NotificationService(session=session, fcm_adapter=mock_fcm)

    booking_id = "8f3b2a10-4c5d-6e7f-8a9b-0c1d2e3f4a5b"

    # Test each canonical status transition
    for status_key, expected in BOOKING_NOTIFICATION_CONTENT.items():
        mock_fcm.sent_messages.clear()
        await service.dispatch_booking_notification(
            user_id=user_id,
            booking_id=booking_id,
            new_status=status_key,
            mechanic_name="Suresh Kumar",
        )

        assert len(mock_fcm.sent_messages) == 1
        msg = mock_fcm.sent_messages[0]
        payload: NotificationPayload = msg["payload"]

        assert payload.title == expected["title"]
        expected_body = expected["body"].format(short_id="8f3b2a10", mechanic="Suresh Kumar")
        assert payload.body == expected_body
        assert payload.entity_type == "booking"
        assert payload.entity_id == booking_id
        assert payload.deep_link == f"mecha://mechanic/booking/{booking_id}/tracking"
        assert payload.metadata["status"] == status_key
