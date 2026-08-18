"""Mechanic booking models (``mechanic_bookings``, ``booking_events``, ``ratings``).

Implements the authoritative ``docs/backend/database/schema.sql`` tables:

- ``mechanic_bookings`` (L279): id UUID PK, user_id UUID FK → users(id),
  mechanic_id TEXT FK → mechanics(id), service_id TEXT FK →
  mechanic_services(id), ``vehicle_id`` (see D6-1), status TEXT NOT NULL,
  address, lat NUMERIC(9,6), lng NUMERIC(9,6), scheduled_at, created_at.
- ``booking_events`` (L293): id UUID PK, booking_id UUID FK → bookings(id),
  status, occurred_at, payload JSONB (live-tracking snapshots).
- ``ratings`` (L301): booking_id UUID PK (1-1 FK → bookings(id)), rating,
  review.

Task 6 decisions applied:

- **D6-1 (vehicles FK):** ``vehicle_id`` is a nullable UUID column WITHOUT a
  foreign key. The ``vehicles`` table is not migrated yet; creating an FK to a
  nonexistent table is forbidden. When the Vehicles module lands, its migration
  may add the proper FK. Documented temporary dependency boundary.
- **D6-2 (booking identifier):** ``id`` stays the authoritative UUID primary
  key (``gen_random_uuid()``). No invented booking-number system.
- **D6-4 (booking status):** stored as TEXT with the seven frozen states and a
  CHECK constraint (``ck_mechanic_bookings_status``), mirroring the existing
  ``ck_users_role`` / ``ck_chat_messages_role`` convention.
- **D6-3 (rating capability):** the ``ratings`` model exists per the
  authoritative schema (1-1 with a booking). API/service enforcement is a
  later stage; no Flutter integration here.

Owner-scoped FKs use ``ondelete=CASCADE`` (matching the Task 4 convention):
``mechanic_bookings.user_id`` (user deletion cleans bookings), and the
booking-scoped children ``booking_events.booking_id`` and
``ratings.booking_id``. ``mechanic_id``/``service_id`` reference catalog rows
and keep the schema's default (NO ACTION) so a booking is never silently
orphaned by catalog changes.
"""

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    Text,
    Uuid,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.mechanic_status import BookingStatus


class MechanicBooking(Base):
    """A customer booking of a mechanic service (``mechanic_bookings``)."""

    __tablename__ = "mechanic_bookings"

    __table_args__ = (
        CheckConstraint(
            "status IN ('requested', 'accepted', 'mechanicAssigned', 'enRoute', "
            "'arrived', 'completed', 'cancelled')",
            name="ck_mechanic_bookings_status",
        ),
        Index("ix_mechanic_bookings_user_id", "user_id"),
        Index("ix_mechanic_bookings_mechanic_id", "mechanic_id"),
        Index("ix_mechanic_bookings_service_id", "service_id"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # Owner (authenticated customer). FK → users(id), CASCADE (Task 4 convention).
    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey(
            "users.id",
            name="fk_mechanic_bookings_user_id_users",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    # Catalog references — schema default (NO ACTION): a booking never
    # disappears when a mechanic/service catalog row changes.
    mechanic_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanics.id",
            name="fk_mechanic_bookings_mechanic_id_mechanics",
        ),
        nullable=False,
    )
    service_id: Mapped[Optional[str]] = mapped_column(
        Text,
        ForeignKey(
            "mechanic_services.id",
            name="fk_mechanic_bookings_service_id_mechanic_services",
        ),
        nullable=True,
    )

    # D6-1: nullable UUID WITHOUT FK (vehicles table not migrated yet).
    vehicle_id: Mapped[Optional[str]] = mapped_column(Uuid(as_uuid=False), nullable=True)

    status: Mapped[str] = mapped_column(Text, nullable=False, default=BookingStatus.REQUESTED.value)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    lat: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
    lng: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
    scheduled_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        default=lambda: datetime.now(timezone.utc),
    )

    # --- Relationships (lazy, no eager loading) ---
    user: Mapped["User"] = relationship(passive_deletes=True)
    mechanic: Mapped["Mechanic"] = relationship(back_populates="bookings")
    service: Mapped[Optional["MechanicService"]] = relationship(
        back_populates="bookings", passive_deletes=True
    )
    events: Mapped[list["BookingEvent"]] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="BookingEvent.occurred_at",
    )
    rating: Mapped[Optional["Rating"]] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        passive_deletes=True,
        uselist=False,
    )


class BookingEvent(Base):
    """One persisted snapshot of a booking lifecycle (``booking_events``)."""

    __tablename__ = "booking_events"

    __table_args__ = (
        Index("ix_booking_events_booking_id", "booking_id"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    booking_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey(
            "mechanic_bookings.id",
            name="fk_booking_events_booking_id_mechanic_bookings",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    status: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        default=lambda: datetime.now(timezone.utc),
    )
    payload: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB, nullable=True)

    booking: Mapped["MechanicBooking"] = relationship(back_populates="events")


class Rating(Base):
    """A post-service rating of a booking (``ratings``, 1-1 with a booking).

    D6-3: model capability only (per authoritative schema). The one-rating-per-
    booking invariant is enforced structurally by the ``booking_id`` primary
    key; ownership/completed-state enforcement belongs to the service layer in
    a later stage.
    """

    __tablename__ = "ratings"

    booking_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey(
            "mechanic_bookings.id",
            name="fk_ratings_booking_id_mechanic_bookings",
            ondelete="CASCADE",
        ),
        primary_key=True,
    )
    rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2), nullable=True)
    review: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    booking: Mapped["MechanicBooking"] = relationship(back_populates="rating")


from app.models.mechanic import Mechanic  # noqa: E402,F401
from app.models.mechanic_service import MechanicService  # noqa: E402,F401
from app.models.user import User  # noqa: E402,F401