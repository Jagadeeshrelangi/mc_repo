"""Pydantic v2 schemas for Device Token registration and lifecycle."""

import uuid
from datetime import datetime
from enum import Enum
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field


class DevicePlatform(str, Enum):
    """Allowed device platforms."""

    ANDROID = "android"
    IOS = "ios"
    WEB = "web"


class DeviceTokenCreate(BaseModel):
    """Payload to register or update an FCM device token."""

    fcm_token: str = Field(
        ...,
        min_length=1,
        max_length=4096,
        description="FCM registration token issued by Firebase SDK.",
    )
    platform: DevicePlatform = Field(
        ...,
        description="Operating system / platform: 'android', 'ios', or 'web'.",
    )
    device_id: Optional[str] = Field(
        None,
        max_length=255,
        description="Optional hardware/install UUID for idempotent updates.",
    )
    app_version: Optional[str] = Field(
        None,
        max_length=50,
        description="Optional client app version string.",
    )

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class DeviceTokenDelete(BaseModel):
    """Payload to unregister an FCM device token."""

    fcm_token: str = Field(
        ...,
        min_length=1,
        max_length=4096,
        description="FCM token to unregister/delete.",
    )

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class DeviceTokenResponse(BaseModel):
    """Public representation of a registered device token."""

    id: uuid.UUID
    fcm_token: str
    platform: str
    device_id: Optional[str] = None
    app_version: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
