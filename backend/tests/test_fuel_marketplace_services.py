"""Tests for Task 8 Stage 3B — Fuel & Marketplace Service Layer.

Validates business logic and transaction boundaries:
- Price calculation engines (Fuel Delivery & Marketplace)
- Multi-repository transaction orchestration (atomic commits)
- User ownership isolation
- Validation & domain error raising (EntityNotFoundException, InvalidInputException)
- State transitions and terminal state protection
- Coupon validation and discount computation
- Unified activity ledger creation
"""

from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, Mock
import pytest

from app.core.exceptions import EntityNotFoundException, InvalidInputException
from app.models.coupon import Coupon
from app.models.fuel_order import FuelOrder
from app.models.fuel_station import FuelStation
from app.models.invoice import Invoice
from app.models.order import Order
from app.models.order_entry import OrderEntry
from app.models.price_estimate import PriceEstimate
from app.models.product import Product
from app.repositories.fuel import (
    FuelOrderRepository,
    FuelPartnerRepository,
    FuelStationRepository,
    InvoiceRepository,
    PriceEstimateRepository,
    TrackingEventRepository,
)
from app.repositories.marketplace import (
    BrandRepository,
    CategoryRepository,
    CouponRepository,
    OfferRepository,
    OrderEntryRepository,
    OrderRepository,
    ProductRepository,
)
from app.schemas.fuel import FuelOrderCreate
from app.schemas.marketplace import OrderCreate, OrderItemCreate, ProductReviewCreate
from app.services.fuel_service import FuelService
from app.services.marketplace_service import MarketplaceService


def make_mock_session() -> AsyncMock:
    """Build an AsyncSession mock with commit and rollback tracking."""
    session = AsyncMock()
    session.add = Mock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    session.flush = AsyncMock()
    return session


# ============================================================================
# Fuel Service Tests
# ============================================================================


@pytest.mark.asyncio
async def test_fuel_calculate_price() -> None:
    session = make_mock_session()
    station_repo = AsyncMock(spec=FuelStationRepository)
    station_repo.get_by_id.return_value = FuelStation(
        id="st-1", name="IOCL", brand="IOCL", price_per_litre=Decimal("100.00"), eta_minutes=20
    )

    service = FuelService(session, station_repo=station_repo)

    # 1. Standard calculation
    estimate = await service.calculate_price("petrol", Decimal("10.0"), station_id="st-1")
    assert estimate.fuel_cost == Decimal("1000.00")
    assert estimate.delivery_charge == Decimal("29.00")
    assert estimate.platform_fee == Decimal("5.00")
    assert estimate.eta_minutes == 20
    # subtotal = 1034, tax = 20.68, grand_total = 1054.68
    assert estimate.taxes == Decimal("20.68")
    assert estimate.grand_total == Decimal("1054.68")

    # 2. Invalid fuel type
    with pytest.raises(InvalidInputException):
        await service.calculate_price("kerosene", Decimal("5.0"))

    # 3. Quantity bounds check (<1 or >20)
    with pytest.raises(InvalidInputException):
        await service.calculate_price("petrol", Decimal("0.5"))
    with pytest.raises(InvalidInputException):
        await service.calculate_price("petrol", Decimal("25.0"))


@pytest.mark.asyncio
async def test_fuel_create_order_atomic_transaction() -> None:
    session = make_mock_session()
    order_repo = AsyncMock(spec=FuelOrderRepository)
    station_repo = AsyncMock(spec=FuelStationRepository)
    estimate_repo = AsyncMock(spec=PriceEstimateRepository)
    tracking_repo = AsyncMock(spec=TrackingEventRepository)

    station_repo.get_by_id.return_value = FuelStation(
        id="st-1", name="IOCL", brand="IOCL", is_open=True, price_per_litre=Decimal("102.50")
    )
    order_repo.get_by_id.return_value = None

    service = FuelService(
        session,
        order_repo=order_repo,
        station_repo=station_repo,
        estimate_repo=estimate_repo,
        tracking_repo=tracking_repo,
    )

    payload = FuelOrderCreate(
        fuel_type="petrol",
        quantity=Decimal("5.0"),
        station_id="st-1",
        delivery_address="123 MG Road",
    )

    order = await service.create_order("user-123", payload)

    assert order.user_id == "user-123"
    assert order.fuel_type == "petrol"
    assert order.status == "requested"

    # Verify atomic multi-repository write
    order_repo.create.assert_awaited_once()
    estimate_repo.create.assert_awaited_once()
    tracking_repo.create.assert_awaited_once()
    session.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_fuel_create_order_closed_station_rejected() -> None:
    session = make_mock_session()
    station_repo = AsyncMock(spec=FuelStationRepository)
    station_repo.get_by_id.return_value = FuelStation(
        id="st-1", name="IOCL", brand="IOCL", is_open=False
    )

    service = FuelService(session, station_repo=station_repo)

    payload = FuelOrderCreate(
        fuel_type="petrol",
        quantity=Decimal("5.0"),
        station_id="st-1",
        delivery_address="123 MG Road",
    )

    with pytest.raises(InvalidInputException) as exc:
        await service.create_order("user-123", payload)
    assert "currently closed" in str(exc.value)


@pytest.mark.asyncio
async def test_fuel_order_ownership_and_not_found() -> None:
    session = make_mock_session()
    order_repo = AsyncMock(spec=FuelOrderRepository)
    order_repo.get_owned.return_value = None  # Missing or not owned

    service = FuelService(session, order_repo=order_repo)

    with pytest.raises(EntityNotFoundException):
        await service.get_order("fo-999", "user-123")


@pytest.mark.asyncio
async def test_fuel_update_order_status_and_terminal_protection() -> None:
    session = make_mock_session()
    order_repo = AsyncMock(spec=FuelOrderRepository)
    tracking_repo = AsyncMock(spec=TrackingEventRepository)
    invoice_repo = AsyncMock(spec=InvoiceRepository)

    active_order = FuelOrder(
        id="fo-1",
        user_id="user-123",
        fuel_type="petrol",
        quantity=Decimal("5.0"),
        status="enRoute",
        price_estimate=PriceEstimate(grand_total=Decimal("550.00")),
    )
    order_repo.get_owned.return_value = active_order
    invoice_repo.get_by_order_id.return_value = None

    service = FuelService(
        session,
        order_repo=order_repo,
        tracking_repo=tracking_repo,
        invoice_repo=invoice_repo,
    )

    # 1. Update to delivered -> creates invoice and tracking event
    updated = await service.update_order_status("fo-1", "delivered", user_id="user-123")
    assert updated.status == "delivered"
    order_repo.update.assert_awaited_once()
    tracking_repo.create.assert_awaited_once()
    invoice_repo.create.assert_awaited_once()
    session.commit.assert_awaited_once()

    # 2. Re-updating delivered order is rejected (terminal state)
    with pytest.raises(InvalidInputException):
        await service.update_order_status("fo-1", "cancelled", user_id="user-123")


# ============================================================================
# Marketplace Service Tests
# ============================================================================


@pytest.mark.asyncio
async def test_marketplace_validate_coupon() -> None:
    session = make_mock_session()
    coupon_repo = AsyncMock(spec=CouponRepository)

    from datetime import timedelta
    now = datetime.now(timezone.utc)
    coupon_repo.get_by_code.side_effect = lambda code: {
        "SAVE20": Coupon(
            id="cp-1",
            code="SAVE20",
            type="percent",
            value=Decimal("20.00"),
            min_order_value=Decimal("500.00"),
            max_discount=Decimal("200.00"),
            valid_from=now - timedelta(days=1),
            valid_until=now + timedelta(days=7),
        ),
        "FREEDEL": Coupon(
            id="cp-2",
            code="FREEDEL",
            type="freeDelivery",
            value=Decimal("0.00"),
            min_order_value=Decimal("200.00"),
            valid_from=now - timedelta(days=1),
            valid_until=now + timedelta(days=7),
        ),
    }.get(code)

    service = MarketplaceService(session, coupon_repo=coupon_repo)

    # 1. Valid percent coupon
    res1 = await service.validate_coupon("SAVE20", Decimal("800.00"))
    assert res1.is_valid is True
    assert res1.discount_amount == Decimal("160.00")

    # 2. Min order value not met
    res2 = await service.validate_coupon("SAVE20", Decimal("400.00"))
    assert res2.is_valid is False
    assert "Minimum order value" in res2.message

    # 3. Invalid coupon
    res3 = await service.validate_coupon("INVALID_CODE", Decimal("1000.00"))
    assert res3.is_valid is False


@pytest.mark.asyncio
async def test_marketplace_create_order_atomic_transaction() -> None:
    session = make_mock_session()
    order_repo = AsyncMock(spec=OrderRepository)
    entry_repo = AsyncMock(spec=OrderEntryRepository)
    product_repo = AsyncMock(spec=ProductRepository)
    coupon_repo = AsyncMock(spec=CouponRepository)

    product_repo.get_by_id.return_value = Product(
        id="prod-1", name="Brake Pads", price=Decimal("1500.00"), stock=10
    )
    coupon_repo.get_by_code.return_value = None
    order_repo.get_by_id.return_value = None

    service = MarketplaceService(
        session,
        order_repo=order_repo,
        entry_repo=entry_repo,
        product_repo=product_repo,
        coupon_repo=coupon_repo,
    )

    payload = OrderCreate(
        address="100 Feet Road, Indiranagar",
        payment_method="Credit Card",
        items=[
            OrderItemCreate(
                product_id="prod-1",
                product_name="Brake Pads",
                quantity=2,
                unit_price=Decimal("1500.00"),
            )
        ],
    )

    order = await service.create_order("user-abc", payload)

    assert order.user_id == "user-abc"
    assert order.subtotal == Decimal("3000.00")
    # Subtotal >= 999 -> free delivery (0)
    assert order.delivery == Decimal("0.00")
    # 18% GST on 3000 = 540.00
    assert order.tax == Decimal("540.00")
    assert order.grand_total == Decimal("3540.00")

    # Verify atomic commit
    order_repo.create.assert_awaited_once()
    entry_repo.create.assert_awaited_once()
    session.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_marketplace_create_order_empty_items_rejected() -> None:
    session = make_mock_session()
    service = MarketplaceService(session)

    # Empty items list
    payload = OrderCreate.model_construct(
        address="123 Street",
        payment_method="UPI",
        items=[],
    )

    with pytest.raises(InvalidInputException):
        await service.create_order("user-abc", payload)


@pytest.mark.asyncio
async def test_marketplace_order_ownership() -> None:
    session = make_mock_session()
    order_repo = AsyncMock(spec=OrderRepository)
    order_repo.get_owned.return_value = None

    service = MarketplaceService(session, order_repo=order_repo)

    with pytest.raises(EntityNotFoundException):
        await service.get_order("ord-uuid-1", "user-abc")
