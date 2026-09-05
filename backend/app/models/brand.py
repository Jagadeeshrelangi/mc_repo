"""Product brand catalog model (``brands`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``brands``: id TEXT PK, name.
"""

from typing import TYPE_CHECKING

from sqlalchemy import (
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.product import Product


class Brand(Base):
    """An auto parts / accessories manufacturer brand (authoritative ``brands``)."""

    __tablename__ = "brands"

    id: Mapped[str] = mapped_column(Text, primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)

    # --- Relationships ---
    products: Mapped[list["Product"]] = relationship(
        "Product",
        back_populates="brand",
    )
