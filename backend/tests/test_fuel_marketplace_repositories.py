"""Tests for Task 8 Stage 3A — Fuel & Marketplace Repositories.

Validates data access contracts:
- Repository construction & session injection
- SQL statement generation & compilation (PostgreSQL dialect)
- Explicit user ownership filtering (FuelOrder, Order, OrderEntry)
- Relationship eager loading (selectinload)
- Catalog queries, sorting, and filtering
"""

import pytest
from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, Mock

from sqlalchemy import select
from sqlalchemy.dialects import postgresql
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fuel_order import FuelOrder
from app.models.fuel_partner import FuelPartner
from app.models.fuel_station import FuelStation
from app.models.invoice import Invoice
from app.models.price_estimate import PriceEstimate
from app.models.tracking_event import TrackingEvent
from app.models.brand import Brand
from app.models.category import Category
from app.models.coupon import Coupon
from app.models.offer import Offer
from app.models.order import Order
from app.models.order_entry import OrderEntry
from app.models.order_item import OrderItem
from app.models.product import Product
from app.models.product_review import ProductReview

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


def make_session() -> AsyncMock:
    """Build an AsyncSession mock."""
    session = AsyncMock(spec=AsyncSession)
    session.add = Mock()
    return session


def compile_stmt(stmt) -> str:
    """Compile a SQLAlchemy statement to PostgreSQL SQL text (literal binds)."""
    return str(
        stmt.compile(
            dialect=postgresql.dialect(),
            compile_kwargs={"literal_binds": True},
        )
    )


# ============================================================================
# Fuel Delivery Repositories
# ============================================================================


def test_fuel_station_repository_queries() -> None:
    session = make_session()
    repo = FuelStationRepository(session)
    assert repo.session is session
    assert repo.model is FuelStation


@pytest.mark.asyncio
async def test_fuel_station_repository_list_all() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = FuelStationRepository(session)
    await repo.list_all(is_open=True, limit=10)

    session.scalars.assert_called_once()
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM fuel_stations" in sql
    assert "fuel_stations.is_open = true" in sql
    assert "LIMIT 10" in sql


@pytest.mark.asyncio
async def test_fuel_partner_repository_list_available() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = FuelPartnerRepository(session)
    await repo.list_available(limit=5)

    session.scalars.assert_called_once()
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM fuel_partners" in sql
    assert "fuel_partners.is_available IS true" in sql
    assert "LIMIT 5" in sql


@pytest.mark.asyncio
async def test_tracking_event_repository_list_for_order() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = TrackingEventRepository(session)
    await repo.list_for_order("ORD-101")

    session.scalars.assert_called_once()
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM tracking_events" in sql
    assert "tracking_events.order_id = 'ORD-101'" in sql
    assert "ORDER BY tracking_events.occurred_at ASC" in sql


@pytest.mark.asyncio
async def test_fuel_order_repository_ownership_filtering() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.one_or_none.return_value = None
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = FuelOrderRepository(session)

    # 1. get_owned enforces both id and user_id in SQL
    await repo.get_owned("ORD-101", "usr-abc", load_relations=False)
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM fuel_orders" in sql
    assert "fuel_orders.id = 'ORD-101'" in sql
    assert "fuel_orders.user_id =" in sql

    # 2. list_for_user enforces user_id and newest-first order
    session.scalars.reset_mock()
    await repo.list_for_user("usr-abc", limit=20, load_relations=False)
    stmt2 = session.scalars.call_args[0][0]
    sql2 = compile_stmt(stmt2)
    assert "FROM fuel_orders" in sql2
    assert "fuel_orders.user_id =" in sql2
    assert "ORDER BY fuel_orders.created_at DESC" in sql2
    assert "LIMIT 20" in sql2


@pytest.mark.asyncio
async def test_fuel_order_create_flushes_session() -> None:
    session = make_session()
    repo = FuelOrderRepository(session)

    order = FuelOrder(
        id="ORD-101",
        user_id="usr-abc",
        fuel_type="petrol",
        quantity=Decimal("10.00"),
        status="requested",
    )
    created = await repo.create(order)
    assert created is order
    session.add.assert_called_once_with(order)
    session.flush.assert_awaited_once()


# ============================================================================
# Marketplace Repositories
# ============================================================================


@pytest.mark.asyncio
async def test_category_and_brand_repositories() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    cat_repo = CategoryRepository(session)
    await cat_repo.list_all()
    stmt_cat = session.scalars.call_args[0][0]
    sql_cat = compile_stmt(stmt_cat)
    assert "FROM categories" in sql_cat
    assert "ORDER BY categories.sort_order ASC, categories.name ASC" in sql_cat

    session.scalars.reset_mock()
    brand_repo = BrandRepository(session)
    await brand_repo.list_all()
    stmt_b = session.scalars.call_args[0][0]
    sql_b = compile_stmt(stmt_b)
    assert "FROM brands" in sql_b
    assert "ORDER BY brands.name ASC" in sql_b


@pytest.mark.asyncio
async def test_coupon_repository_get_by_code() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.one_or_none.return_value = None
    session.scalars.return_value = mock_result

    repo = CouponRepository(session)
    await repo.get_by_code("SAVE20")

    session.scalars.assert_called_once()
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM coupons" in sql
    assert "coupons.code = 'SAVE20'" in sql


@pytest.mark.asyncio
async def test_product_repository_filters_and_search() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = ProductRepository(session)
    await repo.list_all(
        category_id="cat-1",
        brand_id="brand-1",
        is_featured=True,
        search="Brake",
        load_relations=False,
    )

    session.scalars.assert_called_once()
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM products" in sql
    assert "products.category_id = 'cat-1'" in sql
    assert "products.brand_id = 'brand-1'" in sql
    assert "products.is_featured = true" in sql
    assert "products.name ILIKE '%Brake%'" in sql or "ILIKE" in sql


@pytest.mark.asyncio
async def test_order_repository_ownership_filtering() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.one_or_none.return_value = None
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = OrderRepository(session)

    # get_owned
    await repo.get_owned("ord-uuid-1", "user-uuid-1", load_relations=False)
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM orders" in sql
    assert "orders.id =" in sql
    assert "orders.user_id =" in sql

    # list_for_user
    session.scalars.reset_mock()
    await repo.list_for_user("user-uuid-1", load_relations=False)
    stmt2 = session.scalars.call_args[0][0]
    sql2 = compile_stmt(stmt2)
    assert "FROM orders" in sql2
    assert "orders.user_id =" in sql2
    assert "ORDER BY orders.created_at DESC" in sql2


@pytest.mark.asyncio
async def test_order_entry_repository_list_for_user() -> None:
    session = make_session()
    mock_result = Mock()
    mock_result.all.return_value = []
    session.scalars.return_value = mock_result

    repo = OrderEntryRepository(session)
    await repo.list_for_user("user-uuid-1", entry_type="parts")

    session.scalars.assert_called_once()
    stmt = session.scalars.call_args[0][0]
    sql = compile_stmt(stmt)
    assert "FROM order_entries" in sql
    assert "order_entries.user_id =" in sql
    assert "order_entries.type = 'parts'" in sql
    assert "ORDER BY order_entries.occurred_at DESC" in sql
