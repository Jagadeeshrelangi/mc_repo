"""API-level tests for the Task 6, Stage 5 Mechanics routes.

Strategy (mirrors ``test_users_api.py`` / ``test_auth_ai_route_protection.py``):
build a lightweight FastAPI app that mounts the REAL mechanics router (+ auth
router for intact-route checks) and registers the same ``MechaException`` →
HTTP mapping as ``app.main``. ``get_db`` is overridden with a fake session;
``get_current_user`` runs the REAL ``app.api.deps`` implementation (real JWT
verification) against a configured test secret.

``MechanicService`` is patched at the class boundary (Stage 8 convention) to a
``FakeMechanicService`` whose methods are ``AsyncMock`` so tests control
return values and exceptions while proving the ROUTE layer:
- public vs protected (missing/malformed/expired/refresh/inactive auth),
- ownership (user id always from ``get_current_user``; body cannot override),
- correct status codes + response models,
- error mapping (NOT_FOUND → 404, BAD_REQUEST → 400, no raw leaks),
- route ordering (``/featured``/``/services``/``/categories``/``/bookings``
  never captured by ``/{mechanic_id}``).

The REAL ``MechanicService`` coordination (commit-once, ownership guards,
transitions) is exercised by the Stage 4 service tests; this file tests the
HTTP layer wiring only. No live PostgreSQL is required (and none is faked).

No commits, pushes, resets, or reverts are performed.
"""

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Dict, Optional
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api import deps
from app.api.deps import get_db
from app.core import security
from app.core.config import settings
from app.core.exceptions import EntityNotFoundException, InvalidInputException, MechaException
from app.models.user import User
from app.schemas.mechanic import (
    BookingEventOut,
    BookingOut,
    MechanicCategoryOut,
    MechanicOut,
    MechanicReviewOut,
    MechanicServiceOut,
    RatingOut,
)
from app.services.mechanic_service import MechanicService

TEST_JWT_SECRET = "task6-mechanic-routes-test-secret-not-for-production"
USER_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
USER_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
B_ID = "11111111-1111-1111-1111-111111111111"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)

MECHANIC_BASE = "/api/v1/mechanic"
AUTH_BASE = "/api/v1/auth"

# The 15 routes under test: (method, path, needs_auth, json_body)
ROUTES = [
    ("get", f"{MECHANIC_BASE}/mechanics", False, None),
    ("get", f"{MECHANIC_BASE}/mechanics/featured", False, None),
    ("get", f"{MECHANIC_BASE}/mechanics/m1", False, None),
    ("get", f"{MECHANIC_BASE}/mechanics/m1/services", False, None),
    ("get", f"{MECHANIC_BASE}/mechanics/m1/reviews", False, None),
    ("get", f"{MECHANIC_BASE}/services", False, None),
    ("get", f"{MECHANIC_BASE}/categories", False, None),
    ("get", f"{MECHANIC_BASE}/bookings", True, None),
    ("post", f"{MECHANIC_BASE}/bookings", True, {"mechanic_id": "m1", "service_id": "svc_1"}),
    ("get", f"{MECHANIC_BASE}/bookings/{B_ID}", True, None),
    ("post", f"{MECHANIC_BASE}/bookings/{B_ID}/cancel", True, None),
    ("post", f"{MECHANIC_BASE}/bookings/{B_ID}/complete", True, None),
    ("get", f"{MECHANIC_BASE}/bookings/{B_ID}/events", True, None),
    ("post", f"{MECHANIC_BASE}/bookings/{B_ID}/rating", True, {"rating": 4.5}),
    ("get", f"{MECHANIC_BASE}/bookings/{B_ID}/rating", True, None),
]

PROTECTED_ROUTES = [(m, p, b) for m, p, auth, b in ROUTES if auth]
PUBLIC_ROUTES = [(m, p, b) for m, p, auth, b in ROUTES if not auth]


class FakeSession:
    """Minimal session supporting the ``get_current_user`` user lookup."""

    def __init__(self, users: Optional[Dict[str, User]] = None) -> None:
        self.users = users or {}

    async def get(self, model, entity_id) -> Optional[User]:
        if model is User:
            return self.users.get(str(entity_id))
        return None

    async def commit(self) -> None:
        pass

    async def rollback(self) -> None:
        pass


def make_user(**overrides) -> User:
    defaults: Dict = {
        "id": USER_A,
        "name": "Jagadeesh Gowda",
        "email": "jagadeesh@example.com",
        "phone": "+919876543210",
        "password_hash": "$2b$12$irrelevantfortask6",
        "role": "customer",
        "is_active": True,
        "is_verified": False,
        "failed_login_attempts": 0,
        "membership_tier": "free",
        "joined_at": NOW,
        "created_at": NOW,
        "updated_at": NOW,
        "last_login_at": None,
        "lockout_at": None,
    }
    defaults.update(overrides)
    return User(**defaults)


def _access_token(user_id: str = USER_A, expires_in: Optional[timedelta] = None) -> str:
    return security.create_access_token(user_id, expires_in=expires_in)


def _refresh_token(user_id: str = USER_A) -> str:
    return security.create_refresh_token(user_id)


def make_mechanic_out(mid: str = "m1") -> MechanicOut:
    return MechanicOut(
        id=mid,
        name="Raju Auto Works",
        rating=Decimal("4.80"),
        review_count=120,
        experience_years=12,
        distance_km=Decimal("2.50"),
        eta_minutes=15,
        is_available=True,
        price_starting=Decimal("299.00"),
        phone="+919876543210",
        about="Certified mechanic",
        is_verified=True,
        skills=["Engine"],
        languages=["English"],
        working_hours=[],
        services=[],
    )


def make_booking_out() -> BookingOut:
    return BookingOut(
        id=B_ID,
        mechanic_id="m1",
        service_id="svc_1",
        vehicle_id=None,
        status="requested",
        address="12 MG Road",
        lat=Decimal("12.971599"),
        lng=Decimal("77.594566"),
        scheduled_at=None,
        created_at=NOW,
    )


def make_event_out() -> BookingEventOut:
    return BookingEventOut(
        id="22222222-2222-2222-2222-222222222222",
        booking_id=B_ID,
        status="requested",
        occurred_at=NOW,
        payload=None,
    )


def make_rating_out() -> RatingOut:
    return RatingOut(booking_id=B_ID, rating=Decimal("4.50"), review="Good")


class FakeMechanicService:
    """Request-scoped double mirroring ``MechanicService``.

    Every public method is an ``AsyncMock`` so tests can set
    ``return_value``/``side_effect`` per test and assert call arguments
    (e.g. that the route passes ``user_id`` from the token).
    """

    def __init__(self, session=None) -> None:
        self.session = session
        self.list_mechanics = AsyncMock(return_value=[make_mechanic_out("m1")])
        self.list_featured_mechanics = AsyncMock(return_value=[make_mechanic_out("m1")])
        self.get_mechanic = AsyncMock(return_value=make_mechanic_out("m1"))
        self.list_services = AsyncMock(return_value=[MechanicServiceOut(id="svc_1", name="Engine Repair")])
        self.list_mechanic_services = AsyncMock(return_value=[MechanicServiceOut(id="svc_1", name="Engine Repair")])
        self.list_categories = AsyncMock(return_value=[MechanicCategoryOut(id="cat-1", name="Engine")])
        self.list_mechanic_reviews = AsyncMock(
            return_value=[MechanicReviewOut(id="r1", reviewer_name="Rahul", rating=Decimal("4.50"))]
        )
        self.get_booking = AsyncMock(return_value=make_booking_out())
        self.list_user_bookings = AsyncMock(return_value=[make_booking_out()])
        self.list_booking_events = AsyncMock(return_value=[make_event_out()])
        self.create_booking = AsyncMock(return_value=make_booking_out())
        self.cancel_booking = AsyncMock(return_value=make_booking_out())
        self.complete_booking = AsyncMock(return_value=make_booking_out())
        self.create_rating = AsyncMock(return_value=make_rating_out())
        self.get_rating = AsyncMock(return_value=make_rating_out())


@pytest.fixture
def fake_service() -> FakeMechanicService:
    return FakeMechanicService()


@pytest.fixture
def mechanic_app(monkeypatch, fake_service) -> FastAPI:
    """Mount the REAL mechanics router + auth router + the MechaException map."""
    from app.api.v1 import auth as auth_router
    from app.api.v1 import mechanic as mechanic_router

    # Patch the request-scoped service class so every route construction
    # resolves to the shared fake (Stage 8 class-boundary convention).
    monkeypatch.setattr(mechanic_router, "MechanicService", lambda session: fake_service)

    app = FastAPI()

    @app.exception_handler(MechaException)
    async def mecha_exception_handler(request, exc: MechaException):
        mapping = {
            "NOT_FOUND": status.HTTP_404_NOT_FOUND,
            "UNAUTHORIZED": status.HTTP_401_UNAUTHORIZED,
            "BAD_REQUEST": status.HTTP_400_BAD_REQUEST,
            "INFERENCE_FAILED": status.HTTP_422_UNPROCESSABLE_ENTITY,
        }
        return JSONResponse(
            status_code=mapping.get(exc.code, status.HTTP_500_INTERNAL_SERVER_ERROR),
            content={"error_code": exc.code, "message": exc.message, "details": exc.details},
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request, exc: Exception):
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error_code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected error occurred on the server.",
                "details": {},
            },
        )

    app.include_router(mechanic_router.router, prefix="/api/v1")
    app.include_router(auth_router.router, prefix="/api/v1/auth")

    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)
    return app


@pytest.fixture
def client(mechanic_app) -> TestClient:
    """Client whose get_db resolves to a fake session (no active user by default)."""

    async def _default_db():
        yield FakeSession()

    mechanic_app.dependency_overrides[get_db] = _default_db
    # Mirror production uvicorn behavior: the base-Exception handler returns a
    # sanitized 500 rather than re-raising (TestClient would otherwise
    # propagate the exception to the caller).
    return TestClient(mechanic_app, raise_server_exceptions=False)


def _set_active_user(client: TestClient, user: Optional[User] = None) -> None:
    active = user if user is not None else make_user()

    async def _db_with_user():
        yield FakeSession({active.id: active})

    client.app.dependency_overrides[get_db] = _db_with_user


# ============================================================================
# 1. PUBLIC CATALOG — success + schema
# ============================================================================


def test_public_catalog_routes_succeed_without_auth(client, fake_service) -> None:
    _set_active_user(client)
    cases = {
        "get": [
            (f"{MECHANIC_BASE}/mechanics", fake_service.list_mechanics, list),
            (f"{MECHANIC_BASE}/mechanics/featured", fake_service.list_featured_mechanics, list),
            (f"{MECHANIC_BASE}/mechanics/m1", fake_service.get_mechanic, dict),
            (f"{MECHANIC_BASE}/mechanics/m1/services", fake_service.list_mechanic_services, list),
            (f"{MECHANIC_BASE}/mechanics/m1/reviews", fake_service.list_mechanic_reviews, list),
            (f"{MECHANIC_BASE}/services", fake_service.list_services, list),
            (f"{MECHANIC_BASE}/categories", fake_service.list_categories, list),
        ]
    }
    for path, method, shape in cases["get"]:
        response = client.get(path)  # NO Authorization header
        assert response.status_code == 200, path
        assert isinstance(response.json(), shape)
        method.assert_awaited_once()


def test_public_catalog_schema_shape(client) -> None:
    _set_active_user(client)
    body = client.get(f"{MECHANIC_BASE}/mechanics").json()
    assert isinstance(body, list)
    item = body[0]
    for field in ("id", "name", "rating", "is_available", "skills", "languages", "services"):
        assert field in item
    # Sensitive auth/user fields must never leak.
    for secret_field in ("password_hash", "token_digest", "jti", "user_id"):
        assert secret_field not in item


def test_missing_mechanic_returns_generic_404(client, fake_service) -> None:
    _set_active_user(client)
    fake_service.get_mechanic.side_effect = EntityNotFoundException("Mechanic not found.")
    response = client.get(f"{MECHANIC_BASE}/mechanics/missing")
    assert response.status_code == 404
    assert response.json()["error_code"] == "NOT_FOUND"
    assert "Mechanic not found." == response.json()["message"]


# ============================================================================
# 2. AUTH — protected routes reject invalid credentials
# ============================================================================


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_missing_authorization_rejected(client, method, path, body) -> None:
    _set_active_user(client)
    kwargs = {"json": body} if body else {}
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_malformed_authorization_rejected(client, method, path, body) -> None:
    _set_active_user(client)
    kwargs = {"json": body, "headers": {"Authorization": "Bearer not-a-jwt"}} if body else {
        "headers": {"Authorization": "Bearer not-a-jwt"}
    }
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_expired_access_token_rejected(client, method, path, body) -> None:
    _set_active_user(client)
    kwargs = {"json": body, "headers": {"Authorization": f"Bearer {_access_token(expires_in=timedelta(seconds=-60))}"}} if body else {
        "headers": {"Authorization": f"Bearer {_access_token(expires_in=timedelta(seconds=-60))}"}
    }
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_refresh_token_rejected_as_access(client, method, path, body) -> None:
    _set_active_user(client)
    kwargs = {"json": body, "headers": {"Authorization": f"Bearer {_refresh_token()}"}} if body else {
        "headers": {"Authorization": f"Bearer {_refresh_token()}"}
    }
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_inactive_user_rejected(client, method, path, body) -> None:
    _set_active_user(client, make_user(is_active=False))
    kwargs = {"json": body, "headers": {"Authorization": f"Bearer {_access_token()}"}} if body else {
        "headers": {"Authorization": f"Bearer {_access_token()}"}
    }
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code == 401


# ============================================================================
# 3. AUTH — valid access token passes (each protected route reaches service)
# ============================================================================


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_valid_access_token_reaches_service(client, fake_service, method, path, body) -> None:
    _set_active_user(client)
    kwargs = {"json": body, "headers": {"Authorization": f"Bearer {_access_token()}"}} if body else {
        "headers": {"Authorization": f"Bearer {_access_token()}"}
    }
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code in (200, 201)


# ============================================================================
# 4. OWNERSHIP — user_id from token, never from body/path
# ============================================================================


def test_booking_read_passes_token_user_id(client, fake_service) -> None:
    _set_active_user(client)
    response = client.get(
        f"{MECHANIC_BASE}/bookings/{B_ID}",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 200
    fake_service.get_booking.assert_awaited_once_with(B_ID, user_id=USER_A)


def test_create_booking_binds_authenticated_user(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings",
        json={"mechanic_id": "m1", "service_id": "svc_1"},
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 201
    fake_service.create_booking.assert_awaited_once()
    _, kwargs = fake_service.create_booking.await_args
    assert kwargs["user_id"] == USER_A


def test_request_body_cannot_override_ownership(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings",
        json={"mechanic_id": "m1", "service_id": "svc_1", "user_id": USER_B},
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    # BookingCreate is extra="forbid" → unknown field rejected wholesale.
    assert response.status_code == 422
    fake_service.create_booking.assert_not_awaited()


def test_rating_body_cannot_override_booking_id(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings/{B_ID}/rating",
        json={"rating": 4.5, "booking_id": "99999999-9999-9999-9999-999999999999"},
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 422
    fake_service.create_rating.assert_not_awaited()


def test_foreign_booking_returns_same_generic_404(client, fake_service) -> None:
    # USER_B authenticates; the booking is owned by USER_A (service rejects).
    _set_active_user(client, make_user(id=USER_B))
    fake_service.get_booking.side_effect = EntityNotFoundException("Booking not found.")
    response = client.get(
        f"{MECHANIC_BASE}/bookings/{B_ID}",
        headers={"Authorization": f"Bearer {_access_token(USER_B)}"},
    )
    assert response.status_code == 404
    assert response.json()["error_code"] == "NOT_FOUND"
    # The generic message must be identical for foreign vs missing — no leak.
    assert response.json()["message"] == "Booking not found."
    fake_service.get_booking.assert_awaited_once_with(B_ID, user_id=USER_B)


def test_missing_booking_returns_same_generic_404(client, fake_service) -> None:
    _set_active_user(client)
    fake_service.get_booking.side_effect = EntityNotFoundException("Booking not found.")
    response = client.get(
        f"{MECHANIC_BASE}/bookings/{B_ID}",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 404
    assert response.json()["message"] == "Booking not found."


# ============================================================================
# 5. WRITE OPERATIONS — status codes + service calls
# ============================================================================


def test_create_booking_returns_201(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings",
        json={"mechanic_id": "m1", "service_id": "svc_1"},
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["id"] == B_ID
    assert body["status"] == "requested"


def test_cancel_booking_returns_200(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings/{B_ID}/cancel",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 200
    fake_service.cancel_booking.assert_awaited_once_with(B_ID, user_id=USER_A)


def test_complete_booking_returns_200(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings/{B_ID}/complete",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 200
    fake_service.complete_booking.assert_awaited_once_with(B_ID, user_id=USER_A)


def test_create_rating_returns_201(client, fake_service) -> None:
    _set_active_user(client)
    response = client.post(
        f"{MECHANIC_BASE}/bookings/{B_ID}/rating",
        json={"rating": 4.5, "review": "Great work"},
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 201
    fake_service.create_rating.assert_awaited_once()
    args, kwargs = fake_service.create_rating.await_args
    assert args[0] == B_ID  # booking_id comes from the path (positional).
    assert kwargs["user_id"] == USER_A


# ============================================================================
# 6. ERROR MAPPING — controlled service exceptions → HTTP
# ============================================================================


def test_entity_not_found_maps_to_404(client, fake_service) -> None:
    _set_active_user(client)
    fake_service.get_mechanic.side_effect = EntityNotFoundException("Mechanic not found.")
    response = client.get(f"{MECHANIC_BASE}/mechanics/nope")
    assert response.status_code == 404
    assert response.json()["error_code"] == "NOT_FOUND"


def test_invalid_input_maps_to_400(client, fake_service) -> None:
    _set_active_user(client)
    fake_service.complete_booking.side_effect = InvalidInputException(
        "This booking is already finished and cannot be changed."
    )
    response = client.post(
        f"{MECHANIC_BASE}/bookings/{B_ID}/complete",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 400
    assert response.json()["error_code"] == "BAD_REQUEST"


def test_service_failure_not_leaked_to_client(client, fake_service) -> None:
    """A raw repository/DB exception must not surface a traceback to clients."""
    _set_active_user(client)
    fake_service.list_mechanics.side_effect = RuntimeError("boom")
    response = client.get(f"{MECHANIC_BASE}/mechanics")
    # The app-level generic handler returns a sanitized 500.
    assert response.status_code == 500
    body = response.json()
    assert body["error_code"] == "INTERNAL_SERVER_ERROR"
    assert "boom" not in str(body)


# ============================================================================
# 7. ROUTE ORDERING — static suffixes never captured by {mechanic_id}
# ============================================================================


def test_featured_reaches_featured_endpoint(client, fake_service) -> None:
    _set_active_user(client)
    response = client.get(f"{MECHANIC_BASE}/mechanics/featured")
    assert response.status_code == 200
    fake_service.list_featured_mechanics.assert_awaited_once()
    fake_service.get_mechanic.assert_not_awaited()


def test_services_not_captured_as_mechanic_id(client, fake_service) -> None:
    _set_active_user(client)
    response = client.get(f"{MECHANIC_BASE}/services")
    assert response.status_code == 200
    fake_service.list_services.assert_awaited_once()
    fake_service.get_mechanic.assert_not_awaited()


def test_categories_not_captured_as_mechanic_id(client, fake_service) -> None:
    _set_active_user(client)
    response = client.get(f"{MECHANIC_BASE}/categories")
    assert response.status_code == 200
    fake_service.list_categories.assert_awaited_once()
    fake_service.get_mechanic.assert_not_awaited()


def test_bookings_not_captured_as_mechanic_id(client, fake_service) -> None:
    _set_active_user(client)
    response = client.get(
        f"{MECHANIC_BASE}/bookings",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 200
    fake_service.list_user_bookings.assert_awaited_once()
    fake_service.get_mechanic.assert_not_awaited()


# ============================================================================
# 8. ROUTE REGISTRATION + OpenAPI
# ============================================================================


def test_openapi_contains_all_mechanic_paths(mechanic_app) -> None:
    paths = set(mechanic_app.openapi()["paths"].keys())
    expected = {
        f"{MECHANIC_BASE}/mechanics",
        f"{MECHANIC_BASE}/mechanics/featured",
        f"{MECHANIC_BASE}/mechanics/{{mechanic_id}}",
        f"{MECHANIC_BASE}/mechanics/{{mechanic_id}}/services",
        f"{MECHANIC_BASE}/mechanics/{{mechanic_id}}/reviews",
        f"{MECHANIC_BASE}/services",
        f"{MECHANIC_BASE}/categories",
        f"{MECHANIC_BASE}/bookings",
        f"{MECHANIC_BASE}/bookings/{{booking_id}}",
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/cancel",
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/complete",
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/events",
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/rating",
    }
    assert expected.issubset(paths)


def test_openapi_public_routes_have_no_security(mechanic_app) -> None:
    schema = mechanic_app.openapi()
    template_paths = {
        f"{MECHANIC_BASE}/mechanics": "get",
        f"{MECHANIC_BASE}/mechanics/featured": "get",
        f"{MECHANIC_BASE}/mechanics/{{mechanic_id}}": "get",
        f"{MECHANIC_BASE}/mechanics/{{mechanic_id}}/services": "get",
        f"{MECHANIC_BASE}/mechanics/{{mechanic_id}}/reviews": "get",
        f"{MECHANIC_BASE}/services": "get",
        f"{MECHANIC_BASE}/categories": "get",
    }
    for path, method in template_paths.items():
        for op in schema["paths"][path].values():
            assert "security" not in op, f"{method.upper()} {path} must be public"


def test_openapi_protected_routes_require_bearer(mechanic_app) -> None:
    schema = mechanic_app.openapi()
    template_paths = {
        f"{MECHANIC_BASE}/bookings": ("get", "post"),
        f"{MECHANIC_BASE}/bookings/{{booking_id}}": ("get",),
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/cancel": ("post",),
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/complete": ("post",),
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/events": ("get",),
        f"{MECHANIC_BASE}/bookings/{{booking_id}}/rating": ("get", "post"),
    }
    for path, methods in template_paths.items():
        for method in methods:
            op = schema["paths"][path][method]
            assert "security" in op, f"{method.upper()} {path} must be protected"
            assert op["security"] == [{"HTTPBearer": []}]


def test_existing_auth_routes_still_registered(mechanic_app) -> None:
    paths = set(mechanic_app.openapi()["paths"].keys())
    for expected in (
        f"{AUTH_BASE}/register",
        f"{AUTH_BASE}/login",
        f"{AUTH_BASE}/refresh",
        f"{AUTH_BASE}/logout",
        f"{AUTH_BASE}/me",
    ):
        assert expected in paths