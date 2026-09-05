"""Fuel order tracking event model (``tracking_events`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``tracking_events``: id UUID PK, order_id TEXT FK → fuel_orders(id), status,
  partner_lat, partner_lng, distance_remaining, eta_minutes, occurred_at.
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    Text,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.fuel_order import FuelOrder


class TrackingEvent(Base):
    """A milestone / GPS tracking point for a fuel order (authoritative ``tracking_events``)."""

    __tablename__ = "tracking_events"

    __table_args__ = (
        Index("ix_tracking_events_order_id", "order_id"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    order_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("fuel_orders.id", name="fk_tracking_events_order_id_fuel_orders", ondelete="CASCADE"),
        nullable=False,
    )

    status: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    partner_lat: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
    partner_lng: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
    distance_remaining: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    eta_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    # --- Relationships ---
    fuel_order: Mapped["FuelOrder"] = relationship(
        "FuelOrder",
        back_populates="tracking_events",
    )
