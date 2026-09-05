"""Marketplace discount coupon model (``coupons`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``coupons``: id TEXT PK, code TEXT UNIQUE, title, description, type, value,
  max_discount, min_order_value, valid_from, valid_until.
- CHECK constraint: ``type IN ('percent', 'freeDelivery')``.
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Numeric,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Coupon(Base):
    """A promotional coupon code (authoritative ``coupons``)."""

    __tablename__ = "coupons"

    __table_args__ = (
        UniqueConstraint("code", name="uq_coupons_code"),
        CheckConstraint(
            "type IN ('percent', 'freeDelivery')",
            name="ck_coupons_type",
        ),
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)
    code: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    title: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    value: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 2), nullable=True)
    max_discount: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    min_order_value: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    valid_from: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    valid_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
