"""Unit and API tests for Device Token registration and lifecycle."""

from datetime import datetime, timezone
from typing import Any, List, Optional
import uuid
import pytest
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_current_user, get_db
from app.api.v1.device_tokens import router as device_tokens_router
from app.core.exceptions import MechaException
from app.models.device_token import DeviceToken
from app.models.user import User, UserRole
from app.repositories.device_token import DeviceTokenRepository
from app.schemas.device_token import DevicePlatform


class FakeDeviceTokenSession:
    """In-memory async session fake for device token testing."""

    def __init__(self) -> None:
        self.device_tokens: List[DeviceToken] = []
        self.flushes = 0
        self.commits = 0

    async def execute(self, stmt: Any) -> Any:
        stmt_str = str(stmt).lower()

        # Handle SELECT ... FROM device_tokens WHERE ...
        if "select" in stmt_str and "device_tokens" in stmt_str:
            target_fcm = None
            target_user = None
            is_active_check = "is_active is true" in stmt_str or "is_active = true" in stmt_str

            if hasattr(stmt, "compile"):
                compiled = stmt.compile()
                for col, val in compiled.params.items():
                    if "fcm_token" in col:
                        target_fcm = str(val)
                    elif "user_id" in col:
                        target_user = str(val)

            matched = []
            for dt in self.device_tokens:
                if target_fcm and dt.fcm_token != target_fcm:
                    continue
                if target_user and str(dt.user_id) != target_user:
                    continue
                if is_active_check and not dt.is_active:
                    continue
                matched.append(dt)

            class FakeResult:
                def __init__(self, items: List[Any]):
                    self._items = items

                def scalar_one_or_none(self):
                    return self._items[0] if self._items else None

                def scalars(self):
                    class FakeScalars:
                        def __init__(self, it):
                            self._it = it
                        def all(self):
                            return [x.fcm_token for x in self._it]
                    return FakeScalars(self._items)

            return FakeResult(matched)

        # Handle DELETE FROM device_tokens WHERE ...
        if "delete from device_tokens" in stmt_str:
            target_fcm = None
            target_user = None
            if hasattr(stmt, "compile"):
                compiled = stmt.compile()
                for col, val in compiled.params.items():
                    if "fcm_token" in col:
                        target_fcm = str(val)
                    elif "user_id" in col:
                        target_user = str(val)

            initial_len = len(self.device_tokens)
            self.device_tokens = [
                dt for dt in self.device_tokens
                if not (
                    (target_fcm is None or dt.fcm_token == target_fcm)
                    and (target_user is None or str(dt.user_id) == target_user)
                )
            ]
            deleted_count = initial_len - len(self.device_tokens)

            class FakeDeleteResult:
                rowcount = deleted_count

            return FakeDeleteResult()

        class GenericResult:
            rowcount = 0
            def scalar_one_or_none(self):
                return None
            def scalars(self):
                class EmptyScalars:
                    def all(self):
                        return []
                return EmptyScalars()

        return GenericResult()

    def add(self, entity: Any) -> None:
        if isinstance(entity, DeviceToken):
            if not getattr(entity, "id", None):
                entity.id = uuid.uuid4()
            self.device_tokens.append(entity)

    async def flush(self) -> None:
        self.flushes += 1

    async def commit(self) -> None:
        self.commits += 1

    async def refresh(self, entity: Any) -> None:
        pass


def create_test_client(fake_session: FakeDeviceTokenSession, current_user: Optional[User] = None) -> TestClient:
    app = FastAPI()

    @app.exception_handler(MechaException)
    async def mecha_exception_handler(request, exc: MechaException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.message, "error_code": exc.error_code},
        )

    app.include_router(device_tokens_router, prefix="/api/v1")

    async def override_get_db():
        yield fake_session

    async def override_get_current_user():
        if current_user is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
        return current_user

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    return TestClient(app)


def test_register_device_token_success() -> None:
    session = FakeDeviceTokenSession()
    user = User(
        id=uuid.uuid4(),
        name="John Doe",
        email="john@example.com",
        phone="+919876543210",
        role=UserRole.CUSTOMER,
    )
    client = create_test_client(session, user)

    payload = {
        "fcm_token": "fcm-token-123456",
        "platform": "android",
        "device_id": "device-uuid-1",
        "app_version": "1.0.0+1",
    }
    response = client.post("/api/v1/device-tokens", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["fcm_token"] == "fcm-token-123456"
    assert data["platform"] == "android"
    assert data["device_id"] == "device-uuid-1"
    assert data["is_active"] is True
    assert len(session.device_tokens) == 1
    assert str(session.device_tokens[0].user_id) == str(user.id)


def test_register_duplicate_token_updates_existing() -> None:
    session = FakeDeviceTokenSession()
    user = User(
        id=uuid.uuid4(),
        name="John Doe",
        email="john@example.com",
        phone="+919876543210",
        role=UserRole.CUSTOMER,
    )
    client = create_test_client(session, user)

    # First registration
    payload = {
        "fcm_token": "shared-fcm-token",
        "platform": "android",
        "device_id": "device-1",
    }
    res1 = client.post("/api/v1/device-tokens", json=payload)
    assert res1.status_code == 201

    # Second registration with same token but updated version
    payload2 = {
        "fcm_token": "shared-fcm-token",
        "platform": "android",
        "device_id": "device-1",
        "app_version": "1.0.1",
    }
    res2 = client.post("/api/v1/device-tokens", json=payload2)
    assert res2.status_code == 201

    # Should only have 1 record in database (upserted)
    assert len(session.device_tokens) == 1
    assert session.device_tokens[0].app_version == "1.0.1"


def test_token_ownership_transfer_on_account_switch() -> None:
    session = FakeDeviceTokenSession()
    user_a = User(id=uuid.uuid4(), name="User A", email="a@example.com", phone="+919111111111")
    user_b = User(id=uuid.uuid4(), name="User B", email="b@example.com", phone="+919222222222")

    # User A registers token on device
    client_a = create_test_client(session, user_a)
    res_a = client_a.post("/api/v1/device-tokens", json={"fcm_token": "device-token-xyz", "platform": "android"})
    assert res_a.status_code == 201
    assert str(session.device_tokens[0].user_id) == str(user_a.id)

    # User B logs in on same device and registers same token
    client_b = create_test_client(session, user_b)
    res_b = client_b.post("/api/v1/device-tokens", json={"fcm_token": "device-token-xyz", "platform": "android"})
    assert res_b.status_code == 201

    # Ownership must now belong to User B; row count remains 1
    assert len(session.device_tokens) == 1
    assert str(session.device_tokens[0].user_id) == str(user_b.id)


def test_multiple_devices_for_same_user() -> None:
    session = FakeDeviceTokenSession()
    user = User(id=uuid.uuid4(), name="Multi Device User", email="multi@example.com", phone="+919333333333")
    client = create_test_client(session, user)

    # Register phone
    client.post("/api/v1/device-tokens", json={"fcm_token": "token-phone", "platform": "android", "device_id": "phone-1"})
    # Register tablet
    client.post("/api/v1/device-tokens", json={"fcm_token": "token-tablet", "platform": "android", "device_id": "tablet-1"})

    assert len(session.device_tokens) == 2
    assert {dt.fcm_token for dt in session.device_tokens} == {"token-phone", "token-tablet"}


def test_delete_device_token_owner_safe() -> None:
    session = FakeDeviceTokenSession()
    user_a = User(id=uuid.uuid4(), name="User A", email="a@example.com", phone="+919111111111")
    user_b = User(id=uuid.uuid4(), name="User B", email="b@example.com", phone="+919222222222")

    # Add token for User A
    token_a = DeviceToken(
        id=uuid.uuid4(),
        user_id=user_a.id,
        fcm_token="token-user-a",
        platform="android",
        is_active=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    session.device_tokens.append(token_a)

    # User B attempts to delete User A's token
    client_b = create_test_client(session, user_b)
    res_b = client_b.request("DELETE", "/api/v1/device-tokens", json={"fcm_token": "token-user-a"})
    assert res_b.status_code == status.HTTP_204_NO_CONTENT
    # Token must NOT be deleted because User B is not the owner
    assert len(session.device_tokens) == 1

    # User A deletes their own token
    client_a = create_test_client(session, user_a)
    res_a = client_a.request("DELETE", "/api/v1/device-tokens", json={"fcm_token": "token-user-a"})
    assert res_a.status_code == status.HTTP_204_NO_CONTENT
    # Token is now removed
    assert len(session.device_tokens) == 0


def test_validation_errors() -> None:
    session = FakeDeviceTokenSession()
    user = User(id=uuid.uuid4(), name="User", email="u@example.com", phone="+919444444444")
    client = create_test_client(session, user)

    # Invalid platform
    res = client.post("/api/v1/device-tokens", json={"fcm_token": "tok", "platform": "windows_phone"})
    assert res.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Empty token
    res = client.post("/api/v1/device-tokens", json={"fcm_token": "", "platform": "android"})
    assert res.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Extra field forbidden
    res = client.post("/api/v1/device-tokens", json={"fcm_token": "tok", "platform": "android", "malicious_field": "hacked"})
    assert res.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_unauthenticated_request_rejected() -> None:
    session = FakeDeviceTokenSession()
    client = create_test_client(session, current_user=None)

    res = client.post("/api/v1/device-tokens", json={"fcm_token": "tok", "platform": "android"})
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
