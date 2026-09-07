"""Unified Orders & Cross-Domain Activity Service.

Aggregates and manages user orders across all product domains:
- Parts (Marketplace orders)
- Fuel (Fuel delivery orders)
- Mechanic (Service bookings)
- AI (Diagnosis reports)

Backbone table: ``order_entries`` (authoritative unified activity ledger).
"""

from decimal import Decimal
from typing import List, Optional, Sequence
import uuid

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import EntityNotFoundException, InvalidInputException
from app.models.diagnosis import Diagnosis
from app.models.fuel_order import FuelOrder
from app.models.mechanic_booking import MechanicBooking
from app.models.mechanic_service import MechanicService
from app.models.mechanic import Mechanic
from app.models.order import Order
from app.models.order_entry import OrderEntry
from app.repositories.marketplace import OrderEntryRepository
from app.schemas.order import OrderCancelResponse, OrderDetailResponse, OrderEntryResponse


class OrderService:
    """Business logic for cross-domain unified orders."""

    def __init__(
        self,
        session: AsyncSession,
        entry_repo: Optional[OrderEntryRepository] = None,
    ):
        self.session = session
        self.entry_repo = entry_repo or OrderEntryRepository(session)

    async def sync_domain_orders_for_user(self, user_id: str) -> None:
        """Backfill/sync any domain records (Fuel, Mechanic, Parts, AI) into ``order_entries``.
        
        Ensures orders created prior to this unified service or across domain APIs
        automatically appear in the user's unified activity ledger.
        """
        # Fetch existing ledger IDs for this user
        existing_stmt = select(OrderEntry.id).where(OrderEntry.user_id == user_id)
        existing_res = await self.session.scalars(existing_stmt)
        existing_ids = set(existing_res.all())

        new_entries: List[OrderEntry] = []

        # 1. Sync Fuel Orders
        fuel_stmt = select(FuelOrder).where(FuelOrder.user_id == user_id)
        fuel_orders = (await self.session.scalars(fuel_stmt)).all()
        for fo in fuel_orders:
            if fo.id not in existing_ids:
                status_map = {
                    "requested": "In Progress",
                    "accepted": "In Progress",
                    "fuelPacked": "In Progress",
                    "partnerAssigned": "In Progress",
                    "enRoute": "In Progress",
                    "arrived": "In Progress",
                    "delivered": "Delivered",
                    "cancelled": "Cancelled",
                }
                order_status = status_map.get(fo.status, "In Progress")
                price = (
                    (fo.price_per_litre * fo.quantity)
                    if (fo.price_per_litre and fo.quantity)
                    else Decimal("500.00")
                )
                fuel_name = f"Fuel Delivery · {int(fo.quantity)}L {fo.fuel_type.capitalize()}"
                entry = OrderEntry(
                    id=fo.id,
                    user_id=user_id,
                    name=fuel_name,
                    brand=fo.brand or fo.station_name or "Fuel Partner",
                    quantity=int(fo.quantity),
                    price=price,
                    type="fuel",
                    status=order_status,
                    occurred_at=fo.created_at,
                    source="Fuel Delivery",
                )
                new_entries.append(entry)
                existing_ids.add(fo.id)

        # 2. Sync Mechanic Bookings
        mb_stmt = (
            select(MechanicBooking)
            .where(MechanicBooking.user_id == user_id)
            .options(
                selectinload(MechanicBooking.service),
                selectinload(MechanicBooking.mechanic),
            )
        )
        mechanic_bookings = (await self.session.scalars(mb_stmt)).all()
        for mb in mechanic_bookings:
            mb_id = str(mb.id)
            if mb_id not in existing_ids:
                status_map = {
                    "requested": "In Progress",
                    "assigned": "In Progress",
                    "en_route": "In Progress",
                    "arrived": "In Progress",
                    "in_progress": "In Progress",
                    "completed": "Completed",
                    "cancelled": "Cancelled",
                }
                mb_status = status_map.get(mb.status, "In Progress")
                service_name = mb.service.name if mb.service else "Mechanic Service"
                mechanic_name = mb.mechanic.name if mb.mechanic else "Mecha Partner"
                price = mb.service.price if mb.service and mb.service.price else Decimal("499.00")
                entry = OrderEntry(
                    id=mb_id,
                    user_id=user_id,
                    name=service_name,
                    brand=mechanic_name,
                    quantity=1,
                    price=price,
                    type="mechanic",
                    status=mb_status,
                    occurred_at=mb.created_at,
                    source="Mechanic Booking",
                )
                new_entries.append(entry)
                existing_ids.add(mb_id)

        # 3. Sync Marketplace Orders (if any exist without an entry)
        mkp_stmt = select(Order).where(Order.user_id == user_id).options(selectinload(Order.items))
        mkp_orders = (await self.session.scalars(mkp_stmt)).all()
        for mo in mkp_orders:
            order_entry_id = mo.external_id or str(mo.id)
            if order_entry_id not in existing_ids and str(mo.id) not in existing_ids:
                first_item = mo.items[0] if mo.items else None
                summary_name = (
                    first_item.product_name
                    if first_item
                    else "Auto Parts Order"
                )
                if len(mo.items) > 1:
                    summary_name += f" +{len(mo.items) - 1} items"
                brand = first_item.brand if first_item else None
                total_qty = sum(item.quantity for item in mo.items) if mo.items else 1
                entry = OrderEntry(
                    id=order_entry_id,
                    user_id=user_id,
                    name=summary_name,
                    brand=brand,
                    quantity=total_qty,
                    price=mo.grand_total or Decimal("0.00"),
                    type="parts",
                    status=mo.status or "Pending",
                    occurred_at=mo.created_at,
                    source="Marketplace Checkout",
                )
                new_entries.append(entry)
                existing_ids.add(order_entry_id)

        # 4. Sync AI Diagnoses
        diag_stmt = select(Diagnosis).where(Diagnosis.user_id == user_id)
        diagnoses = (await self.session.scalars(diag_stmt)).all()
        for diag in diagnoses:
            if diag.id not in existing_ids:
                entry = OrderEntry(
                    id=diag.id,
                    user_id=user_id,
                    name=diag.problem or "Vehicle Diagnostic Report",
                    brand=diag.vehicle_name or "AI Diagnosis",
                    quantity=1,
                    price=Decimal(str(diag.estimated_cost)) if diag.estimated_cost else Decimal("0.00"),
                    type="aiReport",
                    status="Completed",
                    occurred_at=diag.created_at,
                    source="AI Assistant",
                )
                new_entries.append(entry)
                existing_ids.add(diag.id)

        if new_entries:
            for e in new_entries:
                self.session.add(e)
            await self.session.commit()

    async def list_orders(
        self,
        user_id: str,
        offset: int = 0,
        limit: int = 50,
        entry_type: Optional[str] = None,
        status: Optional[str] = None,
    ) -> Sequence[OrderEntry]:
        """List unified user orders with optional type and status filtering."""
        # Synchronize any unsynced domain records first
        await self.sync_domain_orders_for_user(user_id)

        stmt = select(OrderEntry).where(OrderEntry.user_id == user_id)
        if entry_type:
            stmt = stmt.where(OrderEntry.type == entry_type)
        if status:
            stmt = stmt.where(OrderEntry.status == status)

        stmt = stmt.order_by(OrderEntry.occurred_at.desc()).offset(offset).limit(limit)
        result = await self.session.scalars(stmt)
        return result.all()

    async def get_order(self, order_id: str, user_id: str) -> OrderDetailResponse:
        """Get an order by id (owner-scoped) with rich domain details."""
        entry = await self.entry_repo.get_owned(entry_id=order_id, user_id=user_id)
        if not entry:
            # Check if order_id is a UUID or domain external_id
            await self.sync_domain_orders_for_user(user_id)
            entry = await self.entry_repo.get_owned(entry_id=order_id, user_id=user_id)

        if not entry:
            raise EntityNotFoundException("Order not found.")

        detail = OrderDetailResponse(
            id=entry.id,
            user_id=entry.user_id,
            name=entry.name,
            brand=entry.brand,
            quantity=entry.quantity,
            price=entry.price,
            type=entry.type,
            status=entry.status,
            occurred_at=entry.occurred_at,
            source=entry.source,
            domain_id=order_id,
            details={},
        )
        return detail

    async def cancel_order(self, order_id: str, user_id: str) -> OrderCancelResponse:
        """Cancel an order (owner-scoped) across the activity ledger and underlying domain record."""
        entry = await self.entry_repo.get_owned(entry_id=order_id, user_id=user_id)
        if not entry:
            await self.sync_domain_orders_for_user(user_id)
            entry = await self.entry_repo.get_owned(entry_id=order_id, user_id=user_id)

        if not entry:
            raise EntityNotFoundException("Order not found.")

        if entry.status in ("Delivered", "Completed", "Cancelled"):
            raise InvalidInputException(f"Cannot cancel order with status '{entry.status}'.")

        # Mark ledger status as Cancelled
        entry.status = "Cancelled"

        # Also cancel corresponding domain record if possible
        if entry.type == "fuel":
            await self.session.execute(
                update(FuelOrder)
                .where(FuelOrder.id == entry.id, FuelOrder.user_id == user_id)
                .values(status="cancelled")
            )
        elif entry.type == "mechanic":
            try:
                booking_uuid = uuid.UUID(entry.id)
                await self.session.execute(
                    update(MechanicBooking)
                    .where(MechanicBooking.id == booking_uuid, MechanicBooking.user_id == user_id)
                    .values(status="cancelled")
                )
            except (ValueError, TypeError):
                pass
        elif entry.type == "parts":
            await self.session.execute(
                update(Order)
                .where(
                    (Order.external_id == entry.id) | (Order.id == entry.id),
                    Order.user_id == user_id,
                )
                .values(status="Cancelled")
            )

        await self.session.commit()
        return OrderCancelResponse(
            id=entry.id,
            status="Cancelled",
            message=f"Order '{entry.name}' cancelled successfully.",
        )
