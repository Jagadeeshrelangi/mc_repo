"""Unit tests for Task 8 Stage 2 — Fuel & Marketplace Pydantic v2 Schemas.

Validates schema contracts:
- Valid payload parsing
- Rejection of invalid types / missing required fields
- Enum & constraint validation (fuel types, statuses, coupon types, order entry types)
- Decimal number validation & JSON serialization
- Extra fields forbidden on request schemas (mass-assignment protection)
- Server-controlled field protection
- Nested response serialization
"""

from datetime import date, datetime, timezone
from decimal import Decimal
import pytest
from pydantic import ValidationError

from app.schemas.fuel import (
    FuelOrderCreate,
    FuelOrderUpdate,
    FuelOrderResponse,
    FuelStationResponse,
    FuelPartnerResponse,
    PriceEstimateCalculateIn,
    PriceEstimateResponse,
    TrackingEventCreate,
    TrackingEventResponse,
    InvoiceResponse,
    VALID_FUEL_TYPES,
    VALID_FUEL_ORDER_STATUSES,
)
from app.schemas.marketplace import (
    CategoryResponse,
    BrandResponse,
    ProductResponse,
    ProductSpecificationSchema,
    ProductReviewCreate,
    ProductReviewResponse,
    OfferResponse,
    CouponResponse,
    CouponValidateIn,
    CouponValidationResult,
    OrderCreate,
    OrderItemCreate,
    OrderResponse,
    OrderItemResponse,
    OrderEntryCreate,
    OrderEntryResponse,
    VALID_COUPON_TYPES,
    VALID_ORDER_ENTRY_TYPES,
    VALID_ORDER_ENTRY_STATUSES,
)


# ============================================================================
# Fuel Delivery Schemas
# ============================================================================


def test_fuel_order_create_valid() -> None:
    payload = {
        "fuel_type": "petrol",
        "quantity": Decimal("15.5"),
        "station_id": "st-1",
        "station_name": "Indian Oil",
        "brand": "IndianOil",
        "price_per_litre": Decimal("98.20"),
        "vehicle_type": "car",
        "vehicle_name": "Honda Civic",
        "vehicle_number": "KA-01-AB-1234",
        "delivery_label": "home",
        "delivery_address": "123 Main St, Bengaluru",
        "lat": Decimal("12.9716"),
        "lng": Decimal("77.5946"),
        "payment_method": "UPI",
    }
    schema = FuelOrderCreate.model_validate(payload)
    assert schema.fuel_type == "petrol"
    assert schema.quantity == Decimal("15.5")
    assert schema.payment_method == "UPI"


def test_fuel_order_create_invalid_fuel_type() -> None:
    with pytest.raises(ValidationError) as exc:
        FuelOrderCreate.model_validate({
            "fuel_type": "kerosene",
            "quantity": Decimal("10.0"),
        })
    assert "fuel_type must be one of" in str(exc.value)


def test_fuel_order_create_negative_quantity() -> None:
    with pytest.raises(ValidationError):
        FuelOrderCreate.model_validate({
            "fuel_type": "petrol",
            "quantity": Decimal("-5.0"),
        })


def test_fuel_order_create_extra_fields_forbidden() -> None:
    with pytest.raises(ValidationError):
        FuelOrderCreate.model_validate({
            "fuel_type": "petrol",
            "quantity": Decimal("10.0"),
            "user_id": "injected-user-id",  # Forbidden server-controlled field
        })


def test_fuel_order_update_valid_and_invalid() -> None:
    # Valid
    update = FuelOrderUpdate.model_validate({"status": "enRoute", "partner_id": "fp-1"})
    assert update.status == "enRoute"

    # Invalid status
    with pytest.raises(ValidationError):
        FuelOrderUpdate.model_validate({"status": "unknown_status"})


def test_fuel_order_response_nested_serialization() -> None:
    now = datetime.now(timezone.utc)
    res = FuelOrderResponse(
        id="fo-101",
        user_id="user-1",
        fuel_type="petrol",
        quantity=Decimal("10.00"),
        status="delivered",
        created_at=now,
        price_estimate=PriceEstimateResponse(
            fuel_cost=Decimal("982.00"),
            delivery_charge=Decimal("50.00"),
            platform_fee=Decimal("15.00"),
            taxes=Decimal("104.70"),
            grand_total=Decimal("1151.70"),
            eta_minutes=25,
        ),
        invoice=InvoiceResponse(
            invoice_id="inv-101",
            order_id="fo-101",
            created_at=now,
            grand_total=Decimal("1151.70"),
        ),
        tracking_events=[
            TrackingEventResponse(
                id="te-1",
                order_id="fo-101",
                status="requested",
                occurred_at=now,
            )
        ],
    )
    dumped = res.model_dump()
    assert dumped["id"] == "fo-101"
    assert dumped["price_estimate"]["grand_total"] == Decimal("1151.70")
    assert dumped["invoice"]["invoice_id"] == "inv-101"
    assert len(dumped["tracking_events"]) == 1


def test_price_estimate_calculate_in() -> None:
    valid = PriceEstimateCalculateIn.model_validate({
        "fuel_type": "diesel",
        "quantity": Decimal("20.0"),
    })
    assert valid.quantity == Decimal("20.0")

    with pytest.raises(ValidationError):
        PriceEstimateCalculateIn.model_validate({
            "fuel_type": "diesel",
            "quantity": Decimal("0.0"),  # gt=0 required
        })


# ============================================================================
# Marketplace Schemas
# ============================================================================


def test_product_response_structure() -> None:
    now = datetime.now(timezone.utc)
    prod = ProductResponse(
        id="p1",
        name="Brembo Brake Pads",
        price=Decimal("1499.00"),
        mrp=Decimal("1999.00"),
        rating=Decimal("4.8"),
        rating_count=42,
        stock=15,
        created_at=now,
        updated_at=now,
        brand=BrandResponse(id="b1", name="Brembo"),
        category=CategoryResponse(id="c1", name="Braking"),
        specifications=[ProductSpecificationSchema(label="Material", value="Ceramic")],
        vehicle_types=["car", "suv"],
        compatibility=["Honda Civic", "Toyota Corolla"],
        reviews=[
            ProductReviewResponse(
                id="rev-1",
                product_id="p1",
                author="John Doe",
                rating=Decimal("5.0"),
                comment="Excellent stopping power!",
                reviewed_at=date(2026, 8, 20),
            )
        ],
    )
    dump = prod.model_dump()
    assert dump["id"] == "p1"
    assert dump["brand"]["name"] == "Brembo"
    assert len(dump["specifications"]) == 1
    assert dump["vehicle_types"] == ["car", "suv"]
    assert len(dump["reviews"]) == 1


def test_product_review_create_validation() -> None:
    # Valid
    rev = ProductReviewCreate.model_validate({"rating": Decimal("4.5"), "comment": "Great product"})
    assert rev.rating == Decimal("4.5")

    # Rating < 1.0
    with pytest.raises(ValidationError):
        ProductReviewCreate.model_validate({"rating": Decimal("0.5")})

    # Rating > 5.0
    with pytest.raises(ValidationError):
        ProductReviewCreate.model_validate({"rating": Decimal("5.5")})


def test_coupon_validation_and_types() -> None:
    now = datetime.now(timezone.utc)
    coupon = CouponResponse(
        id="cp-1",
        code="SAVE20",
        title="20% Off",
        type="percent",
        value=Decimal("20.00"),
        max_discount=Decimal("200.00"),
        min_order_value=Decimal("500.00"),
        valid_from=now,
        valid_until=now,
    )
    assert coupon.code == "SAVE20"
    assert coupon.type in VALID_COUPON_TYPES

    val_in = CouponValidateIn.model_validate({"code": "SAVE20", "order_amount": Decimal("1000.00")})
    assert val_in.order_amount == Decimal("1000.00")

    result = CouponValidationResult(
        is_valid=True,
        discount_amount=Decimal("200.00"),
        message="Coupon applied successfully",
    )
    assert result.is_valid is True
    assert result.discount_amount == Decimal("200.00")


def test_order_create_validation() -> None:
    payload = {
        "address": "456 Park Ave, Indiranagar, Bengaluru",
        "payment_method": "UPI",
        "items": [
            {
                "product_id": "p1",
                "product_name": "Brake Fluid DOT 4",
                "brand": "Bosch",
                "quantity": 2,
                "unit_price": Decimal("350.00"),
                "line_total": Decimal("700.00"),
            }
        ],
    }
    order = OrderCreate.model_validate(payload)
    assert order.address == "456 Park Ave, Indiranagar, Bengaluru"
    assert len(order.items) == 1
    assert order.items[0].quantity == 2


def test_order_create_empty_items_rejected() -> None:
    with pytest.raises(ValidationError):
        OrderCreate.model_validate({
            "address": "123 Main St",
            "payment_method": "Card",
            "items": [],  # min_length=1 required
        })


def test_order_create_server_controlled_fields_forbidden() -> None:
    with pytest.raises(ValidationError):
        OrderCreate.model_validate({
            "address": "123 Main St",
            "payment_method": "Card",
            "items": [{"quantity": 1, "unit_price": Decimal("100.00")}],
            "user_id": "injected-user",
            "grand_total": Decimal("0.00"),
        })


def test_order_entry_create_validation() -> None:
    valid = OrderEntryCreate.model_validate({
        "name": "Synthetic Engine Oil 5W-30",
        "brand": "Mobil 1",
        "quantity": 1,
        "price": Decimal("2450.00"),
        "type": "parts",
        "status": "Pending",
        "source": "Marketplace Checkout",
    })
    assert valid.type == "parts"
    assert valid.status == "Pending"

    # Invalid type
    with pytest.raises(ValidationError):
        OrderEntryCreate.model_validate({
            "type": "invalid_type",
            "status": "Pending",
        })

    # Invalid status
    with pytest.raises(ValidationError):
        OrderEntryCreate.model_validate({
            "type": "fuel",
            "status": "invalid_status",
        })
