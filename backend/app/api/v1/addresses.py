"""Address API routes."""

from typing import List
import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.address import AddressCreate, AddressResponse, AddressUpdate
from app.services.address_service import AddressService

router = APIRouter(
    prefix="/addresses",
    tags=["Addresses"],
)


@router.get(
    "",
    response_model=List[AddressResponse],
    status_code=status.HTTP_200_OK,
    summary="List the authenticated user's addresses",
)
async def list_addresses(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[AddressResponse]:
    """Return all addresses owned by the authenticated user."""
    service = AddressService(session)
    return await service.list_addresses(current_user)


@router.post(
    "",
    response_model=AddressResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new address",
)
async def create_address(
    payload: AddressCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> AddressResponse:
    """Create a new address owned by the authenticated user."""
    service = AddressService(session)
    return await service.create_address(current_user, payload)


@router.get(
    "/{address_id}",
    response_model=AddressResponse,
    status_code=status.HTTP_200_OK,
    summary="Get an address by ID",
)
async def get_address(
    address_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> AddressResponse:
    """Get address details strictly asserting ownership."""
    service = AddressService(session)
    return await service.get_address(current_user, address_id)


@router.patch(
    "/{address_id}",
    response_model=AddressResponse,
    status_code=status.HTTP_200_OK,
    summary="Update an address",
)
async def update_address(
    address_id: uuid.UUID,
    payload: AddressUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> AddressResponse:
    """Update address fields strictly asserting ownership."""
    service = AddressService(session)
    return await service.update_address(current_user, address_id, payload)


@router.delete(
    "/{address_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an address",
)
async def delete_address(
    address_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> None:
    """Delete an address strictly asserting ownership."""
    service = AddressService(session)
    await service.delete_address(current_user, address_id)


@router.post(
    "/{address_id}/default",
    response_model=AddressResponse,
    status_code=status.HTTP_200_OK,
    summary="Set address as default",
)
async def set_default_address(
    address_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> AddressResponse:
    """Designate an address as the user's default address."""
    service = AddressService(session)
    return await service.set_default_address(current_user, address_id)
