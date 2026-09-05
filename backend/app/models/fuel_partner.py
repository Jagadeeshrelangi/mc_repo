"""Fuel delivery partner / driver model (``fuel_partners`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``fuel_partners``: id TEXT PK, name, phone, rating, rating_count, distance_km,
  eta_minutes, is_available, vehicle_number, vehicle_model.
"""

from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    Boolean,
    Integer,
    Numeric,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class FuelPartner(Base):
    """A fuel delivery partner / driver (authoritative ``fuel_partners``)."""

    __tablename__ = "fuel_partners"

    id: Mapped[str] = mapped_column(Text, primary_key=True)

    name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    rating: Mapped[Optional[Decimal]] = mapped_column(Numeric(3, 2), nullable=True)
    rating_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    distance_km: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2), nullable=True)
    eta_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_available: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    vehicle_number: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vehicle_model: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
