"""Vehicle service layer.

Orchestrates vehicle management, owner-scoping, and the single-default-vehicle business invariant.
Commits write transactions explicitly.
"""

from typing import Sequence
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.vehicle import Vehicle
from app.repositories.vehicle import VehicleRepository
from app.schemas.vehicle import VehicleCreate, VehicleUpdate


class VehicleService:
    """Business logic for user vehicle operations."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.repo = VehicleRepository(session)

    async def list_vehicles(self, user_id: UUID) -> Sequence[Vehicle]:
        """List all vehicles belonging to the authenticated user."""
        return await self.repo.list_for_user(user_id)

    async def get_vehicle(self, vehicle_id: UUID, user_id: UUID) -> Vehicle:
        """Get an owned vehicle or raise 404."""
        vehicle = await self.repo.get_owned(vehicle_id, user_id)
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found",
            )
        return vehicle

    async def create_vehicle(self, user_id: UUID, payload: VehicleCreate) -> Vehicle:
        """Register a new vehicle for the authenticated user.
        
        If this is the user's first vehicle or if is_default is requested,
        ensures single-default vehicle invariant.
        """
        existing_count = await self.repo.count_for_user(user_id)
        
        # If user has 0 vehicles, automatically make the first one default
        make_default = payload.is_default or (existing_count == 0)

        if make_default:
            await self.repo.unset_all_defaults(user_id)

        vehicle = await self.repo.create_vehicle(
            user_id=user_id,
            brand=payload.brand.strip(),
            model=payload.model.strip(),
            registration=payload.registration.strip().upper(),
            fuel_type=payload.fuel_type,
            insurance_expiry=payload.insurance_expiry,
            puc_expiry=payload.puc_expiry,
            service_due_km=payload.service_due_km,
            service_due_date=payload.service_due_date,
            is_default=make_default,
            health_score=payload.health_score if payload.health_score is not None else 80,
        )
        await self.session.commit()
        await self.session.refresh(vehicle)
        return vehicle

    async def update_vehicle(
        self,
        vehicle_id: UUID,
        user_id: UUID,
        payload: VehicleUpdate,
    ) -> Vehicle:
        """Update an existing owned vehicle."""
        vehicle = await self.get_vehicle(vehicle_id, user_id)

        update_data = payload.model_dump(exclude_unset=True)
        if not update_data:
            return vehicle

        # If switching is_default to True, clear other defaults first
        if update_data.get("is_default") is True:
            await self.repo.unset_all_defaults(user_id)

        if "registration" in update_data and isinstance(update_data["registration"], str):
            update_data["registration"] = update_data["registration"].strip().upper()
        if "brand" in update_data and isinstance(update_data["brand"], str):
            update_data["brand"] = update_data["brand"].strip()
        if "model" in update_data and isinstance(update_data["model"], str):
            update_data["model"] = update_data["model"].strip()

        updated = await self.repo.update_vehicle(vehicle, update_data)
        await self.session.commit()
        await self.session.refresh(updated)
        return updated

    async def set_default_vehicle(self, vehicle_id: UUID, user_id: UUID) -> Vehicle:
        """Promote a specific owned vehicle to default and clear all others."""
        vehicle = await self.get_vehicle(vehicle_id, user_id)
        if vehicle.is_default:
            return vehicle

        await self.repo.unset_all_defaults(user_id)
        vehicle.is_default = True
        updated = await self.repo.update(vehicle)
        await self.session.commit()
        await self.session.refresh(updated)
        return updated

    async def delete_vehicle(self, vehicle_id: UUID, user_id: UUID) -> None:
        """Delete an owned vehicle. If the default is deleted, promote the newest remaining."""
        vehicle = await self.get_vehicle(vehicle_id, user_id)
        was_default = vehicle.is_default

        await self.repo.delete_vehicle(vehicle)

        # If we deleted the default vehicle, promote the first remaining vehicle if any exist
        if was_default:
            remaining = await self.repo.list_for_user(user_id)
            if remaining:
                remaining[0].is_default = True
                await self.repo.update(remaining[0])

        await self.session.commit()
