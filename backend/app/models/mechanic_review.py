"""Mechanic review model (``mechanic_reviews``).

Implements the authoritative ``docs/backend/database/schema.sql`` table
(L269): id TEXT PK (``r*``), mechanic_id FK → mechanics(id), reviewer_name,
rating NUMERIC(3,2), comment, reviewed_at DATE, vehicle.

Owner-scoped FK (``mechanic_reviews.mechanic_id``) uses ``ondelete=CASCADE``
(matching the Task 4 strengthening convention): reviews die with their mechanic.
"""

from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import Date, ForeignKey, Numeric, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class MechanicReview(Base):
    """A public review of a mechanic (authoritative ``mechanic_reviews``)."""

    __tablename__ = "mechanic_reviews"

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    mechanic_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey(
            "mechanics.id",
            name="fk_mechanic_reviews_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    reviewer_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2), nullable=True)
    comment: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    vehicle: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    mechanic: Mapped["Mechanic"] = relationship(back_populates="reviews")


from app.models.mechanic import Mechanic  # noqa: E402,F401