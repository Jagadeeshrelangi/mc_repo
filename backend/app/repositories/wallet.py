"""Wallet, Transaction, and Rewards repository."""

from decimal import Decimal
from typing import List, Optional
import uuid

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.wallet import RewardLedger, Wallet, WalletTransaction
from app.repositories.base import BaseRepository


class WalletRepository(BaseRepository[Wallet]):
    """Data access repository for user wallet and reward operations."""

    model = Wallet

    async def get_or_create_wallet(self, user_id: uuid.UUID) -> Wallet:
        """Fetch the wallet for user_id or create a new 0-balance wallet if none exists."""
        query = select(Wallet).where(Wallet.user_id == user_id)
        result = await self.session.execute(query)
        wallet = result.scalar_one_or_none()
        if wallet is not None:
            return wallet

        bind = getattr(self.session, "bind", None) or getattr(getattr(self.session, "sync_session", None), "bind", None)
        if bind and getattr(bind, "dialect", None) and getattr(bind.dialect, "name", "") == "postgresql":
            stmt = (
                pg_insert(Wallet)
                .values(user_id=user_id, balance=Decimal("0.0"), reward_points=0)
                .on_conflict_do_nothing(index_elements=[Wallet.user_id])
            )
            await self.session.execute(stmt)
            await self.session.flush()
            result = await self.session.execute(query)
            return result.scalar_one()

        wallet = Wallet(user_id=user_id, balance=Decimal("0.0"), reward_points=0)
        self.session.add(wallet)
        await self.session.flush()
        return wallet

    async def list_transactions(self, user_id: uuid.UUID, limit: int = 50) -> List[WalletTransaction]:
        """Fetch recent wallet transactions for user ordered newest first."""
        query = (
            select(WalletTransaction)
            .where(WalletTransaction.user_id == user_id)
            .order_by(WalletTransaction.occurred_at.desc())
            .limit(limit)
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def add_transaction(self, txn: WalletTransaction) -> WalletTransaction:
        """Record a wallet transaction."""
        self.session.add(txn)
        await self.session.flush()
        return txn

    async def list_reward_ledger(self, user_id: uuid.UUID, limit: int = 50) -> List[RewardLedger]:
        """Fetch reward points history for user ordered newest first."""
        query = (
            select(RewardLedger)
            .where(RewardLedger.user_id == user_id)
            .order_by(RewardLedger.occurred_at.desc())
            .limit(limit)
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_total_reward_earned(self, user_id: uuid.UUID) -> int:
        """Calculate lifetime earned reward points for user."""
        query = (
            select(func.coalesce(func.sum(RewardLedger.points), 0))
            .where(RewardLedger.user_id == user_id, RewardLedger.type == "earned")
        )
        result = await self.session.execute(query)
        return int(result.scalar() or 0)
