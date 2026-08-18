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
]