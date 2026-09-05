"""Address repository for database operations on the ``addresses`` table."""

from typing import List, Optional
import uuid

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.address import Address
from app.repositories.base import BaseRepository


class AddressRepository(BaseRepository[Address]):
    """Data access repository for user delivery / service addresses."""

    model = Address

    async def list_for_user(self, user_id: uuid.UUID) -> List[Address]:
        """Fetch all addresses owned by a user, default address first, newest first."""
        query = (
            select(Address)
            .where(Address.user_id == user_id)
            .order_by(Address.is_default.desc(), Address.created_at.desc())
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_owned(self, address_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Address]:
        """Fetch an address by ID strictly asserting user ownership."""
        query = select(Address).where(
            Address.id == address_id,
            Address.user_id == user_id,
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def count_for_user(self, user_id: uuid.UUID) -> int:
        """Return total number of addresses owned by the user."""
        query = select(func.count(Address.id)).where(Address.user_id == user_id)
        result = await self.session.execute(query)
        return result.scalar() or 0

    async def get_newest_for_user(self, user_id: uuid.UUID) -> Optional[Address]:
        """Return the newest created address for a user."""
        query = (
            select(Address)
            .where(Address.user_id == user_id)
            .order_by(Address.created_at.desc())
            .limit(1)
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def unset_all_defaults(self, user_id: uuid.UUID) -> None:
        """Clear `is_default=False` on all addresses owned by the user."""
        stmt = (
            update(Address)
            .where(Address.user_id == user_id)
            .values(is_default=False)
        )
        await self.session.execute(stmt)
        await self.session.flush()
