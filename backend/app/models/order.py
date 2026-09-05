"""Marketplace order model (``orders`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``orders``: id UUID PK, user_id UUID FK → users(id), external_id TEXT UNIQUE,
  address, payment_method, subtotal, discount, delivery, tax, grand_total,
  status, created_at.

Relationships:
- ``items``: 1:N with OrderItem
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
    UniqueConstraint,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.order_item import OrderItem


class Order(Base):
    """A customer purchase order for marketplace parts (authoritative ``orders``)."""

    __tablename__ = "orders"

    __table_args__ = (
        UniqueConstraint("external_id", name="uq_orders_external_id"),
        Index("ix_orders_user_id", "user_id"),
        Index("ix_orders_status", "status"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("users.id", name="fk_orders_user_id_users", ondelete="CASCADE"),
        nullable=False,
    )

    external_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    payment_method: Mapped[str] = mapped_column(Text, nullable=False)

    subtotal: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    discount: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    delivery: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    tax: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    grand_total: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)

    status: Mapped[str] = mapped_column(
        Text, nullable=False, server_default=text("'Pending'"), default="Pending"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    # --- Relationships ---
    items: Mapped[list["OrderItem"]] = relationship(
        "OrderItem",
        back_populates="order",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
