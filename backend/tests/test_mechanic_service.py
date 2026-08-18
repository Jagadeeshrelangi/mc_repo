"""Tests for Task 6, Stage 4 — MechanicService.

Test strategy (mirrors the existing service-layer tests — fake session +
constructor-injected fake repositories, NO live PostgreSQL):

- A ``FakeSession`` records ``commit()``/``rollback()`` calls so the service's
  single-commit-per-write and rollback-on-error boundaries are asserted
  directly.
- Repositories are ``unittest.mock.AsyncMock`` fakes injected via the service
  constructor, so the tests verify the service's actual orchestration:
  correct repository method calls, the exact arguments passed (esp. that
  ``user_id`` ALWAYS comes from the authenticated identity, never a client
  value), state changes, return projections, controlled exceptions, and that
  mutations are never attempted for foreign/missing bookings.
- No raw SQLAlchemy exceptions leak: FK pre-checks produce controlled
  ``EntityNotFoundException``/``InvalidInputException``; a repository failure
  rolls back and re-raises.
- PostgreSQL server-side behavior (real constraint enforcement, UUID
  generation, JSONB) is NOT faked and stays documented as requiring a live
  database.

No commits, pushes, resets, or reverts are performed.
"""

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict
from unittest.mock import AsyncMock

import pytest

from app.core.exceptions import EntityNotFoundException, InvalidInputException
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
from app.schemas.mechanic import (
    BookingCreate,
    BookingEventOut,
    BookingOut,
    MechanicCategoryOut,
    MechanicOut,
    MechanicReviewOut,
    MechanicServiceOut,
    RatingOut,
)
from app.services.mechanic_service import TERMINAL_STATUSES, MechanicService

USER_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
USER_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
B_ID = "11111111-1111-1111-1111-111111111111"
B_ID2 = "22222222-2222-2222-2222-222222222222"
V_ID = "33333333-3333-3333-3333-333333333333"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)


class FakeSession:
    """Records commit/rollback calls so transaction boundaries are asserted."""

    def __init__(self) -> None:
        self.commits = 0
        self.rollbacks = 0

    async def commit(self) -> None:
        self.commits += 1

    async def rollback(self) -> None:
        self.rollbacks += 1

    async def flush(self) -> None:
        pass


def make_mechanic(mid: str = "m1", **overrides: Any) -> Mechanic:
    """Build a catalog ``Mechanic`` with its child collections attached."""
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


def make_service_instance(**repos: Any) -> tuple:
    """Build a service with a FakeSession + given AsyncMock repositories.

    Returns ``(service, session)``. Every repository defaults to a fresh
    ``AsyncMock`` so omitted repos are never accidentally real.
    """
    session = FakeSession()
    kwargs: Dict[str, Any] = {
        "mechanic_repository": AsyncMock(),
        "service_repository": AsyncMock(),
        "category_repository": AsyncMock(),
        "review_repository": AsyncMock(),
        "booking_repository": AsyncMock(),
        "event_repository": AsyncMock(),
        "rating_repository": AsyncMock(),
    }
    kwargs.update(repos)
    return MechanicService(session, **kwargs), session


def booking_create_payload(**overrides: Any) -> BookingCreate:
    payload: Dict[str, Any] = {
        "mechanic_id": "m1",
        "service_id": "svc_1",
        "vehicle_id": V_ID,
        "address": "12 MG Road",
        "lat": "12.971599",
        "lng": "77.594566",
        "scheduled_at": "2026-08-16T10:00:00Z",
    }
    payload.update(overrides)
    return BookingCreate.model_validate(payload)


# ---------------------------------------------------------------------------
# Catalog reads
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_mechanics_returns_serialized_mechanic_out() -> None:
    svc, _ = make_service_instance(
        mechanic_repository=AsyncMock(
            list_all=AsyncMock(return_value=[make_mechanic("m1"), make_mechanic("m2")])
        )
    )
    result = await svc.list_mechanics()
    assert isinstance(result, list) and len(result) == 2
    assert all(isinstance(m, MechanicOut) for m in result)
    assert result[0].id == "m1"
    assert result[0].skills == ["Engine"]
    assert result[0].services[0].price == Decimal("499.00")
    svc.mechanic_repo.list_all.assert_awaited_once()


@pytest.mark.asyncio
async def test_list_featured_mechanics_uses_featured_repository() -> None:
    svc, _ = make_service_instance(
        mechanic_repository=AsyncMock(list_featured=AsyncMock(return_value=[make_mechanic("m1")]))
    )
    result = await svc.list_featured_mechanics()
    svc.mechanic_repo.list_featured.assert_awaited_once()
    assert len(result) == 1
    assert result[0].id == "m1"


@pytest.mark.asyncio
async def test_get_mechanic_returns_mechanic_out() -> None:
    svc, _ = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_mechanic("m1")))
    )
    result = await svc.get_mechanic("m1")
    assert isinstance(result, MechanicOut)
    assert result.id == "m1"
    svc.mechanic_repo.get_by_id.assert_awaited_once_with("m1")


@pytest.mark.asyncio
async def test_get_mechanic_not_found_raises_controlled_404() -> None:
    svc, _ = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=None))
    )
    with pytest.raises(EntityNotFoundException) as exc:
        await svc.get_mechanic("missing")
    assert exc.value.code == "NOT_FOUND"


@pytest.mark.asyncio
async def test_list_services_returns_mechanic_service_out() -> None:
    svc, _ = make_service_instance(
        service_repository=AsyncMock(list_all=AsyncMock(return_value=[make_service()]))
    )
    result = await svc.list_services()
    assert len(result) == 1
    assert isinstance(result[0], MechanicServiceOut)
    assert result[0].id == "svc_1"
    svc.service_repo.list_all.assert_awaited_once()


@pytest.mark.asyncio
async def test_list_mechanic_services_scoped_to_mechanic() -> None:
    svc, _ = make_service_instance(
        service_repository=AsyncMock(
            list_for_mechanic=AsyncMock(return_value=[make_service()])
        )
    )
    result = await svc.list_mechanic_services("m1")
    svc.service_repo.list_for_mechanic.assert_awaited_once_with("m1")
    assert len(result) == 1
    assert result[0].name == "Engine Repair"


@pytest.mark.asyncio
async def test_list_categories_returns_mechanic_category_out() -> None:
    svc, _ = make_service_instance(
        category_repository=AsyncMock(list_all=AsyncMock(return_value=[make_category()]))
    )
    result = await svc.list_categories()
    assert len(result) == 1
    assert isinstance(result[0], MechanicCategoryOut)
    assert result[0].name == "Engine"


@pytest.mark.asyncio
async def test_list_mechanic_reviews_scoped_to_mechanic() -> None:
    svc, _ = make_service_instance(
        review_repository=AsyncMock(
            list_for_mechanic=AsyncMock(return_value=[make_review()])
        )
    )
    result = await svc.list_mechanic_reviews("m1")
    svc.review_repo.list_for_mechanic.assert_awaited_once_with("m1")
    assert len(result) == 1
    assert isinstance(result[0], MechanicReviewOut)
    assert result[0].rating == Decimal("4.50")


# ---------------------------------------------------------------------------
# Booking reads (ownership)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_booking_returns_owned_booking() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=make_booking()))
    )
    result = await svc.get_booking(B_ID, USER_A)
    svc.booking_repo.get_owned.assert_awaited_once_with(B_ID, USER_A)
    assert isinstance(result, BookingOut)
    assert result.status == BookingStatus.REQUESTED
    assert str(result.id) == B_ID


@pytest.mark.asyncio
async def test_get_booking_foreign_or_missing_raises_generic_404() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=None))
    )
    for user in (USER_A, USER_B):
        with pytest.raises(EntityNotFoundException) as exc:
            await svc.get_booking(B_ID, user)
        assert exc.value.code == "NOT_FOUND"
        assert "Booking not found." in exc.value.message


@pytest.mark.asyncio
async def test_list_user_bookings_scoped_to_user() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(
            list_for_user=AsyncMock(return_value=[make_booking()])
        )
    )
    result = await svc.list_user_bookings(USER_A)
    svc.booking_repo.list_for_user.assert_awaited_once_with(USER_A)
    assert len(result) == 1
    assert isinstance(result[0], BookingOut)


@pytest.mark.asyncio
async def test_list_booking_events_owner_guarded() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=make_booking())),
        event_repository=AsyncMock(
            list_for_booking=AsyncMock(return_value=[make_event()])
        ),
    )
    result = await svc.list_booking_events(B_ID, USER_A)
    svc.booking_repo.get_owned.assert_awaited_once_with(B_ID, USER_A)
    svc.event_repo.list_for_booking.assert_awaited_once_with(B_ID)
    assert len(result) == 1
    assert isinstance(result[0], BookingEventOut)
    assert result[0].status == BookingStatus.REQUESTED


@pytest.mark.asyncio
async def test_list_booking_events_foreign_user_404_no_leak() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=None))
    )
    with pytest.raises(EntityNotFoundException):
        await svc.list_booking_events(B_ID, USER_B)
    svc.event_repo.list_for_booking.assert_not_awaited()


# ---------------------------------------------------------------------------
# Booking creation (authenticated identity + canonical status)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_booking_binds_authenticated_user_and_requests_status() -> None:
    """user_id comes from the service argument (authenticated identity), never
    a client-supplied value; status is the canonical 'requested'."""
    booking = make_booking(user_id=USER_A)
    svc, session = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_mechanic())),
        service_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_service())),
        booking_repository=AsyncMock(create_booking=AsyncMock(return_value=booking)),
        event_repository=AsyncMock(append=AsyncMock(return_value=make_event())),
    )
    payload = booking_create_payload()
    result = await svc.create_booking(payload, USER_A)

    svc.booking_repo.create_booking.assert_awaited_once_with(
        user_id=USER_A,
        mechanic_id="m1",
        service_id="svc_1",
        vehicle_id=V_ID,
        status=BookingStatus.REQUESTED.value,
        address="12 MG Road",
        lat=Decimal("12.971599"),
        lng=Decimal("77.594566"),
        scheduled_at=payload.scheduled_at,
    )
    svc.event_repo.append.assert_awaited_once_with(
        booking_id=booking.id, status=BookingStatus.REQUESTED.value
    )
    assert isinstance(result, BookingOut)
    assert result.status == BookingStatus.REQUESTED
    assert session.commits == 1
    assert session.rollbacks == 0


@pytest.mark.asyncio
async def test_create_booking_null_vehicle_and_custom_service_passed_through() -> None:
    """Custom-issue booking (service_id None, vehicle_id None) maps to None."""
    booking = make_booking(user_id=USER_A)
    svc, session = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_mechanic())),
        booking_repository=AsyncMock(create_booking=AsyncMock(return_value=booking)),
        event_repository=AsyncMock(append=AsyncMock(return_value=make_event())),
    )
    payload = booking_create_payload(service_id=None, vehicle_id=None)
    await svc.create_booking(payload, USER_A)
    call_kwargs = svc.booking_repo.create_booking.await_args.kwargs
    assert call_kwargs["service_id"] is None
    assert call_kwargs["vehicle_id"] is None
    assert call_kwargs["user_id"] == USER_A
    assert session.commits == 1


@pytest.mark.asyncio
async def test_create_booking_unknown_mechanic_raises_404_and_rolls_back() -> None:
    """FK pre-check: an unknown mechanic is a controlled 404, never a raw DB
    IntegrityError; nothing is written."""
    svc, session = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=None)),
        booking_repository=AsyncMock(create_booking=AsyncMock()),
        event_repository=AsyncMock(append=AsyncMock()),
    )
    with pytest.raises(EntityNotFoundException) as exc:
        await svc.create_booking(booking_create_payload(), USER_A)
    assert exc.value.code == "NOT_FOUND"
    svc.booking_repo.create_booking.assert_not_awaited()
    svc.event_repo.append.assert_not_awaited()
    assert session.commits == 0
    assert session.rollbacks == 1


@pytest.mark.asyncio
async def test_create_booking_unknown_service_raises_404_and_rolls_back() -> None:
    svc, session = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_mechanic())),
        service_repository=AsyncMock(get_by_id=AsyncMock(return_value=None)),
        booking_repository=AsyncMock(create_booking=AsyncMock()),
        event_repository=AsyncMock(append=AsyncMock()),
    )
    with pytest.raises(EntityNotFoundException):
        await svc.create_booking(booking_create_payload(), USER_A)
    svc.booking_repo.create_booking.assert_not_awaited()
    assert session.commits == 0
    assert session.rollbacks == 1


# ---------------------------------------------------------------------------
# Booking cancellation
# ---------------------------------------------------------------------------


async def _do_cancel(booking: MechanicBooking) -> MechanicBooking:
    booking.status = BookingStatus.CANCELLED.value
    return booking


@pytest.mark.asyncio
async def test_cancel_booking_transitions_to_cancelled_and_commits_once() -> None:
    booking = make_booking()
    svc, session = make_service_instance(
        booking_repository=AsyncMock(
            get_owned=AsyncMock(return_value=booking),
            cancel=AsyncMock(side_effect=_do_cancel),
        ),
        event_repository=AsyncMock(
            append=AsyncMock(return_value=make_event(status="cancelled"))
        ),
    )
    result = await svc.cancel_booking(B_ID, USER_A)
    svc.booking_repo.get_owned.assert_awaited_once_with(B_ID, USER_A)
    svc.booking_repo.cancel.assert_awaited_once_with(booking)
    svc.event_repo.append.assert_awaited_once_with(
        booking_id=B_ID, status=BookingStatus.CANCELLED.value
    )
    assert result.status == BookingStatus.CANCELLED
    assert session.commits == 1
    assert session.rollbacks == 0


@pytest.mark.asyncio
async def test_cancel_booking_foreign_user_404_no_mutation() -> None:
    svc, session = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=None)),
        event_repository=AsyncMock(append=AsyncMock()),
    )
    with pytest.raises(EntityNotFoundException):
        await svc.cancel_booking(B_ID, USER_B)
    svc.booking_repo.cancel.assert_not_awaited()
    svc.event_repo.append.assert_not_awaited()
    assert session.commits == 0
    assert session.rollbacks == 1


@pytest.mark.asyncio
async def test_cancel_booking_terminal_states_rejected() -> None:
    for status in (BookingStatus.CANCELLED.value, BookingStatus.COMPLETED.value):
        svc, session = make_service_instance(
            booking_repository=AsyncMock(
                get_owned=AsyncMock(return_value=make_booking(status=status))
            ),
            event_repository=AsyncMock(append=AsyncMock()),
        )
        with pytest.raises(InvalidInputException) as exc:
            await svc.cancel_booking(B_ID, USER_A)
        assert exc.value.code == "BAD_REQUEST"
        svc.booking_repo.cancel.assert_not_awaited()
        assert session.rollbacks == 1


# ---------------------------------------------------------------------------
# Booking completion
# ---------------------------------------------------------------------------


async def _do_complete(booking: MechanicBooking) -> MechanicBooking:
    booking.status = BookingStatus.COMPLETED.value
    return booking


@pytest.mark.asyncio
async def test_complete_booking_transitions_to_completed_and_commits_once() -> None:
    booking = make_booking()
    svc, session = make_service_instance(
        booking_repository=AsyncMock(
            get_owned=AsyncMock(return_value=booking),
            complete=AsyncMock(side_effect=_do_complete),
        ),
        event_repository=AsyncMock(
            append=AsyncMock(return_value=make_event(status="completed"))
        ),
    )
    result = await svc.complete_booking(B_ID, USER_A)
    svc.booking_repo.get_owned.assert_awaited_once_with(B_ID, USER_A)
    svc.booking_repo.complete.assert_awaited_once_with(booking)
    svc.event_repo.append.assert_awaited_once_with(
        booking_id=B_ID, status=BookingStatus.COMPLETED.value
    )
    assert result.status == BookingStatus.COMPLETED
    assert session.commits == 1
    assert session.rollbacks == 0


@pytest.mark.asyncio
async def test_complete_booking_cancelled_rejected() -> None:
    svc, session = make_service_instance(
        booking_repository=AsyncMock(
            get_owned=AsyncMock(return_value=make_booking(status=BookingStatus.CANCELLED.value))
        ),
        event_repository=AsyncMock(append=AsyncMock()),
    )
    with pytest.raises(InvalidInputException):
        await svc.complete_booking(B_ID, USER_A)
    svc.booking_repo.complete.assert_not_awaited()
    assert session.rollbacks == 1


@pytest.mark.asyncio
async def test_complete_booking_foreign_user_404_no_mutation() -> None:
    svc, session = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=None)),
        event_repository=AsyncMock(append=AsyncMock()),
    )
    with pytest.raises(EntityNotFoundException):
        await svc.complete_booking(B_ID, USER_B)
    svc.booking_repo.complete.assert_not_awaited()
    assert session.commits == 0


# ---------------------------------------------------------------------------
# Ratings (owner + completed + unrated eligibility)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_rating_success_commits_once() -> None:
    rating = make_rating()
    svc, session = make_service_instance(
        booking_repository=AsyncMock(
            get_owned=AsyncMock(
                return_value=make_booking(status=BookingStatus.COMPLETED.value)
            )
        ),
        rating_repository=AsyncMock(
            get_by_booking_id=AsyncMock(return_value=None),
            create_rating=AsyncMock(return_value=rating),
        ),
    )
    from app.schemas.mechanic import RatingCreate

    result = await svc.create_rating(B_ID, USER_A, RatingCreate(rating="4.50", review="Good"))
    svc.booking_repo.get_owned.assert_awaited_once_with(B_ID, USER_A)
    svc.rating_repo.get_by_booking_id.assert_awaited_once_with(B_ID)
    svc.rating_repo.create_rating.assert_awaited_once_with(
        booking_id=B_ID, rating=Decimal("4.50"), review="Good"
    )
    assert isinstance(result, RatingOut)
    assert result.rating == Decimal("4.50")
    assert session.commits == 1
    assert session.rollbacks == 0


@pytest.mark.asyncio
async def test_create_rating_requires_completed_booking() -> None:
    svc, session = make_service_instance(
        booking_repository=AsyncMock(
            get_owned=AsyncMock(
                return_value=make_booking(status=BookingStatus.REQUESTED.value)
            )
        ),
        rating_repository=AsyncMock(create_rating=AsyncMock()),
    )
    from app.schemas.mechanic import RatingCreate

    with pytest.raises(InvalidInputException) as exc:
        await svc.create_rating(B_ID, USER_A, RatingCreate(rating="4.50"))
    assert exc.value.code == "BAD_REQUEST"
    svc.rating_repo.create_rating.assert_not_awaited()
    assert session.rollbacks == 1


@pytest.mark.asyncio
async def test_create_rating_already_rated_rejected() -> None:
    svc, session = make_service_instance(
        booking_repository=AsyncMock(
            get_owned=AsyncMock(
                return_value=make_booking(status=BookingStatus.COMPLETED.value)
            )
        ),
        rating_repository=AsyncMock(
            get_by_booking_id=AsyncMock(return_value=make_rating()),
            create_rating=AsyncMock(),
        ),
    )
    from app.schemas.mechanic import RatingCreate

    with pytest.raises(InvalidInputException):
        await svc.create_rating(B_ID, USER_A, RatingCreate(rating="4.50"))
    svc.rating_repo.create_rating.assert_not_awaited()
    assert session.rollbacks == 1


@pytest.mark.asyncio
async def test_create_rating_foreign_user_404() -> None:
    svc, session = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=None)),
        rating_repository=AsyncMock(create_rating=AsyncMock()),
    )
    from app.schemas.mechanic import RatingCreate

    with pytest.raises(EntityNotFoundException):
        await svc.create_rating(B_ID, USER_B, RatingCreate(rating="4.50"))
    svc.rating_repo.create_rating.assert_not_awaited()
    assert session.rollbacks == 1


@pytest.mark.asyncio
async def test_get_rating_returns_owned_rating_or_none() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=make_booking())),
        rating_repository=AsyncMock(get_by_booking_id=AsyncMock(return_value=make_rating())),
    )
    result = await svc.get_rating(B_ID, USER_A)
    assert isinstance(result, RatingOut)
    assert str(result.booking_id) == B_ID

    svc2, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=make_booking())),
        rating_repository=AsyncMock(get_by_booking_id=AsyncMock(return_value=None)),
    )
    assert await svc2.get_rating(B_ID, USER_A) is None


@pytest.mark.asyncio
async def test_get_rating_foreign_user_404() -> None:
    svc, _ = make_service_instance(
        booking_repository=AsyncMock(get_owned=AsyncMock(return_value=None)),
        rating_repository=AsyncMock(get_by_booking_id=AsyncMock()),
    )
    with pytest.raises(EntityNotFoundException):
        await svc.get_rating(B_ID, USER_B)
    svc.rating_repo.get_by_booking_id.assert_not_awaited()


# ---------------------------------------------------------------------------
# Transactions / exceptions / DI
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_read_operations_never_commit() -> None:
    svc, session = make_service_instance(
        mechanic_repository=AsyncMock(list_all=AsyncMock(return_value=[])),
        service_repository=AsyncMock(list_all=AsyncMock(return_value=[])),
        category_repository=AsyncMock(list_all=AsyncMock(return_value=[])),
        review_repository=AsyncMock(list_for_mechanic=AsyncMock(return_value=[])),
        booking_repository=AsyncMock(list_for_user=AsyncMock(return_value=[])),
    )
    await svc.list_mechanics()
    await svc.list_services()
    await svc.list_categories()
    await svc.list_mechanic_reviews("m1")
    await svc.list_user_bookings(USER_A)
    assert session.commits == 0
    assert session.rollbacks == 0


@pytest.mark.asyncio
async def test_repository_failure_rolls_back_and_rereaises() -> None:
    """A repository raising (e.g. a DB error) never leaks silently: the
    service rolls back the transaction and re-raises the same exception."""
    svc, session = make_service_instance(
        mechanic_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_mechanic())),
        service_repository=AsyncMock(get_by_id=AsyncMock(return_value=make_service())),
        booking_repository=AsyncMock(create_booking=AsyncMock(side_effect=Exception("db down"))),
        event_repository=AsyncMock(append=AsyncMock()),
    )
    with pytest.raises(Exception, match="db down"):
        await svc.create_booking(booking_create_payload(), USER_A)
    assert session.rollbacks == 1
    assert session.commits == 0


@pytest.mark.asyncio
async def test_constructor_injects_repositories() -> None:
    svc, session = make_service_instance()
    assert svc.session is session
    assert isinstance(svc.mechanic_repo, AsyncMock)
    assert isinstance(svc.booking_repo, AsyncMock)
    assert isinstance(svc.event_repo, AsyncMock)
    assert isinstance(svc.rating_repo, AsyncMock)


@pytest.mark.asyncio
async def test_default_constructor_uses_real_repositories() -> None:
    from app.repositories.mechanics import (
        BookingEventRepository,
        MechanicBookingRepository,
        MechanicCategoryRepository,
        MechanicRepository,
        MechanicReviewRepository,
        MechanicServiceRepository,
        RatingRepository,
    )

    svc = MechanicService(FakeSession())
    assert isinstance(svc.mechanic_repo, MechanicRepository)
    assert isinstance(svc.service_repo, MechanicServiceRepository)
    assert isinstance(svc.category_repo, MechanicCategoryRepository)
    assert isinstance(svc.review_repo, MechanicReviewRepository)
    assert isinstance(svc.booking_repo, MechanicBookingRepository)
    assert isinstance(svc.event_repo, BookingEventRepository)
    assert isinstance(svc.rating_repo, RatingRepository)


@pytest.mark.asyncio
async def test_terminal_statuses_contract() -> None:
    assert TERMINAL_STATUSES == frozenset(
        {BookingStatus.CANCELLED.value, BookingStatus.COMPLETED.value}
    )