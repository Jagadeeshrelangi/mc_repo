"""Conversation model (``conversations`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table
(``conversations``: id TEXT PK, user_id UUID FK → users(id), title, is_pinned,
created_at, updated_at).

Ownership
---------
Every conversation is bound to its owning user via ``user_id``. The FK
``ondelete=CASCADE`` is a deliberate strengthening of the frozen schema's
default (NO ACTION) so deleting a user cleans their conversations (approved
Task 4 architecture decision).

``id`` is app-generated (``session_<12 hex>``, preserving the pre-Task-4
``session_id`` wire format); the authoritative schema declares ``TEXT PRIMARY
KEY`` with no server default, so no server_default is added.
"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Text, Uuid, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def _generate_session_id() -> str:
    """Generate an opaque session id matching the pre-Task-4 wire format."""
    return f"session_{uuid.uuid4().hex[:12]}"


class Conversation(Base):
    """A user-owned conversation thread (authoritative ``conversations``)."""

    __tablename__ = "conversations"

    __table_args__ = (
        Index("ix_conversations_user_id", "user_id"),
    )

    id: Mapped[str] = mapped_column(
        Text,
        primary_key=True,
        default=_generate_session_id,
    )

    # Owning user (Task 4 ownership FK). Matches ``users.id`` (UUID column).
    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("users.id", name="fk_conversations_user_id_users", ondelete="CASCADE"),
        nullable=False,
    )

    title: Mapped[str] = mapped_column(Text, nullable=False)
    is_pinned: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        default=lambda: datetime.now(timezone.utc),
    )

    # --- Relationships ---
    messages: Mapped[list["ChatMessage"]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="ChatMessage.timestamp",
    )


from app.models.chat_message import ChatMessage  # noqa: E402  (avoid circular import)