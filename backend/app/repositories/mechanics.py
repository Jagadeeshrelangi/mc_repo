"""Mechanics data access (Sprint 2, Task 6, Stage 2 — Repositories).

DATA ACCESS ONLY — no FastAPI dependencies, no JWT logic, no password
hashing, and no business policy. Reads never commit; writes ``flush()`` only.
Transaction ownership (commit/rollback) belongs to the future
``MechanicService``, exactly as documented in ``BaseRepository``.

Security conventions
--------------------
- Booking reads are owner-scoped at the SQL level. ``get_owned`` takes an
  explicit ``user_id`` so a booking is only returned when it belongs to that
  user (``None`` for both "missing" and "belongs to someone else" — the
  caller maps ``None`` to a generic 404 so no existence leaks).
- ``get_by_id`` is deliberately the *unscoped* primary-key primitive: it is
  never an authorization decision. Any user-facing path must use
  ``get_owned``/``list_for_user`` (or a similarly explicit owner filter).
- ``list_for_user`` only ever returns the given user's bookings, newest first.
- The service layer will pass the authenticated user's ID (from
  ``get_current_user``); the repository never trusts a client-provided value
  as an authorization decision.

Field rules (Stage 1 models are authoritative)
----------------------------------------------
- mechanic/service/category/review IDs are TEXT; booking IDs are UUID-string
  (``Uuid(as_uuid=False)``); ``vehicle_id`` stays a nullable UUID **without**
  a ``vehicles`` FK (D6-1); money is ``Decimal``/NUMERIC; status is the
  ``BookingStatus`` contract; ``booking_events.payload`` is JSONB.
- No booking external IDs / MEC-numbers, no invoice/GST, no vehicle lookup.

``list_featured`` derivation
----------------------------
The authoritative ``mechanics`` table has **no ``is_featured`` column**, yet
the frozen frontend contract requires a featured list. The frozen mock's
featured mechanics are ``m1, m2, m4`` — exactly the three highest-rated. This
repository therefore derives "featured" as the top-rated mechanics
(``rating DESC``), which reproduces the frozen contract from the data that
exists, without inventing a column or recommendation logic.
"""

from datetime import datetime
from decimal import Decimal
from typing import Any, Optional, Sequence

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.mechanic import Mechanic
from app.models.mechanic_booking import BookingEvent, MechanicBooking, Rating
from app.models.mechanic_category import MechanicCategory
from app.models.mechanic_review import MechanicReview
from app.models.mechanic_service import MechanicService, MechanicServiceOffered
from app.models.mechanic_status import BookingStatus
from app.repositories.base import BaseRepository

# Number of featured mechanics shown by the frozen home screen (API.md §6:
# "3 featured mechanics"). Derivation: top-rated (see module docstring).
FEATURED_LIMIT = 3


def _mechanic_catalog_options():
    """Eager-loads every catalog relationship ``MechanicOut`` serializes.

    ``MechanicOut._flatten_orm_children`` reads ``skills``, ``languages``,
    ``working_hours`` and ``services_offered`` (and each offered row's
    ``service``) while building the response. Without eager-loading, an async
    request would hit those relationships lazily after the statement returns,
    which is unsafe with ``AsyncSession`` (can raise ``MissingGreenlet``).
    These options mirror what ``get_by_id`` already used and are now shared by
    every catalog read (``list_all`` / ``list_featured`` included).
    """
    return (
        selectinload(Mechanic.skills),
        selectinload(Mechanic.languages),
        selectinload(Mechanic.working_hours),
        selectinload(Mechanic.services_offered).selectinload(
            MechanicServiceOffered.service
        ),
    )


class MechanicRepository(BaseRepository[Mechanic]):
    """Data access for the ``mechanics`` catalog (reads only)."""

    model = Mechanic

    async def get_by_id(self, mechanic_id: str) -> Optional[Mechanic]:
        """Fetch a mechanic by id with its related catalog rows.

        Eagerly loads ``skills``, ``languages``, ``working_hours`` and
        ``services_offered`` so a detail response needs no lazy-loading once
        the session hands off to the service.
        """
        stmt = (
            select(Mechanic)
            .where(Mechanic.id == mechanic_id)
            .options(*_mechanic_catalog_options())
        )
        return await self.session.scalar(stmt)

    async def list_all(self) -> Sequence[Mechanic]:
        """Return every mechanic, ordered by id for determinism.

        The frozen frontend fetches all mechanics and filters/sorts
        client-side, so no pagination, search, or distance logic is added.

        Eager-loads the catalog relationships ``MechanicOut`` serializes
        (same options as ``get_by_id``) so list responses never lazy-load
        against the async session.
        """
        stmt = select(Mechanic).options(*_mechanic_catalog_options()).order_by(Mechanic.id)
        result = await self.session.scalars(stmt)
        return list(await result.all())

    async def list_featured(self, limit: int = FEATURED_LIMIT) -> Sequence[Mechanic]:
        """Return the top-rated mechanics (the contract's "featured" list).

        Derived as ``rating DESC`` because the authoritative table has no
        ``is_featured`` column (see module docstring). Eager-loads the same
        catalog relationships as ``get_by_id``/``list_all``.
        """
        stmt = (
            select(Mechanic)
            .options(*_mechanic_catalog_options())
            .order_by(Mechanic.rating.desc())
            .limit(limit)
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())


class MechanicServiceRepository(BaseRepository[MechanicService]):
    """Data access for the global ``mechanic_services`` lookup."""

    model = MechanicService

    async def get_by_id(self, service_id: str) -> Optional[MechanicService]:
        """Fetch a service by id (``svc_*``)."""
        return await self.get(service_id)

    async def list_all(self) -> Sequence[MechanicService]:
        """Return every service, ordered by id for determinism."""
        stmt = select(MechanicService).order_by(MechanicService.id)
        result = await self.session.scalars(stmt)
        return list(await result.all())

    async def list_for_mechanic(self, mechanic_id: str) -> Sequence[MechanicService]:
        """Return the services a mechanic offers (via ``mechanic_service_offered``)."""
        stmt = (
            select(MechanicService)
            .join(
                MechanicServiceOffered,
                MechanicServiceOffered.service_id == MechanicService.id,
            )
            .where(MechanicServiceOffered.mechanic_id == mechanic_id)
            .order_by(MechanicService.id)
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())


class MechanicCategoryRepository(BaseRepository[MechanicCategory]):
    """Data access for the standalone ``mechanic_categories`` lookup."""

    model = MechanicCategory

    async def get_by_id(self, category_id: str) -> Optional[MechanicCategory]:
        """Fetch a category by id."""
        return await self.get(category_id)

    async def list_all(self) -> Sequence[MechanicCategory]:
        """Return every category ordered by ``sort_order`` then id."""
        stmt = select(MechanicCategory).order_by(
            MechanicCategory.sort_order, MechanicCategory.id
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())


class MechanicReviewRepository(BaseRepository[MechanicReview]):
    """Data access for ``mechanic_reviews`` (read-oriented)."""

    model = MechanicReview

    async def get_by_id(self, review_id: str) -> Optional[MechanicReview]:
        """Fetch a review by id."""
        return await self.get(review_id)

    async def list_for_mechanic(self, mechanic_id: str) -> Sequence[MechanicReview]:
        """Return a mechanic's reviews, ordered by id for determinism."""
        stmt = (
            select(MechanicReview)
            .where(MechanicReview.mechanic_id == mechanic_id)
            .order_by(MechanicReview.id)
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())


class MechanicBookingRepository(BaseRepository[MechanicBooking]):
    """Data access for ``mechanic_bookings`` (owner-scoped reads).

    Only ``get_by_id`` is unscoped — and it is documented as a raw primary-key
    primitive, never an authorization decision. Every user-facing read must go
    through ``get_owned`` or ``list_for_user``, which enforce ownership in the
    SQL itself.
    """

    model = MechanicBooking

    async def create_booking(
        self,
        *,
        user_id: str,
        mechanic_id: str,
        service_id: Optional[str] = None,
        vehicle_id: Optional[str] = None,
        status: str = BookingStatus.REQUESTED.value,
        address: Optional[str] = None,
        lat: Optional[Decimal] = None,
        lng: Optional[Decimal] = None,
        scheduled_at: Optional[datetime] = None,
    ) -> MechanicBooking:
        """Create and persist a booking owned by ``user_id`` (flush only).

        ``user_id`` is expected to be the authenticated user's id (the service
        passes it from ``get_current_user`` — never from a request body).
        """
        booking = MechanicBooking(
            user_id=user_id,
            mechanic_id=mechanic_id,
            service_id=service_id,
            vehicle_id=vehicle_id,
            status=status,
            address=address,
            lat=lat,
            lng=lng,
            scheduled_at=scheduled_at,
        )
        return await self.create(booking)

    async def get_by_id(self, booking_id: str) -> Optional[MechanicBooking]:
        """Raw primary-key fetch. **Not owner-scoped** — use ``get_owned``.

        Provided as the data primitive for callers that have already
        established ownership/authorization at a higher layer. Never call this
        directly from a user-facing route with an unverified user.
        """
        return await self.get(booking_id)

    async def get_owned(self, booking_id: str, user_id: str) -> Optional[MechanicBooking]:
        """Fetch a booking ONLY if it belongs to ``user_id``.

        Returns ``None`` for both "does not exist" and "exists but belongs to
        someone else" — the caller maps ``None`` to a generic 404 so no
        ownership information ever leaks (Task 4 conversation pattern).
        """
        stmt = select(MechanicBooking).where(
            MechanicBooking.id == booking_id,
            MechanicBooking.user_id == user_id,
        )
        return await self.session.scalar(stmt)

    async def list_for_user(self, user_id: str) -> Sequence[MechanicBooking]:
        """Return ONLY ``user_id``'s bookings, newest first."""
        stmt = (
            select(MechanicBooking)
            .where(MechanicBooking.user_id == user_id)
            .order_by(MechanicBooking.created_at.desc())
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())

    async def update_status(self, booking: MechanicBooking, status: str) -> MechanicBooking:
        """Set a booking's status on an already-loaded record (flush only).

        Operates on a single loaded instance, so only that record is updated
        (never a blanket UPDATE). Transition legality is a service-layer rule.
        """
        booking.status = status
        return await self.update(booking)

    async def cancel(self, booking: MechanicBooking) -> MechanicBooking:
        """Data-access helper: mark a booking ``cancelled`` (flush only)."""
        return await self.update_status(booking, BookingStatus.CANCELLED.value)

    async def complete(self, booking: MechanicBooking) -> MechanicBooking:
        """Data-access helper: mark a booking ``completed`` (flush only)."""
        return await self.update_status(booking, BookingStatus.COMPLETED.value)


class BookingEventRepository(BaseRepository[BookingEvent]):
    """Data access for ``booking_events`` (persisted tracking snapshots)."""

    model = BookingEvent

    async def append(
        self,
        *,
        booking_id: str,
        status: Optional[str] = None,
        payload: Optional[dict[str, Any]] = None,
    ) -> BookingEvent:
        """Append one event snapshot to a booking (flush only)."""
        event = BookingEvent(booking_id=booking_id, status=status, payload=payload)
        return await self.create(event)

    async def list_for_booking(self, booking_id: str) -> Sequence[BookingEvent]:
        """Return a booking's events, chronological (oldest first)."""
        stmt = (
            select(BookingEvent)
            .where(BookingEvent.booking_id == booking_id)
            .order_by(BookingEvent.occurred_at)
        )
        result = await self.session.scalars(stmt)
        return list(await result.all())


class RatingRepository(BaseRepository[Rating]):
    """Data access for ``ratings`` (1-1 with a booking).

    The one-rating-per-booking invariant is enforced structurally by the
    ``booking_id`` primary key. Whether a booking is completed, owned by the
    current user, or eligible for rating are service-layer rules (Stage 4) and
    are deliberately NOT decided here.
    """

    model = Rating

    async def get_by_booking_id(self, booking_id: str) -> Optional[Rating]:
        """Fetch the rating for a booking, or ``None`` if not yet rated."""
        stmt = select(Rating).where(Rating.booking_id == booking_id)
        return await self.session.scalar(stmt)

    async def create_rating(
        self,
        *,
        booking_id: str,
        rating: Optional[Decimal] = None,
        review: Optional[str] = None,
    ) -> Rating:
        """Create a rating row keyed by ``booking_id`` (flush only)."""
        record = Rating(booking_id=booking_id, rating=rating, review=review)
        return await self.create(record)


# Re-export the module-level default clock used by tests that inspect
# ``created_at`` ordering (no-op re-import to satisfy linters).
__all__ = [
    "FEATURED_LIMIT",
    "MechanicRepository",
    "MechanicServiceRepository",
    "MechanicCategoryRepository",
    "MechanicReviewRepository",
    "MechanicBookingRepository",
    "BookingEventRepository",
    "RatingRepository",
]