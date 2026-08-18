from fastapi import APIRouter
from app.api.v1 import auth, diagnosis, knowledge, conversation, users, mechanic

api_router = APIRouter()

# Mount feature routers under versioned paths
api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["Authentication"]
)
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

api_router.include_router(
    users.router,
    tags=["Users"]
)

api_router.include_router(
    mechanic.router,
    tags=["Mechanics"]
)
