"""API-level unit & security tests for Vehicle routes."""

import uuid
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional

import pytest
from fastapi import FastAPI, status
from fastapi.testclient import TestClient

from app.api.deps import get_current_user, get_db
from app.api.v1.vehicles import router as vehicles_router
from app.core import security
from app.core.config import settings
from app.models.user import User
from app.models.vehicle import Vehicle
from app.schemas.vehicle import VehicleResponse

USER_A_ID = uuid.UUID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
USER_B_ID = uuid.UUID("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")


class _FakeScalarResult:
    def __init__(self, items: List[Any]) -> None:
        self.items = items

    def all(self) -> List[Any]:
        return list(self.items)

    def scalar(self) -> Any:
        return self.items[0] if self.items else None


class FakeVehicleSession:
    """In-memory session simulating vehicle queries and default constraints."""

    def __init__(self, vehicles: Optional[List[Vehicle]] = None) -> None:
        self.vehicles = vehicles or []
        self.flushes = 0

    async def get(self, model: Any, entity_id: Any) -> Optional[Any]:
        if model is Vehicle:
            for v in self.vehicles:
                if str(v.id) == str(entity_id):
                    return v
        return None

    async def scalar(self, stmt: Any) -> Optional[Any]:
        # Handle select(Vehicle).where(Vehicle.id == ..., Vehicle.user_id == ...)
        from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
        from sqlalchemy.sql.operators import eq

        target_id = None
        target_user = None

        if hasattr(stmt, "whereclause") and stmt.whereclause is not None:
            clauses = stmt.whereclause.clauses if isinstance(stmt.whereclause, BooleanClauseList) else [stmt.whereclause]
            for c in clauses:
                if isinstance(c, BinaryExpression) and c.operator is eq:
                    col = getattr(c.left, "name", None)
                    val = getattr(c.right, "value", c.right)
                    if col == "id":
                        target_id = str(val)
                    elif col == "user_id":
                        target_user = str(val)

        for v in self.vehicles:
            match = True
            if target_id is not None and str(v.id) != target_id:
                match = False
            if target_user is not None and str(v.user_id) != target_user:
                match = False
            if match:
                return v
        return None

    async def scalars(self, stmt: Any) -> _FakeScalarResult:
        from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
        from sqlalchemy.sql.operators import eq

        target_user = None
        if hasattr(stmt, "whereclause") and stmt.whereclause is not None:
            clauses = stmt.whereclause.clauses if isinstance(stmt.whereclause, BooleanClauseList) else [stmt.whereclause]
            for c in clauses:
                if isinstance(c, BinaryExpression) and c.operator is eq:
                    col = getattr(c.left, "name", None)
                    val = getattr(c.right, "value", c.right)
                    if col == "user_id":
                        target_user = str(val)

        matched = [v for v in self.vehicles if target_user is None or str(v.user_id) == target_user]
        # Sort defaults first
        matched.sort(key=lambda x: (not x.is_default, x.created_at))
        return _FakeScalarResult(matched)

    async def execute(self, stmt: Any) -> None:
        # Handle unset_all_defaults update
        from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
        from sqlalchemy.sql.operators import eq

        target_user = None
        if hasattr(stmt, "whereclause") and stmt.whereclause is not None:
            clauses = stmt.whereclause.clauses if isinstance(stmt.whereclause, BooleanClauseList) else [stmt.whereclause]
            for c in clauses:
                if isinstance(c, BinaryExpression) and c.operator is eq:
                    col = getattr(c.left, "name", None)
                    val = getattr(c.right, "value", c.right)
                    if col == "user_id":
                        target_user = str(val)

        if target_user:
            for v in self.vehicles:
                if str(v.user_id) == target_user:
                    v.is_default = False

    def add(self, obj: Any) -> None:
        if not hasattr(obj, "id") or obj.id is None:
            obj.id = uuid.uuid4()
        if not hasattr(obj, "created_at") or obj.created_at is None:
            obj.created_at = datetime.now(timezone.utc)
        if not hasattr(obj, "updated_at") or obj.updated_at is None:
            obj.updated_at = datetime.now(timezone.utc)
        self.vehicles.append(obj)

    async def flush(self) -> None:
        self.flushes += 1

    async def commit(self) -> None:
        self.flushes += 1

    async def refresh(self, obj: Any) -> None:
        pass

    async def delete(self, obj: Any) -> None:
        if obj in self.vehicles:
            self.vehicles.remove(obj)


from app.core.exceptions import MechaException
from fastapi.responses import JSONResponse


def create_test_app(fake_session: FakeVehicleSession, current_user: Optional[User] = None) -> TestClient:
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

    app.include_router(vehicles_router, prefix="/api/v1")

    app.dependency_overrides[get_db] = lambda: fake_session
    if current_user:
        app.dependency_overrides[get_current_user] = lambda: current_user

    return TestClient(app)


def test_unauthenticated_request_returns_401():
    client = create_test_app(FakeVehicleSession())
    res = client.get("/api/v1/vehicles")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED


def test_list_vehicles_empty_for_new_user():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    res = client.get("/api/v1/vehicles")
    assert res.status_code == status.HTTP_200_OK
    assert res.json() == []


def test_create_vehicle_first_vehicle_becomes_default():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    payload = {
        "brand": "Honda",
        "model": "Activa 6G",
        "registration": "KA 01 AB 1234",
        "fuel_type": "petrol",
        "health_score": 90,
    }
    res = client.post("/api/v1/vehicles", json=payload)
    assert res.status_code == status.HTTP_201_CREATED
    data = res.json()
    assert data["brand"] == "Honda"
    assert data["model"] == "Activa 6G"
    assert data["registration"] == "KA 01 AB 1234"
    assert data["fuel_type"] == "petrol"
    assert data["is_default"] is True  # Automatically made default
    assert str(data["user_id"]) == str(USER_A_ID)


def test_create_second_vehicle_does_not_override_default_unless_specified():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    # 1. Create first vehicle
    client.post("/api/v1/vehicles", json={
        "brand": "Honda",
        "model": "Activa 6G",
        "registration": "KA 01 AB 1234",
        "fuel_type": "petrol",
    })

    # 2. Create second vehicle with is_default=False
    res = client.post("/api/v1/vehicles", json={
        "brand": "Maruti",
        "model": "Swift",
        "registration": "KA 02 CD 5678",
        "fuel_type": "diesel",
        "is_default": False,
    })
    assert res.status_code == status.HTTP_201_CREATED
    assert res.json()["is_default"] is False

    # Check list
    list_res = client.get("/api/v1/vehicles")
    assert len(list_res.json()) == 2
    assert list_res.json()[0]["is_default"] is True
    assert list_res.json()[1]["is_default"] is False


def test_set_default_vehicle_promotes_target_and_clears_others():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    # 1. Create v1 (default)
    v1_id = client.post("/api/v1/vehicles", json={
        "brand": "Honda", "model": "Activa 6G", "registration": "KA 01 AB 1234", "fuel_type": "petrol"
    }).json()["id"]

    # 2. Create v2 (not default)
    v2_id = client.post("/api/v1/vehicles", json={
        "brand": "Maruti", "model": "Swift", "registration": "KA 02 CD 5678", "fuel_type": "diesel", "is_default": False
    }).json()["id"]

    # 3. Promote v2 to default
    promote_res = client.post(f"/api/v1/vehicles/{v2_id}/default")
    assert promote_res.status_code == status.HTTP_200_OK
    assert promote_res.json()["is_default"] is True

    # 4. Verify v1 is no longer default
    v1_get = client.get(f"/api/v1/vehicles/{v1_id}").json()
    assert v1_get["is_default"] is False


def test_get_own_vehicle():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    v_id = client.post("/api/v1/vehicles", json={
        "brand": "Honda", "model": "Civic", "registration": "KA 05 MN 9999", "fuel_type": "petrol"
    }).json()["id"]

    res = client.get(f"/api/v1/vehicles/{v_id}")
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["id"] == v_id


def test_user_a_cannot_access_user_b_vehicle_idor_prevention():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    user_b = User(id=USER_B_ID, name="User B", email="b@example.com")

    # User B creates vehicle
    client_b = create_test_app(session, user_b)
    v_b_id = client_b.post("/api/v1/vehicles", json={
        "brand": "BMW", "model": "3 Series", "registration": "KA 03 XY 7777", "fuel_type": "petrol"
    }).json()["id"]

    # User A tries to GET User B's vehicle
    client_a = create_test_app(session, user_a)
    get_res = client_a.get(f"/api/v1/vehicles/{v_b_id}")
    assert get_res.status_code == status.HTTP_404_NOT_FOUND

    # User A tries to PATCH User B's vehicle
    patch_res = client_a.patch(f"/api/v1/vehicles/{v_b_id}", json={"brand": "Hacked"})
    assert patch_res.status_code == status.HTTP_404_NOT_FOUND

    # User A tries to DELETE User B's vehicle
    del_res = client_a.delete(f"/api/v1/vehicles/{v_b_id}")
    assert del_res.status_code == status.HTTP_404_NOT_FOUND

    # User A tries to setDefault on User B's vehicle
    def_res = client_a.post(f"/api/v1/vehicles/{v_b_id}/default")
    assert def_res.status_code == status.HTTP_404_NOT_FOUND


def test_update_own_vehicle():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    v_id = client.post("/api/v1/vehicles", json={
        "brand": "Hyundai", "model": "i20", "registration": "KA 04 EF 1111", "fuel_type": "petrol"
    }).json()["id"]

    res = client.patch(f"/api/v1/vehicles/{v_id}", json={
        "registration": "KA 04 EF 2222",
        "health_score": 88,
    })
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["registration"] == "KA 04 EF 2222"
    assert res.json()["health_score"] == 88


def test_delete_own_vehicle_promotes_remaining_when_default_deleted():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    # 1. Create v1 (default)
    v1_id = client.post("/api/v1/vehicles", json={
        "brand": "Honda", "model": "Activa 6G", "registration": "KA 01 AB 1234", "fuel_type": "petrol"
    }).json()["id"]

    # 2. Create v2
    v2_id = client.post("/api/v1/vehicles", json={
        "brand": "Maruti", "model": "Swift", "registration": "KA 02 CD 5678", "fuel_type": "diesel", "is_default": False
    }).json()["id"]

    # 3. Delete v1 (the default)
    del_res = client.delete(f"/api/v1/vehicles/{v1_id}")
    assert del_res.status_code == status.HTTP_204_NO_CONTENT

    # 4. v2 should now be promoted to default
    v2_get = client.get(f"/api/v1/vehicles/{v2_id}").json()
    assert v2_get["is_default"] is True


def test_validation_errors_reject_invalid_payload():
    session = FakeVehicleSession()
    user_a = User(id=USER_A_ID, name="User A", email="a@example.com")
    client = create_test_app(session, user_a)

    # Invalid fuel_type
    res1 = client.post("/api/v1/vehicles", json={
        "brand": "Honda", "model": "City", "registration": "KA 01 XY 1234", "fuel_type": "nuclear"
    })
    assert res1.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Invalid health_score > 100
    res2 = client.post("/api/v1/vehicles", json={
        "brand": "Honda", "model": "City", "registration": "KA 01 XY 1234", "fuel_type": "petrol", "health_score": 150
    })
    assert res2.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Extra field forbidden (user_id injection attempt)
    res3 = client.post("/api/v1/vehicles", json={
        "brand": "Honda", "model": "City", "registration": "KA 01 XY 1234", "fuel_type": "petrol", "user_id": str(USER_B_ID)
    })
    assert res3.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
