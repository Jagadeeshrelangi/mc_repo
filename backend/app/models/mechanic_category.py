"""Mechanic category model (``mechanic_categories``).

Implements the authoritative ``docs/backend/database/schema.sql`` table
(L259): id TEXT PK, name, icon, color, bg_color, description, sort_order.

A standalone lookup used as the home-screen category grid. There is no FK
linking services to categories in the authoritative schema, and the frozen
Flutter ``MechanicCategory`` model carries no ``id`` and no service relation —
so none is added here (no invented links).
"""

from typing import Optional

from sqlalchemy import Integer, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class MechanicCategory(Base):
    """A mechanic category for the discovery grid (``mechanic_categories``)."""

    __tablename__ = "mechanic_categories"

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    name: Mapped[str] = mapped_column(Text, nullable=False)
    icon: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    color: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    bg_color: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"), default=0
    )