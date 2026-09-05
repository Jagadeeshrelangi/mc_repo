"""Fuel delivery order model (``fuel_orders`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``fuel_orders``: id TEXT PK, user_id UUID FK → users(id), fuel_type, quantity,
  vehicle_type, vehicle_name, vehicle_number, station_id, station_name, brand,
  price_per_litre, delivery_label, delivery_address, lat, lng, status,
  payment_method, partner_id, created_at.

Relationships:
- ``price_estimate``: 1:1 with PriceEstimate
- ``tracking_events``: 1:N with TrackingEvent
- ``invoice``: 1:1 with Invoice
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    Text,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.price_estimate import PriceEstimate
    from app.models.tracking_event import TrackingEvent
    from app.models.invoice import Invoice


class FuelOrder(Base):
    """A customer fuel delivery order (authoritative ``fuel_orders``)."""

    __tablename__ = "fuel_orders"

    __table_args__ = (
        Index("ix_fuel_orders_user_id", "user_id"),
        Index("ix_fuel_orders_status", "status"),
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    # Owning user FK. Matches ``users.id`` (UUID column).
    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("users.id", name="fk_fuel_orders_user_id_users", ondelete="CASCADE"),
        nullable=False,
    )

    fuel_type: Mapped[str] = mapped_column(Text, nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False)

    # Denormalized snapshot fields captured at order time
    vehicle_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vehicle_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vehicle_number: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    station_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    station_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    brand: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    price_per_litre: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)

    delivery_label: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    delivery_address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    lat: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
    lng: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)

    status: Mapped[str] = mapped_column(Text, nullable=False)
    payment_method: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    partner_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    # --- Relationships ---
    price_estimate: Mapped[Optional["PriceEstimate"]] = relationship(
        "PriceEstimate",
        back_populates="fuel_order",
        uselist=False,
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    tracking_events: Mapped[list["TrackingEvent"]] = relationship(
        "TrackingEvent",
        back_populates="fuel_order",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    invoice: Mapped[Optional["Invoice"]] = relationship(
        "Invoice",
        back_populates="fuel_order",
        uselist=False,
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
