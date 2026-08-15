"""User model (``users`` table).

Mirrors the authoritative ``docs/backend/database/schema.sql`` identity fields
and adds the Sprint 2 Task 3 authentication fields (D3): ``role``,
``is_active``, ``is_verified``, ``last_login_at``, ``failed_login_attempts``,
``lockout_at``.
"""

from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Text,
    UniqueConstraint,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class UserRole:
    """Valid ``users.role`` values (D3). Stored as TEXT with a CHECK constraint."""

    CUSTOMER = "customer"
    MECHANIC = "mechanic"
    ADMIN = "admin"

    VALUES = (CUSTOMER, MECHANIC, ADMIN)


class User(Base):
    """Application user account.

    Identity fields follow the authoritative schema; authentication fields
    follow D3. ``role`` defaults to ``customer``, accounts are created active
    and unverified, and lockout/timestamp columns are nullable.
    """

    __tablename__ = "users"

    __table_args__ = (
        UniqueConstraint("email", name="uq_users_email"),
        UniqueConstraint("phone", name="uq_users_phone"),
        CheckConstraint(
            "membership_tier IN ('free', 'pro')",
            name="ck_users_membership_tier",
        ),
        CheckConstraint(
            "role IN ('customer', 'mechanic', 'admin')",
            name="ck_users_role",
        ),
        Index("ix_users_email", "email"),
        Index("ix_users_phone", "phone"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- Identity fields (authoritative schema) ---
    name: Mapped[str] = mapped_column(Text, nullable=False)
    email: Mapped[str] = mapped_column(Text, nullable=False)
    phone: Mapped[str] = mapped_column(Text, nullable=False)
    password_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    date_of_birth: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    gender: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    membership_tier: Mapped[str] = mapped_column(
        Text, nullable=False, server_default=text("'free'")
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    emergency_contact_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    emergency_contact_relation: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    emergency_contact_phone: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    # --- Authentication fields (D3) ---
    role: Mapped[str] = mapped_column(
        Text, nullable=False, server_default=text("'customer'")
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true")
    )
    is_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    last_login_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    failed_login_attempts: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0")
    )
    lockout_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # --- Relationships ---
    # lazy="select" (default) keeps refresh tokens off automatically-loaded
    # user graphs; they are only fetched when explicitly accessed.
    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


from app.models.refresh_token import RefreshToken  # noqa: E402  (avoid circular import)