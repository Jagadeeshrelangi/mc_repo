"""SQLAlchemy models for the Mecha Connect backend (Sprint 2, Task 3).

Importing this package registers every model on ``app.core.database.Base``
metadata so Alembic and autogenerate can discover the full schema.
"""

from app.models.user import User, UserRole
from app.models.refresh_token import RefreshToken
from app.models.conversation import Conversation
from app.models.chat_message import ChatMessage
from app.models.mechanic_status import BookingStatus
from app.models.mechanic import (
    Mechanic,
    MechanicSkill,
    MechanicLanguage,
    MechanicWorkingHour,
)
from app.models.mechanic_service import MechanicService, MechanicServiceOffered
from app.models.mechanic_category import MechanicCategory
from app.models.mechanic_review import MechanicReview
from app.models.mechanic_booking import MechanicBooking, BookingEvent, Rating
from app.models.diagnosis import Diagnosis
from app.models.vehicle import Vehicle

# --- Task 8: Fuel Delivery Models ---
from app.models.fuel_order import FuelOrder
from app.models.price_estimate import PriceEstimate
from app.models.fuel_station import FuelStation
from app.models.fuel_partner import FuelPartner
from app.models.tracking_event import TrackingEvent
from app.models.invoice import Invoice

# --- Task 8: Marketplace Models ---
from app.models.category import Category
from app.models.brand import Brand
from app.models.product import Product
from app.models.product_specification import ProductSpecification
from app.models.product_vehicle_type import ProductVehicleType
from app.models.product_compatibility import ProductCompatibility
from app.models.product_review import ProductReview
from app.models.offer import Offer
from app.models.coupon import Coupon
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.order_entry import OrderEntry
from app.models.address import Address
from app.models.wallet import Wallet, WalletTransaction, RewardLedger
from app.models.notification_setting import NotificationSetting

__all__ = [
    "User",
    "UserRole",
    "RefreshToken",
    "Conversation",
    "ChatMessage",
    "BookingStatus",
    "Mechanic",
    "MechanicSkill",
    "MechanicLanguage",
    "MechanicWorkingHour",
    "MechanicService",
    "MechanicServiceOffered",
    "MechanicCategory",
    "MechanicReview",
    "MechanicBooking",
    "BookingEvent",
    "Rating",
    "Diagnosis",
    "Vehicle",
    # Fuel
    "FuelOrder",
    "PriceEstimate",
    "FuelStation",
    "FuelPartner",
    "TrackingEvent",
    "Invoice",
    # Marketplace
    "Category",
    "Brand",
    "Product",
    "ProductSpecification",
    "ProductVehicleType",
    "ProductCompatibility",
    "ProductReview",
    "Offer",
    "Coupon",
    "Order",
    "OrderItem",
    "OrderEntry",
    # Batch Profile Domains
    "Address",
    "Wallet",
    "WalletTransaction",
    "RewardLedger",
    "NotificationSetting",
]