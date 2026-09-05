"""Vehicle API router.

All routes strictly require authentication via ``get_current_user`` and scope all data operations to ``current_user.id``.
"""

from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.vehicle import VehicleCreate, VehicleResponse, VehicleUpdate
from app.services.vehicle_service import VehicleService

router = APIRouter(
    prefix="/vehicles",
    tags=["Vehicles"],
)


@router.get(
    "",
    response_model=List[VehicleResponse],
    status_code=status.HTTP_200_OK,
    summary="List caller's vehicles",
)
async def list_vehicles(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[VehicleResponse]:
    """Return all vehicles registered to the authenticated caller."""
    service = VehicleService(session)
    return await service.list_vehicles(current_user.id)


@router.post(
    "",
    response_model=VehicleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new vehicle",
)
async def create_vehicle(
    payload: VehicleCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> VehicleResponse:
    """Register a new vehicle attached to the authenticated caller."""
    service = VehicleService(session)
    return await service.create_vehicle(current_user.id, payload)


@router.get(
    "/{vehicle_id}",
    response_model=VehicleResponse,
    status_code=status.HTTP_200_OK,
    summary="Get vehicle details",
)
async def get_vehicle(
    vehicle_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> VehicleResponse:
    """Fetch details for a specific owned vehicle."""
    service = VehicleService(session)
    return await service.get_vehicle(vehicle_id, current_user.id)


@router.patch(
    "/{vehicle_id}",
    response_model=VehicleResponse,
    status_code=status.HTTP_200_OK,
    summary="Update vehicle details",
)
async def update_vehicle(
    vehicle_id: UUID,
    payload: VehicleUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> VehicleResponse:
    """Update details for an owned vehicle."""
    service = VehicleService(session)
    return await service.update_vehicle(vehicle_id, current_user.id, payload)


@router.delete(
    "/{vehicle_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a vehicle",
)
async def delete_vehicle(
    vehicle_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> None:
    """Delete an owned vehicle."""
    service = VehicleService(session)
    await service.delete_vehicle(vehicle_id, current_user.id)


@router.post(
    "/{vehicle_id}/default",
    response_model=VehicleResponse,
    status_code=status.HTTP_200_OK,
    summary="Set vehicle as primary/default",
)
async def set_default_vehicle(
    vehicle_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> VehicleResponse:
    """Promote an owned vehicle to default."""
    service = VehicleService(session)
    return await service.set_default_vehicle(vehicle_id, current_user.id)
