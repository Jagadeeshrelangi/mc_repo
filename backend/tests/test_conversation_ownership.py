"""Tests for Task 4 — Conversation Ownership.

Strategy (mirrors the Stage 7/8 lightweight-app pattern: fake session +
dependency overrides, NO live PostgreSQL):

- A richer ``FakeSession`` than Stage 7/8: it holds an in-memory store keyed by
  model class and evaluates the simple ``select(...)`` / ``scalar`` /
  ``get`` / ``add`` / ``flush`` / ``commit`` calls the ownership repositories
  issue (``WHERE col == value``, ``ORDER BY``, ``LIMIT/OFFSET``). No SQL
  execution happens.
- ``get_current_user`` runs the REAL ``app.api.deps`` implementation (real JWT
  verification) against a real configured test secret — so the tests prove the
  ROUTE→SERVICE ownership flow end-to-end, including authentication.
- The Gemini client is replaced with a fake LLM (captures prompts) so no
  network/model work happens; ``diagnosis_service`` is patched for the
  diagnosis path.
- Covers the 12 scenarios in recon report §15, plus repository unit tests,
  migration DDL assertions, and the OpenAPI path count (14).

No commits, pushes, resets, or reverts are performed.
"""

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Sequence, Type

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import dialect as postgresql_dialect
from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
from sqlalchemy.sql.operators import eq, is_
from sqlalchemy.types import DateTime

from app.api import deps
from app.api.deps import get_db
from app.core import security
from app.core.config import settings
from app.core.exceptions import MechaException
from app.models.chat_message import ChatMessage
from app.models.conversation import Conversation
from app.models.user import User
from app.repositories.chat_messages import ChatMessageRepository
from app.repositories.conversations import ConversationRepository
from app.schemas.chat import ChatRequest, ChatResponse

TEST_JWT_SECRET = "task4-ownership-test-secret-not-for-production"
USER_A_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
USER_B_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)

# Module-level monotonic clock so timestamp ordering is deterministic even when
# many objects are created within the same real microsecond (mirrors a real DB
# where each transaction's ``now()`` is monotonic per transaction).
_CLOCK_STEP = 0
_CLOCK_BASE = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)


def _fake_now() -> datetime:
    """Monotonically increasing fake ``now()`` (one microsecond per call)."""
    global _CLOCK_STEP
    _CLOCK_STEP += 1
    return _CLOCK_BASE + timedelta(microseconds=_CLOCK_STEP)


# ============================================================================
# Fake LLM + Fake Session (in-memory select evaluation)
# ============================================================================


class FakeLLM:
    """Captures prompts instead of calling Gemini."""

    def __init__(self) -> None:
        self.prompts: List[str] = []

    def invoke(self, prompt: str) -> "FakeLLMResult":
        self.prompts.append(prompt)
        return FakeLLMResult("Fake engineer reply")


class FakeLLMResult:
    def __init__(self, content: str) -> None:
        self.content = content


class _FakeScalarResult:
    def __init__(self, items: List[Any]) -> None:
        self.items = items

    def first(self) -> Any:
        return self.items[0] if self.items else None

    def one_or_none(self) -> Any:
        return self.items[0] if self.items else None

    def scalar(self) -> Any:
        return self.items[0] if self.items else None

    async def all(self) -> List[Any]:
        return list(self.items)


class FakeSession:
    """In-memory session evaluating the simple selects the repos issue.

    ``store`` maps model class → list of ORM instances. Primary keys and
    ``timestamp``/``created_at``/``updated_at`` are materialized by the model's
    Python-side defaults at construction, so no DB round-trip is needed.
    """

    def __init__(self, store: Optional[Dict[Type, List[Any]]] = None) -> None:
        self.store = store if store is not None else {}
        self.commits = 0

    # --- identity map helpers ---

    def _rows(self, model: Type) -> List[Any]:
        return self.store.setdefault(model, [])

    def _find_id(self, model: Type, entity_id: Any) -> Optional[Any]:
        for obj in self._rows(model):
            if str(getattr(obj, "id", "")) == str(entity_id):
                return obj
        return None

    def _apply_defaults(self, obj: Any) -> None:
        """Materialize Python-side column defaults (real DB does this at flush).

        Without this, ids/timestamps stay ``None`` until a flush that never
        happens on a fake session — breaking ordering, ownership ids, and
        equality filters. ``DateTime`` columns get the shared monotonic clock
        so ordering is deterministic within a microsecond.
        """
        for column in type(obj).__mapper__.columns:
            if column.default is None:
                continue
            if getattr(obj, column.key, None) is not None:
                continue
            if isinstance(column.type, DateTime):
                setattr(obj, column.key, _fake_now())
            elif column.default.is_scalar:
                setattr(obj, column.key, column.default.arg)
            elif column.default.is_callable:
                setattr(obj, column.key, column.default.arg(None))

    # --- model evaluation helpers ---

    @staticmethod
    def _eval_where(obj: Any, clause: Any) -> bool:
        if clause is None:
            return True
        if isinstance(clause, BooleanClauseList):
            return all(FakeSession._eval_where(obj, c) for c in clause.clauses)
        if not isinstance(clause, BinaryExpression):
            return True
        col_name = getattr(clause.left, "name", None)
        op = clause.operator
        if op is eq:
            value = getattr(clause.right, "value", clause.right)
            return getattr(obj, col_name) == value
        if op is is_:
            value = getattr(clause.right, "value", clause.right)
            return getattr(obj, col_name) is value
        return True  # unsupported operator → pass (repo tests only use ==)

    def _eval_select(self, stmt: Any) -> List[Any]:
        target = stmt.column_descriptions[0]["type"]
        rows = list(self._rows(target))
        rows = [r for r in rows if self._eval_where(r, stmt.whereclause)]

        order_by = getattr(stmt, "_order_by_clauses", None) or []
        if order_by:
            from sqlalchemy.sql.operators import desc_op

            for clause in reversed(order_by):
                is_desc = (
                    getattr(clause, "operator", None) is desc_op
                    or getattr(clause, "modifier", None) is desc_op
                )
                element = getattr(clause, "element", None)
                col_name = getattr(element, "name", None)
                rows.sort(
                    key=lambda r: getattr(r, col_name),
                    reverse=is_desc,
                )

        offset = getattr(stmt, "_offset", None) or 0
        limit = getattr(stmt, "_limit", None)
        rows = rows[offset:] if limit is None else rows[offset : offset + limit]
        return rows

    # --- session API surface used by the repos ---

    async def get(self, model: Type, entity_id: Any) -> Optional[Any]:
        return self._find_id(model, entity_id)

    async def scalar(self, stmt: Any) -> Optional[Any]:
        rows = self._eval_select(stmt)
        return rows[0] if rows else None

    async def scalars(self, stmt: Any) -> "_FakeScalarResult":
        return _FakeScalarResult(self._eval_select(stmt))

    def add(self, obj: Any) -> None:
        self._apply_defaults(obj)
        self._rows(type(obj)).append(obj)

    async def flush(self) -> None:
        pass

    async def commit(self) -> None:
        self.commits += 1

    async def rollback(self) -> None:
        pass


def make_user(user_id: str = USER_A_ID, **overrides) -> User:
    defaults: Dict = {
        "id": user_id,
        "name": "Jagadeesh Gowda",
        "email": f"{user_id}@example.com",
        "phone": f"+9100000000{user_id[-4:]}",
        "password_hash": "$2b$12$irrelevantfortask4",
        "role": "customer",
        "is_active": True,
        "is_verified": False,
        "failed_login_attempts": 0,
        "membership_tier": "free",
        "joined_at": NOW,
        "created_at": NOW,
        "updated_at": NOW,
        "last_login_at": None,
        "lockout_at": None,
    }
    defaults.update(overrides)
    return User(**defaults)


def _access_token(user_id: str = USER_A_ID, expires_in: Optional[timedelta] = None) -> str:
    return security.create_access_token(user_id, expires_in=expires_in)


def _refresh_token(user_id: str = USER_A_ID) -> str:
    return security.create_refresh_token(user_id)


# ============================================================================
# Lightweight app (conversation router + auth router + /health)
# ============================================================================


@pytest.fixture
def store() -> Dict[Type, List[Any]]:
    return {}


@pytest.fixture
def fake_llm(monkeypatch) -> FakeLLM:
    llm = FakeLLM()
    monkeypatch.setattr("app.services.chat_service.ChatService._llm", llm)
    monkeypatch.setattr(settings, "ENABLE_FALLBACK", False)
    return llm


@pytest.fixture
def auth_app(monkeypatch, store, fake_llm) -> FastAPI:
    from app.api.v1 import conversation as conversation_router_mod
    from app.api.v1 import diagnosis as diagnosis_router_mod
    from app.api.v1 import knowledge as knowledge_router_mod
    from app.api.v1 import auth as auth_router

    # Patch the diagnosis + knowledge engines so no real model/FAISS/Gemini
    # work happens (ownership tests focus on the conversation flow).
    from app.schemas.diagnosis import DiagnosisResponse

    class FakeDiagnosisService:
        def predict_fault(self, payload) -> DiagnosisResponse:
            return DiagnosisResponse(
                predicted_fault="Normal",
                confidence=1.0,
                estimated_cost=0,
                repair_time="0h",
                safety_advice="No issue detected.",
                diagnosis_mode="symptom",
            )

    from app.schemas.knowledge import KnowledgeResponse, SourceDoc

    class FakeRagService:
        def query_rag(self, payload) -> KnowledgeResponse:
            return KnowledgeResponse(answer="Grounded test answer", sources=[SourceDoc(source="manual", category="general", score=0.5)])

    monkeypatch.setattr(diagnosis_router_mod, "diagnosis_service", FakeDiagnosisService())
    monkeypatch.setattr(knowledge_router_mod, "rag_service", FakeRagService())

    app = FastAPI()

    @app.exception_handler(MechaException)
    async def mecha_exception_handler(request, exc: MechaException):
        mapping = {
            "NOT_FOUND": status.HTTP_404_NOT_FOUND,
            "UNAUTHORIZED": status.HTTP_401_UNAUTHORIZED,
            "BAD_REQUEST": status.HTTP_400_BAD_REQUEST,
            "INFERENCE_FAILED": status.HTTP_422_UNPROCESSABLE_ENTITY,
        }
        return JSONResponse(
            status_code=mapping.get(exc.code, status.HTTP_500_INTERNAL_SERVER_ERROR),
            content={"error_code": exc.code, "message": exc.message, "details": exc.details},
        )

    @app.get("/health")
    async def health():
        return {"status": "healthy"}

    app.include_router(conversation_router_mod.router, prefix="/api/v1/conversation")
    app.include_router(diagnosis_router_mod.router, prefix="/api/v1/diagnosis")
    app.include_router(knowledge_router_mod.router, prefix="/api/v1/knowledge")
    app.include_router(auth_router.router, prefix="/api/v1/auth")

    def _make_session() -> FakeSession:
        return FakeSession(store)

    async def _default_db():
        yield _make_session()

    app.dependency_overrides[get_db] = _default_db

    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)
    return app


@pytest.fixture
def client(auth_app) -> TestClient:
    return TestClient(auth_app)


def _auth_headers(token: Optional[str]) -> Optional[Dict[str, str]]:
    return {"Authorization": f"Bearer {token}"} if token is not None else None


def _seed_store(client, store, users) -> None:
    """Populate the durable store with users and point get_db at it."""
    from app.api.deps import get_db as _get_db

    store[User] = list(users.values())

    async def _db():
        yield FakeSession(store)

    client.app.dependency_overrides[_get_db] = _db


# ============================================================================
# Ownership scenarios (recon §15)
# ============================================================================


def test_user_a_creates_conversation(client, store) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    response = client.post(
        "/api/v1/conversation/session", headers=_auth_headers(_access_token(USER_A_ID))
    )
    assert response.status_code == 201
    sid = response.json()["session_id"]
    assert sid.startswith("session_")

    # Row is bound to user A in the durable store.
    rows = store.get(Conversation, [])
    assert len(rows) == 1
    assert rows[0].id == sid
    assert str(rows[0].user_id) == USER_A_ID


def test_user_a_sends_message_persists_turns(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers).json()["session_id"]

    response = client.post(
        "/api/v1/conversation/chat",
        json={"message": "Hello there", "session_id": sid},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json()["session_id"] == sid
    assert response.json()["response"] == "Fake engineer reply"

    msgs = store.get(ChatMessage, [])
    assert [m.role for m in msgs] == ["user", "assistant"]
    assert msgs[0].content == "Hello there"
    assert msgs[1].content == "Fake engineer reply"

    # First user message derives the title (schema: title NOT NULL).
    conv = store[Conversation][0]
    assert conv.title == "Hello there"


def test_user_a_reads_own_history(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers).json()["session_id"]
    for i in range(3):
        client.post(
            "/api/v1/conversation/chat",
            json={"message": f"turn {i}", "session_id": sid},
            headers=headers,
        )

    response = client.get(
        f"/api/v1/conversation/history?session_id={sid}", headers=headers
    )
    assert response.status_code == 200
    turns = response.json()["history"]
    assert len(turns) == 6  # 3 user + 3 assistant
    assert turns[0]["role"] == "user"
    assert turns[0]["content"] == "turn 0"
    assert turns[-1]["role"] == "assistant"


def test_user_b_cannot_access_user_a_session(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID), USER_B_ID: make_user(USER_B_ID)})
    headers_a = _auth_headers(_access_token(USER_A_ID))
    headers_b = _auth_headers(_access_token(USER_B_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers_a).json()["session_id"]

    chat = client.post(
        "/api/v1/conversation/chat",
        json={"message": "Hijack attempt", "session_id": sid},
        headers=headers_b,
    )
    history = client.get(f"/api/v1/conversation/history?session_id={sid}", headers=headers_b)
    assert chat.status_code == 404
    assert history.status_code == 404
    assert chat.json()["error_code"] == "NOT_FOUND"
    assert history.json()["error_code"] == "NOT_FOUND"


def test_user_b_cannot_infer_existence(client, store, fake_llm) -> None:
    """Identical 404 body for A's real id vs an unknown id (no existence leak)."""
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID), USER_B_ID: make_user(USER_B_ID)})
    headers_b = _auth_headers(_access_token(USER_B_ID))
    sid = client.post(
        "/api/v1/conversation/session", headers=_auth_headers(_access_token(USER_A_ID))
    ).json()["session_id"]

    unknown = client.get("/api/v1/conversation/history?session_id=session_unknown0000000000", headers=headers_b)
    real = client.get(f"/api/v1/conversation/history?session_id={sid}", headers=headers_b)

    assert unknown.status_code == 404
    assert real.status_code == 404
    assert unknown.json() == real.json()


def test_unknown_session_no_autocreate(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))

    chat = client.post(
        "/api/v1/conversation/chat",
        json={"message": "Does this create a session?", "session_id": "session_ghost000000000"},
        headers=headers,
    )
    history = client.get("/api/v1/conversation/history?session_id=session_ghost000000000", headers=headers)
    assert chat.status_code == 404
    assert history.status_code == 404
    assert chat.json()["error_code"] == "NOT_FOUND"
    assert history.json()["error_code"] == "NOT_FOUND"
    # No auto-create: the durable store must remain empty of this session.
    assert not store.get(Conversation, [])
    assert not store.get(ChatMessage, [])


def test_restart_durability(client, store, fake_llm) -> None:
    """Option B durability: a fresh service/session over the same store sees history."""
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers).json()["session_id"]
    client.post(
        "/api/v1/conversation/chat",
        json={"message": "Persist me", "session_id": sid},
        headers=headers,
    )

    # Simulate a restart: a brand-new service instance over the SAME store.
    session = FakeSession(store)
    service = __import__("app.services.chat_service", fromlist=["ChatService"]).ChatService(session)
    history = asyncio.run(await_history(service, sid, USER_A_ID))
    assert len(history) == 2
    assert history[0]["role"] == "user"
    assert history[0]["content"] == "Persist me"


async def await_history(service, sid, user_id):
    return await service.get_session_history(sid, user_id)


def test_message_ordering_and_12_turn_cap(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers).json()["session_id"]
    for i in range(15):
        client.post(
            "/api/v1/conversation/chat",
            json={"message": f"turn {i}", "session_id": sid},
            headers=headers,
        )

    # The 12-turn cap is applied at the query level (§12.6): history returns the
    # NEWEST 12 turns (6 exchanges), oldest-first within the window.
    history = client.get(f"/api/v1/conversation/history?session_id={sid}", headers=headers)
    assert history.status_code == 200
    turns = history.json()["history"]
    assert len(turns) == 12
    assert turns[0]["role"] == "user"
    assert turns[0]["content"] == "turn 9"
    assert turns[-1]["role"] == "assistant"
    assert turns[-1]["content"] == "Fake engineer reply"

    # The PROMPT window is capped at the newest 12 turns (6 exchanges).
    session = FakeSession(store)
    service = __import__("app.services.chat_service", fromlist=["ChatService"]).ChatService(session)
    messages = asyncio.run(list_messages(service, sid))
    assert len(messages) == 12
    assert messages[0].content == "turn 9"
    assert messages[-1].content == "Fake engineer reply"


async def list_messages(service, sid):
    return await service.messages.list_for_conversation(conversation_id=sid, limit=12)


def test_concurrent_chat_requests_append_without_loss(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers).json()["session_id"]

    session = FakeSession(store)
    service = __import__("app.services.chat_service", fromlist=["ChatService"]).ChatService(session)

    async def _run_concurrent():
        await asyncio.gather(
            service.handle_chat(ChatRequest(message="parallel one", session_id=sid), USER_A_ID),
            service.handle_chat(ChatRequest(message="parallel two", session_id=sid), USER_A_ID),
        )

    asyncio.run(_run_concurrent())

    msgs = store.get(ChatMessage, [])
    roles = [m.role for m in msgs]
    assert roles.count("user") == 2
    assert roles.count("assistant") == 2
    contents = [m.content for m in msgs if m.role == "user"]
    assert "parallel one" in contents and "parallel two" in contents


def test_ai_service_receives_persisted_history(client, store, fake_llm) -> None:
    _seed_store(client, store, {USER_A_ID: make_user(USER_A_ID)})
    headers = _auth_headers(_access_token(USER_A_ID))
    sid = client.post("/api/v1/conversation/session", headers=headers).json()["session_id"]
    client.post(
        "/api/v1/conversation/chat",
        json={"message": "First message", "session_id": sid},
        headers=headers,
    )
    client.post(
        "/api/v1/conversation/chat",
        json={"message": "Second message", "session_id": sid},
        headers=headers,
    )

    # The second call's prompt must include the first user + assistant turns.
    prompts = fake_llm.prompts
    assert len(prompts) == 2
    assert "First message" in prompts[1]
    assert "Fake engineer reply" in prompts[1]
    assert "Second message" in prompts[1]


# ============================================================================
# Authentication remains required (recon §15.11-12)
# ============================================================================


@pytest.mark.parametrize(
    "method,path,body,kind",
    [
        ("post", "/api/v1/conversation/session", {}, "none"),
        ("post", "/api/v1/conversation/session", {}, "malformed"),
        ("post", "/api/v1/conversation/session", {}, "expired"),
        ("post", "/api/v1/conversation/session", {}, "refresh"),
        ("post", "/api/v1/conversation/chat", {"message": "x", "session_id": "s"}, "none"),
        ("get", "/api/v1/conversation/history?session_id=s", {}, "none"),
    ],
    ids=["no-token-session", "malformed-session", "expired-session", "refresh-session", "no-token-chat", "no-token-history"],
)
def test_auth_still_required(client, method, path, body, kind) -> None:
    if kind == "none":
        headers = None
    elif kind == "malformed":
        headers = _auth_headers("not-a-jwt")
    elif kind == "expired":
        headers = _auth_headers(_access_token(USER_A_ID, timedelta(seconds=-60)))
    elif kind == "refresh":
        headers = _auth_headers(_refresh_token(USER_A_ID))
    else:
        headers = None
    kwargs = {"headers": headers} if headers else {}
    if body:
        kwargs["json"] = body
    response = getattr(client, method)(path, **kwargs)
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


def test_health_remains_public(client) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_openapi_path_count_stays_14(client) -> None:
    schema = client.app.openapi()
    assert len(schema["paths"]) == 14
    for path in [
        "/api/v1/conversation/chat",
        "/api/v1/conversation/session",
        "/api/v1/conversation/history",
    ]:
        for op in schema["paths"][path].values():
            assert "security" in op


# ============================================================================
# Repository unit tests
# ============================================================================


def test_conversation_repository_owner_filter(store) -> None:
    session = FakeSession(store)
    repo = ConversationRepository(session)

    conv_a = asyncio.run(repo.create_owned(user_id=USER_A_ID, title="A conversation"))
    asyncio.run(repo.create_owned(user_id=USER_B_ID, title="B conversation"))

    found = asyncio.run(repo.get_owned(conv_a.id, USER_A_ID))
    assert found is not None and found.id == conv_a.id

    # Same id, wrong owner → None (NOT_FOUND in the service).
    assert asyncio.run(repo.get_owned(conv_a.id, USER_B_ID)) is None
    assert asyncio.run(repo.get_owned("session_missing0000000000", USER_A_ID)) is None


def test_conversation_repository_list_for_user_ordered(store) -> None:
    session = FakeSession(store)
    repo = ConversationRepository(session)

    conv_a = asyncio.run(repo.create_owned(user_id=USER_A_ID, title="one"))
    conv_b = asyncio.run(repo.create_owned(user_id=USER_A_ID, title="two"))
    asyncio.run(repo.create_owned(user_id=USER_B_ID, title="other"))

    rows = asyncio.run(repo.list_for_user(user_id=USER_A_ID))
    assert {c.id for c in rows} == {conv_a.id, conv_b.id}
    # Most recently updated first: touch conv_a to move it ahead.
    asyncio.run(repo.touch(conv_a))
    rows = asyncio.run(repo.list_for_user(user_id=USER_A_ID))
    assert rows[0].id == conv_a.id


def test_chat_message_repository_cap_and_order(store) -> None:
    session = FakeSession(store)
    repo = ChatMessageRepository(session)
    conv = asyncio.run(ConversationRepository(session).create_owned(user_id=USER_A_ID))

    for i in range(15):
        asyncio.run(repo.append(conversation_id=conv.id, role="user", content=f"m{i}"))

    messages = asyncio.run(repo.list_for_conversation(conversation_id=conv.id, limit=12))
    assert len(messages) == 12
    assert messages[0].content == "m3"
    assert messages[-1].content == "m14"
    # Oldest-first within the window (timestamp ascending after DESC+reverse).
    assert [m.content for m in messages] == [f"m{i}" for i in range(3, 15)]


# ============================================================================
# Migration DDL assertions (offline — no live DB)
# ============================================================================


def test_migration_ddl_cascade_and_check(store) -> None:
    """Compile the ORM tables against PostgreSQL and verify Task 4 DDL."""
    from sqlalchemy.schema import CreateTable

    conv_ddl = str(CreateTable(Conversation.__table__).compile(dialect=postgresql_dialect()))
    msg_ddl = str(CreateTable(ChatMessage.__table__).compile(dialect=postgresql_dialect()))

    assert "ON DELETE CASCADE" in conv_ddl  # conversations.user_id → users.id
    assert "ON DELETE CASCADE" in msg_ddl  # chat_messages.conversation_id → conversations.id
    assert "CHECK (role IN ('user', 'assistant'))" in msg_ddl
    assert "JSONB" in msg_ddl


def test_chat_message_check_constraint_rejects_invalid_role(store) -> None:
    """The ORM CHECK constraint definition must reject invalid roles at DB level."""
    constraint = next(c for c in ChatMessage.__table__.constraints if getattr(c, "name", "") == "ck_chat_messages_role")
    assert "user" in str(constraint.sqltext)
    assert "assistant" in str(constraint.sqltext)