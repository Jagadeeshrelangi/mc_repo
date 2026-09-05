"""Product vehicle compatibility mapping model (``product_compatibility`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``product_compatibility``: composite PK (product_id, compatible_with);
  product_id TEXT FK → products(id), compatible_with TEXT.
"""

from typing import TYPE_CHECKING

from sqlalchemy import (
    ForeignKey,
    PrimaryKeyConstraint,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.product import Product


class ProductCompatibility(Base):
    """Compatible vehicle model or family for a product (authoritative ``product_compatibility``)."""

    __tablename__ = "product_compatibility"

    __table_args__ = (
        PrimaryKeyConstraint("product_id", "compatible_with", name="pk_product_compatibility"),
    )

    product_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("products.id", name="fk_product_compatibility_product_id_products", ondelete="CASCADE"),
        primary_key=True,
    )
    compatible_with: Mapped[str] = mapped_column(Text, primary_key=True)

    # --- Relationships ---
    product: Mapped["Product"] = relationship(
        "Product",
        back_populates="compatibility",
    )
