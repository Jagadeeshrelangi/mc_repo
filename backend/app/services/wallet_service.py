"""Wallet and Rewards business logic service."""

from decimal import Decimal
from typing import Optional
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.wallet import RewardLedger, WalletTransaction
from app.repositories.wallet import WalletRepository
from app.schemas.wallet import (
    RewardLedgerResponse,
    RewardsResponse,
    WalletResponse,
    WalletTopupRequest,
    WalletTransactionResponse,
)


class WalletService:
    """Coordinates wallet balances, top-ups, transaction logging, and rewards ledger."""

    def __init__(
        self,
        session: AsyncSession,
        wallet_repository: Optional[WalletRepository] = None,
    ) -> None:
        self.session = session
        self.wallet_repo = wallet_repository or WalletRepository(session)

    async def get_wallet(self, user: User) -> WalletResponse:
        """Fetch the authenticated user's wallet with recent transactions."""
        user_uuid = uuid.UUID(str(user.id))
        wallet = await self.wallet_repo.get_or_create_wallet(user_uuid)
        transactions = await self.wallet_repo.list_transactions(user_uuid)
        await self.session.commit()
        return WalletResponse(
            user_id=wallet.user_id,
            balance=wallet.balance,
            reward_points=wallet.reward_points,
            transactions=[WalletTransactionResponse.model_validate(t) for t in transactions],
        )

    async def topup_wallet(self, user: User, payload: WalletTopupRequest) -> WalletResponse:
        """Add balance to user wallet and record transaction."""
        user_uuid = uuid.UUID(str(user.id))
        wallet = await self.wallet_repo.get_or_create_wallet(user_uuid)
        wallet.balance = Decimal(str(wallet.balance)) + Decimal(str(payload.amount))

        method_label = payload.payment_method or "UPI"
        txn = WalletTransaction(
            user_id=user_uuid,
            title="Recharge",
            subtitle=f"{method_label} added \u20b9{payload.amount:,.0f}",
            amount=Decimal(str(payload.amount)),
            type="credit",
        )
        await self.wallet_repo.add_transaction(txn)
        await self.session.commit()
        await self.session.refresh(wallet)
        return await self.get_wallet(user)

    async def get_rewards(self, user: User) -> RewardsResponse:
        """Fetch rewards points summary and ledger for user."""
        user_uuid = uuid.UUID(str(user.id))
        wallet = await self.wallet_repo.get_or_create_wallet(user_uuid)
        ledger = await self.wallet_repo.list_reward_ledger(user_uuid)
        total_earned = await self.wallet_repo.get_total_reward_earned(user_uuid)
        if total_earned < wallet.reward_points:
            total_earned = wallet.reward_points
        await self.session.commit()
        return RewardsResponse(
            redeemable_points=wallet.reward_points,
            total_earned=total_earned,
            ledger=[RewardLedgerResponse.model_validate(entry) for entry in ledger],
        )
