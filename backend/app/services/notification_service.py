"""Notification settings business logic service."""

import uuid
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.notification_setting import NotificationSettingRepository
from app.schemas.notification_setting import (
    NotificationSettingResponse,
    NotificationSettingUpdate,
)


class NotificationService:
    """Coordinates notification preference persistence."""

    def __init__(
        self,
        session: AsyncSession,
        notification_repository: Optional[NotificationSettingRepository] = None,
    ) -> None:
        self.session = session
        self.repo = notification_repository or NotificationSettingRepository(session)

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
