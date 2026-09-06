"""Conversation data access (Sprint 2, Task 4 — Conversation Ownership).

DATA ACCESS ONLY — ownership decisions (generic 404, no existence leaks)
belong to the ChatService, not here. These methods take an explicit
``user_id`` so every read is scoped to the owning user at the SQL level.

Reads never commit; writes ``flush()`` only (commit owned by the service).
"""

from datetime import datetime, timezone
import inspect
from typing import Optional, Sequence
from sqlalchemy import delete, select

from app.models.chat_message import ChatMessage
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
        """List a user's conversations: pinned first, then most recently updated."""
        stmt = (
            select(Conversation)
            .where(Conversation.user_id == user_id)
            .order_by(Conversation.is_pinned.desc(), Conversation.updated_at.desc())
            .offset(offset)
            .limit(limit)
        )
        result = await self.session.scalars(stmt)
        res_all = result.all()
        if inspect.isawaitable(res_all):
            res_all = await res_all
        return list(res_all)

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

    async def update_properties(
        self,
        conversation: Conversation,
        *,
        title: Optional[str] = None,
        is_pinned: Optional[bool] = None,
    ) -> Conversation:
        """Update title and/or is_pinned flag (flush only)."""
        if title is not None:
            conversation.title = title.strip()
        if is_pinned is not None:
            conversation.is_pinned = is_pinned
        conversation.updated_at = datetime.now(timezone.utc)
        return await self.update(conversation)

    async def delete_owned(self, conversation_id: str, user_id: str) -> bool:
        """Delete a conversation if owned by user_id.

        Flushes on success; caller owns the transaction commit.
        Returns True if deleted, False if not found or unauthorized.
        """
        conversation = await self.get_owned(conversation_id, user_id)
        if conversation is None:
            return False
        # Explicitly delete child messages to handle databases without ON DELETE CASCADE FKs
        await self.session.execute(
            delete(ChatMessage).where(ChatMessage.conversation_id == conversation_id)
        )
        await self.session.delete(conversation)
        if hasattr(self.session, "flush") and callable(self.session.flush):
            res = self.session.flush()
            if inspect.isawaitable(res):
                await res
        return True

    async def touch(self, conversation: Conversation) -> Conversation:
        """Bump ``updated_at`` so list ordering stays current (flush only)."""
        conversation.updated_at = datetime.now(timezone.utc)
        return await self.update(conversation)

