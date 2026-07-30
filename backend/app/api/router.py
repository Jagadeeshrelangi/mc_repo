from fastapi import APIRouter
from app.api.v1 import diagnosis, knowledge, conversation

api_router = APIRouter()

# Mount feature routers under versioned paths
api_router.include_router(
    diagnosis.router,
    prefix="/diagnosis",
    tags=["Diagnosis"]
)

api_router.include_router(
    knowledge.router,
    prefix="/knowledge",
    tags=["Knowledge Base"]
)

api_router.include_router(
    conversation.router,
    prefix="/conversation",
    tags=["Conversation Engine"]
)
