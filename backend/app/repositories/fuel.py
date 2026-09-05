"""Fuel Delivery repository layer (Task 8 Stage 3A).

DATA ACCESS ONLY — no FastAPI dependencies, no HTTP logic, no business rules.
Reads never commit; writes ``flush()`` only.
Transaction boundaries are owned by the service layer.
"""

from datetime import datetime
from typing import Optional, Sequence

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.fuel_order import FuelOrder
from app.models.fuel_partner import FuelPartner
from app.models.fuel_station import FuelStation
from app.models.invoice import Invoice
from app.models.price_estimate import PriceEstimate
from app.models.tracking_event import TrackingEvent
from app.repositories.base import BaseRepository


def _fuel_order_relations():
    """Selectinload options for FuelOrder relationships."""
    return (
        selectinload(FuelOrder.price_estimate),
        selectinload(FuelOrder.invoice),
        selectinload(FuelOrder.tracking_events),
    )


class FuelStationRepository(BaseRepository[FuelStation]):
    """Data access for partner fuel stations catalog."""

    model = FuelStation

    async def get_by_id(self, station_id: str) -> Optional[FuelStation]:
        """Fetch station by primary key."""
        return await self.session.get(self.model, station_id)

    async def list_all(
        self,
        *,
        offset: int = 0,
        limit: int = 100,
        is_open: Optional[bool] = None,
    ) -> Sequence[FuelStation]:
        """List stations with optional is_open filtering."""
        stmt = select(self.model)
        if is_open is not None:
            stmt = stmt.where(self.model.is_open == is_open)
        stmt = stmt.order_by(self.model.id).offset(offset).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())

    async def list_by_brand(self, brand: str, *, limit: int = 50) -> Sequence[FuelStation]:
        """List stations for a specific brand."""
        stmt = select(self.model).where(self.model.brand == brand).order_by(self.model.id).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())


class FuelPartnerRepository(BaseRepository[FuelPartner]):
    """Data access for fuel delivery partners / drivers."""

    model = FuelPartner

    async def get_by_id(self, partner_id: str) -> Optional[FuelPartner]:
        """Fetch delivery partner by primary key."""
        return await self.session.get(self.model, partner_id)

    async def list_available(self, *, limit: int = 50) -> Sequence[FuelPartner]:
        """List currently available delivery partners."""
        stmt = select(self.model).where(self.model.is_available.is_(True)).order_by(self.model.id).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())


class PriceEstimateRepository(BaseRepository[PriceEstimate]):
    """Data access for fuel order price breakdowns."""

    model = PriceEstimate

    async def get_by_order_id(self, fuel_order_id: str) -> Optional[PriceEstimate]:
        """Fetch price estimate by fuel order ID."""
        return await self.session.get(self.model, fuel_order_id)


class TrackingEventRepository(BaseRepository[TrackingEvent]):
    """Data access for fuel order real-time tracking events."""

    model = TrackingEvent

    async def list_for_order(self, order_id: str) -> Sequence[TrackingEvent]:
        """List all tracking events for an order, ordered chronologically."""
        stmt = (
            select(self.model)
            .where(self.model.order_id == order_id)
            .order_by(self.model.occurred_at.asc())
        )
        result = await self.session.scalars(stmt)
        return list(result.all())


class InvoiceRepository(BaseRepository[Invoice]):
    """Data access for completed fuel order invoices."""

    model = Invoice

    async def get_by_id(self, invoice_id: str) -> Optional[Invoice]:
        """Fetch invoice by primary key."""
        return await self.session.get(self.model, invoice_id)

    async def get_by_order_id(self, order_id: str) -> Optional[Invoice]:
        """Fetch invoice by associated fuel order ID (1:1 relation)."""
        stmt = select(self.model).where(self.model.order_id == order_id)
        result = await self.session.scalars(stmt)
        return result.one_or_none()


class FuelOrderRepository(BaseRepository[FuelOrder]):
    """Data access for fuel delivery orders."""

    model = FuelOrder

    async def get_by_id(self, order_id: str, *, load_relations: bool = True) -> Optional[FuelOrder]:
        """Fetch order by ID (unscoped primary key read)."""
        if not load_relations:
            return await self.session.get(self.model, order_id)
        stmt = select(self.model).where(self.model.id == order_id).options(*_fuel_order_relations())
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def get_owned(
        self, order_id: str, user_id: str, *, load_relations: bool = True
    ) -> Optional[FuelOrder]:
        """Fetch order only if owned by the specified user (ownership-scoped read)."""
        stmt = (
            select(self.model)
            .where(self.model.id == order_id, self.model.user_id == user_id)
        )
        if load_relations:
            stmt = stmt.options(*_fuel_order_relations())
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def list_for_user(
        self,
        user_id: str,
        *,
        offset: int = 0,
        limit: int = 50,
        load_relations: bool = True,
    ) -> Sequence[FuelOrder]:
        """List orders belonging to a user, newest first."""
        stmt = (
            select(self.model)
            .where(self.model.user_id == user_id)
            .order_by(self.model.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        if load_relations:
            stmt = stmt.options(*_fuel_order_relations())
        result = await self.session.scalars(stmt)
        return list(result.all())

    async def list_all(
        self,
        *,
        offset: int = 0,
        limit: int = 50,
        status: Optional[str] = None,
        load_relations: bool = True,
    ) -> Sequence[FuelOrder]:
        """List orders across all users (for administrative views)."""
        stmt = select(self.model)
        if status is not None:
            stmt = stmt.where(self.model.status == status)
        stmt = stmt.order_by(self.model.created_at.desc()).offset(offset).limit(limit)
        if load_relations:
            stmt = stmt.options(*_fuel_order_relations())
        result = await self.session.scalars(stmt)
        return list(result.all())
