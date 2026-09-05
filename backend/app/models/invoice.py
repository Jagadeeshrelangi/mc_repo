"""Fuel order invoice model (``invoices`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``invoices``: invoice_id TEXT PK, order_id TEXT UNIQUE FK → fuel_orders(id),
  created_at, fuel_type, quantity, price_per_litre, fuel_cost, delivery_charge,
  platform_fee, taxes, grand_total, partner_name, vehicle_number.
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Numeric,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.fuel_order import FuelOrder


class Invoice(Base):
    """A finalized invoice attached to a completed fuel order (authoritative ``invoices``)."""

    __tablename__ = "invoices"

    __table_args__ = (
        UniqueConstraint("order_id", name="uq_invoices_order_id"),
    )

    invoice_id: Mapped[str] = mapped_column(Text, primary_key=True)

    order_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("fuel_orders.id", name="fk_invoices_order_id_fuel_orders", ondelete="CASCADE"),
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    fuel_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    quantity: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    price_per_litre: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    fuel_cost: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    delivery_charge: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    platform_fee: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    taxes: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    grand_total: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    partner_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vehicle_number: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Relationships ---
    fuel_order: Mapped["FuelOrder"] = relationship(
        "FuelOrder",
        back_populates="invoice",
    )
