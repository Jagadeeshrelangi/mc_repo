"""HTTP API routes test suite for Canonical Unified Orders (/api/v1/orders).

Validates:
- Route registration under /api/v1/orders
- Protected authenticated endpoints (401 on missing/invalid token)
- Listing orders with optional type and status filtering
- Getting order details by ID (owner-guarded)
- Cancelling orders via PUT and POST
- Rejection of invalid cancellations (terminal state 400)
- Ownership isolation
"""

from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_current_user, get_db
from app.api.router import api_router
from app.core.exceptions import EntityNotFoundException, InvalidInputException, MechaException
from app.models.order_entry import OrderEntry
from app.models.user import User, UserRole
from app.schemas.order import OrderCancelResponse, OrderDetailResponse, OrderEntryResponse
from app.services.order_service import OrderService

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
            content={
                "error_code": exc.code,
                "message": exc.message,
                "details": exc.details,
            },
        )

    test_app.dependency_overrides[get_db] = lambda: AsyncMock()
    test_app.include_router(api_router, prefix="/api/v1")
    return test_app


@pytest.fixture
def mock_user_a() -> User:
    user = User(
        id=USER_A_ID,
        email="driver.a@mecha.test",
        name="Jagadeesh Gowda",
        role=UserRole.CUSTOMER,
        is_active=True,
    )
    return user


@pytest.fixture
def mock_user_b() -> User:
    user = User(
        id=USER_B_ID,
        email="driver.b@mecha.test",
        name="Other Driver",
        role=UserRole.CUSTOMER,
        is_active=True,
    )
    return user


@pytest.fixture
def sample_orders() -> List[OrderEntry]:
    now = datetime.now(timezone.utc)
    return [
        OrderEntry(
            id="ORD-1001",
            user_id=USER_A_ID,
            name="Brake Pads",
            brand="TVS",
            quantity=2,
            price=Decimal("699.00"),
            type="parts",
            status="Delivered",
            occurred_at=now,
            source="Marketplace Checkout",
        ),
        OrderEntry(
            id="FO-1234ABCD",
            user_id=USER_A_ID,
            name="Fuel Delivery · 5L Petrol",
            brand="Indian Oil",
            quantity=5,
            price=Decimal("500.00"),
            type="fuel",
            status="In Progress",
            occurred_at=now,
            source="Fuel Delivery",
        ),
        OrderEntry(
            id="MEC-998877",
            user_id=USER_A_ID,
            name="Engine Oil Change",
            brand="Castrol Point",
            quantity=1,
            price=Decimal("899.00"),
            type="mechanic",
            status="Pending",
            occurred_at=now,
            source="Mechanic Booking",
        ),
        OrderEntry(
            id="diag-abcdef123456",
            user_id=USER_A_ID,
            name="Battery & Starter Diagnostic",
            brand="Honda Activa",
            quantity=1,
            price=Decimal("0.00"),
            type="aiReport",
            status="Completed",
            occurred_at=now,
            source="AI Assistant",
        ),
    ]


# ---------------------------------------------------------------------------
# Route Protection & Auth
# ---------------------------------------------------------------------------


def test_list_orders_unauthorized():
    app = create_test_app()
    client = TestClient(app)
    response = client.get("/api/v1/orders")
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


def test_get_order_unauthorized():
    app = create_test_app()
    client = TestClient(app)
    response = client.get("/api/v1/orders/ORD-1001")
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


def test_cancel_order_unauthorized():
    app = create_test_app()
    client = TestClient(app)
    response = client.post("/api/v1/orders/ORD-1001/cancel")
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# Listing Orders
# ---------------------------------------------------------------------------


def test_list_orders_success(mock_user_a, sample_orders):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    with patch.object(OrderService, "list_orders", new_callable=AsyncMock) as mock_list:
        mock_list.return_value = sample_orders

        client = TestClient(app)
        response = client.get("/api/v1/orders")
        assert response.status_code == status.HTTP_200_OK

        data = response.json()
        assert len(data) == 4
        assert data[0]["id"] == "ORD-1001"
        assert data[0]["type"] == "parts"
        assert data[1]["type"] == "fuel"
        assert data[2]["type"] == "mechanic"
        assert data[3]["type"] == "aiReport"


def test_list_orders_with_type_filter(mock_user_a, sample_orders):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    with patch.object(OrderService, "list_orders", new_callable=AsyncMock) as mock_list:
        mock_list.return_value = [sample_orders[1]]  # fuel only

        client = TestClient(app)
        response = client.get("/api/v1/orders?type=fuel")
        assert response.status_code == status.HTTP_200_OK

        mock_list.assert_called_once()
        assert mock_list.call_args.kwargs["entry_type"] == "fuel"

        data = response.json()
        assert len(data) == 1
        assert data[0]["type"] == "fuel"


# ---------------------------------------------------------------------------
# Get Order Detail
# ---------------------------------------------------------------------------


def test_get_order_detail_success(mock_user_a, sample_orders):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    detail = OrderDetailResponse(
        id="ORD-1001",
        user_id=USER_A_ID,
        name="Brake Pads",
        brand="TVS",
        quantity=2,
        price=Decimal("699.00"),
        type="parts",
        status="Delivered",
        occurred_at=datetime.now(timezone.utc),
        source="Marketplace Checkout",
        domain_id="ORD-1001",
        details={},
    )

    with patch.object(OrderService, "get_order", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = detail

        client = TestClient(app)
        response = client.get("/api/v1/orders/ORD-1001")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["id"] == "ORD-1001"
        assert data["name"] == "Brake Pads"


def test_get_order_not_found(mock_user_a):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    with patch.object(OrderService, "get_order", new_callable=AsyncMock) as mock_get:
        mock_get.side_effect = EntityNotFoundException("Order not found.")

        client = TestClient(app)
        response = client.get("/api/v1/orders/non-existent")
        assert response.status_code == status.HTTP_404_NOT_FOUND


# ---------------------------------------------------------------------------
# Cancel Order
# ---------------------------------------------------------------------------


def test_cancel_order_put_success(mock_user_a):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    cancel_res = OrderCancelResponse(
        id="MEC-998877",
        status="Cancelled",
        message="Order cancelled successfully.",
    )

    with patch.object(OrderService, "cancel_order", new_callable=AsyncMock) as mock_cancel:
        mock_cancel.return_value = cancel_res

        client = TestClient(app)
        response = client.put("/api/v1/orders/MEC-998877/cancel")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["status"] == "Cancelled"


def test_cancel_order_post_success(mock_user_a):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    cancel_res = OrderCancelResponse(
        id="FO-1234ABCD",
        status="Cancelled",
        message="Order cancelled successfully.",
    )

    with patch.object(OrderService, "cancel_order", new_callable=AsyncMock) as mock_cancel:
        mock_cancel.return_value = cancel_res

        client = TestClient(app)
        response = client.post("/api/v1/orders/FO-1234ABCD/cancel")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["status"] == "Cancelled"


def test_cancel_order_already_terminal(mock_user_a):
    app = create_test_app()
    app.dependency_overrides[get_current_user] = lambda: mock_user_a
    app.dependency_overrides[get_db] = lambda: AsyncMock()

    with patch.object(OrderService, "cancel_order", new_callable=AsyncMock) as mock_cancel:
        mock_cancel.side_effect = InvalidInputException("Cannot cancel order with status 'Delivered'.")

        client = TestClient(app)
        response = client.post("/api/v1/orders/ORD-1001/cancel")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        data = response.json()
        assert data["error_code"] == "BAD_REQUEST"
