"""Chat-message data access (Sprint 2, Task 4 — Conversation Ownership).

DATA ACCESS ONLY. Message reads are scoped through ``conversation_id`` (the
ownership check happens at the conversation level in the ChatService).

The 12-turn prompt window is expressed as ``ORDER BY timestamp DESC LIMIT 12``
reversed to ascending — the "last 12 messages" cap that used to live in
in-memory ``SessionMemory`` now lives at the query level.
"""

from typing import Optional, Sequence

from sqlalchemy import select

from app.models.chat_message import ChatMessage
from app.repositories.base import BaseRepository

# Number of recent turns fed into the LLM prompt window (unchanged from the
# pre-Task-4 in-memory cap, now enforced by the query).
HISTORY_WINDOW = 12


class ChatMessageRepository(BaseRepository[ChatMessage]):
    """Data access for the ``chat_messages`` table."""

    model = ChatMessage

    async def list_for_conversation(
        self,
        *,
        conversation_id: str,
        limit: int = HISTORY_WINDOW,
    ) -> Sequence[ChatMessage]:
        """Return the most recent ``limit`` messages, oldest-first.

        Queries the newest ``limit`` rows by ``timestamp DESC`` then reverses
        so the prompt builder receives chronological history.
        """
        stmt = (
            select(ChatMessage)
            .where(ChatMessage.conversation_id == conversation_id)
            .order_by(ChatMessage.timestamp.desc())
            .limit(limit)
        )
        result = await self.session.scalars(stmt)
        rows = list(await result.all())
        return list(reversed(rows))

    async def append(
        self,
        *,
        conversation_id: str,
        role: str,
        content: str,
        response: Optional[dict] = None,
    ) -> ChatMessage:
        """Append a message to a conversation (flush only)."""
        message = ChatMessage(
            conversation_id=conversation_id,
            role=role,
            content=content,
            response=response,
        )
        return await self.create(message)