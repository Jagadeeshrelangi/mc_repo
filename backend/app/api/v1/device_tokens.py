import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.repositories.device_token import DeviceTokenRepository
from app.schemas.device_token import (
    DeviceTokenCreate,
    DeviceTokenDelete,
    DeviceTokenResponse,
)

router = APIRouter(
    prefix="/device-tokens",
    tags=["Device Tokens"],
)


@router.post(
    "",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register or update an FCM device token",
)
async def register_device_token(
    payload: DeviceTokenCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> DeviceTokenResponse:
    """Register or refresh an FCM device token for the authenticated user."""
    user_uuid = uuid.UUID(str(current_user.id))
    repo = DeviceTokenRepository(session)
    token = await repo.upsert_token(
        user_id=user_uuid,
        fcm_token=payload.fcm_token,
        platform=payload.platform.value,
        device_id=payload.device_id,
        app_version=payload.app_version,
    )
    await session.commit()
    await session.refresh(token)
    return DeviceTokenResponse.model_validate(token)


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Unregister an FCM device token",
)
async def unregister_device_token(
    payload: Optional[DeviceTokenDelete] = None,
    fcm_token: Optional[str] = Query(None, description="FCM token to unregister via query param"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> Response:
    """Unregister an FCM device token on logout or permission revocation."""
    token_str = (payload.fcm_token if payload else None) or fcm_token
    if token_str:
        user_uuid = uuid.UUID(str(current_user.id))
        repo = DeviceTokenRepository(session)
        await repo.delete_token(
            fcm_token=token_str,
            user_id=user_uuid,
        )
        await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
