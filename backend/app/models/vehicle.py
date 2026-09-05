"""Vehicle model (``vehicles`` table).

Mirrors the Supabase ``vehicles`` table for user vehicle ownership, specifications,
maintenance reminders, and default vehicle preference.
"""

import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    SmallInteger,
    Text,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.user import User


class Vehicle(Base):
    """User-owned vehicle entity matching public.vehicles table."""

    __tablename__ = "vehicles"

    __table_args__ = (
        CheckConstraint(
            "health_score >= 0 AND health_score <= 100",
            name="vehicles_health_score_check",
        ),
        Index("ix_vehicles_user_id", "user_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    brand: Mapped[str] = mapped_column(Text, nullable=False)
    model: Mapped[str] = mapped_column(Text, nullable=False)
    registration: Mapped[str] = mapped_column(Text, nullable=False)
    fuel_type: Mapped[str] = mapped_column(Text, nullable=False)
    insurance_expiry: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    puc_expiry: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    service_due_km: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    service_due_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_default: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default=text("false")
    )
    health_score: Mapped[Optional[int]] = mapped_column(
        SmallInteger, nullable=True, default=80
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        onupdate=text("now()"),
    )

    # Optional relationship to user
    user: Mapped["User"] = relationship("User", backref="vehicles", lazy="select")
