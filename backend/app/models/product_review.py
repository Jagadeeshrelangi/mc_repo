"""Product review model (``product_reviews`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``product_reviews``: id UUID PK, product_id TEXT FK → products(id), author,
  rating, comment, reviewed_at, is_verified_purchase, helpful_count.
"""

from datetime import date
from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    Date,
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
    from app.models.product import Product


class ProductReview(Base):
    """A customer review on a marketplace product (authoritative ``product_reviews``)."""

    __tablename__ = "product_reviews"

    __table_args__ = (
        Index("ix_product_reviews_product_id", "product_id"),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    product_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("products.id", name="fk_product_reviews_product_id_products", ondelete="CASCADE"),
        nullable=False,
    )

    author: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2), nullable=True)
    comment: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_verified_purchase: Mapped[Optional[bool]] = mapped_column(
        Boolean, nullable=True, server_default=text("true"), default=True
    )
    helpful_count: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, server_default=text("0"), default=0
    )

    # --- Relationships ---
    product: Mapped["Product"] = relationship(
        "Product",
        back_populates="reviews",
    )
