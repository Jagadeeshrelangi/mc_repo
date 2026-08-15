"""Conversation data access (Sprint 2, Task 4 — Conversation Ownership).

DATA ACCESS ONLY — ownership decisions (generic 404, no existence leaks)
belong to the ChatService, not here. These methods take an explicit
``user_id`` so every read is scoped to the owning user at the SQL level.

Reads never commit; writes ``flush()`` only (commit owned by the service).
"""

from datetime import datetime, timezone
from typing import Optional, Sequence

from sqlalchemy import select

from app.models.conversation import Conversation
from app.repositories.base import BaseRepository


class ConversationRepository(BaseRepository[Conversation]):
    """Data access for the ``conversations`` table (owner-scoped)."""

    model = Conversation

    async def get_owned(self, conversation_id: str, user_id: str) -> Optional[Conversation]:
        """Fetch a conversation by id ONLY if it belongs to ``user_id``.

        Returns ``None`` for both "does not exist" and "exists but belongs to
        someone else" — the caller (service) maps ``None`` to a generic 404 so
        no ownership information ever leaks.
        """
        stmt = select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id,
        )
        return await self.session.scalar(stmt)

    async def list_for_user(
        self,
        *,
        user_id: str,
        offset: int = 0,
        limit: int = 100,
    ) -> Sequence[Conversation]:
        """List a user's conversations, most recently updated first."""
        stmt = (
            select(Conversation)
            .where(Conversation.user_id == user_id)
            .order_by(Conversation.updated_at.desc())
            .offset(offset)
            .limit(limit)
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())

    async def create_owned(
        self,
        *,
        user_id: str,
        title: str = "New conversation",
    ) -> Conversation:
        """Create and persist a conversation owned by ``user_id`` (flush only)."""
        conversation = Conversation(user_id=user_id, title=title)
        return await self.create(conversation)

    async def update_title(self, conversation: Conversation, title: str) -> Conversation:
        """Set the conversation title (flush only)."""
        conversation.title = title
        return await self.update(conversation)

    async def touch(self, conversation: Conversation) -> Conversation:
        """Bump ``updated_at`` so list ordering stays current (flush only)."""
        conversation.updated_at = datetime.now(timezone.utc)
        return await self.update(conversation)