"""Repository package for the Mecha Connect backend."""

from app.repositories.base import BaseRepository
from app.repositories.users import RefreshTokenRepository, UserRepository
from app.repositories.conversations import ConversationRepository
from app.repositories.chat_messages import ChatMessageRepository
from app.repositories.diagnosis import DiagnosisRepository
from app.repositories.vehicle import VehicleRepository
from app.repositories.mechanics import (
    BookingEventRepository,
    MechanicBookingRepository,
    MechanicCategoryRepository,
    MechanicRepository,
    MechanicReviewRepository,
    MechanicServiceRepository,
    RatingRepository,
)
from app.repositories.fuel import (
    FuelOrderRepository,
    FuelPartnerRepository,
    FuelStationRepository,
    InvoiceRepository,
    PriceEstimateRepository,
    TrackingEventRepository,
)
from app.repositories.marketplace import (
    BrandRepository,
    CategoryRepository,
    CouponRepository,
    OfferRepository,
    OrderEntryRepository,
    OrderRepository,
    ProductRepository,
)

__all__ = [
    "BaseRepository",
    "UserRepository",
    "RefreshTokenRepository",
    "ConversationRepository",
    "ChatMessageRepository",
    "DiagnosisRepository",
    "VehicleRepository",
    "MechanicRepository",
    "MechanicCategoryRepository",
    "MechanicServiceRepository",
    "MechanicReviewRepository",
    "MechanicBookingRepository",
    "BookingEventRepository",
    "RatingRepository",
    # Fuel
    "FuelStationRepository",
    "FuelPartnerRepository",
    "PriceEstimateRepository",
    "TrackingEventRepository",
    "InvoiceRepository",
    "FuelOrderRepository",
    # Marketplace
    "CategoryRepository",
    "BrandRepository",
    "OfferRepository",
    "CouponRepository",
    "ProductRepository",
    "OrderRepository",
    "OrderEntryRepository",
    # Batch Profile Domains
    "AddressRepository",
    "WalletRepository",
    "NotificationSettingRepository",
]

from app.repositories.address import AddressRepository
from app.repositories.wallet import WalletRepository
from app.repositories.notification_setting import NotificationSettingRepository