"""Product specification model (``product_specifications`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``product_specifications``: id UUID PK, product_id TEXT FK → products(id),
  label, value, sort_order.
"""

from typing import TYPE_CHECKING

from sqlalchemy import (
    ForeignKey,
    Index,
    Integer,
    Text,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.product import Product


class ProductSpecification(Base):
    """A specification row for a marketplace product (authoritative ``product_specifications``)."""

    __tablename__ = "product_specifications"

    __table_args__ = (
        Index("ix_product_specifications_product_id", "product_id"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    product_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("products.id", name="fk_product_specifications_product_id_products", ondelete="CASCADE"),
        nullable=False,
    )

    label: Mapped[str] = mapped_column(Text, nullable=False)
    value: Mapped[str] = mapped_column(Text, nullable=False)
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"), default=0
    )

    # --- Relationships ---
    product: Mapped["Product"] = relationship(
        "Product",
        back_populates="specifications",
    )
