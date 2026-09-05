"""Pydantic v2 schemas for the Fuel Delivery module (Task 8 Stage 2).

Pure request/response validation/serialization contracts.
Adheres to Pydantic v2 conventions (ConfigDict, field_validator, model_validator, etc.).
"""

from datetime import datetime
from decimal import Decimal
from typing import Any, List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_serializer, field_validator


# ---------------------------------------------------------------------------
# Shared Decimal-to-JSON Mixin
# ---------------------------------------------------------------------------


class _DecimalJsonMixin(BaseModel):
    """Serialize Decimal fields to numbers on the wire when dumping JSON."""

    @field_serializer("*", when_used="json", check_fields=False)
    def _decimal_to_json_number(self, value: Any) -> Any:
        return float(value) if isinstance(value, Decimal) else value


# ---------------------------------------------------------------------------
# Value Constants / Constraints
# ---------------------------------------------------------------------------

VALID_FUEL_TYPES = ("petrol", "diesel", "premiumPetrol", "electric", "cng")
VALID_FUEL_ORDER_STATUSES = (
    "requested",
    "accepted",
    "fuelPacked",
    "partnerAssigned",
    "enRoute",
    "arrived",
    "delivered",
    "cancelled",
)
VALID_STATION_AVAILABILITIES = ("available", "low", "outOfStock")


# ---------------------------------------------------------------------------
# Fuel Station Schemas
# ---------------------------------------------------------------------------


class FuelStationResponse(_DecimalJsonMixin):
    """Catalog response for a fuel station bunk."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    name: Optional[str] = None
    brand: Optional[str] = None
    rating: Optional[Decimal] = None
    rating_count: Optional[int] = None
    distance_km: Optional[Decimal] = None
    eta_minutes: Optional[int] = None
    price_per_litre: Optional[Decimal] = None
    availability: Optional[str] = None
    is_open: Optional[bool] = None
    address: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None


# ---------------------------------------------------------------------------
# Fuel Partner Schemas
# ---------------------------------------------------------------------------


class FuelPartnerResponse(_DecimalJsonMixin):
    """Catalog / assigned driver response for fuel delivery."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    name: Optional[str] = None
    phone: Optional[str] = None
    rating: Optional[Decimal] = None
    rating_count: Optional[int] = None
    distance_km: Optional[Decimal] = None
    eta_minutes: Optional[int] = None
    is_available: Optional[bool] = None
    vehicle_number: Optional[str] = None
    vehicle_model: Optional[str] = None


# ---------------------------------------------------------------------------
# Price Estimate Schemas
# ---------------------------------------------------------------------------


class PriceEstimateCalculateIn(BaseModel):
    """Input parameters to request an upfront fuel delivery price estimate."""

    model_config = ConfigDict(extra="forbid")

    fuel_type: str
    quantity: Decimal = Field(gt=0, description="Quantity in litres")
    station_id: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None

    @field_validator("fuel_type")
    @classmethod
    def validate_fuel_type(cls, v: str) -> str:
        if v not in VALID_FUEL_TYPES:
            raise ValueError(f"fuel_type must be one of {VALID_FUEL_TYPES}")
        return v


class PriceEstimateResponse(_DecimalJsonMixin):
    """Price breakdown response."""

    model_config = ConfigDict(from_attributes=True)

    fuel_order_id: Optional[str] = None
    fuel_cost: Optional[Decimal] = None
    delivery_charge: Optional[Decimal] = None
    platform_fee: Optional[Decimal] = None
    taxes: Optional[Decimal] = None
    grand_total: Optional[Decimal] = None
    eta_minutes: Optional[int] = None


# ---------------------------------------------------------------------------
# Tracking Event Schemas
# ---------------------------------------------------------------------------


class TrackingEventCreate(BaseModel):
    """Input payload to append a tracking progress milestone / GPS coordinate."""

    model_config = ConfigDict(extra="forbid")

    status: Optional[str] = None
    partner_lat: Optional[Decimal] = None
    partner_lng: Optional[Decimal] = None
    distance_remaining: Optional[Decimal] = None
    eta_minutes: Optional[int] = None


class TrackingEventResponse(_DecimalJsonMixin):
    """Tracking event snapshot response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    order_id: str
    status: Optional[str] = None
    partner_lat: Optional[Decimal] = None
    partner_lng: Optional[Decimal] = None
    distance_remaining: Optional[Decimal] = None
    eta_minutes: Optional[int] = None
    occurred_at: datetime


# ---------------------------------------------------------------------------
# Invoice Schemas
# ---------------------------------------------------------------------------


class InvoiceResponse(_DecimalJsonMixin):
    """Invoice response attached to a delivered fuel order."""

    model_config = ConfigDict(from_attributes=True)

    invoice_id: str
    order_id: str
    created_at: datetime
    fuel_type: Optional[str] = None
    quantity: Optional[Decimal] = None
    price_per_litre: Optional[Decimal] = None
    fuel_cost: Optional[Decimal] = None
    delivery_charge: Optional[Decimal] = None
    platform_fee: Optional[Decimal] = None
    taxes: Optional[Decimal] = None
    grand_total: Optional[Decimal] = None
    partner_name: Optional[str] = None
    vehicle_number: Optional[str] = None


# ---------------------------------------------------------------------------
# Fuel Order Schemas
# ---------------------------------------------------------------------------


class FuelOrderCreate(BaseModel):
    """Client payload to place a new fuel delivery order.
    
    Server controls: id, user_id, status, created_at, invoice, tracking_events.
    """

    model_config = ConfigDict(extra="forbid")

    fuel_type: str
    quantity: Decimal = Field(gt=0, description="Quantity in litres (positive number)")

    # Optional vehicle snapshot
    vehicle_type: Optional[str] = None
    vehicle_name: Optional[str] = None
    vehicle_number: Optional[str] = None

    # Optional chosen station snapshot
    station_id: Optional[str] = None
    station_name: Optional[str] = None
    brand: Optional[str] = None
    price_per_litre: Optional[Decimal] = None

    # Delivery address details
    delivery_label: Optional[str] = None
    delivery_address: Optional[str] = None
    lat: Optional[Decimal] = None
    lng: Optional[Decimal] = None

    payment_method: Optional[str] = "UPI"

    @field_validator("fuel_type")
    @classmethod
    def validate_fuel_type(cls, v: str) -> str:
        if v not in VALID_FUEL_TYPES:
            raise ValueError(f"fuel_type must be one of {VALID_FUEL_TYPES}")
        return v


class FuelOrderUpdate(BaseModel):
    """Client or partner payload to update an existing fuel order status."""

    model_config = ConfigDict(extra="forbid")

    status: Optional[str] = None
    partner_id: Optional[str] = None

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_FUEL_ORDER_STATUSES:
            raise ValueError(f"status must be one of {VALID_FUEL_ORDER_STATUSES}")
        return v


class FuelOrderResponse(_DecimalJsonMixin):
    """Comprehensive fuel order response with nested price estimate, invoice, and tracking."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    fuel_type: str
    quantity: Decimal
    vehicle_type: Optional[str] = None
    vehicle_name: Optional[str] = None
    vehicle_number: Optional[str] = None
    station_id: Optional[str] = None
    station_name: Optional[str] = None
    brand: Optional[str] = None
    price_per_litre: Optional[Decimal] = None
    delivery_label: Optional[str] = None
    delivery_address: Optional[str] = None
    lat: Optional[Decimal] = None
    lng: Optional[Decimal] = None
    status: str
    payment_method: Optional[str] = None
    partner_id: Optional[str] = None
    created_at: datetime

    # Relationships
    price_estimate: Optional[PriceEstimateResponse] = None
    invoice: Optional[InvoiceResponse] = None
    tracking_events: List[TrackingEventResponse] = []
