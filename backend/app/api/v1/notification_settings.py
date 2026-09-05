"""Notification Settings API routes."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.notification_setting import (
    NotificationSettingResponse,
    NotificationSettingUpdate,
)
from app.services.notification_service import NotificationService

router = APIRouter(
    prefix="/notification-settings",
    tags=["Notification Settings"],
)


@router.get(
    "",
    response_model=NotificationSettingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get user notification preferences",
)
async def get_notification_settings(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> NotificationSettingResponse:
    """Return notification preferences for the authenticated user."""
    service = NotificationService(session)
    return await service.get_settings(current_user)


@router.patch(
    "",
    response_model=NotificationSettingResponse,
    status_code=status.HTTP_200_OK,
    summary="Update user notification preferences",
)
async def update_notification_settings(
    payload: NotificationSettingUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> NotificationSettingResponse:
    """Update notification preferences for the authenticated user."""
    service = NotificationService(session)
    return await service.update_settings(current_user, payload)
