"""Users / Profile API routes (Sprint 2, Task 5).

THIN HTTP LAYER over ``UserService`` — no business logic, no SQLAlchemy, no
field whitelist decisions, no transaction handling here.

Owner-scoped only:
- ``GET /api/v1/users/me`` — read the authenticated user's safe profile.
- ``PATCH /api/v1/users/me`` — update ONLY the safe whitelisted profile fields.

Identity ALWAYS comes from ``get_current_user()`` (Bearer access token). There
is intentionally NO ``GET /users/{user_id}`` endpoint: no client-supplied
``user_id`` (body / query / path) is ever accepted, preventing IDOR.
"""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UserOut, UserProfileUpdate
from app.services.user_service import UserService

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


@router.get(
    "/me",
    response_model=UserOut,
    status_code=status.HTTP_200_OK,
    summary="Get the authenticated user's profile",
)
async def get_me(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> UserOut:
    """Return the safe profile projection of the authenticated owner.

    Identity is resolved from the Bearer token by ``get_current_user()``; the
    response never exposes ``password_hash``, token digests, JWT secrets,
    ``failed_login_attempts``, ``lockout_at``, ``last_login_at``, or audit
    timestamps (the ``UserOut`` projection omits them).
    """
    service = UserService(session)
    return await service.get_profile(current_user)


@router.patch(
    "/me",
    response_model=UserOut,
    status_code=status.HTTP_200_OK,
    summary="Update the authenticated user's profile (safe fields only)",
)
async def update_me(
    payload: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> UserOut:
    """Update ONLY the safe whitelisted profile fields (name, date_of_birth,
    gender, emergency-contact trio).

    The writable contract is the explicit whitelist in
    ``app.schemas.user.UserProfileUpdate`` (extra fields are rejected), and
    ``UserService`` re-checks every key against ``SAFE_PROFILE_FIELDS``. Role,
    is_active, is_verified, membership_tier, password_hash, email, phone and
    audit timestamps can never be modified through this endpoint.
    """
    service = UserService(session)
    return await service.update_profile(current_user, payload)