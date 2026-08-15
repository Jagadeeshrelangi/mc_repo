"""FastAPI dependency wiring (Sprint 2, Task 3, Stage 7).

REQUEST/SESSION + AUTHENTICATION WIRING:

- ``get_db`` — re-export of the foundation async-session dependency.
- ``get_current_user`` — resolves the authenticated ``User`` from a Bearer
  access token via ``app.core.security.verify_access_token`` + the
  ``UserRepository``. Rejects missing/malformed/wrong-type tokens, missing
  users, and inactive accounts.
- ``role_required`` — dependency factory asserting the current user's role
  against the approved D3 roles; rejects unauthorized roles generically.
  No second role enum is introduced (``UserRole`` remains the single source).
- ``get_auth_rate_limit`` — D10 process-local in-memory auth rate limiter
  (10 requests/minute per client), applied only to auth endpoints.

No hashing, JWT creation, or business rules live here — only wiring.
"""

from collections.abc import AsyncIterator
from typing import Any, Callable, Optional, Set

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import security
from app.core.database import AsyncSessionFactory, get_db as _get_db
from app.core.exceptions import EntityNotFoundException, UnauthorizedException
from app.core.rate_limit import RateLimiter
from app.models.user import User
from app.repositories.users import UserRepository

# Re-export the foundation session dependency so API modules import it from a
# single wiring point. Provides an AsyncSession for the lifetime of a request
# and rolls back on error (see app.core.database.get_db).
get_db: Callable[[], AsyncIterator[AsyncSession]] = _get_db

# Bearer scheme that does NOT auto-reject: we want to distinguish "missing
# header" from "malformed token" ourselves and answer with a controlled
# 401 rather than a framework 403.
_bearer_scheme = HTTPBearer(auto_error=False)

# Generic auth-failure message (D9 convention): never reveals whether the
# identifier, token, or account state caused the failure.
GENERIC_TOKEN_FAILURE = "Invalid or expired access token"

# D10: process-local in-memory auth limiter, 10 requests/minute per client.
AUTH_RATE_LIMIT_MAX_REQUESTS = 10
AUTH_RATE_LIMIT_WINDOW_SECONDS = 60
auth_rate_limiter = RateLimiter(
    max_requests=AUTH_RATE_LIMIT_MAX_REQUESTS,
    window_seconds=AUTH_RATE_LIMIT_WINDOW_SECONDS,
)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
    session: AsyncSession = Depends(get_db),
) -> User:
    """Resolve the authenticated user from the Bearer access token.

    - Missing/malformed ``Authorization`` header → 401 (generic).
    - ``verify_access_token`` rejects expired, tampered, wrong-secret, or
      non-access-type tokens (e.g. a refresh token) → 401 (generic).
    - User must exist (else NOT_FOUND) and be active (else 401).
    """
    if credentials is None or not credentials.credentials:
        raise UnauthorizedException("Not authenticated.")
    try:
        claims = security.verify_access_token(credentials.credentials)
    except security.SecurityError as exc:
        raise UnauthorizedException(GENERIC_TOKEN_FAILURE) from exc

    user_id = claims.get("sub")
    user = await UserRepository(session).get(user_id)
    if user is None:
        raise EntityNotFoundException("User not found.")
    if not user.is_active:
        raise UnauthorizedException("Account is not active.")
    return user


def role_required(*roles: str) -> Callable[..., Any]:
    """Return a dependency requiring the current user to hold one of ``roles``.

    Roles are the approved D3 string values (``UserRole.CUSTOMER`` /
    ``UserRole.MECHANIC`` / ``UserRole.ADMIN``). A user without the required
    role gets a generic 401 — the check never reveals available roles.
    """
    allowed: Set[str] = set(roles)

    async def _role_dependency(user: User = Depends(get_current_user)) -> User:
        if user.role not in allowed:
            raise UnauthorizedException("You do not have permission to perform this action.")
        return user

    return _role_dependency


async def get_auth_rate_limit(request: Request) -> None:
    """D10 dependency: reject auth requests beyond 10/minute per client IP.

    Scoped to the auth router only — other endpoints are never affected.
    The limiter instance is module-level so it is shared across the auth
    routes for one process (no Redis); tests may swap it for a deterministic
    clock via ``app.api.deps.auth_rate_limiter``.
    """
    client = request.client.host if request.client else "unknown"
    if not auth_rate_limiter.allow(client):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please try again later.",
        )