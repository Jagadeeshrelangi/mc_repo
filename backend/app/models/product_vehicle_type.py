"""Product vehicle type mapping model (``product_vehicle_types`` table).

Implements the authoritative ``docs/backend/database/schema.sql`` table:
- ``product_vehicle_types``: composite PK (product_id, vehicle_type);
  product_id TEXT FK → products(id), vehicle_type TEXT.
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


class ProductVehicleType(Base):
    """Supported vehicle type for a product (authoritative ``product_vehicle_types``)."""

    __tablename__ = "product_vehicle_types"

    __table_args__ = (
        PrimaryKeyConstraint("product_id", "vehicle_type", name="pk_product_vehicle_types"),
    )

    product_id: Mapped[str] = mapped_column(
        Text,
        ForeignKey("products.id", name="fk_product_vehicle_types_product_id_products", ondelete="CASCADE"),
        primary_key=True,
    )
    vehicle_type: Mapped[str] = mapped_column(Text, primary_key=True)

    # --- Relationships ---
    product: Mapped["Product"] = relationship(
        "Product",
        back_populates="vehicle_types",
    )
