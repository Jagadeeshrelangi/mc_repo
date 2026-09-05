"""Pydantic schemas for Notification Settings."""

from pydantic import BaseModel, ConfigDict, Field


class NotificationSettingUpdate(BaseModel):
    """Payload to update notification settings."""

    push: bool = Field(..., description="Enable or disable push notifications.")

    model_config = ConfigDict(extra="forbid")


class NotificationSettingResponse(BaseModel):
    """Public representation of notification settings."""

    push: bool = Field(..., description="Push notification status.")

    model_config = ConfigDict(from_attributes=True)
