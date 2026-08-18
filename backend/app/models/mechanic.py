"""Mechanic catalog models (``mechanics`` + attribute child tables).

Implements the authoritative ``docs/backend/database/schema.sql`` tables:

- ``mechanics`` (L225): id TEXT PK (``m*``), name, rating, review_count,
  experience_years, distance_km, eta_minutes, is_available, price_starting,
  phone, about, is_verified.
- ``mechanic_skills`` (L240): composite PK (mechanic_id, skill).
- ``mechanic_languages`` (L241): composite PK (mechanic_id, language).
- ``mechanic_working_hours`` (L242): composite PK (mechanic_id, day);
  day TEXT, open/close TEXT.

Owner-scoped FKs (``mechanic_skills/languages/working_hours.mechanic_id``)
use ``ondelete=CASCADE`` — the same deliberate strengthening of the frozen
schema's default (NO ACTION) that Task 4 applied to conversations, so deleting
a mechanic cleans its attribute rows.
"""

from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    Boolean,
    ForeignKey,
    Integer,
    Numeric,
    PrimaryKeyConstraint,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Mechanic(Base):
    """A mechanic catalog entry (authoritative ``mechanics``)."""

    __tablename__ = "mechanics"

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    name: Mapped[str] = mapped_column(Text, nullable=False)
    rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2), nullable=True)
    review_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    experience_years: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    distance_km: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    eta_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_available: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), default=True
    )
    price_starting: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    about: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )

    # --- Relationships (lazy, no eager loading) ---
    skills: Mapped[list["MechanicSkill"]] = relationship(
        back_populates="mechanic",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    languages: Mapped[list["MechanicLanguage"]] = relationship(
        back_populates="mechanic",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    working_hours: Mapped[list["MechanicWorkingHour"]] = relationship(
        back_populates="mechanic",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    services_offered: Mapped[list["MechanicServiceOffered"]] = relationship(
        back_populates="mechanic",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    reviews: Mapped[list["MechanicReview"]] = relationship(
        back_populates="mechanic",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    bookings: Mapped[list["MechanicBooking"]] = relationship(
        back_populates="mechanic", passive_deletes=True
    )


class MechanicSkill(Base):
    """A skill label on a mechanic (composite-key child of ``mechanics``)."""

    __tablename__ = "mechanic_skills"

    __table_args__ = (
        PrimaryKeyConstraint("mechanic_id", "skill", name="pk_mechanic_skills"),
    )

    mechanic_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanics.id",
            name="fk_mechanic_skills_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    skill: Mapped[str] = mapped_column(Text, nullable=False)

    mechanic: Mapped["Mechanic"] = relationship(back_populates="skills")


class MechanicLanguage(Base):
    """A language spoken by a mechanic (composite-key child of ``mechanics``)."""

    __tablename__ = "mechanic_languages"

    __table_args__ = (
        PrimaryKeyConstraint("mechanic_id", "language", name="pk_mechanic_languages"),
    )

    mechanic_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanics.id",
            name="fk_mechanic_languages_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    language: Mapped[str] = mapped_column(Text, nullable=False)

    mechanic: Mapped["Mechanic"] = relationship(back_populates="languages")


class MechanicWorkingHour(Base):
    """One open/close window per day for a mechanic.

    The database stays normalized per schema.sql (day, open, close rows);
    a grouped representation (``{"Mon-Fri": "8:00 AM - 8:00 PM"}``) is a
    service/schema-layer concern (D6-5), never stored here.
    """

    __tablename__ = "mechanic_working_hours"

    __table_args__ = (
        PrimaryKeyConstraint("mechanic_id", "day", name="pk_mechanic_working_hours"),
    )

    mechanic_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanics.id",
            name="fk_mechanic_working_hours_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    day: Mapped[str] = mapped_column(Text, nullable=False)
    open: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    close: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    mechanic: Mapped["Mechanic"] = relationship(back_populates="working_hours")


# bottom-imports for relationship resolution (mirror existing model files)
from app.models.mechanic_booking import MechanicBooking  # noqa: E402,F401
from app.models.mechanic_review import MechanicReview  # noqa: E402,F401
from app.models.mechanic_service import MechanicServiceOffered  # noqa: E402,F401