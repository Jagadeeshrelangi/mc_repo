"""Cross-domain unified user activity ledger model (``order_entries`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``order_entries``: id TEXT PK, user_id UUID FK → users(id), name, brand,
  quantity, price, type, status, occurred_at, source.
- CHECK constraints:
  - ``type IN ('parts', 'mechanic', 'fuel', 'aiReport')``
  - ``status IN ('Pending', 'Delivered', 'Completed', 'In Progress', 'Cancelled')``
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    Text,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class OrderEntry(Base):
    """A cross-domain activity ledger row for unified order tracking (authoritative ``order_entries``)."""

    __tablename__ = "order_entries"

    __table_args__ = (
        Index("ix_order_entries_user_id", "user_id"),
        CheckConstraint(
            "type IN ('parts', 'mechanic', 'fuel', 'aiReport')",
            name="ck_order_entries_type",
        ),
        CheckConstraint(
            "status IN ('Pending', 'Delivered', 'Completed', 'In Progress', 'Cancelled')",
            name="ck_order_entries_status",
        ),
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("users.id", name="fk_order_entries_user_id_users", ondelete="CASCADE"),
        nullable=False,
    )

    name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    brand: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    quantity: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2), nullable=True)
    type: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(Text, nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    source: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
