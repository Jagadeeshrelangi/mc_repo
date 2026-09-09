"""Device Token repository."""

import uuid
from datetime import datetime, timezone
from typing import Optional, Sequence

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device_token import DeviceToken
from app.repositories.base import BaseRepository


class DeviceTokenRepository(BaseRepository[DeviceToken]):
    """Data access repository for FCM device registration tokens."""

    model = DeviceToken

    async def upsert_token(
        self,
        user_id: uuid.UUID,
        fcm_token: str,
        platform: str,
        device_id: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> DeviceToken:
        """Register or update an FCM device token.

        If the token already exists (even if previously registered by another
        user on the same physical device), ownership is transferred to the
        given user and the token is reactivated.
        """
        stmt = select(DeviceToken).where(DeviceToken.fcm_token == fcm_token)
        result = await self.session.execute(stmt)
        token = result.scalar_one_or_none()

        now = datetime.now(timezone.utc)
        if token is not None:
            token.user_id = user_id
            token.platform = platform
            if device_id is not None:
                token.device_id = device_id
            if app_version is not None:
                token.app_version = app_version
            token.is_active = True
            token.updated_at = now
        else:
            token = DeviceToken(
                user_id=user_id,
                fcm_token=fcm_token,
                platform=platform,
                device_id=device_id,
                app_version=app_version,
                is_active=True,
                created_at=now,
                updated_at=now,
            )
            self.session.add(token)

        await self.session.flush()
        return token

    async def get_active_tokens_for_user(self, user_id: uuid.UUID) -> Sequence[str]:
        """Return all active FCM tokens registered to the given user."""
        stmt = (
            select(DeviceToken.fcm_token)
            .where(
                DeviceToken.user_id == user_id,
                DeviceToken.is_active.is_(True),
            )
            .order_by(DeviceToken.updated_at.desc())
        )
        result = await self.session.execute(stmt)
        return result.scalars().all()

    async def delete_token(
        self,
        fcm_token: str,
        user_id: Optional[uuid.UUID] = None,
    ) -> bool:
        """Delete a token by FCM token string, optionally owner-scoped.

        Returns True if a row was deleted, False otherwise.
        """
        stmt = delete(DeviceToken).where(DeviceToken.fcm_token == fcm_token)
        if user_id is not None:
            stmt = stmt.where(DeviceToken.user_id == user_id)
        result = await self.session.execute(stmt)
        await self.session.flush()
        return (result.rowcount or 0) > 0

    async def delete_by_token(self, fcm_token: str) -> bool:
        """Unconditionally delete a token by FCM string (used for stale token cleanup)."""
        return await self.delete_token(fcm_token)

    async def deactivate_token(
        self,
        fcm_token: str,
        user_id: Optional[uuid.UUID] = None,
    ) -> bool:
        """Mark a token inactive without deleting the row."""
        stmt = (
            update(DeviceToken)
            .where(DeviceToken.fcm_token == fcm_token)
            .values(is_active=False, updated_at=datetime.now(timezone.utc))
        )
        if user_id is not None:
            stmt = stmt.where(DeviceToken.user_id == user_id)
        result = await self.session.execute(stmt)
        await self.session.flush()
        return (result.rowcount or 0) > 0
