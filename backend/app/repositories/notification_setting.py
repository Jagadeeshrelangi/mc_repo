"""Notification settings repository."""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification_setting import NotificationSetting
from app.repositories.base import BaseRepository


class NotificationSettingRepository(BaseRepository[NotificationSetting]):
    """Data access repository for user notification settings."""

    model = NotificationSetting

    async def get_or_create(self, user_id: uuid.UUID) -> NotificationSetting:
        """Fetch notification settings for user, creating default if not exists."""
        query = select(NotificationSetting).where(NotificationSetting.user_id == user_id)
        result = await self.session.execute(query)
        setting = result.scalar_one_or_none()
        if setting is None:
            setting = NotificationSetting(user_id=user_id, push=True)
            self.session.add(setting)
            await self.session.flush()
        return setting
