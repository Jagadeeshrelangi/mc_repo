"""Authentication API routes (Sprint 2, Task 3, Stage 7).

THIN HTTP LAYER over ``AuthService``. These routes contain NO business logic:
no password hashing, no JWT creation, no SQLAlchemy queries, no lockout/rotation
policy. They parse request bodies, call the service, and return responses.

Exception mapping (HTTP-agnostic service → HTTP):
- ``UnauthorizedException`` / ``InvalidInputException`` /
  ``EntityNotFoundException`` are handled by the app-level ``MechaException``
  handler in ``app.main`` (401 / 400 / 404).
- ``NotImplementedError`` from the Stage 6 verification/reset boundaries is
  surfaced as HTTP 501 NOT IMPLEMENTED below — the endpoints do NOT pretend
  verification/reset works (D13: no verification/reset-token persistence).

D10 rate limiting is applied at the router level (auth endpoints only).
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_auth_rate_limit, get_current_user, get_db
from app.models.user import User
from app.schemas.auth import (
    CurrentUserResponse,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LogoutRequest,
    LogoutResponse,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    ResetPasswordResponse,
    TokenResponse,
    VerifyRequest,
)
from app.schemas.user import UserOut
from app.services.auth_service import AuthService

router = APIRouter(
    dependencies=[Depends(get_auth_rate_limit)],
    tags=["Authentication"],
)


def _not_implemented(exc: NotImplementedError) -> HTTPException:
    """Map the Stage 6 documented boundary to HTTP 501 without inventing a
    table, token type, or provider."""
    return HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail=str(exc),
    )


@router.post(
    "/register",
    response_model=UserOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account",
)
async def register(
    payload: RegisterRequest,
    session: AsyncSession = Depends(get_db),
) -> UserOut:
    """Register a new customer account (thin wrapper over AuthService.register)."""
    service = AuthService(session)
    return await service.register(payload)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Login with email or phone",
)
async def login(
    payload: LoginRequest,
    session: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Authenticate by email or phone; returns an access/refresh token pair."""
    service = AuthService(session)
    return await service.login(payload.identifier, payload.password)


@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Refresh access token (rotation)",
)
async def refresh(
    payload: RefreshRequest,
    session: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Rotate a refresh token into a new access/refresh pair (D6)."""
    service = AuthService(session)
    return await service.refresh(payload.refresh_token)


@router.post(
    "/verify",
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    summary="Verify account (documented boundary — not implemented)",
)
async def verify(
    payload: VerifyRequest,
    session: AsyncSession = Depends(get_db),
):
    """Surface the Stage 6 verification boundary (D7/F1) as 501.

    The approved Task 3 DB scope (D13) has no verification-token persistence,
    so verification is intentionally NOT implemented — no fake success.
    """
    service = AuthService(session)
    try:
        await service.verify(payload.token)
    except NotImplementedError as exc:
        raise _not_implemented(exc) from exc
    raise _not_implemented(NotImplementedError("Account verification is not implemented."))


@router.post(
    "/forgot-password",
    response_model=ForgotPasswordResponse,
    status_code=status.HTTP_200_OK,
    summary="Enumeration-safe forgot-password",
)
async def forgot_password(
    payload: ForgotPasswordRequest,
    session: AsyncSession = Depends(get_db),
) -> ForgotPasswordResponse:
    """Enumeration-safe generic response (D8): identical whether or not the
    identifier exists; performs no account lookup."""
    service = AuthService(session)
    return await service.forgot_password(payload.identifier)


@router.post(
    "/reset-password",
    status_code=status.HTTP_501_NOT_IMPLEMENTED,
    summary="Reset password (documented boundary — not implemented)",
)
async def reset_password(
    payload: ResetPasswordRequest,
    session: AsyncSession = Depends(get_db),
):
    """Surface the Stage 6 reset-password boundary (D8/F2) as 501.

    The approved Task 3 DB scope (D13) has no reset-token persistence, so
    password reset is intentionally NOT implemented — no fake success.
    """
    service = AuthService(session)
    try:
        await service.reset_password(payload.token, payload.new_password)
    except NotImplementedError as exc:
        raise _not_implemented(exc) from exc
    raise _not_implemented(NotImplementedError("Password reset is not implemented."))


@router.get(
    "/me",
    response_model=CurrentUserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get the authenticated user's profile",
)
async def me(
    current_user: User = Depends(get_current_user),
) -> User:
    """Return the safe user projection (never password_hash, token digests,
    JWT secrets, failed_login_attempts, lockout_at, or last_login_at)."""
    return current_user


@router.post(
    "/logout",
    response_model=LogoutResponse,
    status_code=status.HTTP_200_OK,
    summary="Logout (revoke refresh session)",
)
async def logout(
    payload: LogoutRequest,
    session: AsyncSession = Depends(get_db),
) -> LogoutResponse:
    """Terminate the refresh session idempotently; no credential echo."""
    service = AuthService(session)
    return await service.logout(payload.refresh_token)