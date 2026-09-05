"""Fuel station catalog model (``fuel_stations`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``fuel_stations``: id TEXT PK, name, brand, rating, rating_count, distance_km,
  eta_minutes, price_per_litre, availability, is_open, address, latitude, longitude.
"""

from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Integer,
    Numeric,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class FuelStation(Base):
    """A partner fuel station (authoritative ``fuel_stations``)."""

    __tablename__ = "fuel_stations"

    __table_args__ = (
        CheckConstraint(
            "availability IN ('available', 'low', 'outOfStock')",
            name="ck_fuel_stations_availability",
        ),
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    brand: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2), nullable=True)
    rating_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    distance_km: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    eta_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    price_per_litre: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    availability: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_open: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
    longitude: Mapped[Optional[Decimal]] = mapped_column(Numeric(9, 6), nullable=True)
