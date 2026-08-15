"""Security primitives for the Mecha Connect backend.

Infrastructure-level, reusable security engine (Sprint 2, Task 3, Stage 2):

- bcrypt password hashing at cost factor 12 (D4)
- JWT creation/verification with config-driven lifetimes (D5)
- token-type enforcement (`type` claim = "access" | "refresh")
- SHA-256 digest for refresh tokens, for DB storage (D2)

This module intentionally contains NO SQLAlchemy, FastAPI, repositories, HTTP
response handling, or database logic. Errors are raised as controlled
exceptions derived from `app.core.exceptions.MechaException`.
"""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Union
from uuid import UUID

from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError, JWTClaimsError
from passlib.context import CryptContext

from app.core.config import settings
from app.core.exceptions import MechaException

# --- bcrypt (D4) ------------------------------------------------------------

# Locked bcrypt cost factor (D4).
BCRYPT_ROUNDS: int = 12

# bcrypt only considers the first 72 bytes of a password. We reject longer
# inputs explicitly rather than silently truncating them.
BCRYPT_MAX_PASSWORD_BYTES: int = 72

_pwd_context: CryptContext = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=BCRYPT_ROUNDS,
)


def hash_password(password: str) -> str:
    """Return a bcrypt hash of ``password`` at cost factor 12.

    Raises ``ValueError`` for empty or >72-byte inputs; plaintext passwords
    are never stored. The returned string is ``$2b$12$...``.
    """
    if not isinstance(password, str) or not password:
        raise ValueError("password must be a non-empty string")
    if len(password.encode("utf-8")) > BCRYPT_MAX_PASSWORD_BYTES:
        raise ValueError(
            f"password must not exceed {BCRYPT_MAX_PASSWORD_BYTES} bytes"
        )
    return _pwd_context.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    """Verify ``password`` against a bcrypt ``hashed_password``.

    Returns ``False`` for invalid inputs (never raises on a normal mismatch)
    so that login code can respond with a generic failure.
    """
    if not isinstance(password, str) or not password:
        return False
    if not isinstance(hashed_password, str) or not hashed_password:
        return False
    if len(password.encode("utf-8")) > BCRYPT_MAX_PASSWORD_BYTES:
        return False
    return bool(_pwd_context.verify(password, hashed_password))


# --- JWT (D5) ---------------------------------------------------------------

# Token-type claim name, kept consistent across creation and verification.
# Documented contract: the claim is "type" with values "access" or "refresh".
TOKEN_TYPE_CLAIM: str = "type"
TOKEN_TYPE_ACCESS: str = "access"
TOKEN_TYPE_REFRESH: str = "refresh"


class SecurityError(MechaException):
    """Base error for the security engine."""


class SecurityConfigurationError(SecurityError):
    """Raised when required security configuration (e.g. the JWT secret) is missing."""

    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None) -> None:
        super().__init__(message, code="SECURITY_CONFIG_ERROR", details=details)


class TokenVerificationError(SecurityError):
    """Raised when a token is invalid (bad signature/claims/structure)."""

    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None) -> None:
        super().__init__(message, code="INVALID_TOKEN", details=details)


class ExpiredTokenError(TokenVerificationError):
    """Raised when a token has expired."""


class TokenTypeError(TokenVerificationError):
    """Raised when a token is presented for the wrong token type."""


def _jwt_secret() -> str:
    """Return the configured JWT signing secret or fail safely.

    Never generates or falls back to a random/production secret silently.
    """
    secret = settings.JWT_SECRET_KEY
    if not secret:
        raise SecurityConfigurationError(
            "JWT_SECRET_KEY is not configured. Set it in backend/.env before "
            "using JWT operations. No fallback secret is used."
        )
    return secret


def _jwt_algorithm() -> str:
    return settings.JWT_ALGORITHM or "HS256"


def _normalize_user_id(user_id: Union[str, UUID]) -> str:
    """Return a canonical string form of a user identifier for ``sub``."""
    if isinstance(user_id, UUID):
        return str(user_id)
    if isinstance(user_id, str) and user_id.strip():
        return user_id.strip()
    raise ValueError("user_id must be a non-empty UUID or string")


def _build_claims(
    user_id: Union[str, UUID],
    token_type: str,
    expires_in: timedelta,
) -> Dict[str, Any]:
    now = datetime.now(timezone.utc)
    return {
        "sub": _normalize_user_id(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + expires_in).timestamp()),
        "jti": secrets.token_urlsafe(24),
        TOKEN_TYPE_CLAIM: token_type,
    }


def _encode_token(claims: Dict[str, Any]) -> str:
    return jwt.encode(claims, _jwt_secret(), algorithm=_jwt_algorithm())


def create_access_token(
    user_id: Union[str, UUID],
    expires_in: Optional[timedelta] = None,
) -> str:
    """Create a signed access token (default lifetime from configuration: 15 minutes).

    ``expires_in`` exists only to override the configured lifetime (e.g. in
    tests for expiry); production callers omit it.
    """
    if expires_in is None:
        expires_in = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return _encode_token(_build_claims(user_id, TOKEN_TYPE_ACCESS, expires_in))


def create_refresh_token(
    user_id: Union[str, UUID],
    expires_in: Optional[timedelta] = None,
) -> str:
    """Create a signed refresh token (default lifetime from configuration: 7 days).

    ``expires_in`` exists only to override the configured lifetime (e.g. in
    tests for expiry); production callers omit it.
    """
    if expires_in is None:
        expires_in = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    return _encode_token(_build_claims(user_id, TOKEN_TYPE_REFRESH, expires_in))


def _decode_token(token: str) -> Dict[str, Any]:
    """Decode and validate a token's signature, expiry, and required claims.

    Raises controlled ``TokenVerificationError`` subclasses instead of leaking
    ``jose`` exceptions to API clients.
    """
    if not isinstance(token, str) or not token:
        raise TokenVerificationError("token must be a non-empty string")

    try:
        payload = jwt.decode(
            token,
            _jwt_secret(),
            algorithms=[_jwt_algorithm()],
        )
    except ExpiredSignatureError as exc:
        raise ExpiredTokenError("token has expired") from exc
    except JWTClaimsError as exc:
        raise TokenVerificationError("token claims are invalid") from exc
    except JWTError as exc:
        raise TokenVerificationError("token is invalid") from exc

    for claim in ("sub", "iat", "exp", "jti", TOKEN_TYPE_CLAIM):
        if claim not in payload:
            raise TokenVerificationError(
                f"token is missing required claim '{claim}'"
            )
    return payload


def verify_access_token(token: str) -> Dict[str, Any]:
    """Verify a token as an *access* token and return its validated claims.

    Raises ``TokenTypeError`` if a non-access token (e.g. a refresh token) is
    presented, ``ExpiredTokenError`` if expired, or ``TokenVerificationError``
    for any other invalid token.
    """
    payload = _decode_token(token)
    if payload.get(TOKEN_TYPE_CLAIM) != TOKEN_TYPE_ACCESS:
        raise TokenTypeError("token is not an access token")
    return payload


def verify_refresh_token(token: str) -> Dict[str, Any]:
    """Verify a token as a *refresh* token and return its validated claims.

    Raises ``TokenTypeError`` if a non-refresh token (e.g. an access token) is
    presented, ``ExpiredTokenError`` if expired, or ``TokenVerificationError``
    for any other invalid token.
    """
    payload = _decode_token(token)
    if payload.get(TOKEN_TYPE_CLAIM) != TOKEN_TYPE_REFRESH:
        raise TokenTypeError("token is not a refresh token")
    return payload


# --- Refresh-token digest (D2) ----------------------------------------------

def hash_refresh_token(token: str) -> str:
    """Return the deterministic SHA-256 hex digest of a refresh token.

    Only this digest (never the plaintext token) is intended to be stored. The
    digest is 64 lowercase hex characters. The refresh_tokens table itself is
    created in a later stage (D1/D13).
    """
    if not isinstance(token, str) or not token:
        raise ValueError("refresh token must be a non-empty string")
    return hashlib.sha256(token.encode("utf-8")).hexdigest()