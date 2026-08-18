"""Mechanics module Pydantic schemas (Task 6, Stage 3).

Pure request/response validation/serialization contracts for the frozen
Mechanics API (``docs/backend/API.md`` §6 + ``endpoint_catalog.md`` §3.5).

Schema layer rules enforced here:
- **No business logic.** No repository/service/database calls, no JWT/hashing,
  no authorization, no status-transition legality, no rating eligibility, no
  mechanic-assignment, no transaction handling. Validation + serialization only.
- **Money is Decimal in the schema** (matches NUMERIC columns) and is serialized
  to a JSON **number** (``double`` INR, per API.md §1) via ``when_used="json"``
  field serializers; ``model_dump()`` keeps the exact ``Decimal``.
- **No second BookingStatus.** The canonical ``BookingStatus`` enum from
  ``app.models.mechanic_status`` is reused verbatim (D6-4) — nothing here
  redefines status values.
- **No invented fields.** Every field maps to an authoritative model column or
  the frozen API contract. No ``photo_url`` (no DB column), no booking
  ``estimated_cost``/``estimated_arrival`` (no DB columns), no MEC booking
  numbers (D6-2), no vehicle snapshot/vehicle API (``vehicle_id`` is a nullable
  UUID without an FK — D6-1).
- **Working hours** are exposed as normalized rows ``(day, open, close)``
  (D6-5). A grouped map (``{"Mon-Fri": "8:00 AM - 8:00 PM"}``) is a client
  display concern; it is not produced here.
- **Request schemas** use ``extra="forbid"`` (mass-assignment protection,
  Task 5 pattern). **Response schemas** use ``ConfigDict(from_attributes=True)``
  for direct ORM serialization where the field maps 1:1.

ORM serialization note: ``Mechanic.skills``/``.languages`` are child rows and
``.services_offered`` is a junction, so ``MechanicOut`` uses a ``model_validator``
(before) that flattens those ORM collections into the contract shapes
(``skills: List[str]``, ``services: List[MechanicServiceOut]``). This is
serialization shape-mapping only — no queries, no decisions.
"""

from datetime import date, datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_serializer, model_validator

from app.models.mechanic_status import BookingStatus

# ---------------------------------------------------------------------------
# Shared serialization
# ---------------------------------------------------------------------------


class _DecimalJsonMixin(BaseModel):
    """Serialize ``Decimal`` fields to JSON numbers (double INR) on the wire.

    ``when_used="json"``: ``model_dump()`` keeps exact ``Decimal``; only
    ``model_dump_json()`` / FastAPI's ``jsonable_encoder`` emit floats.
    """

    @field_serializer("*", when_used="json", check_fields=False)
    def _decimal_to_json_number(self, value: Any) -> Any:
        return float(value) if isinstance(value, Decimal) else value


# ---------------------------------------------------------------------------
# Mechanic service / category / working hours (global lookups)
# ---------------------------------------------------------------------------


class MechanicServiceOut(_DecimalJsonMixin):
    """A bookable mechanic service (``mechanic_services``, ``svc_*``).

    Public lookup; matches the frozen ``MechanicService`` entity
    (id, name, icon, price, estimatedMinutes, description).
    """

    id: str = Field(..., description="Service id (``svc_*``).")
    name: str = Field(..., min_length=1, max_length=200, description="Service name.")
    icon: Optional[str] = Field(None, description="Stable icon-name string (client maps to its own icons).")
    price: Optional[Decimal] = Field(
        None,
        ge=0,
        max_digits=12,
        decimal_places=2,
        description="Service price in INR (double on the wire).",
    )
    estimated_minutes: Optional[int] = Field(None, ge=1, description="Estimated duration in minutes.")
    description: Optional[str] = Field(None, max_length=1000, description="Service description.")

    model_config = ConfigDict(from_attributes=True)


class MechanicCategoryOut(_DecimalJsonMixin):
    """A mechanic discovery-grid category (``mechanic_categories``).

    The frozen frontend ``MechanicCategory`` has no ``id``; the backend exposes
    the authoritative PK as an additive field (client ignores unknown fields).
    ``sort_order`` stays server-side (the repository already orders by it).
    """

    id: str = Field(..., description="Category id (TEXT PK).")
    name: str = Field(..., min_length=1, max_length=100, description="Category name.")
    icon: Optional[str] = Field(None, description="Icon-name string.")
    color: Optional[str] = Field(None, max_length=50, description="Primary color token.")
    bg_color: Optional[str] = Field(None, max_length=50, description="Background color token.")
    description: Optional[str] = Field(None, max_length=500, description="Category description.")

    model_config = ConfigDict(from_attributes=True)


class MechanicWorkingHourOut(_DecimalJsonMixin):
    """One normalized working-hours row ``(day, open, close)`` (D6-5).

    The database stays normalized; grouping into a client-side map is a display
    concern, not a schema concern.
    """

    day: str = Field(..., min_length=1, max_length=20, description="Day label (e.g. 'Mon-Fri').")
    open: Optional[str] = Field(None, max_length=20, description="Opening time (e.g. '8:00 AM').")
    close: Optional[str] = Field(None, max_length=20, description="Closing time (e.g. '8:00 PM').")

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Mechanic review / mechanic (public catalog)
# ---------------------------------------------------------------------------


class MechanicReviewOut(_DecimalJsonMixin):
    """A public review of a mechanic (``mechanic_reviews``, ``r*``).

    Matches the frozen ``MechanicReview`` entity. ``reviewed_at`` is returned as
    an ISO date; the client renders its own display string (additive, recon
    §12). No eligibility/ownership logic here.
    """

    id: str = Field(..., description="Review id (``r*``).")
    reviewer_name: Optional[str] = Field(None, max_length=100, description="Display name of the reviewer.")
    rating: Optional[Decimal] = Field(
        None,
        ge=0,
        le=5,
        max_digits=3,
        decimal_places=2,
        description="Star rating 0.00-5.00.",
    )
    comment: Optional[str] = Field(None, max_length=2000, description="Review comment.")
    reviewed_at: Optional[date] = Field(None, description="ISO date the review was left.")
    vehicle: Optional[str] = Field(None, max_length=200, description="Vehicle summary (e.g. brand + model).")

    model_config = ConfigDict(from_attributes=True)


class MechanicOut(_DecimalJsonMixin):
    """Public mechanic catalog/profile response (``mechanics``, ``m*``).

    Exposes only public catalog data (name, rating, price, availability, etc.).
    NEVER exposes any ``User``/auth internals (``password_hash``, tokens,
    lockout state) — there is no user reference on the model and none is added.

    Nested relationships are represented deliberately:
    - ``skills`` / ``languages`` as flat string lists (frozen contract).
    - ``working_hours`` as normalized rows (D6-5).
    - ``services`` as the mechanic's offered services (``svc_*``), derived from
      the ``services_offered`` junction.
    """

    id: str = Field(..., description="Mechanic id (``m*``).")
    name: str = Field(..., min_length=1, max_length=200, description="Mechanic display name.")
    rating: Optional[Decimal] = Field(
        None,
        ge=0,
        le=5,
        max_digits=3,
        decimal_places=2,
        description="Average rating 0.00-5.00.",
    )
    review_count: Optional[int] = Field(None, ge=0, description="Number of reviews.")
    experience_years: Optional[int] = Field(None, ge=0, description="Years of experience.")
    distance_km: Optional[Decimal] = Field(
        None, ge=0, max_digits=6, decimal_places=2, description="Distance from the user in km."
    )
    eta_minutes: Optional[int] = Field(None, ge=0, description="Estimated arrival in minutes.")
    is_available: bool = Field(..., description="Whether the mechanic accepts new bookings.")
    price_starting: Optional[Decimal] = Field(
        None,
        ge=0,
        max_digits=12,
        decimal_places=2,
        description="Starting price in INR (double on the wire).",
    )
    phone: Optional[str] = Field(None, max_length=16, description="Public contact phone.")
    about: Optional[str] = Field(None, max_length=2000, description="Short profile description.")
    is_verified: bool = Field(..., description="Whether the mechanic is verified.")
    skills: List[str] = Field(default_factory=list, description="Skill labels.")
    languages: List[str] = Field(default_factory=list, description="Spoken languages.")
    working_hours: List[MechanicWorkingHourOut] = Field(
        default_factory=list, description="Normalized working-hours rows."
    )
    services: List[MechanicServiceOut] = Field(
        default_factory=list, description="Services this mechanic offers."
    )

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def _flatten_orm_children(cls, data: Any) -> Any:
        """Map ORM ``Mechanic`` children into the contract shapes.

        Accepts a plain dict (validated as-is) or a ``Mechanic`` ORM instance
        whose ``skills``/``languages`` child rows and ``services_offered``
        junction are flattened to the public shapes. Shape-mapping only.
        """
        if isinstance(data, dict):
            return data
        return {
            "id": data.id,
            "name": data.name,
            "rating": data.rating,
            "review_count": data.review_count,
            "experience_years": data.experience_years,
            "distance_km": data.distance_km,
            "eta_minutes": data.eta_minutes,
            "is_available": data.is_available,
            "price_starting": data.price_starting,
            "phone": data.phone,
            "about": data.about,
            "is_verified": data.is_verified,
            "skills": [skill.skill for skill in (data.skills or [])],
            "languages": [lang.language for lang in (data.languages or [])],
            "working_hours": list(data.working_hours or []),
            "services": [offered.service for offered in (data.services_offered or [])],
        }


# ---------------------------------------------------------------------------
# Booking (create/read) and booking events
# ---------------------------------------------------------------------------


class BookingCreate(BaseModel):
    """Input for creating a mechanic booking.

    Explicit allowlist (``extra="forbid"``) — no mass assignment. The
    authenticated ``user_id`` is NOT part of the body: the service binds the
    identity from ``get_current_user`` (never trusted from the client, recon
    §9/§17). ``status`` is not settable here — the service creates the booking
    as ``requested``. No invented booking number (D6-2).
    """

    mechanic_id: str = Field(..., min_length=1, max_length=200, description="Mechanic id (``m*``).")
    service_id: Optional[str] = Field(
        None, min_length=1, max_length=200, description="Service id (``svc_*``); null for a custom issue."
    )
    vehicle_id: Optional[UUID] = Field(None, description="Nullable vehicle UUID (D6-1: no FK yet).")
    address: Optional[str] = Field(None, max_length=500, description="Service address.")
    lat: Optional[Decimal] = Field(None, ge=-90, le=90, max_digits=9, decimal_places=6, description="Latitude.")
    lng: Optional[Decimal] = Field(None, ge=-180, le=180, max_digits=9, decimal_places=6, description="Longitude.")
    scheduled_at: Optional[datetime] = Field(None, description="Scheduled service time (ISO-8601).")

    model_config = ConfigDict(extra="forbid")


class BookingOut(_DecimalJsonMixin):
    """Booking response (``mechanic_bookings``).

    Owner-scoped reads only (the route uses ``get_owned``/``list_for_user``).
    ``user_id`` is deliberately NOT exposed — it is the authenticated caller's
    own identity and the client does not need it echoed back. ``status`` uses
    the canonical ``BookingStatus`` (no second enum).
    """

    id: UUID = Field(..., description="Authoritative booking UUID.")
    mechanic_id: str = Field(..., description="Mechanic id (``m*``).")
    service_id: Optional[str] = Field(None, description="Service id (``svc_*``); null for a custom issue.")
    vehicle_id: Optional[UUID] = Field(None, description="Nullable vehicle UUID (D6-1).")
    status: BookingStatus = Field(..., description="Booking lifecycle status.")
    address: Optional[str] = Field(None, max_length=500, description="Service address.")
    lat: Optional[Decimal] = Field(None, description="Latitude.")
    lng: Optional[Decimal] = Field(None, description="Longitude.")
    scheduled_at: Optional[datetime] = Field(None, description="Scheduled service time.")
    created_at: datetime = Field(..., description="Booking creation timestamp.")

    model_config = ConfigDict(from_attributes=True)


class BookingEventOut(_DecimalJsonMixin):
    """One persisted booking-lifecycle snapshot (``booking_events``).

    Read-only representation for live-tracking data. No event generation or
    persistence logic here.
    """

    id: UUID = Field(..., description="Event UUID.")
    booking_id: UUID = Field(..., description="Parent booking UUID.")
    status: Optional[BookingStatus] = Field(None, description="Status at the time of the snapshot.")
    occurred_at: datetime = Field(..., description="When the snapshot was recorded.")
    payload: Optional[Dict[str, Any]] = Field(None, description="Live-tracking snapshot payload (JSONB).")

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Rating (post-service)
# ---------------------------------------------------------------------------


class RatingCreate(BaseModel):
    """Input for submitting a post-service rating.

    Explicit allowlist (``extra="forbid"``). ``booking_id`` is NOT in the body:
    the route binds it from the booking path and the service enforces ownership
    + one-per-booking (1-1 PK) + completed-state. Rating eligibility is a
    service-layer rule, not a schema rule.
    """

    rating: Decimal = Field(
        ...,
        ge=1,
        le=5,
        max_digits=3,
        decimal_places=2,
        description="Star rating 1.00-5.00.",
    )
    review: Optional[str] = Field(None, max_length=2000, description="Optional review comment.")

    model_config = ConfigDict(extra="forbid")


class RatingOut(_DecimalJsonMixin):
    """Rating response (``ratings``, 1-1 with a booking)."""

    booking_id: UUID = Field(..., description="Booking UUID this rating belongs to.")
    rating: Optional[Decimal] = Field(None, ge=0, le=5, max_digits=3, decimal_places=2, description="Star rating.")
    review: Optional[str] = Field(None, max_length=2000, description="Review comment.")

    model_config = ConfigDict(from_attributes=True)


__all__ = [
    "BookingCreate",
    "BookingEventOut",
    "BookingOut",
    "MechanicCategoryOut",
    "MechanicOut",
    "MechanicReviewOut",
    "MechanicServiceOut",
    "MechanicWorkingHourOut",
    "RatingCreate",
    "RatingOut",
]