"""Pydantic schemas package for Mecha Connect backend."""

from app.schemas.fuel import (
    FuelStationResponse,
    FuelPartnerResponse,
    PriceEstimateCalculateIn,
    PriceEstimateResponse,
    TrackingEventCreate,
    TrackingEventResponse,
    InvoiceResponse,
    FuelOrderCreate,
    FuelOrderUpdate,
    FuelOrderResponse,
    VALID_FUEL_TYPES,
    VALID_FUEL_ORDER_STATUSES,
    VALID_STATION_AVAILABILITIES,
)
from app.schemas.marketplace import (
    CategoryResponse,
    BrandResponse,
    ProductSpecificationSchema,
    ProductReviewCreate,
    ProductReviewResponse,
    ProductResponse,
    OfferResponse,
    CouponResponse,
    CouponValidateIn,
    CouponValidationResult,
    OrderItemCreate,
    OrderItemResponse,
    OrderCreate,
    OrderResponse,
    OrderEntryCreate,
    OrderEntryResponse,
    VALID_COUPON_TYPES,
    VALID_ORDER_ENTRY_TYPES,
    VALID_ORDER_ENTRY_STATUSES,
    VALID_VEHICLE_TYPES,
)
from app.schemas.vehicle import (
    VehicleCreate,
    VehicleUpdate,
    VehicleResponse,
    VALID_VEHICLE_FUEL_TYPES,
)

__all__ = [
    # Fuel
    "FuelStationResponse",
    "FuelPartnerResponse",
    "PriceEstimateCalculateIn",
    "PriceEstimateResponse",
    "TrackingEventCreate",
    "TrackingEventResponse",
    "InvoiceResponse",
    "FuelOrderCreate",
    "FuelOrderUpdate",
    "FuelOrderResponse",
    "VALID_FUEL_TYPES",
    "VALID_FUEL_ORDER_STATUSES",
    "VALID_STATION_AVAILABILITIES",
    # Marketplace
    "CategoryResponse",
    "BrandResponse",
    "ProductSpecificationSchema",
    "ProductReviewCreate",
    "ProductReviewResponse",
    "ProductResponse",
    "OfferResponse",
    "CouponResponse",
    "CouponValidateIn",
    "CouponValidationResult",
    "OrderItemCreate",
    "OrderItemResponse",
    "OrderCreate",
    "OrderResponse",
    "OrderEntryCreate",
    "OrderEntryResponse",
    "VALID_COUPON_TYPES",
    "VALID_ORDER_ENTRY_TYPES",
    "VALID_ORDER_ENTRY_STATUSES",
    "VALID_VEHICLE_TYPES",
    # Vehicles
    "VehicleCreate",
    "VehicleUpdate",
    "VehicleResponse",
    "VALID_VEHICLE_FUEL_TYPES",
    # Address
    "AddressCreate",
    "AddressUpdate",
    "AddressResponse",
    # Wallet & Rewards
    "WalletResponse",
    "WalletTopupRequest",
    "WalletTransactionResponse",
    "RewardsResponse",
    "RewardLedgerResponse",
    # Notification Settings
    "NotificationSettingUpdate",
    "NotificationSettingResponse",
    # Diagnosis
    "DiagnosisInput",
    "DiagnosisResponse",
    "DiagnosisRecordResponse",
]

from app.schemas.diagnosis import (
    DiagnosisInput,
    DiagnosisResponse,
    DiagnosisRecordResponse,
)
from app.schemas.address import (
    AddressCreate,
    AddressUpdate,
    AddressResponse,
)
from app.schemas.wallet import (
    WalletResponse,
    WalletTopupRequest,
    WalletTransactionResponse,
    RewardsResponse,
    RewardLedgerResponse,
)
from app.schemas.notification_setting import (
    NotificationSettingUpdate,
    NotificationSettingResponse,
)