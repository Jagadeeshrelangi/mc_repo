"""Authentication business logic (Sprint 2, Task 3, Stage 6).

``AuthService`` coordinates the schemas → security engine → repositories →
database transaction layers. It owns authentication business rules and
transaction boundaries, but contains NO route decorators, HTTP handling,
SQLAlchemy query construction, raw session creation, password hashing, or JWT
implementation — those live in the schema/security/repository layers.

Transaction ownership
---------------------
Repositories flush() without committing (see ``app.repositories.base``).
This service owns the commit/rollback boundary:
- successful multi-step workflows flush then ``session.commit()`` once;
- failures ``session.rollback()`` and re-raise the controlled error.

The service is request-scoped: construct one per request with the ``AsyncSession``
provided by ``app.api.deps.get_db`` (or the repositories for that session). No
module-level singleton is created because the session is per-request.
"""

from datetime import datetime, timedelta, timezone
from typing import Optional

from app.core import security
from app.core.config import settings
from app.core.exceptions import (
    EntityNotFoundException,
    InvalidInputException,
    UnauthorizedException,
)
from app.models.user import UserRole
from app.repositories.users import RefreshTokenRepository, UserRepository
from app.schemas.auth import (
    ForgotPasswordResponse,
    LogoutResponse,
    RegisterRequest,
    TokenResponse,
)
from app.schemas.user import UserOut

# --- Lockout policy (D9) ----------------------------------------------------

# Approved policy: 5 failed attempts within 10 minutes → temporary lockout.
MAX_FAILED_LOGIN_ATTEMPTS: int = 5
LOCKOUT_DURATION: timedelta = timedelta(minutes=10)

# --- Generic, enumeration-safe failure messages ------------------------------

# Identical for unknown identifier, wrong password, inactive account, or
# locked account — never reveals WHICH condition failed (D9).
GENERIC_LOGIN_FAILURE: str = "Invalid email/phone or password"

# Generic for revoked/consumed/expired/invalid refresh tokens (D6).
GENERIC_REFRESH_FAILURE: str = "Invalid or expired refresh token"


class AuthService:
    """Coordinates authentication workflows across layers.

    Constructor-injected dependencies: the request ``AsyncSession`` and the
    repositories bound to it (created internally if not provided, which keeps
    tests able to inject fakes that exercise coordination only).
    """

    def __init__(
        self,
        session,
        user_repository: Optional[UserRepository] = None,
        refresh_token_repository: Optional[RefreshTokenRepository] = None,
    ) -> None:
        self.session = session
        self.user_repo = user_repository or UserRepository(session)
        self.refresh_token_repo = refresh_token_repository or RefreshTokenRepository(session)

    # --- Registration -------------------------------------------------------

    async def register(self, payload: RegisterRequest) -> UserOut:
        """Register a new user.

        Flow: uniqueness checks → hash password (D4) → create via repository →
        commit → safe user representation. Defaults per D3: role=customer,
        is_active=true, is_verified=false, failed_login_attempts=0.
        """
        try:
            if await self.user_repo.get_by_email(payload.email) is not None:
                raise InvalidInputException("An account with this email already exists.")
            if await self.user_repo.get_by_phone(payload.phone) is not None:
                raise InvalidInputException("An account with this phone number already exists.")

            password_hash = security.hash_password(payload.password)
            user = await self.user_repo.create_user(
                name=payload.name,
                email=payload.email,
                phone=payload.phone,
                password_hash=password_hash,
                role=UserRole.CUSTOMER,
            )
            user.is_active = True
            user.is_verified = False
            user.failed_login_attempts = 0

            await self.session.commit()
            return UserOut.model_validate(user)
        except Exception:
            await self.session.rollback()
            raise

    # --- Login --------------------------------------------------------------

    async def login(self, identifier: str, password: str) -> TokenResponse:
        """Authenticate by email OR phone (approved identifier contract).

        On success: clear lockout, record successful login, issue access +
        refresh tokens, store only the SHA-256 digest of the refresh token
        (D2), commit once, return TokenResponse.

        On failure: generic, enumeration-safe ``UnauthorizedException`` — never
        reveals whether the identifier, password, account state, or lockout was
        the cause (D9).
        """
        try:
            user = await self._find_by_identifier(identifier)
            if user is None or not user.password_hash or not user.is_active:
                raise UnauthorizedException(GENERIC_LOGIN_FAILURE)

            now = datetime.now(timezone.utc)

            # D9 lockout: while lockout is active, deny generically.
            if user.lockout_at is not None:
                if now - user.lockout_at < LOCKOUT_DURATION:
                    raise UnauthorizedException(GENERIC_LOGIN_FAILURE)
                # Lockout expired → clear stale lockout state and allow auth.
                await self.user_repo.unlock_account(user)

            if not security.verify_password(password, user.password_hash):
                await self.user_repo.record_failed_login(user)
                if user.failed_login_attempts >= MAX_FAILED_LOGIN_ATTEMPTS:
                    await self.user_repo.lock_account(user, now)
                # Persist the failure counter so lockout survives this request.
                await self.session.commit()
                raise UnauthorizedException(GENERIC_LOGIN_FAILURE)

            # Successful authentication → reset failures + lockout, mark login.
            await self.user_repo.unlock_account(user)
            await self.user_repo.record_successful_login(user)

            access_token, refresh_token, jti, expires_at = self._issue_tokens(user.id)
            await self.refresh_token_repo.create_refresh_token(
                user_id=user.id,
                token_digest=security.hash_refresh_token(refresh_token),
                jti=jti,
                expires_at=expires_at,
            )

            await self.session.commit()
            return self._build_token_response(access_token, refresh_token)
        except Exception:
            await self.session.rollback()
            raise

    # --- Refresh rotation (D6) ----------------------------------------------

    async def refresh(self, refresh_token: str) -> TokenResponse:
        """Rotate a refresh token into a new access + refresh pair.

        Flow: verify signature/expiry/type → hash digest → find record →
        verify active → load user → verify active → revoke old → issue new
        pair → store new digest → record replacement lineage → commit once.
        Everything is inside ONE transaction; nothing is committed halfway.

        Old/revoked/consumed/expired tokens and access tokens presented as
        refresh tokens all produce a generic authentication failure.
        """
        try:
            try:
                security.verify_refresh_token(refresh_token)
            except security.SecurityError as exc:
                raise UnauthorizedException(GENERIC_REFRESH_FAILURE) from exc

            digest = security.hash_refresh_token(refresh_token)
            record = await self.refresh_token_repo.get_by_digest(digest)
            if record is None or not self.refresh_token_repo.is_active(record):
                raise UnauthorizedException(GENERIC_REFRESH_FAILURE)

            user = await self.user_repo.get(record.user_id)
            if user is None or not user.is_active:
                raise UnauthorizedException(GENERIC_REFRESH_FAILURE)

            # Rotate: revoke old, create replacement, link lineage (atomic).
            await self.refresh_token_repo.revoke(record)

            access_token, new_refresh_token, jti, expires_at = self._issue_tokens(user.id)
            new_record = await self.refresh_token_repo.create_refresh_token(
                user_id=user.id,
                token_digest=security.hash_refresh_token(new_refresh_token),
                jti=jti,
                expires_at=expires_at,
            )
            await self.refresh_token_repo.mark_replaced(record, new_record.id)

            await self.session.commit()
            return self._build_token_response(access_token, new_refresh_token)
        except Exception:
            await self.session.rollback()
            raise

    # --- Logout -------------------------------------------------------------

    async def logout(self, refresh_token: str) -> LogoutResponse:
        """Terminate the refresh session (idempotent, no info leak).

        Best-effort structural verification is attempted but never raises to
        the caller; revocation is by digest lookup so unknown or already-
        revoked tokens are handled safely. No credential is echoed.
        """
        try:
            try:
                security.verify_refresh_token(refresh_token)
            except security.SecurityError:
                pass  # still attempt revocation by digest; never leak existence

            digest = security.hash_refresh_token(refresh_token)
            record = await self.refresh_token_repo.get_by_digest(digest)
            if record is not None:
                await self.refresh_token_repo.revoke(record)
                await self.session.commit()

            return LogoutResponse(message="Successfully logged out")
        except Exception:
            await self.session.rollback()
            raise

    # --- Current user -------------------------------------------------------

    async def get_current_user(self, user_id: str) -> UserOut:
        """Return a safe public representation of the active user.

        Raises NOT_FOUND if the user does not exist and UNAUTHORIZED if the
        account is inactive. NEVER exposes password_hash, token digests, JWT
        secrets, failed_login_attempts, lockout_at, or other internal state
        (the UserOut projection omits them).
        """
        user = await self.user_repo.get(user_id)
        if user is None:
            raise EntityNotFoundException("User not found.")
        if not user.is_active:
            raise UnauthorizedException("Account is not active.")
        return UserOut.model_validate(user)

    # --- Account verification (D7) — documented boundary --------------------

    async def verify(self, token: str) -> None:
        """Account verification (STOP at approved-schema boundary).

        D7 requires a verification-token persistence/validation structure to
        implement a secure ``/verify`` state transition. The approved Task 3
        database scope (D13) contains ONLY the users auth fields + the
        ``refresh_tokens`` table — there is no verification-token storage, and
        the security engine defines only access/refresh token types. Creating a
        table or a verification token type is out of the approved scope.

        Rather than inventing an unapproved table or provider (F1), this method
        documents the dependency and fails loudly until a verification-token
        structure is approved.
        """
        raise NotImplementedError(
            "Account verification requires a verification-token persistence "
            "structure that is NOT part of the approved Task 3 database scope "
            "(D13: users auth fields + refresh_tokens only). Stop at this "
            "boundary until a verification-token table/field is approved (D7/F1)."
        )

    # --- Password reset (D8) — documented boundary --------------------------

    async def forgot_password(self, identifier: str) -> ForgotPasswordResponse:
        """Enumeration-safe forgot-password behavior (D8).

        Returns an identical generic response whether or not the identifier
        exists, and performs no account lookup — avoiding the timing
        side-channel that would leak account existence. Reset-token issuance
        and delivery remain deferred (F2): the approved schema has no reset
        token persistence.
        """
        return ForgotPasswordResponse(
            message="If an account exists, a password reset link has been sent."
        )

    async def reset_password(self, token: str, new_password: str) -> None:
        """Password reset (STOP at approved-schema boundary).

        D8 requires a secure reset-token persistence/validation mechanism.
        The approved Task 3 database scope (D13) does not contain one, and the
        security engine defines only access/refresh token types. Rather than
        inventing storage, this method documents the dependency and fails
        loudly until a reset-token structure is approved (D8/F2).
        """
        raise NotImplementedError(
            "Password reset requires a reset-token persistence/validation "
            "mechanism that is NOT part of the approved Task 3 database scope "
            "(D13: users auth fields + refresh_tokens only). Stop at this "
            "boundary until a reset-token table is approved (D8/F2)."
        )

    # --- Helpers ------------------------------------------------------------

    async def _find_by_identifier(self, identifier: str) -> Optional[object]:
        """Resolve the login identifier to a user (email or phone, D11)."""
        if "@" in identifier:
            return await self.user_repo.get_by_email(identifier)
        return await self.user_repo.get_by_phone(identifier)

    def _issue_tokens(self, user_id: str) -> tuple:
        """Create access + refresh tokens and derive record fields.

        JWT creation and digesting are delegated to the security engine (D2/D5).
        The freshly created refresh token is verified back through the engine to
        obtain its ``jti`` claim and ``exp`` timestamp for DB storage — the
        service never touches JWT internals directly.
        """
        access_token = security.create_access_token(user_id)
        refresh_token = security.create_refresh_token(user_id)
        claims = security.verify_refresh_token(refresh_token)
        expires_at = datetime.fromtimestamp(claims["exp"], tz=timezone.utc)
        return access_token, refresh_token, claims["jti"], expires_at

    def _build_token_response(self, access_token: str, refresh_token: str) -> TokenResponse:
        """Build the TokenResponse; lifetime is config-driven (D5)."""
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )