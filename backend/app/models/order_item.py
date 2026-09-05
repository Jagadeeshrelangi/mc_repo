"""Marketplace order item line model (``order_items`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``order_items``: id UUID PK, order_id UUID FK → orders(id), product_id TEXT,
  product_name TEXT, brand TEXT, quantity INT, unit_price NUMERIC, line_total NUMERIC, image TEXT.
"""

from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
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
    from app.models.order import Order


class OrderItem(Base):
    """An individual line item within a marketplace order (authoritative ``order_items``)."""

    __tablename__ = "order_items"

    __table_args__ = (
        Index("ix_order_items_order_id", "order_id"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    order_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("orders.id", name="fk_order_items_order_id_orders", ondelete="CASCADE"),
        nullable=False,
    )

    product_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    product_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    brand: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    quantity: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    unit_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    line_total: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    image: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Relationships ---
    order: Mapped["Order"] = relationship(
        "Order",
        back_populates="items",
    )
