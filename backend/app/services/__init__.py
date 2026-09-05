"""Services package for Mecha Connect backend."""

from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.chat_service import ChatService
from app.services.diagnosis_service import DiagnosisService
from app.services.mechanic_service import MechanicService
from app.services.fuel_service import FuelService
from app.services.marketplace_service import MarketplaceService
from app.services.vehicle_service import VehicleService
from app.services.address_service import AddressService
from app.services.wallet_service import WalletService
from app.services.notification_service import NotificationService

__all__ = [
    "AuthService",
    "UserService",
    "ChatService",
    "DiagnosisService",
    "MechanicService",
    "FuelService",
    "MarketplaceService",
    "VehicleService",
    "AddressService",
    "WalletService",
    "NotificationService",
]