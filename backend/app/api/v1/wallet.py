"""Wallet and Rewards API routes."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.wallet import RewardsResponse, WalletResponse, WalletTopupRequest
from app.services.wallet_service import WalletService

router = APIRouter(
    tags=["Wallet & Rewards"],
)


@router.get(
    "/wallet",
    response_model=WalletResponse,
    status_code=status.HTTP_200_OK,
    summary="Get user wallet summary and recent transactions",
)
async def get_wallet(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> WalletResponse:
    """Return the authenticated user's wallet balance, points, and transaction history."""
    service = WalletService(session)
    return await service.get_wallet(current_user)


@router.post(
    "/wallet/topup",
    response_model=WalletResponse,
    status_code=status.HTTP_200_OK,
    summary="Top up wallet balance",
)
async def topup_wallet(
    payload: WalletTopupRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> WalletResponse:
    """Add funds to the user wallet."""
    service = WalletService(session)
    return await service.topup_wallet(current_user, payload)


@router.get(
    "/rewards",
    response_model=RewardsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get user reward points and activity ledger",
)
async def get_rewards(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> RewardsResponse:
    """Return the authenticated user's reward points balance and ledger history."""
    service = WalletService(session)
    return await service.get_rewards(current_user)
