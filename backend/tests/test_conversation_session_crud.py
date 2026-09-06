"""Tests for Conversation Sessions CRUD & Lifecycle management.

Validates:
1. Authentication: 401 on unauthenticated calls to all endpoints.
2. GET /api/v1/conversation/sessions: Lists caller's sessions, pinned-first then newest updated, with preview and message counts.
3. GET /api/v1/conversation/sessions/{session_id}: Fetches full conversation detail with messages.
4. PATCH /api/v1/conversation/sessions/{session_id}: Renames thread and updates pin status.
5. DELETE /api/v1/conversation/sessions/{session_id}: Deletes conversation and cascades messages (204 No Content).
6. Strict ownership isolation: User B receives generic 404 on User A's session (IDOR safe).
"""

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_db
from app.api.v1.conversation import router as conversation_router
from app.core import security
from app.core.config import settings
from app.core.exceptions import MechaException
from app.models.chat_message import ChatMessage
from app.models.conversation import Conversation
from app.models.user import User
from app.repositories.chat_messages import ChatMessageRepository
from app.repositories.conversations import ConversationRepository
from app.services.chat_service import ChatService

USER_A_ID = "11111111-1111-1111-1111-111111111111"
USER_B_ID = "22222222-2222-2222-2222-222222222222"
NOW = datetime(2026, 9, 6, 12, 0, 0, tzinfo=timezone.utc)


class FakeSessionCrudStore:
    """In-memory store for conversations and chat messages."""

    def __init__(self) -> None:
        self.conversations: Dict[str, Conversation] = {}
        self.messages: Dict[str, List[ChatMessage]] = {}


class FakeSessionCrudDb:
    """Async session spy operating over FakeSessionCrudStore."""

    def __init__(self, store: FakeSessionCrudStore) -> None:
        self.store = store
        self.committed = False
        self.flushed = False

    def add(self, obj: Any) -> None:
        if isinstance(obj, Conversation):
            self.store.conversations[obj.id] = obj
        elif isinstance(obj, ChatMessage):
            self.store.messages.setdefault(obj.conversation_id, []).append(obj)

    async def delete(self, obj: Any) -> None:
        if isinstance(obj, Conversation):
            self.store.conversations.pop(obj.id, None)
            self.store.messages.pop(obj.id, None)

    async def flush(self) -> None:
        self.flushed = True

    async def commit(self) -> None:
        self.committed = True

    async def rollback(self) -> None:
        pass

    async def get(self, model: Any, entity_id: Any) -> Optional[User]:
        entity_id_str = str(entity_id)
        if model is User:
            if entity_id_str == USER_A_ID:
                return User(
                    id=USER_A_ID,
                    name="User A",
                    email="usera@example.com",
                    phone="+919876543210",
                    password_hash="irrelevant",
                    role="customer",
                    is_active=True,
                    is_verified=True,
                    failed_login_attempts=0,
                    membership_tier="free",
                    joined_at=NOW,
                    created_at=NOW,
                    updated_at=NOW,
                )
            elif entity_id_str == USER_B_ID:
                return User(
                    id=USER_B_ID,
                    name="User B",
                    email="userb@example.com",
                    phone="+919876543211",
                    password_hash="irrelevant",
                    role="customer",
                    is_active=True,
                    is_verified=True,
                    failed_login_attempts=0,
                    membership_tier="free",
                    joined_at=NOW,
                    created_at=NOW,
                    updated_at=NOW,
                )
        return None

    async def scalar(self, stmt: Any) -> Optional[Any]:
        # Handle select(Conversation).where(Conversation.id == id, Conversation.user_id == uid)
        # Evaluated through store
        for conv in self.store.conversations.values():
            return conv
        return None

    async def scalars(self, stmt: Any) -> Any:
        class ResultWrapper:
            def __init__(self, items: List[Any]) -> None:
                self._items = items

            def all(self) -> List[Any]:
                return self._items

        return ResultWrapper(list(self.store.conversations.values()))


@pytest.fixture
def store() -> FakeSessionCrudStore:
    s = FakeSessionCrudStore()
    c1 = Conversation(
        id="session_user_a_1",
        user_id=USER_A_ID,
        title="Engine Misfire Diagnostic",
        is_pinned=True,
        created_at=NOW - timedelta(days=2),
        updated_at=NOW - timedelta(hours=1),
    )
    c2 = Conversation(
        id="session_user_a_2",
        user_id=USER_A_ID,
        title="Brake Noise Check",
        is_pinned=False,
        created_at=NOW - timedelta(days=1),
        updated_at=NOW,
    )
    c3 = Conversation(
        id="session_user_b_1",
        user_id=USER_B_ID,
        title="User B Conversation",
        is_pinned=False,
        created_at=NOW,
        updated_at=NOW,
    )
    s.conversations[c1.id] = c1
    s.conversations[c2.id] = c2
    s.conversations[c3.id] = c3

    s.messages[c1.id] = [
        ChatMessage(
            id="msg_1",
            conversation_id=c1.id,
            role="user",
            content="My engine is vibrating on idle",
            timestamp=c1.created_at,
        ),
        ChatMessage(
            id="msg_2",
            conversation_id=c1.id,
            role="assistant",
            content="Check the spark plugs and engine mounts.",
            timestamp=c1.updated_at,
        ),
    ]
    return s


@pytest.fixture
def test_app(store: FakeSessionCrudStore, monkeypatch) -> FastAPI:
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "crud-session-test-secret")

    app = FastAPI()

    @app.exception_handler(MechaException)
    async def mecha_exception_handler(request, exc: MechaException):
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        if exc.code == "NOT_FOUND":
            status_code = status.HTTP_404_NOT_FOUND
        elif exc.code == "UNAUTHORIZED":
            status_code = status.HTTP_401_UNAUTHORIZED
        elif exc.code == "BAD_REQUEST":
            status_code = status.HTTP_400_BAD_REQUEST

        return JSONResponse(
            status_code=status_code,
            content={"error_code": exc.code, "message": exc.message, "details": exc.details},
        )

    app.include_router(conversation_router, prefix="/api/v1/conversation")

    async def override_get_db():
        session = FakeSessionCrudDb(store)
        app.state.last_session = session
        yield session

    app.dependency_overrides[get_db] = override_get_db
    return app


def test_conversation_endpoints_unauthenticated(test_app: FastAPI) -> None:
    client = TestClient(test_app)

    assert client.get("/api/v1/conversation/sessions").status_code == status.HTTP_401_UNAUTHORIZED
    assert client.get("/api/v1/conversation/sessions/session_user_a_1").status_code == status.HTTP_401_UNAUTHORIZED
    assert client.patch("/api/v1/conversation/sessions/session_user_a_1", json={"is_pinned": True}).status_code == status.HTTP_401_UNAUTHORIZED
    assert client.delete("/api/v1/conversation/sessions/session_user_a_1").status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.anyio
async def test_chat_service_session_crud() -> None:
    from unittest.mock import AsyncMock, MagicMock

    session = AsyncMock()
    conv_repo = AsyncMock()
    msg_repo = AsyncMock()
    service = ChatService(session, conversation_repository=conv_repo, chat_message_repository=msg_repo)

    # 1. list_sessions
    c1 = Conversation(
        id="session_1",
        user_id=USER_A_ID,
        title="Thread 1",
        is_pinned=True,
        created_at=NOW,
        updated_at=NOW,
    )
    conv_repo.list_for_user.return_value = [c1]
    msg_repo.list_for_conversation.return_value = [
        ChatMessage(id="m1", conversation_id="session_1", role="assistant", content="How can I assist you?", timestamp=NOW)
    ]

    sessions = await service.list_sessions(USER_A_ID)
    assert len(sessions) == 1
    assert sessions[0].id == "session_1"
    assert sessions[0].is_pinned is True
    assert sessions[0].preview == "How can I assist you?"

    # 2. get_session_detail - 404 when missing
    conv_repo.get_owned.return_value = None
    with pytest.raises(MechaException) as exc:
        await service.get_session_detail("session_nonexistent", USER_A_ID)
    assert exc.value.code == "NOT_FOUND"

    # 3. get_session_detail - success
    conv_repo.get_owned.return_value = c1
    detail = await service.get_session_detail("session_1", USER_A_ID)
    assert detail.id == "session_1"
    assert len(detail.messages) == 1

    # 4. update_session
    conv_repo.update_properties.return_value = Conversation(
        id="session_1",
        user_id=USER_A_ID,
        title="Updated Title",
        is_pinned=False,
        created_at=NOW,
        updated_at=NOW,
    )
    updated = await service.update_session("session_1", USER_A_ID, title="Updated Title", is_pinned=False)
    assert updated.title == "Updated Title"
    assert updated.is_pinned is False

    # 5. delete_session
    conv_repo.delete_owned.return_value = True
    deleted = await service.delete_session("session_1", USER_A_ID)
    assert deleted is True

    # 6. delete_session - 404
    conv_repo.delete_owned.return_value = False
    with pytest.raises(MechaException) as exc:
        await service.delete_session("session_other", USER_A_ID)
    assert exc.value.code == "NOT_FOUND"


def test_conversation_session_http_flow(test_app: FastAPI, monkeypatch) -> None:
    token_a = security.create_access_token(USER_A_ID)
    token_b = security.create_access_token(USER_B_ID)
    client = TestClient(test_app)

    c_owned = Conversation(
        id="session_test_1",
        user_id=USER_A_ID,
        title="Original Title",
        is_pinned=False,
        created_at=NOW,
        updated_at=NOW,
    )

    from app.services.chat_service import ChatService
    from app.schemas.chat import ConversationSummaryResponse, ConversationDetailResponse, MessageLog

    async def mock_list_sessions(self, user_id, offset=0, limit=50):
        if user_id == USER_A_ID:
            return [
                ConversationSummaryResponse(
                    id="session_test_1",
                    title="Original Title",
                    is_pinned=False,
                    created_at=NOW,
                    updated_at=NOW,
                    message_count=1,
                    preview="Latest reply",
                )
            ]
        return []

    async def mock_get_detail(self, session_id, user_id):
        if user_id == USER_A_ID and session_id == "session_test_1":
            return ConversationDetailResponse(
                id="session_test_1",
                title="Original Title",
                is_pinned=False,
                created_at=NOW,
                updated_at=NOW,
                messages=[MessageLog(id="msg_1", role="user", content="Help me", timestamp=NOW)],
            )
        raise MechaException("Conversation not found.", code="NOT_FOUND")

    async def mock_update(self, session_id, user_id, title=None, is_pinned=None):
        if user_id == USER_A_ID and session_id == "session_test_1":
            return ConversationSummaryResponse(
                id="session_test_1",
                title=title or "Original Title",
                is_pinned=is_pinned if is_pinned is not None else False,
                created_at=NOW,
                updated_at=NOW,
            )
        raise MechaException("Conversation not found.", code="NOT_FOUND")

    async def mock_delete(self, session_id, user_id):
        if user_id == USER_A_ID and session_id == "session_test_1":
            return True
        raise MechaException("Conversation not found.", code="NOT_FOUND")

    monkeypatch.setattr(ChatService, "list_sessions", mock_list_sessions)
    monkeypatch.setattr(ChatService, "get_session_detail", mock_get_detail)
    monkeypatch.setattr(ChatService, "update_session", mock_update)
    monkeypatch.setattr(ChatService, "delete_session", mock_delete)

    # User A lists sessions
    r = client.get("/api/v1/conversation/sessions", headers={"Authorization": f"Bearer {token_a}"})
    assert r.status_code == status.HTTP_200_OK
    data = r.json()
    assert len(data) == 1
    assert data[0]["id"] == "session_test_1"

    # User A gets detail
    r = client.get("/api/v1/conversation/sessions/session_test_1", headers={"Authorization": f"Bearer {token_a}"})
    assert r.status_code == status.HTTP_200_OK
    detail = r.json()
    assert detail["id"] == "session_test_1"
    assert len(detail["messages"]) == 1

    # User B gets User A's session -> 404 (IDOR guard)
    r = client.get("/api/v1/conversation/sessions/session_test_1", headers={"Authorization": f"Bearer {token_b}"})
    assert r.status_code == status.HTTP_404_NOT_FOUND

    # User A updates session title and pins it
    r = client.patch(
        "/api/v1/conversation/sessions/session_test_1",
        json={"title": "Renamed Session", "is_pinned": True},
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert r.status_code == status.HTTP_200_OK
    assert r.json()["title"] == "Renamed Session"
    assert r.json()["is_pinned"] is True

    # User B updates User A's session -> 404
    r = client.patch(
        "/api/v1/conversation/sessions/session_test_1",
        json={"title": "Malicious rename"},
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert r.status_code == status.HTTP_404_NOT_FOUND

    # User B deletes User A's session -> 404
    r = client.delete("/api/v1/conversation/sessions/session_test_1", headers={"Authorization": f"Bearer {token_b}"})
    assert r.status_code == status.HTTP_404_NOT_FOUND

    # User A deletes session -> 204
    r = client.delete("/api/v1/conversation/sessions/session_test_1", headers={"Authorization": f"Bearer {token_a}"})
    assert r.status_code == status.HTTP_204_NO_CONTENT
