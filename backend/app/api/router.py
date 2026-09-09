from fastapi import APIRouter
from app.api.v1 import (
    addresses,
    auth,
    conversation,
    device_tokens,
    diagnosis,
    fuel,
    knowledge,
    marketplace,
    mechanic,
    notification_settings,
    orders,
    users,
    vehicles,
    wallet,
)

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
    vehicles.router,
    tags=["Vehicles"]
)

api_router.include_router(
    addresses.router,
    tags=["Addresses"]
)

api_router.include_router(
    wallet.router,
    tags=["Wallet & Rewards"]
)

api_router.include_router(
    notification_settings.router,
    tags=["Notification Settings"]
)

api_router.include_router(
    device_tokens.router,
    tags=["Device Tokens"]
)

api_router.include_router(
    mechanic.router,
    tags=["Mechanics"]
)

api_router.include_router(
    fuel.router,
    prefix="/fuel",
    tags=["Fuel Delivery"]
)

api_router.include_router(
    marketplace.router,
    prefix="/marketplace",
    tags=["Marketplace"]
)

api_router.include_router(
    orders.router,
    prefix="/orders",
    tags=["Orders"]
)

