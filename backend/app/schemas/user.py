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
    emergency_contact_relation: Optional[str] = Field(None, description="Emergency contact relation (if set).")
    emergency_contact_phone: Optional[str] = Field(None, description="Emergency contact phone (if set).")

    model_config = ConfigDict(from_attributes=True)


class UserProfileUpdate(BaseModel):
    """Owner-writable profile fields (Sprint 2, Task 5).

    Explicit whitelist contract for ``PATCH /api/v1/users/me``: ONLY the safe
    profile fields listed below may be written by the account owner. Identity
    (``id``, ``email``, ``phone``), security (``role``, ``is_active``,
    ``is_verified``, ``password_hash``, ``failed_login_attempts``,
    ``lockout_at``, ``last_login_at``), billing (``membership_tier``) and audit
    (``created_at``, ``updated_at``) fields are intentionally absent from the
    writable contract — Pydantic rejects them rather than silently ignoring
    them (``extra="forbid"``), preventing mass assignment.
    """

    name: Optional[str] = Field(
        None,
        min_length=3,
        max_length=100,
        description="Full display name of the user.",
        example="Jagadeesh Gowda",
    )
    date_of_birth: Optional[date] = Field(
        None,
        description="Date of birth (optional).",
    )
    gender: Optional[str] = Field(
        None,
        max_length=20,
        description="Gender (optional).",
    )
    emergency_contact_name: Optional[str] = Field(
        None,
        max_length=100,
        description="Emergency contact name (optional).",
    )
    emergency_contact_relation: Optional[str] = Field(
        None,
        max_length=50,
        description="Emergency contact relation (optional).",
    )
    emergency_contact_phone: Optional[str] = Field(
        None,
        max_length=16,
        pattern=r"^\+?[0-9]{10,15}$",
        description="Emergency contact phone (optional).",
    )

    model_config = ConfigDict(extra="forbid")


__all__ = ["UserOut", "UserProfileUpdate", "UserRoleLiteral"]