"""API-level tests for the Stage 7 auth routes (thin HTTP layer).

Strategy: mount ONLY the auth router on a minimal FastAPI app that registers the
same ``MechaException`` → HTTP mapping as ``app.main`` (keeps this test file
free of the heavy AI import). No live PostgreSQL: ``get_db`` is overridden with
a fake session and ``AuthService`` methods are patched at the class level so the
thin routes are exercised end-to-end (schema validation, status mapping,
response serialization).

Rate limiting is disabled per-test via an isolated permissive limiter so these
tests are not coupled to D10 window behavior (that is covered by
``test_auth_rate_limit.py``).
"""

from datetime import datetime, timezone
from typing import Dict, Optional

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api import deps
from app.api.deps import get_db
from app.api.v1.auth import router as auth_router
from app.core import security
from app.core.config import settings
from app.core.exceptions import (
    EntityNotFoundException,
    InvalidInputException,
    MechaException,
    UnauthorizedException,
)
from app.core.rate_limit import RateLimiter
from app.models.user import User
from app.schemas.auth import (
    ForgotPasswordResponse,
    LogoutResponse,
    TokenResponse,
)
from app.schemas.user import UserOut
from app.services.auth_service import AuthService

TEST_JWT_SECRET = "stage7-api-test-secret-not-for-production"
USER_ID = "11111111-1111-1111-1111-111111111111"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)

BASE = "/api/v1/auth"


class FakeSession:
    """Minimal session supporting the repository calls used by the routes."""

    def __init__(self, users: Optional[Dict[str, User]] = None) -> None:
        self.users = users or {}
        self.commits = 0

    async def get(self, model, entity_id) -> Optional[User]:
        if model is User:
            return self.users.get(str(entity_id))
        return None

    async def commit(self) -> None:
        self.commits += 1

    async def rollback(self) -> None:
        pass


def make_user(**overrides) -> User:
    defaults: Dict = {
        "id": USER_ID,
        "name": "Jagadeesh Gowda",
        "email": "jagadeesh@example.com",
        "phone": "+919876543210",
        "password_hash": "$2b$12$irrelevantforapi",
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


def make_user_out(**overrides) -> UserOut:
    return UserOut.model_validate(make_user(**overrides))


def make_token_response() -> TokenResponse:
    return TokenResponse(
        access_token="access-token",
        refresh_token="refresh-token",
        token_type="bearer",
        expires_in=900,
    )


@pytest.fixture
def auth_app(monkeypatch) -> FastAPI:
    """Minimal app mirroring main.py's MechaException handler + per-test limiter."""
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

    app.include_router(auth_router, prefix="/api/v1/auth")

    # Isolate rate limiting so these tests are not coupled to D10 windows.
    monkeypatch.setattr(
        deps,
        "auth_rate_limiter",
        RateLimiter(max_requests=100000, window_seconds=60),
    )
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)

    # No live PostgreSQL: every route's session resolves to a fake session.
    async def _default_db():
        yield FakeSession()

    app.dependency_overrides[get_db] = _default_db
    return app


@pytest.fixture
def client(auth_app) -> TestClient:
    return TestClient(auth_app)


# ============================================================================
# REGISTER
# ============================================================================


def test_register_valid_request_reaches_service(client, monkeypatch) -> None:
    captured = {}

    async def fake_register(self, payload):
        captured["payload"] = payload
        return make_user_out()

    monkeypatch.setattr(AuthService, "register", fake_register)
    response = client.post(
        f"{BASE}/register",
        json={
            "name": "Jagadeesh Gowda",
            "email": "jagadeesh@example.com",
            "phone": "+919876543210",
            "password": "StrongPass123",
        },
    )
    assert response.status_code == 201
    assert captured["payload"].email == "jagadeesh@example.com"
    body = response.json()
    assert body["email"] == "jagadeesh@example.com"
    assert "password_hash" not in body


def test_register_validation_errors(client) -> None:
    response = client.post(
        f"{BASE}/register",
        json={"name": "J", "email": "not-an-email", "phone": "123", "password": "short"},
    )
    assert response.status_code == 422


def test_register_duplicate_maps_to_400(client, monkeypatch) -> None:
    async def fake_register(self, payload):
        raise InvalidInputException("An account with this email already exists.")

    monkeypatch.setattr(AuthService, "register", fake_register)
    response = client.post(
        f"{BASE}/register",
        json={
            "name": "Jagadeesh Gowda",
            "email": "dupe@example.com",
            "phone": "+919876543210",
            "password": "StrongPass123",
        },
    )
    assert response.status_code == 400
    assert response.json()["error_code"] == "BAD_REQUEST"


# ============================================================================
# LOGIN
# ============================================================================


def test_login_valid_request(client, monkeypatch) -> None:
    async def fake_login(self, identifier, password):
        return make_token_response()

    monkeypatch.setattr(AuthService, "login", fake_login)
    response = client.post(
        f"{BASE}/login",
        json={"identifier": "jagadeesh@example.com", "password": "StrongPass123"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["access_token"] == "access-token"
    assert body["token_type"] == "bearer"


def test_login_invalid_credentials_generic_401(client, monkeypatch) -> None:
    async def fake_login(self, identifier, password):
        raise UnauthorizedException("Invalid email/phone or password")

    monkeypatch.setattr(AuthService, "login", fake_login)
    response = client.post(
        f"{BASE}/login",
        json={"identifier": "jagadeesh@example.com", "password": "WrongPass123"},
    )
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"
    # Generic: must not reveal whether the identifier exists.
    assert response.json()["message"] == "Invalid email/phone or password"


def test_login_inactive_account_generic_401(client, monkeypatch) -> None:
    async def fake_login(self, identifier, password):
        raise UnauthorizedException("Invalid email/phone or password")

    monkeypatch.setattr(AuthService, "login", fake_login)
    response = client.post(
        f"{BASE}/login",
        json={"identifier": "jagadeesh@example.com", "password": "StrongPass123"},
    )
    assert response.status_code == 401
    assert response.json()["message"] == "Invalid email/phone or password"


# ============================================================================
# REFRESH
# ============================================================================


def test_refresh_valid_request(client, monkeypatch) -> None:
    async def fake_refresh(self, refresh_token):
        return make_token_response()

    monkeypatch.setattr(AuthService, "refresh", fake_refresh)
    response = client.post(
        f"{BASE}/refresh",
        json={"refresh_token": "refresh-token"},
    )
    assert response.status_code == 200
    assert response.json()["access_token"] == "access-token"


def test_refresh_invalid_token_generic_401(client, monkeypatch) -> None:
    async def fake_refresh(self, refresh_token):
        raise UnauthorizedException("Invalid or expired refresh token")

    monkeypatch.setattr(AuthService, "refresh", fake_refresh)
    response = client.post(
        f"{BASE}/refresh",
        json={"refresh_token": "bad-token"},
    )
    assert response.status_code == 401
    assert response.json()["message"] == "Invalid or expired refresh token"


# ============================================================================
# LOGOUT
# ============================================================================


def test_logout_success(client, monkeypatch) -> None:
    async def fake_logout(self, refresh_token):
        return LogoutResponse(message="Successfully logged out")

    monkeypatch.setattr(AuthService, "logout", fake_logout)
    response = client.post(f"{BASE}/logout", json={"refresh_token": "refresh-token"})
    assert response.status_code == 200
    assert response.json()["message"] == "Successfully logged out"


def test_logout_idempotent(client, monkeypatch) -> None:
    async def fake_logout(self, refresh_token):
        return LogoutResponse(message="Successfully logged out")

    monkeypatch.setattr(AuthService, "logout", fake_logout)
    assert client.post(f"{BASE}/logout", json={"refresh_token": "refresh-token"}).status_code == 200
    assert client.post(f"{BASE}/logout", json={"refresh_token": "refresh-token"}).status_code == 200


# ============================================================================
# ME (real get_current_user dependency + real JWT verification)
# ============================================================================


def _override_db(app, users):
    async def fake_get_db():
        yield FakeSession(users)

    app.dependency_overrides[get_db] = fake_get_db


def _access_token(user_id: str = USER_ID) -> str:
    return security.create_access_token(user_id)


def _refresh_token(user_id: str = USER_ID) -> str:
    return security.create_refresh_token(user_id)


def test_me_missing_authorization(client) -> None:
    _override_db(client.app, {})
    response = client.get(f"{BASE}/me")
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


def test_me_malformed_authorization(client) -> None:
    _override_db(client.app, {})
    response = client.get(f"{BASE}/me", headers={"Authorization": "Bearer not-a-jwt"})
    assert response.status_code == 401


def test_me_access_token_accepted(client) -> None:
    user = make_user()
    _override_db(client.app, {USER_ID: user})
    response = client.get(
        f"{BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == USER_ID
    assert body["email"] == "jagadeesh@example.com"
    assert body["role"] == "customer"


def test_me_refresh_token_rejected(client) -> None:
    user = make_user()
    _override_db(client.app, {USER_ID: user})
    response = client.get(
        f"{BASE}/me",
        headers={"Authorization": f"Bearer {_refresh_token()}"},
    )
    assert response.status_code == 401


def test_me_inactive_user_rejected(client) -> None:
    user = make_user(is_active=False)
    _override_db(client.app, {USER_ID: user})
    response = client.get(
        f"{BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 401


def test_me_safe_response_fields_only(client) -> None:
    user = make_user(
        password_hash="secret-hash",
        failed_login_attempts=4,
        lockout_at=NOW,
        last_login_at=NOW,
    )
    _override_db(client.app, {USER_ID: user})
    response = client.get(
        f"{BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
    )
    assert response.status_code == 200
    body = response.json()
    for secret_field in ("password_hash", "token_digest", "failed_login_attempts", "lockout_at", "last_login_at"):
        assert secret_field not in body
    assert body["id"] == USER_ID


# ============================================================================
# VERIFY / RESET BOUNDARIES
# ============================================================================


def test_verify_documented_501_boundary(client) -> None:
    """The verify endpoint must surface 501, never fake success."""
    response = client.post(f"{BASE}/verify", json={"token": "some-token"})
    assert response.status_code == 501


def test_reset_password_documented_501_boundary(client) -> None:
    response = client.post(
        f"{BASE}/reset-password",
        json={"token": "some-token", "new_password": "NewStrongPass456"},
    )
    assert response.status_code == 501


# ============================================================================
# FORGOT PASSWORD (enumeration-safe)
# ============================================================================


def test_forgot_password_generic_response(client, monkeypatch) -> None:
    async def fake_forgot(self, identifier):
        return ForgotPasswordResponse(
            message="If an account exists, a password reset link has been sent."
        )

    monkeypatch.setattr(AuthService, "forgot_password", fake_forgot)
    response = client.post(
        f"{BASE}/forgot-password",
        json={"identifier": "nobody@example.com"},
    )
    assert response.status_code == 200
    assert response.json()["message"] == "If an account exists, a password reset link has been sent."