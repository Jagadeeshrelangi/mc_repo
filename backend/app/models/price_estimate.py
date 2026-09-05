"""Price estimate model (``price_estimates`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``price_estimates``: fuel_order_id TEXT PK/FK → fuel_orders(id), fuel_cost,
  delivery_charge, platform_fee, taxes, grand_total, eta_minutes.
"""

from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    ForeignKey,
    Integer,
    Numeric,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.fuel_order import FuelOrder


class PriceEstimate(Base):
    """Financial price breakdown for a fuel order (authoritative ``price_estimates``)."""

    __tablename__ = "price_estimates"

    fuel_order_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("fuel_orders.id", name="fk_price_estimates_fuel_order_id_fuel_orders", ondelete="CASCADE"),
        primary_key=True,
    )

    fuel_cost: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    delivery_charge: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    platform_fee: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    taxes: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    grand_total: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    eta_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # --- Relationships ---
    fuel_order: Mapped["FuelOrder"] = relationship(
        "FuelOrder",
        back_populates="price_estimate",
    )
