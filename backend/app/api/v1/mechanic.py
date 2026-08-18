"""Mechanics API routes (Sprint 2, Task 6, Stage 5).

THIN HTTP LAYER over ``MechanicService`` — no business logic, no SQLAlchemy,
no session/ownership decisions, no transaction handling here (mirrors
``auth.py`` / ``users.py`` / ``conversation.py``).

Public catalog (frozen discovery contract — ``docs/backend/API.md`` §6):
- ``GET  /mechanics`` — list all mechanics.
- ``GET  /mechanics/featured`` — featured (top-rated) mechanics.
- ``GET  /mechanics/{mechanic_id}`` — mechanic detail + services/working hours.
- ``GET  /mechanics/{mechanic_id}/services`` — services a mechanic offers.
- ``GET  /mechanics/{mechanic_id}/reviews`` — mechanic's public reviews.
- ``GET  /services`` — global services lookup.
- ``GET  /categories`` — discovery-grid categories.

Protected (authenticated owner; identity ALWAYS from ``get_current_user()``,
never from a request body or path):
- ``GET  /bookings`` — authenticated user's booking history (newest first).
- ``POST /bookings`` — create a booking for the authenticated user.
- ``GET  /bookings/{booking_id}`` — owner-scoped booking read.
- ``POST /bookings/{booking_id}/cancel`` — cancel (owner-scoped).
- ``POST /bookings/{booking_id}/complete`` — complete (owner-scoped).
- ``GET  /bookings/{booking_id}/events`` — owner-scoped lifecycle snapshots.
- ``POST /bookings/{booking_id}/rating`` — submit post-service rating.
- ``GET  /bookings/{booking_id}/rating`` — read booking rating (owner-scoped).

Route ordering: static suffixes (``/featured``, ``/services``, ``/reviews``)
are declared BEFORE the ``/{mechanic_id}`` capture so they are never swallowed
as a mechanic id; bookings live under a distinct ``/bookings`` prefix.

Error mapping: service exceptions (``EntityNotFoundException`` /
``InvalidInputException``) are translated to HTTP by the app-level
``MechaException`` handler in ``app.main`` (404 / 400). No raw exceptions are
leaked (``app.main`` generic handler returns a sanitized 500).
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
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
from app.services.mechanic_service import MechanicService

router = APIRouter(
    prefix="/mechanic",
    tags=["Mechanics"],
)


# ---------------------------------------------------------------------------
# PUBLIC CATALOG (frozen discovery contract — no authentication)
# ---------------------------------------------------------------------------


@router.get(
    "/mechanics",
    response_model=List[MechanicOut],
    status_code=status.HTTP_200_OK,
    summary="List all mechanics",
)
async def list_mechanics(
    session: AsyncSession = Depends(get_db),
) -> List[MechanicOut]:
    """Return the full mechanic catalog (availability, rating, skills, etc.)."""
    service = MechanicService(session)
    return await service.list_mechanics()


@router.get(
    "/mechanics/featured",
    response_model=List[MechanicOut],
    status_code=status.HTTP_200_OK,
    summary="List featured mechanics",
)
async def list_featured_mechanics(
    session: AsyncSession = Depends(get_db),
) -> List[MechanicOut]:
    """Return the featured (top-rated) mechanics."""
    service = MechanicService(session)
    return await service.list_featured_mechanics()


@router.get(
    "/mechanics/{mechanic_id}",
    response_model=MechanicOut,
    status_code=status.HTTP_200_OK,
    summary="Get mechanic by id",
)
async def get_mechanic(
    mechanic_id: str,
    session: AsyncSession = Depends(get_db),
) -> MechanicOut:
    """Return one mechanic's public profile (incl. services and working hours)."""
    service = MechanicService(session)
    return await service.get_mechanic(mechanic_id)


@router.get(
    "/mechanics/{mechanic_id}/services",
    response_model=List[MechanicServiceOut],
    status_code=status.HTTP_200_OK,
    summary="List a mechanic's offered services",
)
async def list_mechanic_services(
    mechanic_id: str,
    session: AsyncSession = Depends(get_db),
) -> List[MechanicServiceOut]:
    """Return the services a mechanic offers (M:N junction)."""
    service = MechanicService(session)
    return await service.list_mechanic_services(mechanic_id)


@router.get(
    "/mechanics/{mechanic_id}/reviews",
    response_model=List[MechanicReviewOut],
    status_code=status.HTTP_200_OK,
    summary="List a mechanic's public reviews",
)
async def list_mechanic_reviews(
    mechanic_id: str,
    session: AsyncSession = Depends(get_db),
) -> List[MechanicReviewOut]:
    """Return a mechanic's public reviews."""
    service = MechanicService(session)
    return await service.list_mechanic_reviews(mechanic_id)


@router.get(
    "/services",
    response_model=List[MechanicServiceOut],
    status_code=status.HTTP_200_OK,
    summary="List all mechanic services",
)
async def list_services(
    session: AsyncSession = Depends(get_db),
) -> List[MechanicServiceOut]:
    """Return the global ``mechanic_services`` lookup."""
    service = MechanicService(session)
    return await service.list_services()


@router.get(
    "/categories",
    response_model=List[MechanicCategoryOut],
    status_code=status.HTTP_200_OK,
    summary="List mechanic categories",
)
async def list_categories(
    session: AsyncSession = Depends(get_db),
) -> List[MechanicCategoryOut]:
    """Return the discovery-grid categories, sort-order first."""
    service = MechanicService(session)
    return await service.list_categories()


# ---------------------------------------------------------------------------
# PROTECTED — BOOKINGS (authenticated owner; identity from get_current_user)
# ---------------------------------------------------------------------------


@router.get(
    "/bookings",
    response_model=List[BookingOut],
    status_code=status.HTTP_200_OK,
    summary="List the authenticated user's bookings",
)
async def list_user_bookings(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[BookingOut]:
    """Return ONLY the authenticated user's bookings, newest first."""
    service = MechanicService(session)
    return await service.list_user_bookings(user_id=user.id)


@router.post(
    "/bookings",
    response_model=BookingOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a mechanic booking",
)
async def create_booking(
    payload: BookingCreate,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> BookingOut:
    """Create a booking for the AUTHENTICATED user (owner bound to the token).

    ``user_id`` is never accepted from the request body — ``BookingCreate`` has
    no user field and the service binds the identity from ``get_current_user``.
    """
    service = MechanicService(session)
    return await service.create_booking(payload, user_id=user.id)


@router.get(
    "/bookings/{booking_id}",
    response_model=BookingOut,
    status_code=status.HTTP_200_OK,
    summary="Get a booking (owner-guarded)",
)
async def get_booking(
    booking_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> BookingOut:
    """Return the authenticated user's booking, or a generic 404."""
    service = MechanicService(session)
    return await service.get_booking(booking_id, user_id=user.id)


@router.post(
    "/bookings/{booking_id}/cancel",
    response_model=BookingOut,
    status_code=status.HTTP_200_OK,
    summary="Cancel a booking (owner-guarded)",
)
async def cancel_booking(
    booking_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> BookingOut:
    """Cancel the authenticated user's booking (owner-guarded)."""
    service = MechanicService(session)
    return await service.cancel_booking(booking_id, user_id=user.id)


@router.post(
    "/bookings/{booking_id}/complete",
    response_model=BookingOut,
    status_code=status.HTTP_200_OK,
    summary="Complete a booking (owner-guarded)",
)
async def complete_booking(
    booking_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> BookingOut:
    """Mark the authenticated user's booking ``completed`` (owner-guarded)."""
    service = MechanicService(session)
    return await service.complete_booking(booking_id, user_id=user.id)


@router.get(
    "/bookings/{booking_id}/events",
    response_model=List[BookingEventOut],
    status_code=status.HTTP_200_OK,
    summary="List a booking's lifecycle events (owner-guarded)",
)
async def list_booking_events(
    booking_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[BookingEventOut]:
    """Return a booking's persisted lifecycle snapshots (owner-guarded)."""
    service = MechanicService(session)
    return await service.list_booking_events(booking_id, user_id=user.id)


@router.post(
    "/bookings/{booking_id}/rating",
    response_model=RatingOut,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a rating for a completed booking (owner-guarded)",
)
async def create_rating(
    booking_id: str,
    payload: RatingCreate,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> RatingOut:
    """Rate a completed booking owned by the authenticated user.

    ``booking_id`` comes from the path (never the body); eligibility (owned +
    completed + unrated) is enforced by the service.
    """
    service = MechanicService(session)
    return await service.create_rating(booking_id, user_id=user.id, payload=payload)


@router.get(
    "/bookings/{booking_id}/rating",
    response_model=Optional[RatingOut],
    status_code=status.HTTP_200_OK,
    summary="Get a booking's rating (owner-guarded)",
)
async def get_rating(
    booking_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> Optional[RatingOut]:
    """Return the authenticated user's rating for a booking, or ``None``.

    Owner-guarded: unknown or foreign bookings raise a generic 404.
    """
    service = MechanicService(session)
    return await service.get_rating(booking_id, user_id=user.id)