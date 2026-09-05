"""Pydantic v2 schemas for Vehicle endpoints.

Strictly forbids `user_id` in client input payloads (derived server-side from JWT).
"""

from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

VALID_VEHICLE_FUEL_TYPES = ("petrol", "diesel", "electric", "cng")


class VehicleCreate(BaseModel):
    """Client request body to register a new vehicle under their authenticated account."""

    model_config = ConfigDict(extra="forbid")

    brand: str = Field(..., min_length=1, max_length=100, description="Vehicle manufacturer brand")
    model: str = Field(..., min_length=1, max_length=100, description="Vehicle model name")
    registration: str = Field(..., min_length=1, max_length=50, description="License plate registration number")
    fuel_type: str = Field(..., description="Fuel type: petrol, diesel, electric, or cng")
    insurance_expiry: Optional[date] = Field(None, description="Insurance policy expiration date")
    puc_expiry: Optional[date] = Field(None, description="PUC certificate expiration date")
    service_due_km: Optional[int] = Field(None, ge=0, description="Next service due odometer kilometer")
    service_due_date: Optional[date] = Field(None, description="Next scheduled service date")
    is_default: bool = Field(False, description="Whether to make this the primary/default vehicle")
    health_score: Optional[int] = Field(80, ge=0, le=100, description="Vehicle health score (0-100)")

    @field_validator("fuel_type")
    @classmethod
    def validate_fuel_type(cls, v: str) -> str:
        cleaned = v.strip().lower()
        if cleaned not in VALID_VEHICLE_FUEL_TYPES:
            raise ValueError(f"fuel_type must be one of {VALID_VEHICLE_FUEL_TYPES}")
        return cleaned


class VehicleUpdate(BaseModel):
    """Client request body to update an existing vehicle."""

    model_config = ConfigDict(extra="forbid")

    brand: Optional[str] = Field(None, min_length=1, max_length=100)
    model: Optional[str] = Field(None, min_length=1, max_length=100)
    registration: Optional[str] = Field(None, min_length=1, max_length=50)
    fuel_type: Optional[str] = None
    insurance_expiry: Optional[date] = None
    puc_expiry: Optional[date] = None
    service_due_km: Optional[int] = Field(None, ge=0)
    service_due_date: Optional[date] = None
    is_default: Optional[bool] = None
    health_score: Optional[int] = Field(None, ge=0, le=100)

    @field_validator("fuel_type")
    @classmethod
    def validate_fuel_type(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip().lower()
        if cleaned not in VALID_VEHICLE_FUEL_TYPES:
            raise ValueError(f"fuel_type must be one of {VALID_VEHICLE_FUEL_TYPES}")
        return cleaned


class VehicleResponse(BaseModel):
    """Full vehicle serialization returned to clients."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    brand: str
    model: str
    registration: str
    fuel_type: str
    insurance_expiry: Optional[date] = None
    puc_expiry: Optional[date] = None
    service_due_km: Optional[int] = None
    service_due_date: Optional[date] = None
    is_default: bool
    health_score: Optional[int] = None
    created_at: datetime
    updated_at: datetime
