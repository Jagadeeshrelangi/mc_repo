"""Vehicle repository layer.

DATA ACCESS ONLY — no FastAPI dependencies, no HTTP logic, no business rules.
Reads never commit; writes ``flush()`` only.
Transaction boundaries are owned by the service layer / database session context.
Every user-facing query strictly scopes by ``user_id`` to eliminate IDOR vulnerabilities.
"""

from typing import Any, Dict, Optional, Sequence
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.vehicle import Vehicle
from app.repositories.base import BaseRepository


class VehicleRepository(BaseRepository[Vehicle]):
    """Data access for user-owned vehicles."""

    model = Vehicle

    async def get_by_id(self, vehicle_id: UUID) -> Optional[Vehicle]:
        """Fetch a vehicle strictly by primary key without ownership check (internal)."""
        return await self.get(vehicle_id)

    async def get_owned(self, vehicle_id: UUID, user_id: UUID) -> Optional[Vehicle]:
        """Fetch a vehicle ONLY if it belongs to ``user_id`` (IDOR prevention)."""
        stmt = select(Vehicle).where(
            Vehicle.id == vehicle_id,
            Vehicle.user_id == user_id,
        )
        return await self.session.scalar(stmt)

    async def list_for_user(self, user_id: UUID) -> Sequence[Vehicle]:
        """Return all vehicles owned by ``user_id``, defaults first, newest first."""
        stmt = (
            select(Vehicle)
            .where(Vehicle.user_id == user_id)
            .order_by(Vehicle.is_default.desc(), Vehicle.created_at.desc())
        )
        result = await self.session.scalars(stmt)
        return list(result.all())

    async def count_for_user(self, user_id: UUID) -> int:
        """Count the number of vehicles registered to ``user_id``."""
        stmt = select(Vehicle).where(Vehicle.user_id == user_id)
        result = await self.session.scalars(stmt)
        return len(list(result.all()))

    async def unset_all_defaults(self, user_id: UUID) -> None:
        """Clear the ``is_default`` flag on all vehicles belonging to ``user_id``."""
        stmt = (
            update(Vehicle)
            .where(Vehicle.user_id == user_id, Vehicle.is_default.is_(True))
            .values(is_default=False)
        )
        await self.session.execute(stmt)
        await self.session.flush()

    async def create_vehicle(
        self,
        *,
        user_id: UUID,
        brand: str,
        model: str,
        registration: str,
        fuel_type: str,
        insurance_expiry: Optional[Any] = None,
        puc_expiry: Optional[Any] = None,
        service_due_km: Optional[int] = None,
        service_due_date: Optional[Any] = None,
        is_default: bool = False,
        health_score: Optional[int] = 80,
    ) -> Vehicle:
        """Create and persist a new vehicle row attached to ``user_id`` (flush only)."""
        vehicle = Vehicle(
            user_id=user_id,
            brand=brand,
            model=model,
            registration=registration,
            fuel_type=fuel_type,
            insurance_expiry=insurance_expiry,
            puc_expiry=puc_expiry,
            service_due_km=service_due_km,
            service_due_date=service_due_date,
            is_default=is_default,
            health_score=health_score,
        )
        return await self.create(vehicle)

    async def update_vehicle(
        self,
        vehicle: Vehicle,
        fields: Dict[str, Any],
    ) -> Vehicle:
        """Update fields on an already-loaded, verified-owned vehicle instance."""
        for key, value in fields.items():
            if hasattr(vehicle, key) and value is not None:
                setattr(vehicle, key, value)
        return await self.update(vehicle)

    async def delete_vehicle(self, vehicle: Vehicle) -> None:
        """Delete an already-loaded, verified-owned vehicle instance."""
        await self.delete(vehicle)
