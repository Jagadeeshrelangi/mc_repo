"""Mechanic service catalog models (``mechanic_services`` + ``mechanic_service_offered``).

Implements the authoritative ``docs/backend/database/schema.sql`` tables:

- ``mechanic_services`` (L244): id TEXT PK (``svc_*``), name, icon, price
  NUMERIC(12,2), estimated_minutes, description. A global service lookup —
  per-mechanic availability is the M:N junction ``mechanic_service_offered``.
- ``mechanic_service_offered`` (L253): composite PK (mechanic_id, service_id)
  linking a mechanic to the services it offers.

Junction FKs use ``ondelete=CASCADE`` (both sides), matching the Task 4
convention of cleaning owner-scoped rows.
"""

from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    ForeignKey,
    Integer,
    Numeric,
    PrimaryKeyConstraint,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class MechanicService(Base):
    """A bookable service (authoritative ``mechanic_services``, ``svc_*``)."""

    __tablename__ = "mechanic_services"

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    name: Mapped[str] = mapped_column(Text, nullable=False)
    icon: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    estimated_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Relationships (lazy, no eager loading) ---
    offered_by: Mapped[list["MechanicServiceOffered"]] = relationship(
        back_populates="service",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    bookings: Mapped[list["MechanicBooking"]] = relationship(
        back_populates="service", passive_deletes=True
    )


class MechanicServiceOffered(Base):
    """M:N link between a mechanic and a service it offers."""

    __tablename__ = "mechanic_service_offered"

    __table_args__ = (
        PrimaryKeyConstraint(
            "mechanic_id", "service_id", name="pk_mechanic_service_offered"
        ),
    )

    mechanic_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanics.id",
            name="fk_mechanic_service_offered_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    service_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanic_services.id",
            name="fk_mechanic_service_offered_service_id_mechanic_services",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    mechanic: Mapped["Mechanic"] = relationship(back_populates="services_offered")
    service: Mapped["MechanicService"] = relationship(back_populates="offered_by")


from app.models.mechanic_booking import MechanicBooking  # noqa: E402,F401
from app.models.mechanic import Mechanic  # noqa: E402,F401