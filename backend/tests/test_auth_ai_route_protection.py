"""Tests for Stage 8 auth-only protection of the AI routers.

Strategy (mirrors Stage 7 test_auth_api.py):
- Build a lightweight FastAPI app that mounts ONLY the three AI routers
  (diagnosis, knowledge, conversation) + a public /health + the auth router,
  and registers the same ``MechaException`` mapping as ``app.main``.
- ``get_db`` is overridden with a fake session; ``get_current_user`` runs the
  REAL ``app.api.deps`` implementation (real JWT verification) against a real
  configured test secret.
- AI services are patched at the class/module boundary (their module-level
  singletons) so no live model/FAISS/Gemini work happens — the tests prove the
  ROUTE auth layer, not the AI inference.
- No live PostgreSQL required.

For EVERY protected AI endpoint we verify:
  1. missing Authorization header → 401
  2. malformed Authorization header → 401
  3. invalid JWT → 401
  4. expired access token → 401
  5. refresh token used as access token → 401
  6. valid access token → passes auth (service reached)
  7. inactive user → 401
Also: /health stays public; auth endpoints remain reachable; AI services are
still invoked after successful authentication.
"""

from datetime import datetime, timedelta, timezone
from typing import Dict, Optional

import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api import deps
from app.api.deps import get_db
from app.core import security
from app.core.config import settings
from app.core.exceptions import MechaException
from app.models.user import User

TEST_JWT_SECRET = "stage8-ai-route-protection-test-secret"
USER_ID = "22222222-2222-2222-2222-222222222222"
NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)


class FakeSession:
    """Minimal session supporting exactly the repository calls used here."""

    def __init__(self, users: Optional[Dict[str, User]] = None) -> None:
        self.users = users or {}

    async def get(self, model, entity_id) -> Optional[User]:
        if model is User:
            return self.users.get(str(entity_id))
        return None


def make_user(**overrides) -> User:
    defaults: Dict = {
        "id": USER_ID,
        "name": "Jagadeesh Gowda",
        "email": "jagadeesh@example.com",
        "phone": "+919876543210",
        "password_hash": "$2b$12$irrelevantforthisstage8",
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


def _access_token(user_id: str = USER_ID, expires_in: Optional[timedelta] = None) -> str:
    return security.create_access_token(user_id, expires_in=expires_in)


def _refresh_token(user_id: str = USER_ID) -> str:
    return security.create_refresh_token(user_id)


# ============================================================================
# Lightweight app: the three AI routers + /health + auth router
# ============================================================================


@pytest.fixture
def auth_app(monkeypatch) -> FastAPI:
    """Mount the real AI routers + auth router + a public /health.

    AI services are patched at their module-level singleton boundary so the
    real inference stack (model files, FAISS index, Gemini) is never loaded.
    """
    from app.api.v1 import conversation as conversation_router_mod
    from app.api.v1 import diagnosis as diagnosis_router_mod
    from app.api.v1 import knowledge as knowledge_router_mod
    from app.schemas.chat import ChatResponse, HistoryResponse, SessionResponse
    from app.schemas.diagnosis import DiagnosisResponse
    from app.schemas.knowledge import KnowledgeResponse

    # --- Patch the service (request-scoped class boundary) ---
    class FakeChatService:
        """Mirrors the Task 4 request-scoped ChatService signatures.

        Constructor takes the request ``session`` (unused here) and the three
        public methods are async with the ``user_id`` ownership argument —
        matching ``app.services.chat_service.ChatService`` exactly.
        """

        def __init__(self, session=None) -> None:
            self.sessions: Dict[str, list] = {}
            self.chat_calls = 0

        async def create_session(self, user_id: str) -> str:
            return "session_stage8_test"

        async def get_session_history(self, session_id: str, user_id: str) -> list:
            if session_id not in self.sessions:
                from fastapi import HTTPException

                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found.")
            return self.sessions[session_id]

        async def handle_chat(self, payload, user_id: str) -> ChatResponse:
            self.chat_calls += 1
            self.sessions.setdefault(payload.session_id, []).extend(
                [
                    {"role": "user", "content": payload.message},
                    {"role": "assistant", "content": "Test assistant reply"},
                ]
            )
            return ChatResponse(
                response="Test assistant reply",
                intent="General Vehicle Question",
                session_id=payload.session_id,
                diagnostic_details=None,
                latency_ms=1.0,
                llm_latency_ms=None,
            )

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

    class FakeRagService:
        def query_rag(self, payload) -> KnowledgeResponse:
            from app.schemas.knowledge import SourceDoc

            return KnowledgeResponse(answer="Grounded test answer", sources=[SourceDoc(source="manual", category="general", score=0.5)])

    fake_chat = FakeChatService()
    fake_diag = FakeDiagnosisService()
    fake_rag = FakeRagService()
    # Routes construct ChatService(session) per request (request-scoped wiring);
    # patch the class so every construction resolves to the same fake instance.
    monkeypatch.setattr(conversation_router_mod, "ChatService", lambda session: fake_chat)
    monkeypatch.setattr(diagnosis_router_mod, "diagnosis_service", fake_diag)
    monkeypatch.setattr(knowledge_router_mod, "rag_service", fake_rag)

    # --- Build the app ---
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

    from app.api.v1 import conversation, diagnosis, knowledge
    from app.api.v1 import auth as auth_router

    app.include_router(diagnosis.router, prefix="/api/v1/diagnosis")
    app.include_router(knowledge.router, prefix="/api/v1/knowledge")
    app.include_router(conversation.router, prefix="/api/v1/conversation")
    app.include_router(auth_router.router, prefix="/api/v1/auth")

    # No live DB: routes resolve their session to a fake session.
    async def _default_db():
        yield FakeSession()

    app.dependency_overrides[get_db] = _default_db

    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)
    return app


@pytest.fixture
def client(auth_app) -> TestClient:
    return TestClient(auth_app)


# The endpoints under test: (method, path, json_body)
DIAGNOSIS = ("post", "/api/v1/diagnosis/diagnose", {"mileage": 85000})
KNOWLEDGE = ("post", "/api/v1/knowledge/query", {"query": "What does P0300 mean?"})
CHAT = ("post", "/api/v1/conversation/chat", {"message": "My car won't start", "session_id": "session_x"})
SESSION = ("post", "/api/v1/conversation/session", {})
HISTORY = ("get", "/api/v1/conversation/history?session_id=session_x", {})

PROTECTED_ENDPOINTS = [DIAGNOSIS, KNOWLEDGE, CHAT, SESSION, HISTORY]


def _auth_headers(token: Optional[str]) -> Optional[Dict[str, str]]:
    return {"Authorization": f"Bearer {token}"} if token is not None else None


def _request(client, method, path, body, headers=None):
    kwargs = {"headers": headers} if headers is not None else {}
    if body:
        kwargs["json"] = body
    return getattr(client, method)(path, **kwargs)


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_missing_authorization_header_rejected(client, method, path, body) -> None:
    response = _request(client, method, path, body)
    assert response.status_code == 401
    assert response.json()["error_code"] == "UNAUTHORIZED"


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_malformed_authorization_header_rejected(client, method, path, body) -> None:
    response = _request(client, method, path, body, headers=_auth_headers("not-a-jwt"))
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_invalid_jwt_rejected(client, method, path, body) -> None:
    garbage = _access_token()[:-10] + "x" * 10  # tampered signature
    response = _request(client, method, path, body, headers=_auth_headers(garbage))
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_expired_access_token_rejected(client, method, path, body) -> None:
    expired = _access_token(expires_in=timedelta(seconds=-60))
    response = _request(client, method, path, body, headers=_auth_headers(expired))
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_refresh_token_rejected_as_access(client, method, path, body) -> None:
    response = _request(client, method, path, body, headers=_auth_headers(_refresh_token()))
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_inactive_user_rejected(client, method, path, body) -> None:
    # The default fake session has no users; to reach the inactive check the
    # user must exist — override with an inactive user.
    async def _db_with_inactive():
        yield FakeSession({USER_ID: make_user(is_active=False)})

    client.app.dependency_overrides[get_db] = _db_with_inactive
    response = _request(client, method, path, body, headers=_auth_headers(_access_token()))
    assert response.status_code == 401


@pytest.mark.parametrize("method,path,body", PROTECTED_ENDPOINTS, ids=["diagnose", "knowledge", "chat", "session", "history"])
def test_valid_access_token_passes_auth(client, method, path, body) -> None:
    async def _db_with_active_user():
        yield FakeSession({USER_ID: make_user()})

    client.app.dependency_overrides[get_db] = _db_with_active_user

    # History returns 404 for an unknown session AFTER auth passes — that is
    # still proof the authentication layer let the request through.
    response = _request(client, method, path, body, headers=_auth_headers(_access_token()))
    assert response.status_code != 401
    assert response.status_code in (200, 201, 404)


def test_health_remains_public(client) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_auth_endpoints_remain_registered(client) -> None:
    schema = client.app.openapi()
    auth_paths = [p for p in schema["paths"] if p.startswith("/api/v1/auth")]
    assert sorted(auth_paths) == [
        "/api/v1/auth/forgot-password",
        "/api/v1/auth/login",
        "/api/v1/auth/logout",
        "/api/v1/auth/me",
        "/api/v1/auth/refresh",
        "/api/v1/auth/register",
        "/api/v1/auth/reset-password",
        "/api/v1/auth/verify",
    ]


def test_openapi_marks_ai_paths_with_security(client) -> None:
    """Each protected AI path must declare the bearer security requirement."""
    schema = client.app.openapi()
    for path in [
        "/api/v1/diagnosis/diagnose",
        "/api/v1/knowledge/query",
        "/api/v1/conversation/chat",
        "/api/v1/conversation/session",
        "/api/v1/conversation/history",
    ]:
        for op in schema["paths"][path].values():
            assert "security" in op, f"{path} {list(op)} missing security requirement"
    # /health must NOT require security
    for op in schema["paths"]["/health"].values():
        assert "security" not in op


def test_diagnosis_service_called_after_auth(client) -> None:
    from app.api.v1 import diagnosis as diagnosis_router_mod

    calls = []

    def _spy_predict_fault(payload):
        calls.append(payload)
        return {
            "predicted_fault": "Engine Misfire",
            "confidence": 0.95,
            "estimated_cost": 1200,
            "repair_time": "3-4 hours",
            "safety_advice": "Do not drive.",
            "diagnosis_mode": "symptom",
        }

    client.app.dependency_overrides[get_db] = _db_with_active_user_factory()

    # Patch the singleton reference bound in the router module (the route
    # calls diagnosis_router_mod.diagnosis_service.predict_fault).
    svc = diagnosis_router_mod.diagnosis_service
    svc.predict_fault = _spy_predict_fault

    response = client.post(
        "/api/v1/diagnosis/diagnose",
        json={"mileage": 85000, "symptoms": ["Engine vibration"]},
        headers=_auth_headers(_access_token()),
    )
    assert response.status_code == 200
    assert response.json()["predicted_fault"] == "Engine Misfire"
    assert len(calls) == 1
    assert calls[0].mileage == 85000


def _db_with_active_user_factory():
    async def _db_with_active_user():
        yield FakeSession({USER_ID: make_user()})

    return _db_with_active_user


def test_chat_service_called_after_auth(client) -> None:
    from app.api.v1 import conversation as conversation_router_mod

    client.app.dependency_overrides[get_db] = _db_with_active_user_factory()

    # The fixture patches ChatService construction to a single fake instance
    # shared across requests; reach it via the module-bound class.
    svc = conversation_router_mod.ChatService(None)
    before = svc.chat_calls
    response = client.post(
        "/api/v1/conversation/chat",
        json={"message": "Test message", "session_id": "session_abc"},
        headers=_auth_headers(_access_token()),
    )
    assert response.status_code == 200
    assert svc.chat_calls == before + 1
    assert response.json()["response"] == "Test assistant reply"


def test_conversation_session_and_history_flow(client) -> None:
    """Authenticated session creation + history retrieval work end-to-end."""
    from app.api.v1 import conversation as conversation_router_mod

    client.app.dependency_overrides[get_db] = _db_with_active_user_factory()

    svc = conversation_router_mod.ChatService(None)
    headers = _auth_headers(_access_token())

    # Seed a session through the fake service so history can be read.
    sid = "session_flow"
    svc.sessions[sid] = [
        {"role": "user", "content": "hi"},
        {"role": "assistant", "content": "hello"},
    ]

    response = client.post("/api/v1/conversation/session", headers=headers)
    assert response.status_code == 201
    assert response.json()["session_id"] == "session_stage8_test"

    history = client.get(f"/api/v1/conversation/history?session_id={sid}", headers=headers)
    assert history.status_code == 200
    assert len(history.json()["history"]) == 2