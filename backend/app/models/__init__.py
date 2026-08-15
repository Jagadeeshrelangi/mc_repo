"""SQLAlchemy models for the Mecha Connect backend (Sprint 2, Task 3).

Importing this package registers every model on ``app.core.database.Base``
metadata so Alembic and autogenerate can discover the full schema.
"""

from app.models.user import User, UserRole
from app.models.refresh_token import RefreshToken
from app.models.conversation import Conversation
from app.models.chat_message import ChatMessage

__all__ = ["User", "UserRole", "RefreshToken", "Conversation", "ChatMessage"]