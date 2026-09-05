"""Notification Setting model (``notification_settings`` table).

Mirrors the authoritative Supabase PostgreSQL schema.
"""

import uuid

from sqlalchemy import Boolean, ForeignKey, Uuid, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class NotificationSetting(Base):
    """User account notification preferences."""

    __tablename__ = "notification_settings"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    push: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        server_default=text("true"),
    )
