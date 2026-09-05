"""Marketplace promotional offer model (``offers`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``offers``: id TEXT PK, title, subtitle, code, category_id TEXT FK → categories(id),
  gradient_start, gradient_end.
"""

from typing import Optional, TYPE_CHECKING

from sqlalchemy import (
    ForeignKey,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.category import Category


class Offer(Base):
    """A promotional campaign banner (authoritative ``offers``)."""

    __tablename__ = "offers"

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    title: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    subtitle: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    code: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    category_id: Mapped[Optional[str]] = mapped_column(
        Text,
        ForeignKey("categories.id", name="fk_offers_category_id_categories"),
        nullable=True,
    )

    gradient_start: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gradient_end: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Relationships ---
    category: Mapped[Optional["Category"]] = relationship(
        "Category",
        back_populates="offers",
    )
