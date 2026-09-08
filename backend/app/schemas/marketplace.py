"""Pydantic v2 schemas for the Marketplace & Parts module (Task 8 Stage 2).

Pure request/response validation/serialization contracts.
Adheres to Pydantic v2 conventions (ConfigDict, field_validator, field_serializer, etc.).
"""

from datetime import date, datetime
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

VALID_COUPON_TYPES = ("percent", "freeDelivery")
VALID_ORDER_ENTRY_TYPES = ("parts", "mechanic", "fuel", "aiReport")
VALID_ORDER_ENTRY_STATUSES = ("Pending", "Delivered", "Completed", "In Progress", "Cancelled")
VALID_VEHICLE_TYPES = ("bike", "car", "suv", "truck")


# ---------------------------------------------------------------------------
# Categories & Brands
# ---------------------------------------------------------------------------


class CategoryResponse(BaseModel):
    """Catalog category response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    icon: Optional[str] = None
    sort_order: int = 0


class BrandResponse(BaseModel):
    """Catalog manufacturer brand response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str


# ---------------------------------------------------------------------------
# Product Attributes & Reviews
# ---------------------------------------------------------------------------


class ProductSpecificationSchema(BaseModel):
    """Single row specification in product details."""

    model_config = ConfigDict(from_attributes=True)

    id: Optional[str] = None
    label: str
    value: str
    sort_order: int = 0


class ProductReviewCreate(BaseModel):
    """Client input to submit a customer review on a product."""

    model_config = ConfigDict(extra="forbid")

    rating: Decimal = Field(ge=1.0, le=5.0, description="Rating between 1.0 and 5.0")
    comment: Optional[str] = None
    author: Optional[str] = None


class ProductReviewResponse(_DecimalJsonMixin):
    """Customer review response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    product_id: str
    author: Optional[str] = None
    rating: Optional[Decimal] = None
    comment: Optional[str] = None
    reviewed_at: Optional[date] = None
    is_verified_purchase: Optional[bool] = True
    helpful_count: Optional[int] = 0


# ---------------------------------------------------------------------------
# Product Schemas
# ---------------------------------------------------------------------------


class ProductResponse(_DecimalJsonMixin):
    """Comprehensive product detail response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    brand_id: Optional[str] = None
    category_id: Optional[str] = None
    name: str
    price: Decimal
    mrp: Decimal
    rating: Optional[Decimal] = Decimal("4.0")
    rating_count: Optional[int] = 0
    stock: int = 0
    image_url: Optional[str] = None
    icon: Optional[str] = None
    description: Optional[str] = None
    warranty: Optional[str] = None
    delivery_estimate: Optional[str] = None
    popularity: Optional[int] = 0
    age_days: Optional[int] = 0
    is_featured: bool = False
    is_best_seller: bool = False
    is_trending: bool = False
    is_flash_deal: bool = False
    is_recommended: bool = False
    created_at: datetime
    updated_at: datetime

    # Nested child attributes
    brand: Optional[BrandResponse] = None
    category: Optional[CategoryResponse] = None
    specifications: List[ProductSpecificationSchema] = []
    vehicle_types: List[str] = []
    compatibility: List[str] = []
    reviews: List[ProductReviewResponse] = []

    @field_validator("vehicle_types", mode="before")
    @classmethod
    def _extract_vehicle_types(cls, v: Any) -> Any:
        if isinstance(v, list):
            res = []
            for item in v:
                if hasattr(item, "vehicle_type"):
                    res.append(item.vehicle_type)
                elif isinstance(item, dict) and "vehicle_type" in item:
                    res.append(item["vehicle_type"])
                else:
                    res.append(item)
            return res
        return v

    @field_validator("compatibility", mode="before")
    @classmethod
    def _extract_compatibility(cls, v: Any) -> Any:
        if isinstance(v, list):
            res = []
            for item in v:
                if hasattr(item, "compatible_with"):
                    res.append(item.compatible_with)
                elif isinstance(item, dict) and "compatible_with" in item:
                    res.append(item["compatible_with"])
                else:
                    res.append(item)
            return res
        return v


# ---------------------------------------------------------------------------
# Promotional Offers & Coupons
# ---------------------------------------------------------------------------


class OfferResponse(BaseModel):
    """Promotional offer banner response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    title: Optional[str] = None
    subtitle: Optional[str] = None
    code: Optional[str] = None
    category_id: Optional[str] = None
    gradient_start: Optional[str] = None
    gradient_end: Optional[str] = None


class CouponResponse(_DecimalJsonMixin):
    """Discount coupon response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    code: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    type: Optional[str] = None
    value: Optional[Decimal] = None
    max_discount: Optional[Decimal] = None
    min_order_value: Optional[Decimal] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None


class CouponValidateIn(BaseModel):
    """Client input to validate and apply a coupon against a cart subtotal."""

    model_config = ConfigDict(extra="forbid")

    code: str
    order_amount: Decimal = Field(gt=0, description="Order subtotal to apply coupon to")


class CouponValidationResult(_DecimalJsonMixin):
    """Result of coupon validation with calculated discount."""

    model_config = ConfigDict(from_attributes=True)

    is_valid: bool
    discount_amount: Decimal = Decimal("0.00")
    message: str


# ---------------------------------------------------------------------------
# Marketplace Orders & Items
# ---------------------------------------------------------------------------


class OrderItemCreate(BaseModel):
    """Client cart item snapshot at checkout time."""

    model_config = ConfigDict(extra="forbid")

    product_id: Optional[str] = None
    product_name: Optional[str] = None
    brand: Optional[str] = None
    quantity: int = Field(gt=0, description="Quantity must be at least 1")
    unit_price: Decimal = Field(ge=0, description="Unit price per item")
    line_total: Optional[Decimal] = None
    image: Optional[str] = None


class OrderItemResponse(_DecimalJsonMixin):
    """Order item line response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    order_id: str
    product_id: Optional[str] = None
    product_name: Optional[str] = None
    brand: Optional[str] = None
    quantity: Optional[int] = None
    unit_price: Optional[Decimal] = None
    line_total: Optional[Decimal] = None
    image: Optional[str] = None


class OrderCreate(BaseModel):
    """Client checkout order submission payload.
    
    Server controls: id, user_id, external_id, calculated subtotal/tax/delivery/grand_total, status, created_at.
    """

    model_config = ConfigDict(extra="forbid")

    address: str = Field(min_length=1, description="Delivery address")
    payment_method: str = Field(min_length=1, description="Payment method e.g. UPI, Card, Cash")
    items: List[OrderItemCreate] = Field(min_length=1, description="Must contain at least 1 order line item")


class OrderResponse(_DecimalJsonMixin):
    """Full marketplace purchase order response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    external_id: Optional[str] = None
    address: str
    payment_method: str
    subtotal: Optional[Decimal] = None
    discount: Optional[Decimal] = None
    delivery: Optional[Decimal] = None
    tax: Optional[Decimal] = None
    grand_total: Optional[Decimal] = None
    status: str
    created_at: datetime

    items: List[OrderItemResponse] = []


# ---------------------------------------------------------------------------
# Cross-Domain Unified Order Entries (Activity Ledger)
# ---------------------------------------------------------------------------


class OrderEntryCreate(BaseModel):
    """Internal / Service payload to record cross-domain user activity."""

    model_config = ConfigDict(extra="forbid")

    name: Optional[str] = None
    brand: Optional[str] = None
    quantity: Optional[int] = None
    price: Optional[Decimal] = None
    type: str
    status: str
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


class OrderEntryResponse(_DecimalJsonMixin):
    """Unified user order history entry response."""

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
