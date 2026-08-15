"""Chat-message model (``chat_messages`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table
(``chat_messages``: id TEXT PK, conversation_id TEXT FK → conversations(id),
role TEXT with CHECK(role IN ('user','assistant')), content TEXT,
timestamp TIMESTAMPTZ, response JSONB).

Appended to its owning conversation via ``conversation_id``; the FK
``ondelete=CASCADE`` ensures messages die with their conversation (approved
Task 4 architecture decision).
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def _generate_message_id() -> str:
    """Generate an opaque message id (``msg_<12 hex>``)."""
    return f"msg_{uuid.uuid4().hex[:12]}"


class ChatMessage(Base):
    """A single turn in a conversation (authoritative ``chat_messages``)."""

    __tablename__ = "chat_messages"

    __table_args__ = (
        CheckConstraint("role IN ('user', 'assistant')", name="ck_chat_messages_role"),
        Index("ix_chat_messages_conversation_id", "conversation_id"),
    )

    id: Mapped[str] = mapped_column(
        Text,
        primary_key=True,
        default=_generate_message_id,
    )

    conversation_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "conversations.id",
            name="fk_chat_messages_conversation_id",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    role: Mapped[str] = mapped_column(Text, nullable=False)
    content: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        default=lambda: datetime.now(timezone.utc),
    )
    response: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB, nullable=True)

    # --- Relationships ---
    conversation: Mapped["Conversation"] = relationship(
        back_populates="messages", passive_deletes=True
    )


from app.models.conversation import Conversation  # noqa: E402  (avoid circular import)