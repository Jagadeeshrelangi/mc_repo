"""Marketplace product catalog model (``products`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``products``: id TEXT PK, brand_id TEXT FK → brands(id), category_id TEXT FK → categories(id),
  name, price, mrp, rating, rating_count, stock, image_url, icon, description,
  warranty, delivery_estimate, popularity, age_days, is_featured, is_best_seller,
  is_trending, is_flash_deal, is_recommended, created_at, updated_at.

Relationships:
- ``brand``: Brand
- ``category``: Category
- ``specifications``: 1:N with ProductSpecification
- ``vehicle_types``: 1:N with ProductVehicleType
- ``compatibility``: 1:N with ProductCompatibility
- ``reviews``: 1:N with ProductReview
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.brand import Brand
    from app.models.category import Category
    from app.models.product_specification import ProductSpecification
    from app.models.product_vehicle_type import ProductVehicleType
    from app.models.product_compatibility import ProductCompatibility
    from app.models.product_review import ProductReview


class Product(Base):
    """A marketplace part or accessory (authoritative ``products``)."""

    __tablename__ = "products"

    __table_args__ = (
        Index("ix_products_brand_id", "brand_id"),
        Index("ix_products_category_id", "category_id"),
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    brand_id: Mapped[Optional[str]] = mapped_column(
        Text,
        ForeignKey("brands.id", name="fk_products_brand_id_brands"),
        nullable=True,
    )

    category_id: Mapped[Optional[str]] = mapped_column(
        Text,
        ForeignKey("categories.id", name="fk_products_category_id_categories"),
        nullable=True,
    )

    name: Mapped[str] = mapped_column(Text, nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    mrp: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    rating: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(3, 2), nullable=True, server_default=text("4.0"), default=Decimal("4.0")
    )
    rating_count: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, server_default=text("0"), default=0
    )
    stock: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"), default=0
    )

    image_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    icon: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    warranty: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    delivery_estimate: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    popularity: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, server_default=text("0"), default=0
    )
    age_days: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, server_default=text("0"), default=0
    )

    is_featured: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )
    is_best_seller: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )
    is_trending: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )
    is_flash_deal: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )
    is_recommended: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    # --- Relationships ---
    brand: Mapped[Optional["Brand"]] = relationship(
        "Brand",
        back_populates="products",
    )

    category: Mapped[Optional["Category"]] = relationship(
        "Category",
        back_populates="products",
    )

    specifications: Mapped[list["ProductSpecification"]] = relationship(
        "ProductSpecification",
        back_populates="product",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    vehicle_types: Mapped[list["ProductVehicleType"]] = relationship(
        "ProductVehicleType",
        back_populates="product",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    compatibility: Mapped[list["ProductCompatibility"]] = relationship(
        "ProductCompatibility",
        back_populates="product",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    reviews: Mapped[list["ProductReview"]] = relationship(
        "ProductReview",
        back_populates="product",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
