"""Reusable async repository base (Sprint 2, Task 3, Stage 4).

Transaction ownership convention
--------------------------------
- A repository receives its ``AsyncSession`` via constructor injection; it
  never creates or owns a global database session.
- **Read** operations never commit.
- **Write** operations add/update/delete and ``flush()`` to surface DB errors
  and materialize server-generated values (e.g. UUID PKs), but they **do not
  commit**. The caller (the future auth service) owns the transaction
  boundary and calls ``session.commit()`` explicitly once a multi-step
  workflow (e.g. register, refresh rotation) completes.

This keeps repositories DATA ACCESS ONLY and lets the service coordinate
atomic multi-operation transactions without unexpected intermediate commits.
"""

from typing import Any, Generic, Optional, Sequence, TypeVar

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import Base

T = TypeVar("T", bound=Base)


class BaseRepository(Generic[T]):
    """Minimal async CRUD abstraction for a single ORM model.

    Subclasses must set ``model`` to the concrete ORM class. The session is
    provided by the caller (dependency injection) — never created here.
    """

    model: type[T]

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get(self, entity_id: Any) -> Optional[T]:
        """Fetch an entity by primary key, or ``None`` if absent."""
        return await self.session.get(self.model, entity_id)

    async def list(
        self,
        *,
        offset: int = 0,
        limit: int = 100,
        **filters: Any,
    ) -> Sequence[T]:
        """List entities, optionally filtered by column equality.

        ``filters`` maps model attribute names to values
        (e.g. ``role="admin"``). Ordering is by primary key for
        determinism. Read-only: never commits.
        """
        stmt = select(self.model)
        for column_name, value in filters.items():
            stmt = stmt.where(getattr(self.model, column_name) == value)
        stmt = stmt.order_by(self.model.id).offset(offset).limit(limit)
        result = await self.session.scalars(stmt)
        return list(await result.all())

    async def create(self, obj: T) -> T:
        """Persist a new entity (flush; commit owned by the caller)."""
        self.session.add(obj)
        await self.session.flush()
        return obj

    async def update(self, obj: T) -> T:
        """Persist pending changes on an already-loaded entity."""
        await self.session.flush()
        return obj

    async def delete(self, obj: T) -> None:
        """Delete an entity (flush; commit owned by the caller)."""
        await self.session.delete(obj)
        await self.session.flush()