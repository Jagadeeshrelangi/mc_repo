"""FCM Adapter and push delivery abstractions.

Isolates all Firebase-specific infrastructure from domain services.
"""

import asyncio
import logging
import os
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Protocol, Sequence, Tuple

from app.core.config import settings

logger = logging.getLogger("mecha_connect.notifications")


@dataclass
class NotificationPayload:
    """Canonical notification payload for all Mecha Connect notification domains."""

    title: str
    body: str
    notification_type: str
    entity_type: str
    entity_id: str
    deep_link: str
    metadata: Dict[str, str] = field(default_factory=dict)

    def to_data_dict(self) -> Dict[str, str]:
        """Produce a string-only data dictionary compliant with FCM data payloads."""
        base = {
            "notification_type": str(self.notification_type),
            "entity_type": str(self.entity_type),
            "entity_id": str(self.entity_id),
            "deep_link": str(self.deep_link),
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        }
        for k, v in self.metadata.items():
            base[str(k)] = str(v)
        return base


@dataclass
class FCMDeliveryReport:
    """Standardized delivery feedback report from an FCM push dispatch."""

    total_tokens: int
    success_count: int
    failure_count: int
    invalid_tokens: List[str] = field(default_factory=list)
    failed_tokens: List[Tuple[str, str]] = field(default_factory=list)


class FCMAdapterProtocol(Protocol):
    """Interface contract for FCM push notification delivery."""

    async def send_multicast(
        self,
        tokens: Sequence[str],
        payload: NotificationPayload,
    ) -> FCMDeliveryReport:
        """Transmit notification to multiple device tokens."""
        ...


class FirebaseAdminAdapter:
    """Production FCM adapter using the official firebase-admin SDK."""

    def __init__(self, credentials_path: Optional[str] = None) -> None:
        self._credentials_path = credentials_path or settings.FIREBASE_CREDENTIALS_PATH
        self._initialized = False
        self._init_lock = asyncio.Lock()

    def _ensure_initialized_sync(self) -> bool:
        """Idempotently initialize the Firebase Admin default app.

        Returns True if initialized and available, False otherwise.
        """
        if self._initialized:
            return True

        if not self._credentials_path or not os.path.exists(self._credentials_path):
            logger.warning(
                "Firebase credentials not configured or file not found at '%s'. "
                "Push notifications cannot be delivered.",
                self._credentials_path,
            )
            return False

        try:
            import firebase_admin
            from firebase_admin import credentials

            if not firebase_admin._apps:
                cred = credentials.Certificate(self._credentials_path)
                firebase_admin.initialize_app(cred)
            self._initialized = True
            return True
        except Exception as exc:
            logger.error("Failed to initialize Firebase Admin SDK: %s", exc)
            return False

    def _send_sync(
        self,
        tokens: Sequence[str],
        payload: NotificationPayload,
    ) -> FCMDeliveryReport:
        """Synchronous implementation run in worker thread."""
        if not self._ensure_initialized_sync():
            return FCMDeliveryReport(
                total_tokens=len(tokens),
                success_count=0,
                failure_count=len(tokens),
                invalid_tokens=[],
                failed_tokens=[(t, "Firebase credentials not configured") for t in tokens],
            )

        from firebase_admin import messaging

        notification = messaging.Notification(
            title=payload.title,
            body=payload.body,
        )
        data = payload.to_data_dict()

        message = messaging.MulticastMessage(
            tokens=list(tokens),
            notification=notification,
            data=data,
        )

        try:
            batch_response = messaging.send_each_for_multicast(message)
        except Exception as exc:
            logger.error("FCM multicast batch failed: %s", exc)
            return FCMDeliveryReport(
                total_tokens=len(tokens),
                success_count=0,
                failure_count=len(tokens),
                invalid_tokens=[],
                failed_tokens=[(t, str(exc)) for t in tokens],
            )

        success_count = batch_response.success_count
        failure_count = batch_response.failure_count
        invalid_tokens: List[str] = []
        failed_tokens: List[Tuple[str, str]] = []

        for idx, resp in enumerate(batch_response.responses):
            if not resp.success:
                token = tokens[idx]
                exc = resp.exception
                err_msg = str(exc)
                is_invalid = False

                if isinstance(exc, messaging.UnregisteredError):
                    is_invalid = True
                elif exc is not None:
                    code = getattr(exc, "code", "") or getattr(exc, "http_response", "")
                    code_str = str(code).lower()
                    if any(
                        sub in code_str
                        for sub in (
                            "not-found",
                            "unregistered",
                            "invalid-argument",
                            "invalid-registration-token",
                        )
                    ):
                        is_invalid = True

                if is_invalid:
                    invalid_tokens.append(token)
                failed_tokens.append((token, err_msg))

        return FCMDeliveryReport(
            total_tokens=len(tokens),
            success_count=success_count,
            failure_count=failure_count,
            invalid_tokens=invalid_tokens,
            failed_tokens=failed_tokens,
        )

    async def send_multicast(
        self,
        tokens: Sequence[str],
        payload: NotificationPayload,
    ) -> FCMDeliveryReport:
        """Asynchronously dispatch multicast notification to Firebase."""
        if not tokens:
            return FCMDeliveryReport(0, 0, 0)
        return await asyncio.to_thread(self._send_sync, tokens, payload)


class MockFCMAdapter:
    """In-memory test double for FCM push notifications."""

    def __init__(
        self,
        *,
        fail_tokens: Optional[Sequence[str]] = None,
        invalid_tokens: Optional[Sequence[str]] = None,
        should_raise: Optional[Exception] = None,
    ) -> None:
        self.sent_messages: List[Dict[str, Any]] = []
        self.fail_tokens = set(fail_tokens or [])
        self.invalid_tokens = set(invalid_tokens or [])
        self.should_raise = should_raise

    async def send_multicast(
        self,
        tokens: Sequence[str],
        payload: NotificationPayload,
    ) -> FCMDeliveryReport:
        if self.should_raise is not None:
            raise self.should_raise

        self.sent_messages.append(
            {
                "tokens": list(tokens),
                "payload": payload,
            }
        )

        invalid: List[str] = []
        failed: List[Tuple[str, str]] = []
        success = 0

        for t in tokens:
            if t in self.invalid_tokens:
                invalid.append(t)
                failed.append((t, "MockUnregisteredToken"))
            elif t in self.fail_tokens:
                failed.append((t, "MockDeliveryFailure"))
            else:
                success += 1

        return FCMDeliveryReport(
            total_tokens=len(tokens),
            success_count=success,
            failure_count=len(failed),
            invalid_tokens=invalid,
            failed_tokens=failed,
        )
