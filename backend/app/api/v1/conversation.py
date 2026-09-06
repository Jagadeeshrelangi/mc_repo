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

from typing import List, Dict, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.chat import (
    ChatRequest,
    ChatResponse,
    ConversationDetailResponse,
    ConversationSummaryResponse,
    ConversationUpdate,
    HistoryResponse,
    SessionResponse,
)
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
@router.post(
    "/sessions",
    response_model=SessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create New Conversation Session (RESTful alias)",
    include_in_schema=False,
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
    "/sessions",
    response_model=List[ConversationSummaryResponse],
    status_code=status.HTTP_200_OK,
    summary="List User's Conversation Sessions",
    description="Lists all conversations owned by the authenticated user, pinned first then newest updated.",
)
async def list_sessions(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[ConversationSummaryResponse]:
    """Fetch conversation sessions belonging to the caller."""
    service = ChatService(session)
    return await service.list_sessions(user_id=user.id, offset=offset, limit=limit)


@router.get(
    "/sessions/{session_id}",
    response_model=ConversationDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Conversation Session Details",
    description="Fetch a conversation session and all its message turns, owner-guarded.",
)
async def get_session_detail(
    session_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> ConversationDetailResponse:
    """Fetch an owned conversation and its dialogue history."""
    service = ChatService(session)
    return await service.get_session_detail(session_id=session_id, user_id=user.id)


@router.patch(
    "/sessions/{session_id}",
    response_model=ConversationSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Conversation Session",
    description="Update title or pin/unpin a conversation session, owner-guarded.",
)
async def update_session(
    session_id: str,
    payload: ConversationUpdate,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> ConversationSummaryResponse:
    """Update title or pin status of an owned conversation."""
    service = ChatService(session)
    return await service.update_session(
        session_id=session_id,
        user_id=user.id,
        title=payload.title,
        is_pinned=payload.is_pinned,
    )


@router.delete(
    "/sessions/{session_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Conversation Session",
    description="Delete an owned conversation thread and its message turns, owner-guarded.",
)
async def delete_session(
    session_id: str,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> None:
    """Delete an owned conversation session and cascade its messages."""
    service = ChatService(session)
    await service.delete_session(session_id=session_id, user_id=user.id)


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