"""Conversation API routes (Sprint 2, Task 4 — Conversation Ownership).

THIN HTTP LAYER over ``ChatService`` — no business logic, no repository access,
no session/ownership decisions. Handlers extract ``user.id`` from
``get_current_user()`` (never from the request body or the session id) and pass
it to the request-scoped service (mirrors the ``AuthService`` wiring in
``auth.py``).

Ownership semantics (recon report §9, §13):
- ``POST /chat`` — owner-guarded; unknown/foreign session → generic 404.
- ``POST /session`` — creates a conversation owned by the caller.
- ``GET /history`` — owner-guarded; unknown/foreign session → generic 404.
"""

from typing import List, Dict

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.chat import ChatRequest, ChatResponse, SessionResponse, HistoryResponse
from app.services.chat_service import ChatService

router = APIRouter(dependencies=[Depends(get_current_user)])


@router.post(
    "/chat",
    response_model=ChatResponse,
    status_code=status.HTTP_200_OK,
    summary="Automotive AI Chat Conversation",
    description="Continues a conversation with a Senior Automotive Engineer. Orchestrates intents to diagnostics, manual searches, or general troubleshooting."
)
async def chat_interaction(
    payload: ChatRequest,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> ChatResponse:
    """
    Interact with the Automotive AI Assistant:

    - **message**: User query or response text.
    - **session_id**: Active session token to track history memory.
    """
    service = ChatService(session)
    return await service.handle_chat(payload, user_id=user.id)


@router.post(
    "/session",
    response_model=SessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create New Conversation Session",
    description="Creates a persistent conversation owned by the authenticated user and returns its session id."
)
async def create_session(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> SessionResponse:
    """
    Create a new conversation session for the authenticated user.
    """
    service = ChatService(session)
    session_id = await service.create_session(user_id=user.id)
    return SessionResponse(session_id=session_id)


@router.get(
    "/history",
    response_model=HistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Retrieve Session History",
    description="Fetches the dialogue turns of a conversation, owner-guarded."
)
async def get_history(
    session_id: str = Query(..., description="The session key to load logs for."),
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> HistoryResponse:
    """
    Retrieve message lists:

    - **session_id**: The target session query key.
    """
    service = ChatService(session)
    logs: List[Dict[str, str]] = await service.get_session_history(
        session_id, user_id=user.id
    )
    return HistoryResponse(session_id=session_id, history=logs)