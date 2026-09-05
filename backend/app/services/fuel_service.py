"""Fuel Delivery service layer (Task 8 Stage 3B).

Coordinates business rules, pricing estimation, multi-repository transaction orchestration,
and ownership verification for Fuel Delivery.

Architecture
------------
- Request-scoped: receives an ``AsyncSession`` via constructor injection.
- Read operations NEVER commit.
- Write operations coordinate multiple repository operations and ``session.commit()``
  EXACTLY ONCE per logical operation; any error performs ``session.rollback()`` and re-raises.
- User ownership is strictly verified via explicit ``user_id`` arguments from authentication.
"""

from decimal import Decimal, ROUND_HALF_UP
from typing import List, Optional, Sequence
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntityNotFoundException, InvalidInputException
from app.models.fuel_order import FuelOrder
from app.models.fuel_station import FuelStation
from app.models.invoice import Invoice
from app.models.price_estimate import PriceEstimate
from app.models.tracking_event import TrackingEvent
from app.repositories.fuel import (
    FuelOrderRepository,
    FuelPartnerRepository,
    FuelStationRepository,
    InvoiceRepository,
    PriceEstimateRepository,
    TrackingEventRepository,
)
from app.schemas.fuel import (
    FuelOrderCreate,
    FuelOrderResponse,
    FuelStationResponse,
    InvoiceResponse,
    PriceEstimateResponse,
    TrackingEventResponse,
    VALID_FUEL_TYPES,
    VALID_FUEL_ORDER_STATUSES,
)

# Standard baseline fuel prices per litre (INR)
DEFAULT_FUEL_PRICES = {
    "petrol": Decimal("102.50"),
    "diesel": Decimal("89.20"),
    "premiumPetrol": Decimal("112.80"),
    "electric": Decimal("15.00"),
    "cng": Decimal("78.50"),
}

# Pricing parameters matching domain rules
MIN_QUANTITY = Decimal("1.0")
MAX_QUANTITY = Decimal("20.0")
STANDARD_DELIVERY_CHARGE = Decimal("29.00")
STANDARD_PLATFORM_FEE = Decimal("5.00")
TAX_RATE = Decimal("0.02")


class FuelService:
    """Service handling all Fuel Delivery business workflows."""

    def __init__(
        self,
        session: AsyncSession,
        order_repo: Optional[FuelOrderRepository] = None,
        station_repo: Optional[FuelStationRepository] = None,
        partner_repo: Optional[FuelPartnerRepository] = None,
        estimate_repo: Optional[PriceEstimateRepository] = None,
        tracking_repo: Optional[TrackingEventRepository] = None,
        invoice_repo: Optional[InvoiceRepository] = None,
    ) -> None:
        self.session = session
        self.order_repo = order_repo or FuelOrderRepository(session)
        self.station_repo = station_repo or FuelStationRepository(session)
        self.partner_repo = partner_repo or FuelPartnerRepository(session)
        self.estimate_repo = estimate_repo or PriceEstimateRepository(session)
        self.tracking_repo = tracking_repo or TrackingEventRepository(session)
        self.invoice_repo = invoice_repo or InvoiceRepository(session)

    # ── Stations ────────────────────────────────────────────────────────────

    async def list_stations(
        self, *, offset: int = 0, limit: int = 100, is_open: Optional[bool] = None
    ) -> Sequence[FuelStation]:
        """List partner fuel stations."""
        return await self.station_repo.list_all(offset=offset, limit=limit, is_open=is_open)

    async def get_station(self, station_id: str) -> FuelStation:
        """Get a single fuel station by ID."""
        station = await self.station_repo.get_by_id(station_id)
        if not station:
            raise EntityNotFoundException("Fuel station not found.")
        return station

    # ── Price Estimation ────────────────────────────────────────────────────

    async def calculate_price(
        self,
        fuel_type: str,
        quantity: Decimal,
        station_id: Optional[str] = None,
    ) -> PriceEstimateResponse:
        """Calculates upfront price estimate using domain pricing rules."""
        if fuel_type not in VALID_FUEL_TYPES:
            raise InvalidInputException(f"Invalid fuel type: {fuel_type}")

        if quantity < MIN_QUANTITY or quantity > MAX_QUANTITY:
            raise InvalidInputException(
                f"Quantity must be between {MIN_QUANTITY} and {MAX_QUANTITY} litres."
            )

        price_per_litre = DEFAULT_FUEL_PRICES.get(fuel_type, Decimal("100.00"))
        eta_minutes = 15

        if station_id:
            station = await self.station_repo.get_by_id(station_id)
            if station:
                if station.price_per_litre is not None and station.price_per_litre > Decimal("0"):
                    price_per_litre = station.price_per_litre
                if station.eta_minutes is not None:
                    eta_minutes = station.eta_minutes

        fuel_cost = (price_per_litre * quantity).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        delivery_charge = STANDARD_DELIVERY_CHARGE
        platform_fee = STANDARD_PLATFORM_FEE
        subtotal = fuel_cost + delivery_charge + platform_fee
        taxes = (subtotal * TAX_RATE).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        grand_total = subtotal + taxes

        return PriceEstimateResponse(
            fuel_cost=fuel_cost,
            delivery_charge=delivery_charge,
            platform_fee=platform_fee,
            taxes=taxes,
            grand_total=grand_total,
            eta_minutes=eta_minutes,
        )

    # ── Orders ──────────────────────────────────────────────────────────────

    async def create_order(self, user_id: str, payload: FuelOrderCreate) -> FuelOrder:
        """Places a new fuel delivery order within an atomic database transaction.

        Flow:
        1. Validate fuel type and quantity bounds.
        2. Validate station if station_id is provided.
        3. Compute price breakdown.
        4. Persist FuelOrder, PriceEstimate, and initial TrackingEvent.
        5. session.commit() once.
        """
        if payload.fuel_type not in VALID_FUEL_TYPES:
            raise InvalidInputException(f"Invalid fuel type: {payload.fuel_type}")

        if payload.quantity < MIN_QUANTITY or payload.quantity > MAX_QUANTITY:
            raise InvalidInputException(
                f"Quantity must be between {MIN_QUANTITY} and {MAX_QUANTITY} litres."
            )

        station_name = payload.station_name
        brand = payload.brand
        price_per_litre = payload.price_per_litre or DEFAULT_FUEL_PRICES.get(payload.fuel_type, Decimal("100.00"))

        if payload.station_id:
            station = await self.station_repo.get_by_id(payload.station_id)
            if not station:
                raise EntityNotFoundException("Selected fuel station not found.")
            if not station.is_open:
                raise InvalidInputException("Selected fuel station is currently closed.")
            station_name = station.name
            brand = station.brand
            if station.price_per_litre:
                price_per_litre = station.price_per_litre

        # Calculate authoritative price estimate
        estimate_data = await self.calculate_price(
            fuel_type=payload.fuel_type,
            quantity=payload.quantity,
            station_id=payload.station_id,
        )

        order_id = f"FO-{uuid.uuid4().hex[:8].upper()}"

        try:
            order = FuelOrder(
                id=order_id,
                user_id=user_id,
                fuel_type=payload.fuel_type,
                quantity=payload.quantity,
                vehicle_type=payload.vehicle_type,
                vehicle_name=payload.vehicle_name,
                vehicle_number=payload.vehicle_number,
                station_id=payload.station_id,
                station_name=station_name,
                brand=brand,
                price_per_litre=price_per_litre,
                delivery_label=payload.delivery_label,
                delivery_address=payload.delivery_address,
                lat=payload.lat,
                lng=payload.lng,
                status="requested",
                payment_method=payload.payment_method or "UPI",
            )
            await self.order_repo.create(order)

            # Persist 1:1 price estimate
            estimate = PriceEstimate(
                fuel_order_id=order_id,
                fuel_cost=estimate_data.fuel_cost,
                delivery_charge=estimate_data.delivery_charge,
                platform_fee=estimate_data.platform_fee,
                taxes=estimate_data.taxes,
                grand_total=estimate_data.grand_total,
                eta_minutes=estimate_data.eta_minutes,
            )
            await self.estimate_repo.create(estimate)

            # Persist initial tracking event
            initial_event = TrackingEvent(
                id=str(uuid.uuid4()),
                order_id=order_id,
                status="requested",
                partner_lat=payload.lat,
                partner_lng=payload.lng,
                eta_minutes=estimate_data.eta_minutes,
            )
            await self.tracking_repo.create(initial_event)

            await self.session.commit()

            # Return loaded order with relations
            loaded_order = await self.order_repo.get_by_id(order_id, load_relations=True)
            return loaded_order or order
        except Exception:
            await self.session.rollback()
            raise

    async def get_order(self, order_id: str, user_id: str) -> FuelOrder:
        """Fetch a fuel order belonging to the authenticated user."""
        order = await self.order_repo.get_owned(order_id, user_id, load_relations=True)
        if not order:
            raise EntityNotFoundException("Fuel order not found.")
        return order

    async def list_user_orders(
        self, user_id: str, *, offset: int = 0, limit: int = 50
    ) -> Sequence[FuelOrder]:
        """List fuel orders for the authenticated user, newest first."""
        return await self.order_repo.list_for_user(
            user_id, offset=offset, limit=limit, load_relations=True
        )

    async def update_order_status(
        self,
        order_id: str,
        new_status: str,
        user_id: Optional[str] = None,
        partner_id: Optional[str] = None,
    ) -> FuelOrder:
        """Updates status of a fuel order and records tracking event in one transaction."""
        if new_status not in VALID_FUEL_ORDER_STATUSES:
            raise InvalidInputException(f"Invalid status: {new_status}")

        order = (
            await self.order_repo.get_owned(order_id, user_id, load_relations=True)
            if user_id
            else await self.order_repo.get_by_id(order_id, load_relations=True)
        )
        if not order:
            raise EntityNotFoundException("Fuel order not found.")

        # Terminal state check
        if order.status in ("delivered", "cancelled"):
            raise InvalidInputException(
                f"Order is already in terminal status '{order.status}' and cannot be modified."
            )

        try:
            order.status = new_status
            if partner_id:
                order.partner_id = partner_id
            await self.order_repo.update(order)

            # Record tracking event
            event = TrackingEvent(
                id=str(uuid.uuid4()),
                order_id=order_id,
                status=new_status,
            )
            await self.tracking_repo.create(event)

            # When delivered, create invoice if not exists
            if new_status == "delivered":
                existing_invoice = await self.invoice_repo.get_by_order_id(order_id)
                if not existing_invoice and order.price_estimate:
                    invoice = Invoice(
                        invoice_id=f"INV-{uuid.uuid4().hex[:8].upper()}",
                        order_id=order_id,
                        grand_total=order.price_estimate.grand_total,
                    )
                    await self.invoice_repo.create(invoice)

            await self.session.commit()
            return order
        except Exception:
            await self.session.rollback()
            raise

    # ── Tracking & Invoices ─────────────────────────────────────────────────

    async def get_tracking_events(self, order_id: str, user_id: str) -> Sequence[TrackingEvent]:
        """Fetch tracking events for a user's fuel order."""
        # Check ownership first
        order = await self.order_repo.get_owned(order_id, user_id, load_relations=False)
        if not order:
            raise EntityNotFoundException("Fuel order not found.")
        return await self.tracking_repo.list_for_order(order_id)

    async def get_invoice(self, order_id: str, user_id: str) -> Invoice:
        """Fetch invoice for a completed fuel order."""
        order = await self.order_repo.get_owned(order_id, user_id, load_relations=False)
        if not order:
            raise EntityNotFoundException("Fuel order not found.")
        invoice = await self.invoice_repo.get_by_order_id(order_id)
        if not invoice:
            raise EntityNotFoundException("Invoice not found for this order.")
        return invoice
