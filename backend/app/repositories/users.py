"""User and refresh-token data access (Sprint 2, Task 3, Stage 4).

DATA ACCESS ONLY — no password hashing, no JWT creation, and no
authentication business decisions live here. Hashing lives in
``app.core.security``; policy (lockout thresholds, rotation decisions) will
live in the future auth service.
"""

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select

from app.models.refresh_token import RefreshToken
from app.models.user import User, UserRole
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    """Data access for the ``users`` table."""

    model = User

    async def get_by_email(self, email: str) -> Optional[User]:
        """Fetch a user by email (login identifier)."""
        stmt = select(User).where(User.email == email)
        return await self.session.scalar(stmt)

    async def get_by_phone(self, phone: str) -> Optional[User]:
        """Fetch a user by phone (login identifier)."""
        stmt = select(User).where(User.phone == phone)
        return await self.session.scalar(stmt)

    async def create_user(
        self,
        *,
        name: str,
        email: str,
        phone: str,
        password_hash: Optional[str] = None,
        role: str = UserRole.CUSTOMER,
    ) -> User:
        """Create and persist a new user (flush; commit owned by the caller).

        ``password_hash`` is expected to be the already-hashed password
        produced by ``app.core.security.hash_password`` — hashing never
        happens inside the repository.
        """
        user = User(
            name=name,
            email=email,
            phone=phone,
            password_hash=password_hash,
            role=role,
        )
        return await self.create(user)

    async def record_successful_login(self, user: User) -> None:
        """Set last-login timestamp and reset failed-attempt counter (flush only)."""
        user.last_login_at = datetime.now(timezone.utc)
        user.failed_login_attempts = 0
        await self.session.flush()

    async def record_failed_login(self, user: User) -> None:
        """Increment the failed-attempt counter (flush only).

        Lockout policy (D9) is decided by the auth service, not here.
        """
        user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
        await self.session.flush()

    async def clear_login_failures(self, user: User) -> None:
        """Reset the failed-attempt counter to 0 (flush only)."""
        user.failed_login_attempts = 0
        await self.session.flush()

    async def lock_account(self, user: User, lockout_at: datetime) -> None:
        """Persist the account lockout timestamp (flush only)."""
        user.lockout_at = lockout_at
        await self.session.flush()

    async def unlock_account(self, user: User) -> None:
        """Clear the lockout and reset failure counters (flush only)."""
        user.lockout_at = None
        user.failed_login_attempts = 0
        await self.session.flush()


class RefreshTokenRepository(BaseRepository[RefreshToken]):
    """Data access for the ``refresh_tokens`` table (D1/D2/D6).

    Database-focused only. The rotation workflow
    (validate -> revoke -> create replacement) is decided by the future
    auth service, not here.
    """

    model = RefreshToken

    async def create_refresh_token(
        self,
        *,
        user_id: str,
        token_digest: str,
        jti: str,
        expires_at: datetime,
    ) -> RefreshToken:
        """Create and persist a refresh-token record (flush; commit by caller).

        ``token_digest`` is the SHA-256 digest from
        ``app.core.security.hash_refresh_token`` — the plaintext token is
        never stored.
        """
        record = RefreshToken(
            user_id=user_id,
            token_digest=token_digest,
            jti=jti,
            expires_at=expires_at,
        )
        return await self.create(record)

    async def get_by_digest(self, token_digest: str) -> Optional[RefreshToken]:
        """Fetch a refresh-token record by its SHA-256 digest."""
        stmt = select(RefreshToken).where(RefreshToken.token_digest == token_digest)
        return await self.session.scalar(stmt)

    async def get_by_jti(self, jti: str) -> Optional[RefreshToken]:
        """Fetch a refresh-token record by its ``jti`` claim."""
        stmt = select(RefreshToken).where(RefreshToken.jti == jti)
        return await self.session.scalar(stmt)

    async def revoke(self, record: RefreshToken) -> None:
        """Mark a refresh-token record as revoked (flush only)."""
        record.revoked_at = datetime.now(timezone.utc)
        await self.session.flush()

    async def mark_replaced(self, record: RefreshToken, replaced_by_id: str) -> None:
        """Record which new refresh token replaced this one (D6, flush only)."""
        record.replaced_by_id = replaced_by_id
        await self.session.flush()

    def is_active(self, record: RefreshToken) -> bool:
        """Data-level check: not revoked and not expired (no DB call)."""
        now = datetime.now(timezone.utc)
        return record.revoked_at is None and record.expires_at > now