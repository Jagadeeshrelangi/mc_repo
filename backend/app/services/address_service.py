"""Address business logic service."""

from typing import List, Optional
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntityNotFoundException
from app.models.address import Address
from app.models.user import User
from app.repositories.address import AddressRepository
from app.schemas.address import AddressCreate, AddressResponse, AddressUpdate


class AddressService:
    """Coordinates address operations, default address invariants, and transactions."""

    def __init__(
        self,
        session: AsyncSession,
        address_repository: Optional[AddressRepository] = None,
    ) -> None:
        self.session = session
        self.address_repo = address_repository or AddressRepository(session)

    async def list_addresses(self, user: User) -> List[AddressResponse]:
        """Fetch all addresses for the authenticated user."""
        user_uuid = uuid.UUID(str(user.id))
        entities = await self.address_repo.list_for_user(user_uuid)
        return [AddressResponse.model_validate(e) for e in entities]

    async def get_address(self, user: User, address_id: uuid.UUID) -> AddressResponse:
        """Fetch an address verifying ownership."""
        user_uuid = uuid.UUID(str(user.id))
        entity = await self.address_repo.get_owned(address_id, user_uuid)
        if entity is None:
            raise EntityNotFoundException("Address not found.")
        return AddressResponse.model_validate(entity)

    async def create_address(self, user: User, payload: AddressCreate) -> AddressResponse:
        """Create an address enforcing the single default invariant and persisting."""
        user_uuid = uuid.UUID(str(user.id))
        total_existing = await self.address_repo.count_for_user(user_uuid)

        # First address is automatically default
        make_default = payload.is_default or total_existing == 0

        if make_default and total_existing > 0:
            await self.address_repo.unset_all_defaults(user_uuid)

        entity = Address(
            user_id=user_uuid,
            label=payload.label,
            address=payload.address,
            latitude=payload.latitude,
            longitude=payload.longitude,
            is_default=make_default,
        )
        self.session.add(entity)
        await self.session.commit()
        await self.session.refresh(entity)
        return AddressResponse.model_validate(entity)

    async def update_address(
        self,
        user: User,
        address_id: uuid.UUID,
        payload: AddressUpdate,
    ) -> AddressResponse:
        """Update an address verifying ownership and maintaining default state."""
        user_uuid = uuid.UUID(str(user.id))
        entity = await self.address_repo.get_owned(address_id, user_uuid)
        if entity is None:
            raise EntityNotFoundException("Address not found.")

        updates = payload.model_dump(exclude_unset=True)
        if updates.get("is_default") is True:
            await self.address_repo.unset_all_defaults(user_uuid)

        for key, value in updates.items():
            setattr(entity, key, value)

        await self.session.commit()
        await self.session.refresh(entity)
        return AddressResponse.model_validate(entity)

    async def delete_address(self, user: User, address_id: uuid.UUID) -> None:
        """Delete an address and promote newest remaining if default is deleted."""
        user_uuid = uuid.UUID(str(user.id))
        entity = await self.address_repo.get_owned(address_id, user_uuid)
        if entity is None:
            raise EntityNotFoundException("Address not found.")

        was_default = entity.is_default
        await self.session.delete(entity)
        await self.session.flush()

        # If deleted address was default, promote newest remaining
        if was_default:
            newest = await self.address_repo.get_newest_for_user(user_uuid)
            if newest is not None:
                newest.is_default = True

        await self.session.commit()

    async def set_default_address(self, user: User, address_id: uuid.UUID) -> AddressResponse:
        """Promote an address to default, clearing defaults on all other addresses."""
        user_uuid = uuid.UUID(str(user.id))
        entity = await self.address_repo.get_owned(address_id, user_uuid)
        if entity is None:
            raise EntityNotFoundException("Address not found.")

        await self.address_repo.unset_all_defaults(user_uuid)
        entity.is_default = True
        await self.session.commit()
        await self.session.refresh(entity)
        return AddressResponse.model_validate(entity)
