"""Authentication schemas (Sprint 2, Task 3, Stage 5).

Pure request/response validation contracts. Schemas MUST NOT:
- hash passwords, create/decode JWTs, store tokens,
- access the database, query repositories, or call services,
- log credentials.

Password validation here is INPUT VALIDATION only; hashing stays in
``app.core.security`` (D4). Token fields are typed containers only — no JWT
is generated or verified in a schema.
"""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.user import UserOut

# ---------------------------------------------------------------------------
# Shared validation primitives
# ---------------------------------------------------------------------------

# Frontend-compatible email pattern (mirrors frontend AuthService.validateEmail).
EMAIL_PATTERN = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

# Login identifier may be an email address or a phone number.
# Phone: optional "+" prefix followed by 10-15 digits.
IDENTIFIER_PATTERN = r"^(\+?[0-9]{10,15}|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$"

PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 128


# ---------------------------------------------------------------------------
# Register (POST /api/v1/auth/register)
# ---------------------------------------------------------------------------


class RegisterRequest(BaseModel):
    """Registration input.

    Mirrors the frontend SignUp contract: name, email, phone, password
    (phone is required by the ``users`` table contract, NOT NULL UNIQUE).
    ``password`` is validated for presence/length only — hashing is performed
    later by ``app.core.security.hash_password`` (D4).
    """

    name: str = Field(
        ...,
        min_length=3,
        max_length=100,
        description="Full display name of the new user.",
        example="Jagadeesh Gowda",
    )
    email: str = Field(
        ...,
        min_length=3,
        max_length=254,
        pattern=EMAIL_PATTERN,
        description="Login email address (unique).",
        example="jagadeesh@example.com",
    )
    phone: str = Field(
        ...,
        min_length=10,
        max_length=16,
        pattern=r"^\+?[0-9]{10,15}$",
        description="Login phone number (unique).",
        example="+919876543210",
    )
    password: str = Field(
        ...,
        min_length=PASSWORD_MIN_LENGTH,
        max_length=PASSWORD_MAX_LENGTH,
        description="Plaintext password (input validation only; never stored).",
        example="StrongPass123",
    )


# ---------------------------------------------------------------------------
# Login (POST /api/v1/auth/login)
# ---------------------------------------------------------------------------


class LoginRequest(BaseModel):
    """Login input.

    The project contract (recon §5.1) authenticates with ``email/phone``, so
    ``identifier`` accepts either an email address or a phone number; the
    future auth service resolves which column to match.
    """

    identifier: str = Field(
        ...,
        min_length=3,
        max_length=254,
        pattern=IDENTIFIER_PATTERN,
        description="Login identifier: email address or phone number.",
        example="jagadeesh@example.com",
    )
    password: str = Field(
        ...,
        min_length=PASSWORD_MIN_LENGTH,
        max_length=PASSWORD_MAX_LENGTH,
        description="Plaintext password (input validation only).",
        example="StrongPass123",
    )


# ---------------------------------------------------------------------------
# Tokens (login/refresh responses) and refresh request
# ---------------------------------------------------------------------------


class TokenResponse(BaseModel):
    """Success payload for ``/login`` and ``/refresh``.

    Field types only — no JWT is generated or verified here. ``expires_in`` is
    the access-token lifetime in seconds (D5: 15 minutes = 900 s), computed by
    the auth service from configuration.
    """

    access_token: str = Field(
        ...,
        description="JWT access token (sent as Authorization: Bearer).",
    )
    refresh_token: str = Field(
        ...,
        description="JWT refresh token returned once at issuance (D2); sent in the body for /refresh (D12).",
    )
    token_type: Literal["bearer"] = Field(
        "bearer",
        description="OAuth2 token-type indicator (Bearer).",
    )
    expires_in: int = Field(
        ...,
        gt=0,
        description="Access-token lifetime in seconds.",
        example=900,
    )


class RefreshRequest(BaseModel):
    """Input for POST /api/v1/auth/refresh.

    D12: the refresh token travels in the request body (no cookies).
    """

    refresh_token: str = Field(
        ...,
        min_length=1,
        description="The refresh token to exchange for a new access/refresh pair (D6 rotation).",
    )


# ---------------------------------------------------------------------------
# Logout (POST /api/v1/auth/logout)
# ---------------------------------------------------------------------------


class LogoutRequest(BaseModel):
    """Input for POST /api/v1/auth/logout.

    Carries the refresh token so the auth service can revoke/consume the
    refresh session. Actual revocation logic is implemented later.
    """

    refresh_token: str = Field(
        ...,
        min_length=1,
        description="Refresh token whose session must be terminated.",
    )


class LogoutResponse(BaseModel):
    """Generic logout acknowledgment (no credential echo)."""

    message: str = Field(
        ...,
        description="Generic success message.",
        example="Successfully logged out",
    )


# ---------------------------------------------------------------------------
# Verification (POST /api/v1/auth/verify)
# ---------------------------------------------------------------------------


class VerifyRequest(BaseModel):
    """Input for POST /api/v1/auth/verify.

    D7: backend verification-state/token architecture only. The token carries
    the identity; no external email/SMS provider is invented here (delivery
    remains a FUTURE / CONFIGURABLE layer).
    """

    token: str = Field(
        ...,
        min_length=1,
        description="Verification token issued during registration.",
    )


# ---------------------------------------------------------------------------
# Password reset (POST /api/v1/auth/forgot-password, /reset-password)
# ---------------------------------------------------------------------------


class ForgotPasswordRequest(BaseModel):
    """Input for POST /api/v1/auth/forgot-password.

    Enumeration-safe: the endpoint responds generically regardless of whether
    the identifier exists (D8). Only the identifier is captured here.
    """

    identifier: str = Field(
        ...,
        min_length=3,
        max_length=254,
        pattern=IDENTIFIER_PATTERN,
        description="Email or phone to send a reset link to (delivery is a FUTURE layer).",
        example="jagadeesh@example.com",
    )


class ForgotPasswordResponse(BaseModel):
    """Generic enumeration-safe response for forgot-password (D8).

    Identical whether or not the identifier exists — no account-existence leak.
    """

    message: str = Field(
        ...,
        description="Generic message sent to any caller.",
        example="If an account exists, a password reset link has been sent.",
    )


class ResetPasswordRequest(BaseModel):
    """Input for POST /api/v1/auth/reset-password.

    Carries the reset token plus the new password (input validation only —
    hashing happens in ``app.core.security``).
    """

    token: str = Field(
        ...,
        min_length=1,
        description="Password-reset token issued by the forgot-password flow.",
    )
    new_password: str = Field(
        ...,
        min_length=PASSWORD_MIN_LENGTH,
        max_length=PASSWORD_MAX_LENGTH,
        description="New plaintext password (input validation only).",
        example="NewStrongPass456",
    )


class ResetPasswordResponse(BaseModel):
    """Confirmation that the password was reset."""

    message: str = Field(
        ...,
        description="Generic success message.",
        example="Password has been reset successfully",
    )


# ---------------------------------------------------------------------------
# Current user (GET /api/v1/auth/me)
# ---------------------------------------------------------------------------


class CurrentUserResponse(UserOut):
    """Response for ``GET /api/v1/auth/me``.

    Reuses the safe user response contract from ``app.schemas.user``. Exposes
    only non-sensitive user fields; NEVER includes ``password_hash``, JWT
    secrets, refresh-token digests, or internal lockout/failure state.
    """

    model_config = ConfigDict(from_attributes=True)


__all__ = [
    "RegisterRequest",
    "LoginRequest",
    "TokenResponse",
    "RefreshRequest",
    "LogoutRequest",
    "LogoutResponse",
    "VerifyRequest",
    "ForgotPasswordRequest",
    "ForgotPasswordResponse",
    "ResetPasswordRequest",
    "ResetPasswordResponse",
    "CurrentUserResponse",
]