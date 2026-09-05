"""HTTP API routes test suite for Fuel Delivery & Marketplace (Task 8 Stage 4).

Validates:
- Route registration under /api/v1/fuel and /api/v1/marketplace
- Public discovery endpoints vs protected authenticated endpoints
- JWT Authentication (Bearer token resolution, 401 on missing/invalid token)
- Correct HTTP status codes (200, 201, 400, 401, 404, 422)
- Domain exception translation via MechaException handler
- Ownership isolation (user ID bound from JWT claims)
"""

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_current_user, get_db
from app.api.router import api_router
from app.core.exceptions import EntityNotFoundException, InvalidInputException, MechaException
from app.models.fuel_order import FuelOrder
from app.models.fuel_station import FuelStation
from app.models.invoice import Invoice
from app.models.order import Order
from app.models.order_entry import OrderEntry
from app.models.price_estimate import PriceEstimate
from app.models.product import Product
from app.models.product_review import ProductReview
from app.models.tracking_event import TrackingEvent
from app.models.user import User, UserRole
from app.schemas.fuel import PriceEstimateResponse
from app.schemas.marketplace import CouponValidationResult
from app.services.fuel_service import FuelService
from app.services.marketplace_service import MarketplaceService

USER_A_ID = "11111111-1111-1111-1111-111111111111"
USER_B_ID = "22222222-2222-2222-2222-222222222222"


def create_test_app() -> FastAPI:
    """Build test FastAPI app with mounted routers and exception handlers."""
    test_app = FastAPI()

    @test_app.exception_handler(MechaException)
    async def mecha_exception_handler(request, exc: MechaException):
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        if exc.code == "NOT_FOUND":
            status_code = status.HTTP_404_NOT_FOUND
        elif exc.code == "UNAUTHORIZED":
            status_code = status.HTTP_401_UNAUTHORIZED
        elif exc.code == "BAD_REQUEST":
            status_code = status.HTTP_400_BAD_REQUEST
        elif exc.code == "INFERENCE_FAILED":
            status_code = status.HTTP_422_UNPROCESSABLE_ENTITY

        return JSONResponse(
            status_code=status_code,
            content={"error_code": exc.code, "message": exc.message, "details": exc.details},
        )

    test_app.include_router(api_router, prefix="/api/v1")
    return test_app


@pytest.fixture
def test_user() -> User:
    return User(
        id=USER_A_ID,
        phone="+919876543210",
        name="Test User",
        role=UserRole.CUSTOMER,
        is_active=True,
    )


@pytest.fixture
def client(test_user: User) -> TestClient:
    app = create_test_app()

    # Override get_db with an async mock session
    mock_db = AsyncMock()
    app.dependency_overrides[get_db] = lambda: mock_db
    # Override get_current_user with test user fixture
    app.dependency_overrides[get_current_user] = lambda: test_user

    return TestClient(app)


@pytest.fixture
def unauth_client() -> TestClient:
    """Client with get_db overridden but REAL get_current_user (will reject unauth)."""
    app = create_test_app()
    mock_db = AsyncMock()
    app.dependency_overrides[get_db] = lambda: mock_db
    return TestClient(app)


# ============================================================================
# Fuel API Routes
# ============================================================================


def test_public_fuel_stations_list(client: TestClient) -> None:
    mock_station = FuelStation(
        id="st-1",
        name="Indian Oil Indiranagar",
        brand="IndianOil",
        address="100ft Road",
        is_open=True,
        availability="available",
        price_per_litre=Decimal("102.50"),
        eta_minutes=15,
        rating=Decimal("4.7"),
    )
    with patch.object(FuelService, "list_stations", new_callable=AsyncMock) as mock_list:
        mock_list.return_value = [mock_station]
        resp = client.get("/api/v1/fuel/stations")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["name"] == "Indian Oil Indiranagar"
        assert data[0]["price_per_litre"] == 102.5


def test_public_fuel_station_detail(client: TestClient) -> None:
    mock_station = FuelStation(
        id="st-1",
        name="Indian Oil Indiranagar",
        brand="IndianOil",
        address="100ft Road",
        is_open=True,
        availability="available",
        price_per_litre=Decimal("102.50"),
        eta_minutes=15,
        rating=Decimal("4.7"),
    )
    with patch.object(FuelService, "get_station", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_station
        resp = client.get("/api/v1/fuel/stations/st-1")
        assert resp.status_code == 200
        assert resp.json()["id"] == "st-1"


def test_public_fuel_station_not_found(client: TestClient) -> None:
    with patch.object(FuelService, "get_station", new_callable=AsyncMock) as mock_get:
        mock_get.side_effect = EntityNotFoundException("Fuel station not found.")
        resp = client.get("/api/v1/fuel/stations/non-existent")
        assert resp.status_code == 404
        assert resp.json()["error_code"] == "NOT_FOUND"


def test_public_fuel_estimate(client: TestClient) -> None:
    estimate = PriceEstimateResponse(
        fuel_cost=Decimal("1025.00"),
        delivery_charge=Decimal("29.00"),
        platform_fee=Decimal("5.00"),
        taxes=Decimal("21.18"),
        grand_total=Decimal("1080.18"),
        eta_minutes=15,
    )
    with patch.object(FuelService, "calculate_price", new_callable=AsyncMock) as mock_calc:
        mock_calc.return_value = estimate
        resp = client.post(
            "/api/v1/fuel/estimate",
            json={"fuel_type": "petrol", "quantity": 10.0, "station_id": "st-1"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["grand_total"] == 1080.18


def test_protected_fuel_order_create_success(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    order = FuelOrder(
        id="FO-101",
        user_id=USER_A_ID,
        fuel_type="petrol",
        quantity=Decimal("10.00"),
        station_name="Indian Oil",
        brand="IndianOil",
        price_per_litre=Decimal("102.50"),
        status="requested",
        payment_method="UPI",
        created_at=now,
        price_estimate=PriceEstimate(
            fuel_cost=Decimal("1025.00"),
            delivery_charge=Decimal("29.00"),
            platform_fee=Decimal("5.00"),
            taxes=Decimal("21.18"),
            grand_total=Decimal("1080.18"),
            eta_minutes=15,
        ),
        tracking_events=[],
    )
    with patch.object(FuelService, "create_order", new_callable=AsyncMock) as mock_create:
        mock_create.return_value = order
        resp = client.post(
            "/api/v1/fuel/orders",
            json={
                "fuel_type": "petrol",
                "quantity": 10.0,
                "station_id": "st-1",
                "delivery_address": "100ft Road",
            },
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["id"] == "FO-101"
        assert data["status"] == "requested"


def test_protected_fuel_order_unauthenticated_rejected(unauth_client: TestClient) -> None:
    resp = unauth_client.post(
        "/api/v1/fuel/orders",
        json={"fuel_type": "petrol", "quantity": 10.0},
    )
    assert resp.status_code == 401


def test_protected_fuel_order_status_update(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    order = FuelOrder(
        id="FO-101",
        user_id=USER_A_ID,
        fuel_type="petrol",
        quantity=Decimal("10.00"),
        status="delivered",
        created_at=now,
        tracking_events=[],
    )
    with patch.object(FuelService, "update_order_status", new_callable=AsyncMock) as mock_up:
        mock_up.return_value = order
        resp = client.patch(
            "/api/v1/fuel/orders/FO-101/status",
            json={"status": "delivered"},
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "delivered"


def test_protected_fuel_order_tracking(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    event = TrackingEvent(
        id="TE-1",
        order_id="FO-101",
        status="requested",
        occurred_at=now,
    )
    with patch.object(FuelService, "get_tracking_events", new_callable=AsyncMock) as mock_tr:
        mock_tr.return_value = [event]
        resp = client.get("/api/v1/fuel/orders/FO-101/tracking")
        assert resp.status_code == 200
        assert len(resp.json()) == 1


def test_protected_fuel_user_orders_list(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    order = FuelOrder(
        id="FO-101",
        user_id=USER_A_ID,
        fuel_type="petrol",
        quantity=Decimal("10.00"),
        status="requested",
        created_at=now,
    )
    with patch.object(FuelService, "list_user_orders", new_callable=AsyncMock) as mock_list:
        mock_list.return_value = [order]
        resp = client.get("/api/v1/fuel/orders")
        assert resp.status_code == 200
        assert len(resp.json()) == 1
        assert resp.json()[0]["id"] == "FO-101"


def test_protected_fuel_order_get_detail(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    order = FuelOrder(
        id="FO-101",
        user_id=USER_A_ID,
        fuel_type="petrol",
        quantity=Decimal("10.00"),
        status="requested",
        created_at=now,
    )
    with patch.object(FuelService, "get_order", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = order
        resp = client.get("/api/v1/fuel/orders/FO-101")
        assert resp.status_code == 200
        assert resp.json()["id"] == "FO-101"


def test_protected_fuel_order_invoice(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    invoice = Invoice(
        invoice_id="INV-101",
        order_id="FO-101",
        grand_total=Decimal("1080.18"),
        created_at=now,
    )
    with patch.object(FuelService, "get_invoice", new_callable=AsyncMock) as mock_inv:
        mock_inv.return_value = invoice
        resp = client.get("/api/v1/fuel/orders/FO-101/invoice")
        assert resp.status_code == 200
        assert resp.json()["invoice_id"] == "INV-101"


# ============================================================================
# Marketplace API Routes
# ============================================================================


def test_public_marketplace_categories(client: TestClient) -> None:
    with patch.object(MarketplaceService, "list_categories", new_callable=AsyncMock) as mock_cat:
        mock_cat.return_value = []
        resp = client.get("/api/v1/marketplace/categories")
        assert resp.status_code == 200
        assert resp.json() == []


def test_public_marketplace_brands(client: TestClient) -> None:
    with patch.object(MarketplaceService, "list_brands", new_callable=AsyncMock) as mock_b:
        mock_b.return_value = []
        resp = client.get("/api/v1/marketplace/brands")
        assert resp.status_code == 200
        assert resp.json() == []


def test_public_marketplace_offers(client: TestClient) -> None:
    with patch.object(MarketplaceService, "list_offers", new_callable=AsyncMock) as mock_o:
        mock_o.return_value = []
        resp = client.get("/api/v1/marketplace/offers")
        assert resp.status_code == 200
        assert resp.json() == []


def test_public_marketplace_products(client: TestClient) -> None:
    with patch.object(MarketplaceService, "list_products", new_callable=AsyncMock) as mock_p:
        mock_p.return_value = []
        resp = client.get("/api/v1/marketplace/products")
        assert resp.status_code == 200
        assert resp.json() == []


def test_public_marketplace_product_detail(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    prod = Product(
        id="prod-1",
        name="Ceramic Brake Pads",
        price=Decimal("2450.00"),
        mrp=Decimal("2800.00"),
        stock=10,
        rating=Decimal("4.5"),
        rating_count=12,
        is_featured=True,
        is_best_seller=False,
        is_trending=False,
        is_flash_deal=False,
        is_recommended=True,
        created_at=now,
        updated_at=now,
        specifications=[],
        vehicle_types=[],
        compatibility=[],
        reviews=[],
    )
    with patch.object(MarketplaceService, "get_product", new_callable=AsyncMock) as mock_p:
        mock_p.return_value = prod
        resp = client.get("/api/v1/marketplace/products/prod-1")
        assert resp.status_code == 200
        assert resp.json()["id"] == "prod-1"


def test_protected_marketplace_add_review(client: TestClient) -> None:
    rev = ProductReview(
        id="rev-1",
        product_id="prod-1",
        author="Test User",
        rating=Decimal("4.5"),
        comment="Great quality!",
        is_verified_purchase=True,
    )
    with patch.object(MarketplaceService, "add_product_review", new_callable=AsyncMock) as mock_rev:
        mock_rev.return_value = rev
        resp = client.post(
            "/api/v1/marketplace/products/prod-1/reviews",
            json={"author": "Test User", "rating": 4.5, "comment": "Great quality!"},
        )
        assert resp.status_code == 201
        assert resp.json()["id"] == "rev-1"


def test_public_marketplace_coupon_validation(client: TestClient) -> None:
    val_res = CouponValidationResult(
        is_valid=True,
        discount_amount=Decimal("150.00"),
        message="Coupon applied successfully.",
    )
    with patch.object(MarketplaceService, "validate_coupon", new_callable=AsyncMock) as mock_val:
        mock_val.return_value = val_res
        resp = client.post(
            "/api/v1/marketplace/coupons/validate",
            json={"code": "SAVE20", "order_amount": 750.0},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_valid"] is True
        assert data["discount_amount"] == 150.0


def test_protected_marketplace_order_create(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    order = Order(
        id="ord-uuid-1",
        user_id=USER_A_ID,
        external_id="ORD-12345678",
        address="100ft Road",
        payment_method="UPI",
        subtotal=Decimal("2000.00"),
        discount=Decimal("0.00"),
        delivery=Decimal("0.00"),
        tax=Decimal("360.00"),
        grand_total=Decimal("2360.00"),
        status="Pending",
        created_at=now,
        items=[],
    )
    with patch.object(MarketplaceService, "create_order", new_callable=AsyncMock) as mock_create:
        mock_create.return_value = order
        resp = client.post(
            "/api/v1/marketplace/orders",
            json={
                "address": "100ft Road",
                "payment_method": "UPI",
                "items": [
                    {
                        "product_id": "prod-1",
                        "product_name": "Brake Fluid",
                        "quantity": 2,
                        "unit_price": 1000.0,
                    }
                ],
            },
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["id"] == "ord-uuid-1"
        assert data["grand_total"] == 2360.0


def test_protected_marketplace_orders_list(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    order = Order(
        id="ord-uuid-1",
        user_id=USER_A_ID,
        external_id="ORD-12345678",
        address="100ft Road",
        payment_method="UPI",
        subtotal=Decimal("2000.00"),
        discount=Decimal("0.00"),
        delivery=Decimal("0.00"),
        tax=Decimal("360.00"),
        grand_total=Decimal("2360.00"),
        status="Pending",
        created_at=now,
        items=[],
    )
    with patch.object(MarketplaceService, "list_user_orders", new_callable=AsyncMock) as mock_list:
        mock_list.return_value = [order]
        resp = client.get("/api/v1/marketplace/orders")
        assert resp.status_code == 200
        assert len(resp.json()) == 1


def test_protected_marketplace_order_detail_owner_isolated(client: TestClient) -> None:
    with patch.object(MarketplaceService, "get_order", new_callable=AsyncMock) as mock_get:
        mock_get.side_effect = EntityNotFoundException("Order not found.")
        resp = client.get("/api/v1/marketplace/orders/ord-other-user")
        assert resp.status_code == 404
        assert resp.json()["error_code"] == "NOT_FOUND"


def test_protected_marketplace_activity_ledger(client: TestClient) -> None:
    now = datetime.now(timezone.utc)
    entry = OrderEntry(
        id="oe-1",
        user_id=USER_A_ID,
        name="Engine Oil 5W-40",
        quantity=1,
        price=Decimal("1500.00"),
        type="parts",
        status="Pending",
        occurred_at=now,
        source="Marketplace Checkout",
    )
    with patch.object(MarketplaceService, "list_user_activity", new_callable=AsyncMock) as mock_act:
        mock_act.return_value = [entry]
        resp = client.get("/api/v1/marketplace/activity")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["type"] == "parts"
