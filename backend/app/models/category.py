"""Product category catalog model (``categories`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``categories``: id TEXT PK, name, icon, sort_order.
"""

from typing import TYPE_CHECKING

from sqlalchemy import (
    Integer,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.product import Product
    from app.models.offer import Offer


class Category(Base):
    """An auto parts / accessories catalog category (authoritative ``categories``)."""

    __tablename__ = "categories"

    id: Mapped[str] = mapped_column(Text, primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    icon: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"), default=0
    )

    # --- Relationships ---
    products: Mapped[list["Product"]] = relationship(
        "Product",
        back_populates="category",
    )

    offers: Mapped[list["Offer"]] = relationship(
        "Offer",
        back_populates="category",
    )
