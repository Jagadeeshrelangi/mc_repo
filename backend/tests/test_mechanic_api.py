"""Task 6, Stage 6 — Mechanic API integration tests (real service).

Strategy (recon §18: "follow ``test_users_api.py`` pattern: fake
``AsyncSession`` + real ``get_current_user`` + real service"):

- The REAL ``mechanic`` router is mounted on a lightweight app that registers
  the same ``MechaException``/generic handlers as ``app.main``.
- ``get_db`` is overridden to yield a single shared ``FakeSession`` (a users
  registry for ``get_current_user`` + commit/rollback/flush counters).
- ``get_current_user`` runs the REAL ``app.api.deps`` implementation against a
  monkeypatched test JWT secret (real JWT verification).
- The REAL ``MechanicService`` is constructed by the routes. Data access is
  faked at the repository-method boundary: the real repository class methods
  are monkeypatched with ``AsyncMock`` returning real ORM objects. This
  exercises the full route -> service -> repository wiring chain (what the
  Stage 5 route tests deliberately do not) while never touching SQL or a live
  PostgreSQL.

Client-supplied identity, owner-scoped reads, illegal transitions, rating
eligibility, sanitized 500s, auth-required 401s, and the OpenAPI
path-count/security contract (recon §18) are all covered here.

No live PostgreSQL: real constraint/UUID/JSONB behavior stays documented as
NOT VERIFIED (``DATABASE_URL`` absent). No commits/pushes/resets are performed.
"""

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, Optional
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_db
from app.api.v1.mechanic import router as mechanic_router
from app.core import security
from app.core.config import settings
from app.core.exceptions import MechaException
from app.models.mechanic import (
    Mechanic,
    MechanicLanguage,
    MechanicSkill,
    MechanicWorkingHour,
)
from app.models.mechanic_booking import BookingEvent, MechanicBooking, Rating
from app.models.mechanic_category import MechanicCategory
from app.models.mechanic_review import MechanicReview
from app.models.mechanic_service import (
    MechanicService as MechanicServiceModel,
    MechanicServiceOffered,
)
from app.models.mechanic_status import BookingStatus
from app.models.user import User
from app.repositories.mechanics import (
    BookingEventRepository,
    MechanicBookingRepository,
    MechanicCategoryRepository,
    MechanicRepository,
    MechanicReviewRepository,
    MechanicServiceRepository,
    RatingRepository,
)

TEST_JWT_SECRET = "task6-mechanic-api-test-secret-not-for-production"
USER_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
USER_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
B_ID = "11111111-1111-1111-1111-111111111111"
B_ID2 = "22222222-2222-2222-2222-222222222222"
V_ID = "33333333-3333-3333-3333-333333333333"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)

BASE = "/api/v1/mechanic"


# ============================================================================
# Fakes
# ============================================================================


class FakeSession:
    """Minimal session: users registry for ``get_current_user`` + counters.

    The real repositories built inside ``MechanicService`` never touch SQL here
    because their data-access methods are monkeypatched at the class boundary;
    the service itself only calls ``commit()``/``rollback()``. ``get()`` serves
    ``UserRepository.get`` used by the real ``get_current_user``.
    """

    def __init__(self, users: Optional[Dict[str, User]] = None) -> None:
        self.users = users if users is not None else {}
        self.commits = 0
        self.rollbacks = 0

    async def get(self, model, entity_id) -> Optional[Any]:
        if model is User:
            return self.users.get(str(entity_id))
        return None

    async def flush(self) -> None:
        pass

    async def commit(self) -> None:
        self.commits += 1

    async def rollback(self) -> None:
        self.rollbacks += 1


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


def make_mechanic(mid: str = "m1", **overrides: Any) -> Mechanic:
    """Build a catalog ``Mechanic`` with child collections attached.

    Children are attached eagerly so ``MechanicOut._flatten_orm_children``
    never needs lazy-loading in tests. The live-DB lazy-load risk for the
    list endpoints (Stage 4 review gap) is separate and documented as
    NOT VERIFIED.
    """
    mechanic = Mechanic(
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
    )
    mechanic.skills = [MechanicSkill(mechanic_id=mid, skill="Engine")]
    mechanic.languages = [MechanicLanguage(mechanic_id=mid, language="English")]
    mechanic.working_hours = [
        MechanicWorkingHour(mechanic_id=mid, day="Mon-Fri", open="8:00 AM", close="8:00 PM")
    ]
    svc = MechanicServiceModel(id="svc_1", name="Engine Repair", price=Decimal("499.00"))
    mechanic.services_offered = [
        MechanicServiceOffered(mechanic_id=mid, service_id="svc_1", service=svc)
    ]
    for key, value in overrides.items():
        setattr(mechanic, key, value)
    return mechanic


def make_booking(
    booking_id: str = B_ID,
    user_id: str = USER_A,
    status: str = BookingStatus.REQUESTED.value,
    **overrides: Any,
) -> MechanicBooking:
    booking = MechanicBooking(
        id=booking_id,
        user_id=user_id,
        mechanic_id="m1",
        service_id="svc_1",
        vehicle_id=None,
        status=status,
        address="12 MG Road",
        lat=Decimal("12.971599"),
        lng=Decimal("77.594566"),
        scheduled_at=None,
        created_at=NOW,
    )
    for key, value in overrides.items():
        setattr(booking, key, value)
    return booking


def make_event(booking_id: str = B_ID, status: str = "requested") -> BookingEvent:
    return BookingEvent(id=B_ID2, booking_id=booking_id, status=status, occurred_at=NOW)


def make_service() -> MechanicServiceModel:
    return MechanicServiceModel(id="svc_1", name="Engine Repair", price=Decimal("499.00"))


def make_category() -> MechanicCategory:
    return MechanicCategory(id="cat-1", name="Engine", sort_order=1)


def make_review() -> MechanicReview:
    return MechanicReview(
        id="r1",
        mechanic_id="m1",
        reviewer_name="Rahul",
        rating=Decimal("4.50"),
        comment="Great",
        vehicle="Honda City",
    )


def make_rating(booking_id: str = B_ID) -> Rating:
    return Rating(booking_id=booking_id, rating=Decimal("4.50"), review="Good")


def _access_token(user_id: str = USER_A) -> str:
    return security.create_access_token(user_id)


def _auth() -> Dict[str, str]:
    return {"Authorization": f"Bearer {_access_token()}"}


def _create_body(**overrides: Any) -> Dict[str, Any]:
    body: Dict[str, Any] = {
        "mechanic_id": "m1",
        "service_id": "svc_1",
        "vehicle_id": V_ID,
        "address": "12 MG Road",
        "lat": 12.971599,
        "lng": 77.594566,
        "scheduled_at": "2026-08-16T10:00:00Z",
    }
    body.update(overrides)
    return body


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mechanic_app(monkeypatch) -> FastAPI:
    """App mirroring main.py's handlers + the REAL mechanic router."""
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

    app.include_router(mechanic_router, prefix="/api/v1")

    # Real JWT verification against a deterministic test secret.
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)

    return app


@pytest.fixture
def session_store():
    """Shared container: users dict + a single FakeSession reused per request."""
    users: Dict[str, User] = {}
    session = FakeSession(users)
    return {"users": users, "session": session}


@pytest.fixture
def client(mechanic_app, session_store) -> TestClient:
    """Client whose get_db resolves to the shared FakeSession."""

    async def fake_get_db():
        yield session_store["session"]

    mechanic_app.dependency_overrides[get_db] = fake_get_db
    return TestClient(mechanic_app, raise_server_exceptions=False)


# ============================================================================
# Catalog integration (public, real service, real repo wiring)
# ============================================================================


def test_list_mechanics_through_real_service(client, session_store, monkeypatch) -> None:
    list_all = AsyncMock(return_value=[make_mechanic("m1"), make_mechanic("m2")])
    monkeypatch.setattr(MechanicRepository, "list_all", list_all)

    response = client.get(f"{BASE}/mechanics")

    assert response.status_code == 200
    body = response.json()
    assert [m["id"] for m in body] == ["m1", "m2"]
    assert body[0]["skills"] == ["Engine"]
    assert body[0]["languages"] == ["English"]
    assert body[0]["working_hours"][0]["day"] == "Mon-Fri"
    assert float(body[0]["services"][0]["price"]) == 499.0
    assert body[0]["is_available"] is True
    list_all.assert_awaited_once()
    assert session_store["session"].commits == 0
    assert session_store["session"].rollbacks == 0


def test_featured_mechanics_through_real_service(client, session_store, monkeypatch) -> None:
    list_featured = AsyncMock(return_value=[make_mechanic("m1")])
    monkeypatch.setattr(MechanicRepository, "list_featured", list_featured)

    response = client.get(f"{BASE}/mechanics/featured")

    assert response.status_code == 200
    assert [m["id"] for m in response.json()] == ["m1"]
    list_featured.assert_awaited_once()
    assert session_store["session"].commits == 0


def test_get_mechanic_detail_through_real_service(client, session_store, monkeypatch) -> None:
    get_by_id = AsyncMock(return_value=make_mechanic("m1"))
    monkeypatch.setattr(MechanicRepository, "get_by_id", get_by_id)

    response = client.get(f"{BASE}/mechanics/m1")

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "m1"
    assert body["name"] == "Raju Auto Works"
    assert float(body["rating"]) == 4.8
    get_by_id.assert_awaited_once_with("m1")
    assert session_store["session"].commits == 0


def test_get_mechanic_not_found_404(client, session_store, monkeypatch) -> None:
    monkeypatch.setattr(MechanicRepository, "get_by_id", AsyncMock(return_value=None))

    response = client.get(f"{BASE}/mechanics/missing")

    assert response.status_code == 404
    assert response.json()["error_code"] == "NOT_FOUND"
    assert response.json()["message"] == "Mechanic not found."
    assert session_store["session"].rollbacks == 0


def test_list_services_through_real_service(client, session_store, monkeypatch) -> None:
    list_all = AsyncMock(return_value=[make_service()])
    monkeypatch.setattr(MechanicServiceRepository, "list_all", list_all)

    response = client.get(f"{BASE}/services")

    assert response.status_code == 200
    assert response.json()[0]["name"] == "Engine Repair"
    list_all.assert_awaited_once()
    assert session_store["session"].commits == 0


def test_list_categories_through_real_service(client, session_store, monkeypatch) -> None:
    list_all = AsyncMock(return_value=[make_category()])
    monkeypatch.setattr(MechanicCategoryRepository, "list_all", list_all)

    response = client.get(f"{BASE}/categories")

    assert response.status_code == 200
    assert response.json()[0]["name"] == "Engine"
    list_all.assert_awaited_once()
    assert session_store["session"].commits == 0


def test_list_mechanic_services_scoped_through_real_service(
    client, session_store, monkeypatch
) -> None:
    list_for_mechanic = AsyncMock(return_value=[make_service()])
    monkeypatch.setattr(MechanicServiceRepository, "list_for_mechanic", list_for_mechanic)

    response = client.get(f"{BASE}/mechanics/m1/services")

    assert response.status_code == 200
    assert [s["name"] for s in response.json()] == ["Engine Repair"]
    list_for_mechanic.assert_awaited_once_with("m1")
    assert session_store["session"].commits == 0


def test_list_mechanic_reviews_through_real_service(client, session_store, monkeypatch) -> None:
    list_for_mechanic = AsyncMock(return_value=[make_review()])
    monkeypatch.setattr(MechanicReviewRepository, "list_for_mechanic", list_for_mechanic)

    response = client.get(f"{BASE}/mechanics/m1/reviews")

    assert response.status_code == 200
    body = response.json()
    assert body[0]["reviewer_name"] == "Rahul"
    assert float(body[0]["rating"]) == 4.5
    list_for_mechanic.assert_awaited_once_with("m1")
    assert session_store["session"].commits == 0


def test_list_mechanic_reviews_unknown_mechanic_empty(
    client, session_store, monkeypatch
) -> None:
    list_for_mechanic = AsyncMock(return_value=[])
    monkeypatch.setattr(MechanicReviewRepository, "list_for_mechanic", list_for_mechanic)

    response = client.get(f"{BASE}/mechanics/unknown/reviews")

    assert response.status_code == 200
    assert response.json() == []
    list_for_mechanic.assert_awaited_once_with("unknown")
    assert session_store["session"].commits == 0


# ============================================================================
# Booking creation (real service orchestration)
# ============================================================================


def test_create_booking_real_service_full_chain(
    client, session_store, monkeypatch
) -> None:
    """Route -> real service -> repo wiring: pre-checks, create, event, commit."""
    session_store["users"][USER_A] = make_user()
    booking = make_booking()
    create_booking = AsyncMock(return_value=booking)
    append = AsyncMock(return_value=make_event())
    monkeypatch.setattr(MechanicRepository, "get_by_id", AsyncMock(return_value=make_mechanic()))
    monkeypatch.setattr(
        MechanicServiceRepository, "get_by_id", AsyncMock(return_value=make_service())
    )
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", create_booking)
    monkeypatch.setattr(BookingEventRepository, "append", append)

    response = client.post(f"{BASE}/bookings", headers=_auth(), json=_create_body())

    assert response.status_code == 201
    body = response.json()
    assert body["id"] == B_ID
    assert body["status"] == BookingStatus.REQUESTED.value
    assert body["mechanic_id"] == "m1"
    assert body["service_id"] == "svc_1"
    assert "user_id" not in body

    call_kwargs = create_booking.await_args.kwargs
    assert call_kwargs["user_id"] == USER_A
    assert call_kwargs["mechanic_id"] == "m1"
    assert call_kwargs["service_id"] == "svc_1"
    assert call_kwargs["status"] == BookingStatus.REQUESTED.value
    append.assert_awaited_once_with(booking_id=B_ID, status=BookingStatus.REQUESTED.value)
    assert session_store["session"].commits == 1
    assert session_store["session"].rollbacks == 0


def test_create_booking_client_user_id_rejected(
    client, session_store, monkeypatch
) -> None:
    """user_id is not a BookingCreate field; mass assignment is a 422."""
    session_store["users"][USER_A] = make_user()
    create_booking = AsyncMock()
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", create_booking)

    response = client.post(
        f"{BASE}/bookings",
        headers=_auth(),
        json=_create_body(user_id="99999999-9999-9999-9999-999999999999"),
    )

    assert response.status_code == 422
    create_booking.assert_not_awaited()
    assert session_store["session"].commits == 0


def test_create_booking_unknown_mechanic_404(client, session_store, monkeypatch) -> None:
    """FK pre-check turns an unknown mechanic into a controlled 404 + rollback."""
    session_store["users"][USER_A] = make_user()
    create_booking = AsyncMock()
    append = AsyncMock()
    monkeypatch.setattr(MechanicRepository, "get_by_id", AsyncMock(return_value=None))
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", create_booking)
    monkeypatch.setattr(BookingEventRepository, "append", append)

    response = client.post(f"{BASE}/bookings", headers=_auth(), json=_create_body())

    assert response.status_code == 404
    assert response.json()["message"] == "Mechanic not found."
    create_booking.assert_not_awaited()
    append.assert_not_awaited()
    assert session_store["session"].commits == 0
    assert session_store["session"].rollbacks == 1


def test_create_booking_unknown_service_404(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    create_booking = AsyncMock()
    monkeypatch.setattr(MechanicRepository, "get_by_id", AsyncMock(return_value=make_mechanic()))
    monkeypatch.setattr(MechanicServiceRepository, "get_by_id", AsyncMock(return_value=None))
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", create_booking)

    response = client.post(f"{BASE}/bookings", headers=_auth(), json=_create_body())

    assert response.status_code == 404
    assert response.json()["message"] == "Service not found."
    create_booking.assert_not_awaited()
    assert session_store["session"].rollbacks == 1


def test_create_booking_custom_issue_no_service(
    client, session_store, monkeypatch
) -> None:
    """service_id null + vehicle_id null (custom issue) passes straight through."""
    session_store["users"][USER_A] = make_user()
    create_booking = AsyncMock(return_value=make_booking())
    append = AsyncMock(return_value=make_event())
    monkeypatch.setattr(MechanicRepository, "get_by_id", AsyncMock(return_value=make_mechanic()))
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", create_booking)
    monkeypatch.setattr(BookingEventRepository, "append", append)

    body = _create_body(service_id=None, vehicle_id=None)
    response = client.post(f"{BASE}/bookings", headers=_auth(), json=body)

    assert response.status_code == 201
    call_kwargs = create_booking.await_args.kwargs
    assert call_kwargs["service_id"] is None
    assert call_kwargs["vehicle_id"] is None
    assert call_kwargs["user_id"] == USER_A
    assert session_store["session"].commits == 1


def test_create_booking_invalid_vehicle_id_422(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    create_booking = AsyncMock()
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", create_booking)

    response = client.post(
        f"{BASE}/bookings",
        headers=_auth(),
        json=_create_body(vehicle_id="not-a-uuid"),
    )

    assert response.status_code == 422
    create_booking.assert_not_awaited()
    assert session_store["session"].commits == 0


def test_create_booking_requires_auth(client, session_store, monkeypatch) -> None:
    monkeypatch.setattr(MechanicBookingRepository, "create_booking", AsyncMock())
    response = client.post(f"{BASE}/bookings", json=_create_body())
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


# ============================================================================
# Booking reads (owner-scoped, real service)
# ============================================================================


def test_get_booking_owned_200(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    get_owned = AsyncMock(return_value=make_booking())
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", get_owned)

    response = client.get(f"{BASE}/bookings/{B_ID}", headers=_auth())

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == B_ID
    assert body["status"] == BookingStatus.REQUESTED.value
    assert "user_id" not in body
    get_owned.assert_awaited_once_with(B_ID, USER_A)
    assert session_store["session"].commits == 0


def test_get_booking_foreign_user_404_same_as_missing(
    client, session_store, monkeypatch
) -> None:
    """Foreign and missing bookings both yield the same generic 404 (no leak)."""
    session_store["users"][USER_A] = make_user()
    session_store["users"][USER_B] = make_user(id=USER_B)
    get_owned = AsyncMock(return_value=None)
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", get_owned)

    foreign_response = client.get(
        f"{BASE}/bookings/{B_ID}", headers={"Authorization": f"Bearer {_access_token(USER_B)}"}
    )
    missing_response = client.get(f"{BASE}/bookings/missing-id", headers=_auth())

    assert foreign_response.status_code == 404
    assert missing_response.status_code == 404
    assert foreign_response.json()["message"] == missing_response.json()["message"]
    assert foreign_response.json()["message"] == "Booking not found."
    assert (B_ID, USER_B) in [c.args for c in get_owned.call_args_list]
    assert ("missing-id", USER_A) in [c.args for c in get_owned.call_args_list]
    assert session_store["session"].commits == 0


def test_list_user_bookings_scoped_to_token_user(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    newer = make_booking(created_at=NOW)
    older = make_booking(booking_id=B_ID2, created_at=datetime(2026, 8, 10, 9, 0, 0, tzinfo=timezone.utc))
    list_for_user = AsyncMock(return_value=[newer, older])
    monkeypatch.setattr(MechanicBookingRepository, "list_for_user", list_for_user)

    response = client.get(f"{BASE}/bookings", headers=_auth())

    assert response.status_code == 200
    body = response.json()
    assert [b["id"] for b in body] == [B_ID, B_ID2]
    list_for_user.assert_awaited_once_with(USER_A)
    assert session_store["session"].commits == 0


def test_list_user_bookings_requires_auth(client, session_store, monkeypatch) -> None:
    monkeypatch.setattr(MechanicBookingRepository, "list_for_user", AsyncMock())
    response = client.get(f"{BASE}/bookings")
    assert response.status_code == 401


# ============================================================================
# Booking lifecycle (cancel / complete / events)
# ============================================================================


def _do_cancel(booking: MechanicBooking) -> MechanicBooking:
    booking.status = BookingStatus.CANCELLED.value
    return booking


def _do_complete(booking: MechanicBooking) -> MechanicBooking:
    booking.status = BookingStatus.COMPLETED.value
    return booking


def test_cancel_booking_transition_and_commit(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    booking = make_booking()
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=booking))
    cancel = AsyncMock(side_effect=_do_cancel)
    monkeypatch.setattr(MechanicBookingRepository, "cancel", cancel)
    append = AsyncMock(return_value=make_event(status="cancelled"))
    monkeypatch.setattr(BookingEventRepository, "append", append)

    response = client.post(f"{BASE}/bookings/{B_ID}/cancel", headers=_auth())

    assert response.status_code == 200
    assert response.json()["status"] == BookingStatus.CANCELLED.value
    cancel.assert_awaited_once_with(booking)
    append.assert_awaited_once_with(booking_id=B_ID, status=BookingStatus.CANCELLED.value)
    assert session_store["session"].commits == 1
    assert session_store["session"].rollbacks == 0


def test_cancel_booking_foreign_user_404_no_mutation(
    client, session_store, monkeypatch
) -> None:
    session_store["users"][USER_B] = make_user(id=USER_B)
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=None))
    cancel = AsyncMock()
    monkeypatch.setattr(MechanicBookingRepository, "cancel", cancel)
    append = AsyncMock()
    monkeypatch.setattr(BookingEventRepository, "append", append)

    response = client.post(
        f"{BASE}/bookings/{B_ID}/cancel",
        headers={"Authorization": f"Bearer {_access_token(USER_B)}"},
    )

    assert response.status_code == 404
    cancel.assert_not_awaited()
    append.assert_not_awaited()
    assert session_store["session"].rollbacks == 1


def test_complete_booking_transition_and_commit(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    booking = make_booking()
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=booking))
    complete = AsyncMock(side_effect=_do_complete)
    monkeypatch.setattr(MechanicBookingRepository, "complete", complete)
    append = AsyncMock(return_value=make_event(status="completed"))
    monkeypatch.setattr(BookingEventRepository, "append", append)

    response = client.post(f"{BASE}/bookings/{B_ID}/complete", headers=_auth())

    assert response.status_code == 200
    assert response.json()["status"] == BookingStatus.COMPLETED.value
    complete.assert_awaited_once_with(booking)
    append.assert_awaited_once_with(booking_id=B_ID, status=BookingStatus.COMPLETED.value)
    assert session_store["session"].commits == 1
    assert session_store["session"].rollbacks == 0


def test_complete_booking_cancelled_rejected_400(client, session_store, monkeypatch) -> None:
    """Illegal transition (terminal state) is rejected, not silently applied."""
    session_store["users"][USER_A] = make_user()
    booking = make_booking(status=BookingStatus.CANCELLED.value)
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=booking))
    complete = AsyncMock()
    monkeypatch.setattr(MechanicBookingRepository, "complete", complete)
    append = AsyncMock()
    monkeypatch.setattr(BookingEventRepository, "append", append)

    response = client.post(f"{BASE}/bookings/{B_ID}/complete", headers=_auth())

    assert response.status_code == 400
    assert response.json()["error_code"] == "BAD_REQUEST"
    assert "already finished" in response.json()["message"]
    complete.assert_not_awaited()
    append.assert_not_awaited()
    assert session_store["session"].rollbacks == 1


def test_list_booking_events_owner_200(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=make_booking()))
    list_for_booking = AsyncMock(return_value=[make_event()])
    monkeypatch.setattr(BookingEventRepository, "list_for_booking", list_for_booking)

    response = client.get(f"{BASE}/bookings/{B_ID}/events", headers=_auth())

    assert response.status_code == 200
    body = response.json()
    assert body[0]["booking_id"] == B_ID
    assert body[0]["status"] == BookingStatus.REQUESTED.value
    list_for_booking.assert_awaited_once_with(B_ID)
    assert session_store["session"].commits == 0


def test_list_booking_events_foreign_user_404(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_B] = make_user(id=USER_B)
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=None))
    list_for_booking = AsyncMock()
    monkeypatch.setattr(BookingEventRepository, "list_for_booking", list_for_booking)

    response = client.get(
        f"{BASE}/bookings/{B_ID}/events",
        headers={"Authorization": f"Bearer {_access_token(USER_B)}"},
    )

    assert response.status_code == 404
    list_for_booking.assert_not_awaited()
    assert session_store["session"].commits == 0


# ============================================================================
# Ratings (owner + completed + unrated eligibility)
# ============================================================================


def test_create_rating_on_completed_booking_201(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    monkeypatch.setattr(
        MechanicBookingRepository,
        "get_owned",
        AsyncMock(return_value=make_booking(status=BookingStatus.COMPLETED.value)),
    )
    monkeypatch.setattr(RatingRepository, "get_by_booking_id", AsyncMock(return_value=None))
    create_rating = AsyncMock(return_value=make_rating())
    monkeypatch.setattr(RatingRepository, "create_rating", create_rating)

    response = client.post(
        f"{BASE}/bookings/{B_ID}/rating",
        headers=_auth(),
        json={"rating": 4.5, "review": "Good"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["booking_id"] == B_ID
    assert float(body["rating"]) == 4.5
    assert body["review"] == "Good"
    create_rating.assert_awaited_once_with(
        booking_id=B_ID, rating=Decimal("4.50"), review="Good"
    )
    assert session_store["session"].commits == 1
    assert session_store["session"].rollbacks == 0


def test_create_rating_non_completed_booking_400(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    monkeypatch.setattr(
        MechanicBookingRepository,
        "get_owned",
        AsyncMock(return_value=make_booking(status=BookingStatus.REQUESTED.value)),
    )
    create_rating = AsyncMock()
    monkeypatch.setattr(RatingRepository, "create_rating", create_rating)

    response = client.post(
        f"{BASE}/bookings/{B_ID}/rating",
        headers=_auth(),
        json={"rating": 4.5},
    )

    assert response.status_code == 400
    assert response.json()["error_code"] == "BAD_REQUEST"
    create_rating.assert_not_awaited()
    assert session_store["session"].rollbacks == 1


def test_create_rating_already_rated_400(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    monkeypatch.setattr(
        MechanicBookingRepository,
        "get_owned",
        AsyncMock(return_value=make_booking(status=BookingStatus.COMPLETED.value)),
    )
    monkeypatch.setattr(RatingRepository, "get_by_booking_id", AsyncMock(return_value=make_rating()))
    create_rating = AsyncMock()
    monkeypatch.setattr(RatingRepository, "create_rating", create_rating)

    response = client.post(
        f"{BASE}/bookings/{B_ID}/rating",
        headers=_auth(),
        json={"rating": 4.5},
    )

    assert response.status_code == 400
    assert "already been rated" in response.json()["message"]
    create_rating.assert_not_awaited()
    assert session_store["session"].rollbacks == 1


def test_create_rating_foreign_user_404(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_B] = make_user(id=USER_B)
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=None))
    create_rating = AsyncMock()
    monkeypatch.setattr(RatingRepository, "create_rating", create_rating)

    response = client.post(
        f"{BASE}/bookings/{B_ID}/rating",
        headers={"Authorization": f"Bearer {_access_token(USER_B)}"},
        json={"rating": 4.5},
    )

    assert response.status_code == 404
    create_rating.assert_not_awaited()
    assert session_store["session"].rollbacks == 1


def test_get_rating_owned_200_or_null(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_A] = make_user()
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=make_booking()))

    rated = AsyncMock(return_value=make_rating())
    monkeypatch.setattr(RatingRepository, "get_by_booking_id", rated)
    rated_response = client.get(f"{BASE}/bookings/{B_ID}/rating", headers=_auth())
    assert rated_response.status_code == 200
    assert rated_response.json()["booking_id"] == B_ID

    unrated = AsyncMock(return_value=None)
    monkeypatch.setattr(RatingRepository, "get_by_booking_id", unrated)
    null_response = client.get(f"{BASE}/bookings/{B_ID}/rating", headers=_auth())
    assert null_response.status_code == 200
    assert null_response.json() is None
    assert session_store["session"].commits == 0


def test_get_rating_foreign_user_404(client, session_store, monkeypatch) -> None:
    session_store["users"][USER_B] = make_user(id=USER_B)
    monkeypatch.setattr(MechanicBookingRepository, "get_owned", AsyncMock(return_value=None))
    get_by_booking_id = AsyncMock()
    monkeypatch.setattr(RatingRepository, "get_by_booking_id", get_by_booking_id)

    response = client.get(
        f"{BASE}/bookings/{B_ID}/rating",
        headers={"Authorization": f"Bearer {_access_token(USER_B)}"},
    )

    assert response.status_code == 404
    get_by_booking_id.assert_not_awaited()
    assert session_store["session"].commits == 0


def test_create_rating_client_booking_id_rejected(client, session_store, monkeypatch) -> None:
    """booking_id is not a RatingCreate field; mass assignment is a 422."""
    session_store["users"][USER_A] = make_user()
    create_rating = AsyncMock()
    monkeypatch.setattr(RatingRepository, "create_rating", create_rating)

    response = client.post(
        f"{BASE}/bookings/{B_ID}/rating",
        headers=_auth(),
        json={"rating": 4.5, "booking_id": "99999999-9999-9999-9999-999999999999"},
    )

    assert response.status_code == 422
    create_rating.assert_not_awaited()
    assert session_store["session"].commits == 0


# ============================================================================
# Auth required (401 without token) across all protected routes
# ============================================================================

PROTECTED_ROUTES = [
    ("GET", f"{BASE}/bookings", None),
    ("POST", f"{BASE}/bookings", {"mechanic_id": "m1"}),
    ("GET", f"{BASE}/bookings/{B_ID}", None),
    ("POST", f"{BASE}/bookings/{B_ID}/cancel", None),
    ("POST", f"{BASE}/bookings/{B_ID}/complete", None),
    ("GET", f"{BASE}/bookings/{B_ID}/events", None),
    ("POST", f"{BASE}/bookings/{B_ID}/rating", {"rating": 4.5}),
    ("GET", f"{BASE}/bookings/{B_ID}/rating", None),
]


@pytest.mark.parametrize("method,path,body", PROTECTED_ROUTES)
def test_all_protected_routes_require_auth(client, method, path, body) -> None:
    response = client.request(method, path, json=body)
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


# ============================================================================
# Sanitized 500 (raw repository failure never leaks through the real service)
# ============================================================================


def test_repository_failure_returns_sanitized_500_and_rolls_back(
    client, session_store, monkeypatch
) -> None:
    session_store["users"][USER_A] = make_user()
    monkeypatch.setattr(MechanicRepository, "get_by_id", AsyncMock(return_value=make_mechanic()))
    monkeypatch.setattr(
        MechanicServiceRepository, "get_by_id", AsyncMock(return_value=make_service())
    )
    monkeypatch.setattr(
        MechanicBookingRepository,
        "create_booking",
        AsyncMock(side_effect=RuntimeError("db down")),
    )
    monkeypatch.setattr(BookingEventRepository, "append", AsyncMock())

    response = client.post(f"{BASE}/bookings", headers=_auth(), json=_create_body())

    assert response.status_code == 500
    body = response.json()
    assert body["error_code"] == "INTERNAL_SERVER_ERROR"
    assert "unexpected error" in body["message"]
    assert "db down" not in response.text
    assert session_store["session"].commits == 0
    assert session_store["session"].rollbacks == 1


# ============================================================================
# OpenAPI contract (recon §18 path-count + security)
# ============================================================================


def test_openapi_path_count_and_presence(client) -> None:
    """The FULL app (main) exposes 28 paths; the mechanic subset is present.

    The isolated test app mounts only the mechanic router (13 paths); the
    real path-count expectation of the running app is verified against
    ``app.main`` (recon §18: baseline 15 -> 28).
    """
    from app.main import app as main_app

    main_paths = main_app.openapi()["paths"]
    assert len(main_paths) == 28

    paths = client.app.openapi()["paths"]
    assert len(paths) == 13
    for expected in (
        f"{BASE}/mechanics",
        f"{BASE}/mechanics/featured",
        f"{BASE}/mechanics/{{mechanic_id}}",
        f"{BASE}/mechanics/{{mechanic_id}}/services",
        f"{BASE}/mechanics/{{mechanic_id}}/reviews",
        f"{BASE}/services",
        f"{BASE}/categories",
        f"{BASE}/bookings",
        f"{BASE}/bookings/{{booking_id}}",
        f"{BASE}/bookings/{{booking_id}}/cancel",
        f"{BASE}/bookings/{{booking_id}}/complete",
        f"{BASE}/bookings/{{booking_id}}/events",
        f"{BASE}/bookings/{{booking_id}}/rating",
    ):
        assert expected in paths
        assert expected in main_paths


def test_openapi_security_declarations(client) -> None:
    spec = client.app.openapi()
    paths = spec["paths"]
    protected_ops = [
        ("bookings", "get"),
        ("bookings", "post"),
        ("bookings/{booking_id}", "get"),
        ("bookings/{booking_id}/cancel", "post"),
        ("bookings/{booking_id}/complete", "post"),
        ("bookings/{booking_id}/events", "get"),
        ("bookings/{booking_id}/rating", "post"),
        ("bookings/{booking_id}/rating", "get"),
    ]
    for path_suffix, method in protected_ops:
        op = paths[f"{BASE}/{path_suffix}"][method]
        assert op["security"] == [{"HTTPBearer": []}], path_suffix

    public_ops = [
        ("mechanics", "get"),
        ("mechanics/featured", "get"),
        ("mechanics/{mechanic_id}", "get"),
        ("mechanics/{mechanic_id}/services", "get"),
        ("mechanics/{mechanic_id}/reviews", "get"),
        ("services", "get"),
        ("categories", "get"),
    ]
    for path_suffix, method in public_ops:
        op = paths[f"{BASE}/{path_suffix}"][method]
        assert "security" not in op, path_suffix