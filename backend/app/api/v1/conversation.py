from fastapi import APIRouter, Query, status
from app.schemas.chat import ChatRequest, ChatResponse, SessionResponse, HistoryResponse
from app.services.chat_service import chat_service

router = APIRouter()

@router.post(
    "/chat",
    response_model=ChatResponse,
    status_code=status.HTTP_200_OK,
    summary="Automotive AI Chat Conversation",
    description="Starts or continues a conversation with a Senior Automotive Engineer. Orchestrates intents to diagnostics, manual searches, or general troubleshooting."
)
def chat_interaction(payload: ChatRequest):
    """
    Interact with the Automotive AI Assistant:
    
    - **message**: User query or response text.
    - **session_id**: Active session token to track history memory.
    """
    return chat_service.handle_chat(payload)

@router.post(
    "/session",
    response_model=SessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create New Conversation Session",
    description="Generates a unique session ID for dialog tracking."
)
def create_session():
    """
    Generate and register a new UUID session token.
    """
    session_id = chat_service.create_session()
    return SessionResponse(session_id=session_id)

@router.get(
    "/history",
    response_model=HistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Retrieve Session History",
    description="Fetches all dialogue turns (user prompts and assistant replies) associated with a session ID."
)
def get_history(session_id: str = Query(..., description="The session key to load logs for.")):
    """
    Retrieve message lists:
    
    - **session_id**: The target session query key.
    """
    logs = chat_service.get_session_history(session_id)
    # Map to schema output model
    formatted_logs = [{"role": m["role"], "content": m["content"]} for m in logs]
    return HistoryResponse(session_id=session_id, history=formatted_logs)
