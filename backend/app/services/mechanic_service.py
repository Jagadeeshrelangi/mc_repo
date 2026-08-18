"""Mechanics module service layer (Task 6, Stage 4).

``MechanicService`` coordinates the Stage 3 schemas → Stage 2 repositories →
database transaction layers for the frozen Mechanics contract
(``docs/backend/API.md`` §6 + ``endpoint_catalog.md`` §3.5). It mirrors the
existing request-scoped services (``AuthService`` / ``UserService`` /
``ChatService``).

Architecture
------------
- Request-scoped: construct one per request with the ``AsyncSession`` provided
  by ``app.api.deps.get_db`` (or test fakes). Repositories default to the real
  Stage 2 implementations bound to that session; tests may inject fakes.
- NO route definitions, NO ``Depends()``, NO HTTP, NO authentication/JWT, NO
  password hashing, NO SQL construction, NO session creation. The future API
  layer (Stage 5) supplies the authenticated ``user_id``.
- Read operations NEVER commit. Write operations flush through the
  repositories (flush-only convention) and ``session.commit()`` EXACTLY ONCE
  per logical operation; any failure ``session.rollback()`` and re-raises.

Ownership (recon §9/§17)
------------------------
- Every booking read/write resolves ``get_owned(booking_id, user_id)``; a miss
  maps to a GENERIC ``EntityNotFoundException("Booking not found.")`` — the
  same 404 for "missing" vs "belongs to someone else" so no existence leaks.
- ``user_id`` ALWAYS comes from the API layer's ``get_current_user``, never
  from a request body: ``BookingCreate`` / ``RatingCreate`` carry no user
  identity (mass-assignment is blocked at the schema layer, Stage 3).

Booking lifecycle (D6-4, recon §11)
-----------------------------------
- create → ``requested``; the initial ``requested`` snapshot is persisted to
  ``booking_events`` in the SAME transaction (multi-write atomicity).
- cancel → ``cancelled`` (event appended); complete → ``completed`` (event
  appended). Only the minimal approved transition rule is enforced (recon
  §17: prevent e.g. completing a cancelled booking): a booking already in a
  terminal state (``cancelled``/``completed``) cannot be cancelled or
  completed again. A finer-grained state matrix is NOT defined by the frozen
  contract and is deliberately NOT invented.

Ratings (D6-3, recon §12/§17)
-----------------------------
- Eligibility: the booking must exist, belong to the authenticated user, be
  ``completed``, and be unrated (1-1 PK). These checks turn a structural
  IntegrityError into a controlled ``InvalidInputException``.
- There is no frontend caller for rating submission today (recon §8); this is
  the backend capability bound to the frozen contract surface.
"""

from typing import List, Optional

from app.core.exceptions import EntityNotFoundException, InvalidInputException
from app.models.mechanic_booking import MechanicBooking
from app.models.mechanic_status import BookingStatus
from app.repositories.mechanics import (
    BookingEventRepository,
    MechanicBookingRepository,
    MechanicCategoryRepository,
    MechanicRepository,
    MechanicReviewRepository,
    MechanicServiceRepository,
    RatingRepository,
)
from app.schemas.mechanic import (
    BookingCreate,
    BookingEventOut,
    BookingOut,
    MechanicCategoryOut,
    MechanicOut,
    MechanicReviewOut,
    MechanicServiceOut,
    RatingCreate,
    RatingOut,
)

# Terminal lifecycle states: once reached, a booking can no longer be cancelled
# or completed (recon §17 illegal-transition rule).
TERMINAL_STATUSES = frozenset(
    {BookingStatus.CANCELLED.value, BookingStatus.COMPLETED.value}
)


class MechanicService:
    """Mechanics orchestration: catalog reads + owner-scoped booking flows.

    Constructor-injected dependencies: the request ``AsyncSession`` and the
    Stage 2 repositories bound to it (created internally if not provided, which
    keeps tests able to inject fakes that exercise coordination only).
    """

    def __init__(
        self,
        session,
        mechanic_repository: Optional[MechanicRepository] = None,
        service_repository: Optional[MechanicServiceRepository] = None,
        category_repository: Optional[MechanicCategoryRepository] = None,
        review_repository: Optional[MechanicReviewRepository] = None,
        booking_repository: Optional[MechanicBookingRepository] = None,
        event_repository: Optional[BookingEventRepository] = None,
        rating_repository: Optional[RatingRepository] = None,
    ) -> None:
        self.session = session
        self.mechanic_repo = mechanic_repository or MechanicRepository(session)
        self.service_repo = service_repository or MechanicServiceRepository(session)
        self.category_repo = category_repository or MechanicCategoryRepository(session)
        self.review_repo = review_repository or MechanicReviewRepository(session)
        self.booking_repo = booking_repository or MechanicBookingRepository(session)
        self.event_repo = event_repository or BookingEventRepository(session)
        self.rating_repo = rating_repository or RatingRepository(session)

    # ---------------------------------------------------------------------------
    # Catalog reads (public, never commit)
    # ---------------------------------------------------------------------------

    async def list_mechanics(self) -> List[MechanicOut]:
        """Return every mechanic (frozen list endpoint)."""
        mechanics = await self.mechanic_repo.list_all()
        return [MechanicOut.model_validate(m) for m in mechanics]

    async def list_featured_mechanics(self) -> List[MechanicOut]:
        """Return the featured (top-rated) mechanics."""
        mechanics = await self.mechanic_repo.list_featured()
        return [MechanicOut.model_validate(m) for m in mechanics]

    async def get_mechanic(self, mechanic_id: str) -> MechanicOut:
        """Return one mechanic with its services/working-hours/reviews data."""
        mechanic = await self.mechanic_repo.get_by_id(mechanic_id)
        if mechanic is None:
            raise EntityNotFoundException("Mechanic not found.")
        return MechanicOut.model_validate(mechanic)

    async def list_services(self) -> List[MechanicServiceOut]:
        """Return the global ``mechanic_services`` lookup."""
        services = await self.service_repo.list_all()
        return [MechanicServiceOut.model_validate(s) for s in services]

    async def list_mechanic_services(self, mechanic_id: str) -> List[MechanicServiceOut]:
        """Return the services a mechanic offers (via the M:N junction)."""
        services = await self.service_repo.list_for_mechanic(mechanic_id)
        return [MechanicServiceOut.model_validate(s) for s in services]

    async def list_categories(self) -> List[MechanicCategoryOut]:
        """Return the discovery-grid categories, sort-order first."""
        categories = await self.category_repo.list_all()
        return [MechanicCategoryOut.model_validate(c) for c in categories]

    async def list_mechanic_reviews(self, mechanic_id: str) -> List[MechanicReviewOut]:
        """Return a mechanic's public reviews."""
        reviews = await self.review_repo.list_for_mechanic(mechanic_id)
        return [MechanicReviewOut.model_validate(r) for r in reviews]

    # ---------------------------------------------------------------------------
    # Booking reads (owner-scoped, never commit)
    # ---------------------------------------------------------------------------

    async def get_booking(self, booking_id: str, user_id: str) -> BookingOut:
        """Return the authenticated user's booking, or a generic 404.

        ``get_owned`` returns ``None`` for both "missing" and "belongs to
        someone else"; both map to the same controlled ``EntityNotFoundException``
        so no ownership information leaks.
        """
        booking = await self._get_owned_or_404(booking_id, user_id)
        return BookingOut.model_validate(booking)

    async def list_user_bookings(self, user_id: str) -> List[BookingOut]:
        """Return ONLY the authenticated user's bookings, newest first."""
        bookings = await self.booking_repo.list_for_user(user_id)
        return [BookingOut.model_validate(b) for b in bookings]

    async def list_booking_events(
        self, booking_id: str, user_id: str
    ) -> List[BookingEventOut]:
        """Return a booking's persisted lifecycle snapshots (owner-guarded)."""
        await self._get_owned_or_404(booking_id, user_id)
        events = await self.event_repo.list_for_booking(booking_id)
        return [BookingEventOut.model_validate(e) for e in events]

    # ---------------------------------------------------------------------------
    # Booking writes (one commit per operation)
    # ---------------------------------------------------------------------------

    async def create_booking(self, payload: BookingCreate, user_id: str) -> BookingOut:
        """Create a booking for the AUTHENTICATED ``user_id`` as ``requested``.

        ``user_id`` is supplied by the API layer's ``get_current_user`` — never
        trusted from the client (``BookingCreate`` has no user field). No
        estimated cost, no estimated arrival, no booking number (D6-2): those
        are not model columns. ``vehicle_id`` stays the nullable UUID contract
        (D6-1, no vehicle lookup). The initial ``requested`` snapshot and the
        booking row are written in ONE transaction.
        """
        try:
            # FK pre-checks → controlled 404 instead of a raw FK IntegrityError.
            if await self.mechanic_repo.get_by_id(payload.mechanic_id) is None:
                raise EntityNotFoundException("Mechanic not found.")
            if payload.service_id is not None and await self.service_repo.get_by_id(
                payload.service_id
            ) is None:
                raise EntityNotFoundException("Service not found.")

            booking = await self.booking_repo.create_booking(
                user_id=user_id,
                mechanic_id=payload.mechanic_id,
                service_id=payload.service_id,
                vehicle_id=str(payload.vehicle_id) if payload.vehicle_id else None,
                status=BookingStatus.REQUESTED.value,
                address=payload.address,
                lat=payload.lat,
                lng=payload.lng,
                scheduled_at=payload.scheduled_at,
            )
            # Persist the initial lifecycle snapshot in the same transaction.
            await self.event_repo.append(
                booking_id=booking.id, status=BookingStatus.REQUESTED.value
            )
            await self.session.commit()
            return BookingOut.model_validate(booking)
        except Exception:
            await self.session.rollback()
            raise

    async def cancel_booking(self, booking_id: str, user_id: str) -> BookingOut:
        """Cancel the authenticated user's booking (owner-guarded).

        Enforces the minimal approved transition rule (recon §17): a booking
        already in a terminal state cannot be cancelled. The ``cancelled``
        snapshot is appended in the same transaction.
        """
        try:
            booking = await self._get_owned_or_404(booking_id, user_id)
            self._assert_mutable(booking)
            await self.booking_repo.cancel(booking)
            await self.event_repo.append(
                booking_id=booking_id, status=BookingStatus.CANCELLED.value
            )
            await self.session.commit()
            return BookingOut.model_validate(booking)
        except Exception:
            await self.session.rollback()
            raise

    async def complete_booking(self, booking_id: str, user_id: str) -> BookingOut:
        """Mark the authenticated user's booking ``completed`` (owner-guarded).

        Enforces the minimal approved transition rule (recon §17): a cancelled
        (or already completed) booking cannot be completed. The ``completed``
        snapshot is appended in the same transaction.
        """
        try:
            booking = await self._get_owned_or_404(booking_id, user_id)
            self._assert_mutable(booking)
            await self.booking_repo.complete(booking)
            await self.event_repo.append(
                booking_id=booking_id, status=BookingStatus.COMPLETED.value
            )
            await self.session.commit()
            return BookingOut.model_validate(booking)
        except Exception:
            await self.session.rollback()
            raise

    # ---------------------------------------------------------------------------
    # Rating (post-service; owner + completed + unrated eligibility)
    # ---------------------------------------------------------------------------

    async def create_rating(
        self, booking_id: str, user_id: str, payload: RatingCreate
    ) -> RatingOut:
        """Submit a rating for a booking the authenticated user owns.

        ``booking_id`` comes from the route/service operation, never the body
        (``RatingCreate`` has no booking field). Eligibility (recon §12/§17):
        the booking must be owned by the caller, ``completed``, and unrated
        (the 1-1 PK structurally enforces one rating per booking; this service
        check turns the resulting IntegrityError into a controlled error).
        """
        try:
            booking = await self._get_owned_or_404(booking_id, user_id)
            if booking.status != BookingStatus.COMPLETED.value:
                raise InvalidInputException("Only completed bookings can be rated.")
            if await self.rating_repo.get_by_booking_id(booking_id) is not None:
                raise InvalidInputException("This booking has already been rated.")

            rating = await self.rating_repo.create_rating(
                booking_id=booking_id,
                rating=payload.rating,
                review=payload.review,
            )
            await self.session.commit()
            return RatingOut.model_validate(rating)
        except Exception:
            await self.session.rollback()
            raise

    async def get_rating(self, booking_id: str, user_id: str) -> Optional[RatingOut]:
        """Return the authenticated user's rating for a booking, or ``None``.

        Owner-guarded: unknown or foreign bookings raise the generic 404.
        ``None`` means the (owned) booking has not been rated yet.
        """
        await self._get_owned_or_404(booking_id, user_id)
        rating = await self.rating_repo.get_by_booking_id(booking_id)
        return RatingOut.model_validate(rating) if rating is not None else None

    # ---------------------------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------------------------

    async def _get_owned_or_404(self, booking_id: str, user_id: str) -> MechanicBooking:
        """Owner-guarded booking lookup → generic 404 (no existence leak)."""
        booking = await self.booking_repo.get_owned(booking_id, user_id)
        if booking is None:
            raise EntityNotFoundException("Booking not found.")
        return booking

    @staticmethod
    def _assert_mutable(booking: MechanicBooking) -> None:
        """Reject cancel/complete on an already-terminal booking (recon §17)."""
        if booking.status in TERMINAL_STATUSES:
            raise InvalidInputException(
                "This booking is already finished and cannot be changed."
            )


__all__ = ["TERMINAL_STATUSES", "MechanicService"]