"""Pydantic schemas for Address management.

Forbids client-supplied ``user_id`` to enforce server-side identity resolution.
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional
import uuid

from pydantic import BaseModel, ConfigDict, Field


class AddressCreate(BaseModel):
    """Payload to create a new address.

    ``user_id`` is forbidden; identity is resolved from the JWT.
    """

    label: str = Field(..., min_length=1, max_length=50, description="Address label (e.g. 'home', 'office', 'other').")
    address: str = Field(..., min_length=3, max_length=500, description="Full formatted address string.")
    latitude: Optional[Decimal] = Field(None, description="Geocoded latitude.")
    longitude: Optional[Decimal] = Field(None, description="Geocoded longitude.")
    is_default: bool = Field(False, description="Whether this should be the default address.")

    model_config = ConfigDict(extra="forbid")


class AddressUpdate(BaseModel):
    """Payload to partially update an address.

    ``user_id`` is forbidden; identity is resolved from the JWT.
    """

    label: Optional[str] = Field(None, min_length=1, max_length=50, description="Address label.")
    address: Optional[str] = Field(None, min_length=3, max_length=500, description="Full formatted address string.")
    latitude: Optional[Decimal] = Field(None, description="Geocoded latitude.")
    longitude: Optional[Decimal] = Field(None, description="Geocoded longitude.")
    is_default: Optional[bool] = Field(None, description="Whether this is the default address.")

    model_config = ConfigDict(extra="forbid")


class AddressResponse(BaseModel):
    """Public address representation."""

    id: uuid.UUID = Field(..., description="Unique address UUID.")
    user_id: uuid.UUID = Field(..., description="Owner user UUID.")
    label: str = Field(..., description="Address label.")
    address: str = Field(..., description="Full address text.")
    latitude: Optional[Decimal] = Field(None, description="Latitude.")
    longitude: Optional[Decimal] = Field(None, description="Longitude.")
    is_default: bool = Field(..., description="Is default address.")
    created_at: datetime = Field(..., description="Creation timestamp.")
    updated_at: datetime = Field(..., description="Last update timestamp.")

    model_config = ConfigDict(from_attributes=True)
