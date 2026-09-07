"""Pydantic v2 schemas for the canonical Unified Orders & Activity API (/api/v1/orders/*).

Honors the frozen contracts in ``docs/backend/API.md`` (§1 ID schemes & §5 Orders-tab integration):
- Types: 'parts', 'mechanic', 'fuel', 'aiReport'
- Statuses: 'Pending', 'In Progress', 'Delivered', 'Completed', 'Cancelled'
- Monies as Decimals serialized to clean strings/numbers.
"""

from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, field_validator


VALID_ORDER_ENTRY_TYPES = ("parts", "mechanic", "fuel", "aiReport")
VALID_ORDER_ENTRY_STATUSES = (
    "Pending",
    "Delivered",
    "Completed",
    "In Progress",
    "Cancelled",
)


class _DecimalJsonMixin(BaseModel):
    """Mixin to serialize Decimal values cleanly in JSON outputs."""

    @classmethod
    def _serialize_decimal(cls, v: Any) -> Any:
        if isinstance(v, Decimal):
            return float(v)
        return v


class OrderEntryResponse(_DecimalJsonMixin):
    """Unified user order history entry response matching client's ordersList item."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    name: Optional[str] = None
    brand: Optional[str] = None
    quantity: Optional[int] = None
    price: Optional[Decimal] = None
    type: str
    status: str
    occurred_at: datetime
    source: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in VALID_ORDER_ENTRY_TYPES:
            raise ValueError(f"type must be one of {VALID_ORDER_ENTRY_TYPES}")
        return v

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        if v not in VALID_ORDER_ENTRY_STATUSES:
            raise ValueError(f"status must be one of {VALID_ORDER_ENTRY_STATUSES}")
        return v


class OrderDetailResponse(_DecimalJsonMixin):
    """Rich order detail response with domain metadata."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    name: Optional[str] = None
    brand: Optional[str] = None
    quantity: Optional[int] = None
    price: Optional[Decimal] = None
    type: str
    status: str
    occurred_at: datetime
    source: Optional[str] = None
    domain_id: Optional[str] = None
    details: Optional[Dict[str, Any]] = None


class OrderCancelResponse(BaseModel):
    """Confirmation payload after cancelling an order."""

    id: str
    status: str = "Cancelled"
    message: str = "Order cancelled successfully."
