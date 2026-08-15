"""API-level security tests for the Task 5 Users/Profile routes.

Strategy (mirrors Stage 7/8 tests): build a lightweight FastAPI app that mounts
the REAL users router (+ auth router for intact-route checks) and registers the
same ``MechaException`` → HTTP mapping as ``app.main``. ``get_db`` is overridden
with a fake session; ``get_current_user`` runs the REAL ``app.api.deps``
implementation (real JWT verification) against a configured test secret. The
REAL ``UserService`` runs against the fake session.

No live PostgreSQL required: a fake successful connection is NOT claimed — live
DB behavior is reported separately as NOT VERIFIED.
"""

from datetime import datetime, timezone
from typing import Dict, Optional

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_db
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.core import security
from app.core.config import settings
from app.core.exceptions import MechaException
from app.models.user import User

TEST_JWT_SECRET = "task5-users-api-test-secret-not-for-production"
USER_ID = "33333333-3333-3333-3333-333333333333"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)

USERS_BASE = "/api/v1/users"
AUTH_BASE = "/api/v1/auth"


class FakeSession:
    """Minimal session supporting the repository calls used by the routes."""

    def __init__(self, users: Optional[Dict[str, User]] = None) -> None:
        self.users = users or {}
        self.commits = 0

    async def get(self, model, entity_id) -> Optional[User]:
        if model is User:
            return self.users.get(str(entity_id))
        return None

    async def flush(self) -> None:
        pass

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
        "password_hash": "$2b$12$irrelevantfortask5",
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


def _access_token(user_id: str = USER_ID) -> str:
    return security.create_access_token(user_id)


def _refresh_token(user_id: str = USER_ID) -> str:
    return security.create_refresh_token(user_id)


@pytest.fixture
def users_app(monkeypatch) -> FastAPI:
    """Minimal app mirroring main.py's handler + real users/auth routers."""
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

    app.include_router(users_router, prefix="/api/v1")
    app.include_router(auth_router, prefix="/api/v1/auth")

    # Real JWT verification against a deterministic test secret.
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)

    return app


@pytest.fixture
def session_store():
    """Shared container so tests can seed/read the fake session's users."""
    return {}


@pytest.fixture
def client(users_app, session_store) -> TestClient:
    """Client whose get_db resolves to a fake session seeded from the store."""

    async def fake_get_db():
        yield FakeSession(session_store)

    users_app.dependency_overrides[get_db] = fake_get_db
    return TestClient(users_app)


# ============================================================================
# 1-2. GET /users/me — authenticated + unauthenticated
# ============================================================================


def test_get_me_authenticated(client, session_store) -> None:
    session_store[USER_ID] = make_user(
        emergency_contact_name="Anu",
        emergency_contact_relation="Sister",
        emergency_contact_phone="+919812345678",
    )
    response = client.get(f"{USERS_BASE}/me", headers={"Authorization": f"Bearer {_access_token()}"})
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == USER_ID
    assert body["email"] == "jagadeesh@example.com"
    assert body["name"] == "Jagadeesh Gowda"
    assert body["emergency_contact_name"] == "Anu"
    assert body["emergency_contact_relation"] == "Sister"
    assert body["emergency_contact_phone"] == "+919812345678"


def test_get_me_missing_authorization(client) -> None:
    response = client.get(f"{USERS_BASE}/me")
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


def test_get_me_malformed_authorization(client) -> None:
    response = client.get(f"{USERS_BASE}/me", headers={"Authorization": "Bearer not-a-jwt"})
    assert response.status_code == 401


def test_get_me_refresh_token_rejected(client, session_store) -> None:
    session_store[USER_ID] = make_user()
    response = client.get(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_refresh_token()}"},
    )
    assert response.status_code == 401


# ============================================================================
# 3. PATCH /users/me — authenticated succeeds
# ============================================================================


def test_patch_me_authenticated_succeeds(client, session_store) -> None:
    session_store[USER_ID] = make_user()
    response = client.patch(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
        json={"name": "Jagadeesh Gowda Kumar", "gender": "male"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Jagadeesh Gowda Kumar"
    assert body["gender"] == "male"
    assert body["id"] == USER_ID
    assert session_store[USER_ID].name == "Jagadeesh Gowda Kumar"
    assert session_store[USER_ID].gender == "male"


def test_patch_me_missing_authorization(client) -> None:
    response = client.patch(f"{USERS_BASE}/me", json={"name": "New Name"})
    assert response.status_code == 401


# ============================================================================
# 4. PATCH only updates safe fields (whitelist behavior)
# ============================================================================


def test_patch_me_only_safe_fields_updated(client, session_store) -> None:
    user = make_user(name="Original", gender="male", date_of_birth=None)
    session_store[USER_ID] = user
    response = client.patch(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
        json={"name": "Renamed", "emergency_contact_name": "EC", "date_of_birth": "1990-05-20"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Renamed"
    assert body["emergency_contact_name"] == "EC"
    assert body["date_of_birth"] == "1990-05-20"
    # Untouched safe field stays unchanged.
    assert body["gender"] == "male"


# ============================================================================
# 5-15. Protected fields cannot be changed (rejected at schema boundary)
# ============================================================================

PROTECTED_FIELD_PAYLOADS = [
    {"role": "admin"},
    {"is_active": False},
    {"is_verified": True},
    {"membership_tier": "pro"},
    {"password_hash": "hacked"},
    {"email": "attacker@example.com"},
    {"phone": "+919900000000"},
    {"failed_login_attempts": 99},
    {"lockout_at": "2026-08-15T12:00:00Z"},
    {"last_login_at": "2026-08-15T12:00:00Z"},
    {"id": "99999999-9999-9999-9999-999999999999"},
]


@pytest.mark.parametrize("payload", PROTECTED_FIELD_PAYLOADS)
def test_patch_me_rejects_protected_fields(client, session_store, payload) -> None:
    session_store[USER_ID] = make_user(role="customer", is_active=True, is_verified=False)
    response = client.patch(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
        json=payload,
    )
    # Mass assignment must be impossible: schema forbids unknown fields → 422.
    assert response.status_code == 422
    # Nothing was changed.
    user = session_store[USER_ID]
    assert user.role == "customer"
    assert user.is_active is True
    assert user.is_verified is False


def test_patch_me_combined_safe_and_protected_rejected(client, session_store) -> None:
    """Even a mixed payload with a protected field is rejected wholesale."""
    session_store[USER_ID] = make_user(name="Original", role="customer")
    response = client.patch(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
        json={"name": "Hacked Name", "role": "admin"},
    )
    assert response.status_code == 422
    assert session_store[USER_ID].name == "Original"
    assert session_store[USER_ID].role == "customer"


# ============================================================================
# 16. Emergency contact trio can be updated
# ============================================================================


def test_patch_me_updates_emergency_contact_trio(client, session_store) -> None:
    session_store[USER_ID] = make_user()
    response = client.patch(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
        json={
            "emergency_contact_name": "Ravi",
            "emergency_contact_relation": "Brother",
            "emergency_contact_phone": "+919811223344",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["emergency_contact_name"] == "Ravi"
    assert body["emergency_contact_relation"] == "Brother"
    assert body["emergency_contact_phone"] == "+919811223344"
    assert session_store[USER_ID].emergency_contact_name == "Ravi"
    assert session_store[USER_ID].emergency_contact_relation == "Brother"
    assert session_store[USER_ID].emergency_contact_phone == "+919811223344"


# ============================================================================
# 17. Response never exposes sensitive fields
# ============================================================================


def test_response_never_exposes_sensitive_fields(client, session_store) -> None:
    user = make_user(
        password_hash="secret-hash",
        failed_login_attempts=4,
        lockout_at=NOW,
        last_login_at=NOW,
    )
    session_store[USER_ID] = user
    for method in ("GET", "PATCH"):
        kwargs = {"json": {"name": "Updated"}} if method == "PATCH" else {}
        response = client.request(
            method,
            f"{USERS_BASE}/me",
            headers={"Authorization": f"Bearer {_access_token()}"},
            **kwargs,
        )
        assert response.status_code == 200
        body = response.json()
        for secret_field in (
            "password_hash",
            "token_digest",
            "jti",
            "failed_login_attempts",
            "lockout_at",
            "last_login_at",
            "created_at",
            "updated_at",
        ):
            assert secret_field not in body


# ============================================================================
# 18. Owner identity comes from get_current_user() (no client user_id)
# ============================================================================


def test_owner_identity_from_token_not_body(client, session_store) -> None:
    session_store[USER_ID] = make_user()
    response = client.patch(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token()}"},
        json={"name": "Owned Profile", "user_id": USER_ID},
    )
    # user_id is not a writable field → rejected (no silent identity change).
    assert response.status_code == 422


def test_get_me_identity_from_token(client, session_store) -> None:
    other_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    session_store[other_id] = make_user(id=other_id)
    response = client.get(
        f"{USERS_BASE}/me",
        headers={"Authorization": f"Bearer {_access_token(other_id)}"},
    )
    assert response.status_code == 200
    assert response.json()["id"] == other_id


# ============================================================================
# 19. No /users/{user_id} endpoint exists
# ============================================================================


def test_no_users_user_id_endpoint(users_app) -> None:
    paths = set(users_app.openapi()["paths"].keys())
    assert f"{USERS_BASE}/me" in paths
    assert not any(p.startswith(f"{USERS_BASE}/{{") for p in paths)
    assert f"{USERS_BASE}/{{user_id}}" not in paths
    assert not any("/admin/users" in p for p in paths)


# ============================================================================
# 20. Existing auth/conversation/AI routes remain intact (router registration)
# ============================================================================


def test_existing_auth_routes_still_registered(users_app) -> None:
    paths = set(users_app.openapi()["paths"].keys())
    for expected in (
        f"{AUTH_BASE}/register",
        f"{AUTH_BASE}/login",
        f"{AUTH_BASE}/refresh",
        f"{AUTH_BASE}/logout",
        f"{AUTH_BASE}/me",
        f"{USERS_BASE}/me",
    ):
        assert expected in paths


def test_auth_me_still_works_after_users_registration(client, session_store) -> None:
    session_store[USER_ID] = make_user()
    response = client.get(f"{AUTH_BASE}/me", headers={"Authorization": f"Bearer {_access_token()}"})
    assert response.status_code == 200
    assert response.json()["id"] == USER_ID