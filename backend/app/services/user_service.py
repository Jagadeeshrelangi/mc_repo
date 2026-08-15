"""Profile business logic (Sprint 2, Task 5).

``UserService`` coordinates the profile read/update workflow across the
schema → repository → transaction layers. It is request-scoped (construct one
per request with the ``AsyncSession`` from ``app.api.deps.get_db``), mirroring
``AuthService``.

Transaction ownership
---------------------
Repositories flush() without committing (see ``app.repositories.base``). This
service owns the commit/rollback boundary:
- a successful profile update flushes then ``session.commit()`` once;
- failures ``session.rollback()`` and re-raise the controlled error.

Security posture
----------------
- Owner identity is ALWAYS provided by ``get_current_user()``; the service
  never receives (or trusts) a ``user_id`` from the client.
- Only the explicitly whitelisted safe fields may be written. Assignments are
  made one field at a time (never ``user.__dict__.update(payload)``) so mass
  assignment / over-posting of identity, role, authentication state, or billing
  fields is impossible even if an unknown key slips through.
- Responses always go through the ``UserOut`` projection (never
  ``password_hash``, token digests, lockout/failure state, audit timestamps).

This service must NOT generate JWTs, hash passwords, modify roles,
authentication state, membership tier, email, or phone, or perform admin
actions.
"""

from typing import Optional

from app.core.exceptions import (
    EntityNotFoundException,
    UnauthorizedException,
)
from app.models.user import User
from app.repositories.users import UserRepository
from app.schemas.user import UserOut, UserProfileUpdate

# Explicit safe-field whitelist (single source of truth for the PATCH contract).
# Any field NOT in this set is never assigned to the ORM entity.
SAFE_PROFILE_FIELDS = frozenset(
    {
        "name",
        "date_of_birth",
        "gender",
        "emergency_contact_name",
        "emergency_contact_relation",
        "emergency_contact_phone",
    }
)


class UserService:
    """Coordinates owner-scoped profile read/update workflows.

    Constructor-injected dependencies: the request ``AsyncSession`` and the
    ``UserRepository`` bound to it (created internally if not provided, which
    keeps tests able to inject fakes that exercise coordination only).
    """

    def __init__(
        self,
        session,
        user_repository: Optional[UserRepository] = None,
    ) -> None:
        self.session = session
        self.user_repo = user_repository or UserRepository(session)

    # --- Profile read -------------------------------------------------------

    async def get_profile(self, user: User) -> UserOut:
        """Return a safe public representation of the authenticated user.

        The caller (the route) supplies the owner from ``get_current_user()``;
        the user's identity is never re-read from the request. Raises
        NOT_FOUND if the account vanished and UNAUTHORIZED if it was
        deactivated after authentication.
        """
        if user is None:
            raise EntityNotFoundException("User not found.")
        if not user.is_active:
            raise UnauthorizedException("Account is not active.")
        return UserOut.model_validate(user)

    # --- Profile update -----------------------------------------------------

    async def update_profile(self, user: User, payload: UserProfileUpdate) -> UserOut:
        """Apply ONLY the safe whitelisted profile fields and persist once.

        Whitelist-first: the payload schema already restricts to the safe
        fields, and the service re-checks every key against
        ``SAFE_PROFILE_FIELDS`` before assigning (defense in depth). Identity,
        role, authentication state, membership tier, email, phone and audit
        timestamps can never be written through this path.
        """
        try:
            updates = payload.model_dump(exclude_unset=True)
            for field, value in updates.items():
                if field in SAFE_PROFILE_FIELDS:
                    setattr(user, field, value)
            await self.user_repo.update(user)
            await self.session.commit()
            return UserOut.model_validate(user)
        except Exception:
            await self.session.rollback()
            raise