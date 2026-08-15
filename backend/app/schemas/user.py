"""User schemas (Sprint 2, Task 3, Stage 5).

Safe public read/update contracts for a user. NEVER exposes ``password_hash``,
JWT secrets, refresh-token digests, or internal security state.
"""

from datetime import date, datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.user import UserRole

# Single source of truth for roles (D3) — reuses the existing representation;
# no second conflicting enum is created.
UserRoleLiteral = Literal[
    UserRole.CUSTOMER,
    UserRole.MECHANIC,
    UserRole.ADMIN,
]


class UserOut(BaseModel):
    """Safe public user response.

    Pydantic-only projection; excludes ``password_hash``, auth internals
    (``failed_login_attempts``, ``lockout_at``, ``last_login_at``) and any
    credential/token material.
    """

    id: str = Field(..., description="User UUID (string form).")
    name: str = Field(..., description="Display name.")
    email: str = Field(..., description="Login email address.")
    phone: str = Field(..., description="Login phone number.")
    role: UserRoleLiteral = Field(..., description="Account role (D3).")
    is_active: bool = Field(..., description="Whether the account is active.")
    is_verified: bool = Field(..., description="Whether the account is verified (D7).")
    membership_tier: str = Field(..., description="Membership tier (free|pro).")
    joined_at: datetime = Field(..., description="Account creation timestamp.")
    date_of_birth: Optional[date] = Field(None, description="Date of birth (if set).")
    gender: Optional[str] = Field(None, description="Gender (if set).")
    emergency_contact_name: Optional[str] = Field(None, description="Emergency contact name (if set).")

    model_config = ConfigDict(from_attributes=True)


__all__ = ["UserOut", "UserRoleLiteral"]