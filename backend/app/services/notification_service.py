"""Notification settings business logic and push notification orchestration service."""

import logging
import uuid
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.device_token import DeviceTokenRepository
from app.repositories.notification_setting import NotificationSettingRepository
from app.schemas.notification_setting import (
    NotificationSettingResponse,
    NotificationSettingUpdate,
)
from app.services.fcm_adapter import (
    FCMAdapterProtocol,
    FCMDeliveryReport,
    FirebaseAdminAdapter,
    NotificationPayload,
)

logger = logging.getLogger("mecha_connect.notifications")

BOOKING_NOTIFICATION_CONTENT = {
    "accepted": {
        "title": "Booking Accepted",
        "body": "Your service request #{short_id} has been accepted.",
    },
    "mechanicAssigned": {
        "title": "Mechanic Assigned",
        "body": "{mechanic} has been assigned to your booking.",
    },
    "enRoute": {
        "title": "Mechanic On The Way",
        "body": "{mechanic} is en route to your location.",
    },
    "arrived": {
        "title": "Mechanic Arrived",
        "body": "{mechanic} has arrived at your location.",
    },
    "completed": {
        "title": "Service Completed",
        "body": "Your service has been completed. View summary & invoice.",
    },
    "cancelled": {
        "title": "Booking Cancelled",
        "body": "Your booking #{short_id} has been cancelled.",
    },
}


class NotificationService:
    """Coordinates notification preferences, device tokens, and FCM push delivery."""

    def __init__(
        self,
        session: AsyncSession,
        notification_repository: Optional[NotificationSettingRepository] = None,
        device_token_repository: Optional[DeviceTokenRepository] = None,
        fcm_adapter: Optional[FCMAdapterProtocol] = None,
    ) -> None:
        self.session = session
        self.repo = notification_repository or NotificationSettingRepository(session)
        self.device_token_repo = device_token_repository or DeviceTokenRepository(session)
        self.fcm_adapter: FCMAdapterProtocol = fcm_adapter or FirebaseAdminAdapter()

    # ---------------------------------------------------------------------------
    # Notification Settings (existing behavior preserved)
    # ---------------------------------------------------------------------------

    async def get_settings(self, user: User) -> NotificationSettingResponse:
        """Fetch notification settings for the authenticated user."""
        user_uuid = uuid.UUID(str(user.id))
        setting = await self.repo.get_or_create(user_uuid)
        await self.session.commit()
        return NotificationSettingResponse.model_validate(setting)

    async def update_settings(
        self,
        user: User,
        payload: NotificationSettingUpdate,
    ) -> NotificationSettingResponse:
        """Update notification settings for the user and persist."""
        user_uuid = uuid.UUID(str(user.id))
        setting = await self.repo.get_or_create(user_uuid)
        setting.push = payload.push
        await self.session.commit()
        await self.session.refresh(setting)
        return NotificationSettingResponse.model_validate(setting)

    # ---------------------------------------------------------------------------
    # Push Notification Dispatch Pipeline
    # ---------------------------------------------------------------------------

    async def dispatch_notification(
        self,
        user_id: uuid.UUID,
        payload: NotificationPayload,
    ) -> Optional[FCMDeliveryReport]:
        """Send a push notification to all active devices of a user.

        Enforces:
        1. User preference check: if `push` is False, delivery is skipped.
        2. Device token query: if user has no tokens, skips gracefully.
        3. FCM multicast delivery.
        4. Stale/unregistered token cleanup from PostgreSQL.
        5. Absolute failure isolation: never propagates errors upward.
        """
        try:
            # 1. Enforce user preference
            setting = await self.repo.get_or_create(user_id)
            if not setting.push:
                logger.info(
                    "Push notification skipped for user %s: push disabled in settings",
                    user_id,
                )
                return None

            # 2. Lookup active device tokens
            tokens = await self.device_token_repo.get_active_tokens_for_user(user_id)
            if not tokens:
                logger.debug("No active device tokens found for user %s", user_id)
                return None

            # 3. Dispatch to FCM adapter
            report = await self.fcm_adapter.send_multicast(tokens, payload)
            logger.info(
                "Push dispatch for user %s: %d total, %d success, %d failure",
                user_id,
                report.total_tokens,
                report.success_count,
                report.failure_count,
            )

            # 4. Clean up invalid / unregistered tokens if any
            if report.invalid_tokens:
                for token in report.invalid_tokens:
                    await self.device_token_repo.delete_by_token(token)
                await self.session.commit()
                logger.info(
                    "Purged %d invalid device token(s) for user %s",
                    len(report.invalid_tokens),
                    user_id,
                )

            return report
        except Exception as exc:
            logger.error(
                "Error dispatching notification to user %s: %s",
                user_id,
                exc,
                exc_info=True,
            )
            return None

    # ---------------------------------------------------------------------------
    # Mechanic Booking Notification Trigger
    # ---------------------------------------------------------------------------

    async def dispatch_booking_notification(
        self,
        user_id: uuid.UUID,
        booking_id: str,
        new_status: str,
        mechanic_name: Optional[str] = None,
    ) -> Optional[FCMDeliveryReport]:
        """Construct and emit a canonical notification for a booking status change."""
        content = BOOKING_NOTIFICATION_CONTENT.get(new_status)
        if not content:
            logger.debug("No notification template defined for booking status '%s'", new_status)
            return None

        short_id = str(booking_id)[:8]
        mech = mechanic_name or "Your mechanic"
        title = content["title"]
        body = content["body"].format(short_id=short_id, mechanic=mech)

        payload = NotificationPayload(
            title=title,
            body=body,
            notification_type="booking.status_changed",
            entity_type="booking",
            entity_id=str(booking_id),
            deep_link=f"mecha://mechanic/booking/{booking_id}/tracking",
            metadata={
                "status": str(new_status),
                "booking_id": str(booking_id),
            },
        )

        return await self.dispatch_notification(user_id, payload)
