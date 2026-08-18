"""Contract tests for the Mechanics Pydantic schemas (Task 6, Stage 3).

Pure validation/serialization-contract tests — no database, no repositories, no
services, no JWT. Both accepted and rejected inputs are exercised per schema,
including ORM serialization and security-boundary checks.
"""

from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Optional

import pytest
from pydantic import ValidationError

from app.models.mechanic import Mechanic, MechanicLanguage, MechanicSkill, MechanicWorkingHour
from app.models.mechanic_booking import BookingEvent, MechanicBooking
from app.models.mechanic_category import MechanicCategory
from app.models.mechanic_review import MechanicReview
from app.models.mechanic_service import MechanicService, MechanicServiceOffered
from app.models.mechanic_status import BookingStatus
from app.schemas.mechanic import (
    BookingCreate,
    BookingEventOut,
    BookingOut,
    MechanicCategoryOut,
    MechanicOut,
    MechanicReviewOut,
    MechanicServiceOut,
    MechanicWorkingHourOut,
    RatingCreate,
    RatingOut,
)

B_ID = "11111111-1111-1111-1111-111111111111"
B_ID2 = "22222222-2222-2222-2222-222222222222"
V_ID = "33333333-3333-3333-3333-333333333333"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)


def assert_validation_error(schema, payload) -> None:
    with pytest.raises(ValidationError):
        schema.model_validate(payload)


# --- MechanicServiceOut -----------------------------------------------------


def test_mechanic_service_out_valid() -> None:
    s = MechanicServiceOut.model_validate(
        {"id": "svc_1", "name": "Engine Repair", "price": "499.00", "estimated_minutes": 45}
    )
    assert s.id == "svc_1"
    assert s.name == "Engine Repair"
    assert s.price == Decimal("499.00")
    assert s.estimated_minutes == 45


def test_mechanic_service_out_serializes_money_as_json_number() -> None:
    s = MechanicServiceOut.model_validate({"id": "svc_1", "name": "Repair", "price": Decimal("499.00")})
    assert s.model_dump()["price"] == Decimal("499.00")
    assert "price" in s.model_dump_json()
    assert "499.00" not in s.model_dump_json()
    assert '"price":499.0' in s.model_dump_json() or '"price":499' in s.model_dump_json()


def test_mechanic_service_out_rejects_missing_id() -> None:
    assert_validation_error(MechanicServiceOut, {"name": "Repair"})


def test_mechanic_service_out_rejects_missing_name() -> None:
    assert_validation_error(MechanicServiceOut, {"id": "svc_1"})


def test_mechanic_service_out_rejects_negative_price() -> None:
    assert_validation_error(MechanicServiceOut, {"id": "svc_1", "name": "Repair", "price": "-1.00"})


def test_mechanic_service_out_accepts_optional_fields() -> None:
    s = MechanicServiceOut.model_validate(
        {"id": "svc_1", "name": "Repair", "icon": "wrench", "description": "Full service"}
    )
    assert s.icon == "wrench"
    assert s.price is None
    assert s.description == "Full service"


def test_mechanic_service_out_orm_serialization() -> None:
    svc = MechanicService(id="svc_1", name="Engine Repair", price=Decimal("499.00"), estimated_minutes=45)
    s = MechanicServiceOut.model_validate(svc)
    assert s.id == "svc_1"
    assert s.price == Decimal("499.00")


# --- MechanicCategoryOut ----------------------------------------------------


def test_mechanic_category_out_valid() -> None:
    c = MechanicCategoryOut.model_validate(
        {"id": "cat-1", "name": "Engine", "icon": "engine", "color": "#FF0000", "bg_color": "#FEE"}
    )
    assert c.id == "cat-1"
    assert c.name == "Engine"
    assert c.bg_color == "#FEE"


def test_mechanic_category_out_rejects_missing_name() -> None:
    assert_validation_error(MechanicCategoryOut, {"id": "cat-1"})


def test_mechanic_category_out_orm_serialization() -> None:
    cat = MechanicCategory(id="cat-1", name="Engine", sort_order=1)
    c = MechanicCategoryOut.model_validate(cat)
    assert c.name == "Engine"


# --- MechanicWorkingHourOut -------------------------------------------------


def test_mechanic_working_hour_out_valid() -> None:
    wh = MechanicWorkingHourOut.model_validate({"day": "Mon-Fri", "open": "8:00 AM", "close": "8:00 PM"})
    assert wh.day == "Mon-Fri"
    assert wh.open == "8:00 AM"


def test_mechanic_working_hour_out_rejects_missing_day() -> None:
    assert_validation_error(MechanicWorkingHourOut, {"open": "8:00 AM"})


def test_mechanic_working_hour_out_orm_serialization() -> None:
    wh = MechanicWorkingHour(mechanic_id="m1", day="Sat", open="9:00 AM", close="6:00 PM")
    out = MechanicWorkingHourOut.model_validate(wh)
    assert out.day == "Sat"
    assert out.close == "6:00 PM"


# --- MechanicReviewOut ------------------------------------------------------


def test_mechanic_review_out_valid() -> None:
    r = MechanicReviewOut.model_validate(
        {
            "id": "r1",
            "reviewer_name": "Rahul",
            "rating": "4.50",
            "comment": "Great work",
            "reviewed_at": "2026-08-01",
            "vehicle": "Honda City",
        }
    )
    assert r.id == "r1"
    assert r.rating == Decimal("4.50")
    assert r.reviewed_at == date(2026, 8, 1)


def test_mechanic_review_out_rejects_rating_over_5() -> None:
    assert_validation_error(MechanicReviewOut, {"id": "r1", "rating": "5.01"})


def test_mechanic_review_out_rejects_negative_rating() -> None:
    assert_validation_error(MechanicReviewOut, {"id": "r1", "rating": "-0.01"})


def test_mechanic_review_out_rejects_missing_id() -> None:
    assert_validation_error(MechanicReviewOut, {"reviewer_name": "Rahul"})


def test_mechanic_review_out_orm_serialization() -> None:
    r = MechanicReview(
        id="r1", mechanic_id="m1", reviewer_name="Rahul", rating=Decimal("4.50"),
        comment="Great", reviewed_at=date(2026, 8, 1), vehicle="Honda City",
    )
    out = MechanicReviewOut.model_validate(r)
    assert out.rating == Decimal("4.50")
    assert out.vehicle == "Honda City"


# --- MechanicOut ------------------------------------------------------------


def _mechanic_payload() -> dict:
    return {
        "id": "m1",
        "name": "Raju Auto Works",
        "rating": "4.80",
        "review_count": 120,
        "experience_years": 12,
        "distance_km": "2.50",
        "eta_minutes": 15,
        "is_available": True,
        "price_starting": "299.00",
        "phone": "+919876543210",
        "about": "Certified mechanic",
        "is_verified": True,
        "skills": ["Engine", "Brakes"],
        "languages": ["English", "Hindi"],
        "working_hours": [{"day": "Mon-Fri", "open": "8:00 AM", "close": "8:00 PM"}],
        "services": [
            {"id": "svc_1", "name": "Engine Repair", "price": "499.00", "estimated_minutes": 45}
        ],
    }


def test_mechanic_out_valid() -> None:
    m = MechanicOut.model_validate(_mechanic_payload())
    assert m.id == "m1"
    assert m.rating == Decimal("4.80")
    assert m.skills == ["Engine", "Brakes"]
    assert m.working_hours[0].day == "Mon-Fri"
    assert m.services[0].id == "svc_1"


def test_mechanic_out_rejects_missing_required_fields() -> None:
    for field in ("id", "name", "is_available", "is_verified"):
        payload = {k: v for k, v in _mechanic_payload().items() if k != field}
        assert_validation_error(MechanicOut, payload)


def test_mechanic_out_rejects_rating_over_5() -> None:
    assert_validation_error(MechanicOut, {**_mechanic_payload(), "rating": "5.01"})


def test_mechanic_out_rejects_negative_price_starting() -> None:
    assert_validation_error(MechanicOut, {**_mechanic_payload(), "price_starting": "-1.00"})


def test_mechanic_out_orm_serialization_flattens_children() -> None:
    """ORM -> MechanicOut: skills/languages flattened, junction -> services."""
    mechanic = Mechanic(
        id="m1",
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
    mechanic.skills = [MechanicSkill(mechanic_id="m1", skill="Engine")]
    mechanic.languages = [MechanicLanguage(mechanic_id="m1", language="English")]
    mechanic.working_hours = [
        MechanicWorkingHour(mechanic_id="m1", day="Mon-Fri", open="8:00 AM", close="8:00 PM")
    ]
    svc = MechanicService(id="svc_1", name="Engine Repair", price=Decimal("499.00"))
    mechanic.services_offered = [MechanicServiceOffered(mechanic_id="m1", service_id="svc_1", service=svc)]

    out = MechanicOut.model_validate(mechanic)
    assert out.skills == ["Engine"]
    assert out.languages == ["English"]
    assert out.working_hours[0].day == "Mon-Fri"
    assert out.services[0].id == "svc_1"
    assert out.services[0].price == Decimal("499.00")


def test_mechanic_out_orm_defaults_empty_children() -> None:
    mechanic = Mechanic(id="m1", name="Raju", is_available=True, is_verified=False)
    out = MechanicOut.model_validate(mechanic)
    assert out.skills == []
    assert out.languages == []
    assert out.working_hours == []
    assert out.services == []


def test_mechanic_out_exposes_no_user_security_fields() -> None:
    for secret in ("password_hash", "token", "jwt", "secret", "user_id", "failed_login_attempts", "lockout_at"):
        assert secret not in MechanicOut.model_fields


def test_mechanic_out_serializes_money_as_json_numbers() -> None:
    m = MechanicOut.model_validate(_mechanic_payload())
    dumped = m.model_dump()
    assert dumped["rating"] == Decimal("4.80")
    assert "4.80" not in m.model_dump_json()
    assert "299.0" in m.model_dump_json()


# --- BookingCreate ----------------------------------------------------------


def _booking_create_payload() -> dict:
    return {
        "mechanic_id": "m1",
        "service_id": "svc_1",
        "vehicle_id": V_ID,
        "address": "12 MG Road",
        "lat": "12.971599",
        "lng": "77.594566",
        "scheduled_at": "2026-08-16T10:00:00Z",
    }


def test_booking_create_valid() -> None:
    b = BookingCreate.model_validate(_booking_create_payload())
    assert b.mechanic_id == "m1"
    assert b.service_id == "svc_1"
    assert str(b.vehicle_id) == V_ID
    assert b.lat == Decimal("12.971599")


def test_booking_create_requires_mechanic_id() -> None:
    payload = {k: v for k, v in _booking_create_payload().items() if k != "mechanic_id"}
    assert_validation_error(BookingCreate, payload)


def test_booking_create_rejects_unknown_fields() -> None:
    """Mass-assignment protection: user_id/status/extra fields are rejected."""
    for bad in ("user_id", "status", "id", "estimated_cost", "mechanic_name"):
        assert_validation_error(BookingCreate, {**_booking_create_payload(), bad: "x"})


def test_booking_create_rejects_invalid_vehicle_id() -> None:
    assert_validation_error(BookingCreate, {**_booking_create_payload(), "vehicle_id": "not-a-uuid"})


def test_booking_create_rejects_out_of_range_lat() -> None:
    assert_validation_error(BookingCreate, {**_booking_create_payload(), "lat": "95.0"})


def test_booking_create_rejects_out_of_range_lng() -> None:
    assert_validation_error(BookingCreate, {**_booking_create_payload(), "lng": "181.0"})


def test_booking_create_accepts_minimal_payload() -> None:
    b = BookingCreate.model_validate({"mechanic_id": "m1"})
    assert b.mechanic_id == "m1"
    assert b.vehicle_id is None
    assert b.scheduled_at is None


def test_booking_create_accepts_null_service_for_custom_issue() -> None:
    b = BookingCreate.model_validate({"mechanic_id": "m1", "service_id": None})
    assert b.service_id is None


# --- BookingOut -------------------------------------------------------------


def _booking_out_payload() -> dict:
    return {
        "id": B_ID,
        "mechanic_id": "m1",
        "service_id": "svc_1",
        "vehicle_id": V_ID,
        "status": BookingStatus.REQUESTED,
        "address": "12 MG Road",
        "lat": "12.971599",
        "lng": "77.594566",
        "scheduled_at": "2026-08-16T10:00:00Z",
        "created_at": "2026-08-15T12:00:00Z",
    }


def test_booking_out_valid() -> None:
    b = BookingOut.model_validate(_booking_out_payload())
    assert str(b.id) == B_ID
    assert b.status == BookingStatus.REQUESTED


def test_booking_out_accepts_all_status_values() -> None:
    for status in BookingStatus.VALUES:
        payload = {**_booking_out_payload(), "status": status}
        out = BookingOut.model_validate(payload)
        assert out.status.value == status


def test_booking_out_rejects_invalid_status() -> None:
    assert_validation_error(BookingOut, {**_booking_out_payload(), "status": "not-a-status"})


def test_booking_out_rejects_invalid_booking_id() -> None:
    assert_validation_error(BookingOut, {**_booking_out_payload(), "id": "not-a-uuid"})


def test_booking_out_requires_created_at() -> None:
    payload = {k: v for k, v in _booking_out_payload().items() if k != "created_at"}
    assert_validation_error(BookingOut, payload)


def test_booking_out_orm_serialization() -> None:
    booking = MechanicBooking(
        id=B_ID,
        user_id="99999999-9999-9999-9999-999999999999",
        mechanic_id="m1",
        service_id="svc_1",
        vehicle_id=V_ID,
        status=BookingStatus.REQUESTED.value,
        address="12 MG Road",
        created_at=NOW,
    )
    out = BookingOut.model_validate(booking)
    assert str(out.id) == B_ID
    assert out.status == BookingStatus.REQUESTED
    assert out.created_at == NOW


def test_booking_out_does_not_expose_user_id() -> None:
    assert "user_id" not in BookingOut.model_fields


# --- BookingEventOut --------------------------------------------------------


def _booking_event_payload() -> dict:
    return {
        "id": B_ID2,
        "booking_id": B_ID,
        "status": "accepted",
        "occurred_at": "2026-08-15T12:05:00Z",
        "payload": {"lat": 12.97, "lng": 77.59, "distance_remaining_km": 3.2},
    }


def test_booking_event_out_valid() -> None:
    e = BookingEventOut.model_validate(_booking_event_payload())
    assert str(e.id) == B_ID2
    assert e.status == BookingStatus.ACCEPTED
    assert e.payload["distance_remaining_km"] == 3.2


def test_booking_event_out_accepts_null_status() -> None:
    payload = {k: v for k, v in _booking_event_payload().items() if k != "status"}
    e = BookingEventOut.model_validate(payload)
    assert e.status is None


def test_booking_event_out_rejects_invalid_status() -> None:
    assert_validation_error(BookingEventOut, {**_booking_event_payload(), "status": "bogus"})


def test_booking_event_out_rejects_invalid_booking_id() -> None:
    assert_validation_error(BookingEventOut, {**_booking_event_payload(), "booking_id": "nope"})


def test_booking_event_out_orm_serialization() -> None:
    event = BookingEvent(
        id=B_ID2,
        booking_id=B_ID,
        status=BookingStatus.EN_ROUTE.value,
        occurred_at=NOW,
        payload={"lat": 12.97},
    )
    out = BookingEventOut.model_validate(event)
    assert out.status == BookingStatus.EN_ROUTE
    assert out.payload == {"lat": 12.97}


# --- RatingCreate -----------------------------------------------------------


def test_rating_create_valid() -> None:
    r = RatingCreate.model_validate({"rating": "4.50", "review": "Great service"})
    assert r.rating == Decimal("4.50")
    assert r.review == "Great service"


def test_rating_create_requires_rating() -> None:
    assert_validation_error(RatingCreate, {"review": "Great"})


def test_rating_create_rejects_rating_below_1() -> None:
    assert_validation_error(RatingCreate, {"rating": "0.50"})


def test_rating_create_rejects_rating_above_5() -> None:
    assert_validation_error(RatingCreate, {"rating": "5.01"})


def test_rating_create_rejects_unknown_fields() -> None:
    """booking_id is NOT a body field (route binds it); mass-assignment blocked."""
    for bad in ("booking_id", "user_id", "status", "id"):
        assert_validation_error(RatingCreate, {"rating": "4.5", bad: "x"})


def test_rating_create_rejects_more_than_two_decimals() -> None:
    assert_validation_error(RatingCreate, {"rating": "4.555"})


def test_rating_create_accepts_optional_review() -> None:
    r = RatingCreate.model_validate({"rating": "5"})
    assert r.review is None


# --- RatingOut --------------------------------------------------------------


def test_rating_out_valid() -> None:
    r = RatingOut.model_validate({"booking_id": B_ID, "rating": "4.50", "review": "Good"})
    assert str(r.booking_id) == B_ID
    assert r.rating == Decimal("4.50")


def test_rating_out_orm_serialization() -> None:
    from app.models.mechanic_booking import Rating

    rating = Rating(booking_id=B_ID, rating=Decimal("4.50"), review="Good")
    out = RatingOut.model_validate(rating)
    assert str(out.booking_id) == B_ID
    assert out.rating == Decimal("4.50")


# --- BookingStatus reuse (no second representation) -------------------------


def test_schemas_use_canonical_booking_status() -> None:
    """The schema layer reuses app.models.mechanic_status.BookingStatus verbatim."""
    from typing import Union, get_args, get_origin

    assert BookingOut.model_fields["status"].annotation is BookingStatus
    event_annotation = BookingEventOut.model_fields["status"].annotation
    assert get_origin(event_annotation) in (Optional, Union)  # Optional[BookingStatus]
    assert BookingStatus in get_args(event_annotation)
    assert tuple(BookingStatus.VALUES) == (
        "requested",
        "accepted",
        "mechanicAssigned",
        "enRoute",
        "arrived",
        "completed",
        "cancelled",
    )


def test_rating_create_has_no_decimal_json_loss() -> None:
    r = RatingCreate.model_validate({"rating": "4.50"})
    assert r.model_dump()["rating"] == Decimal("4.50")