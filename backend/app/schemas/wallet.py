"""Pydantic schemas for Wallet, Transactions, and Rewards."""

from datetime import datetime
from decimal import Decimal
from typing import List, Optional
import uuid

from pydantic import BaseModel, ConfigDict, Field


class WalletTransactionResponse(BaseModel):
    """Public representation of a wallet transaction."""

    id: uuid.UUID = Field(..., description="Transaction UUID.")
    user_id: uuid.UUID = Field(..., description="Owner user UUID.")
    title: Optional[str] = Field(None, description="Transaction title.")
    subtitle: Optional[str] = Field(None, description="Transaction subtitle.")
    amount: Decimal = Field(..., description="Transaction amount.")
    type: str = Field(..., description="'credit' | 'debit'")
    occurred_at: datetime = Field(..., description="Timestamp of transaction.")
    ref_order_id: Optional[str] = Field(None, description="Reference order ID.")

    model_config = ConfigDict(from_attributes=True)


class WalletResponse(BaseModel):
    """User wallet summary including recent transactions."""

    user_id: uuid.UUID = Field(..., description="Owner user UUID.")
    balance: Decimal = Field(..., description="Available wallet balance.")
    reward_points: int = Field(..., description="Total accumulated reward points.")
    transactions: List[WalletTransactionResponse] = Field(default_factory=list, description="Recent wallet transactions.")

    model_config = ConfigDict(from_attributes=True)


class WalletTopupRequest(BaseModel):
    """Payload to add money to wallet."""

    amount: Decimal = Field(..., gt=0, le=100000, description="Amount to add to wallet (INR).")
    payment_method: Optional[str] = Field(None, description="Payment method used (e.g. UPI, Card).")

    model_config = ConfigDict(extra="forbid")


class RewardLedgerResponse(BaseModel):
    """Public representation of a reward points ledger entry."""

    id: uuid.UUID = Field(..., description="Ledger entry UUID.")
    user_id: uuid.UUID = Field(..., description="Owner user UUID.")
    title: Optional[str] = Field(None, description="Reward entry title.")
    subtitle: Optional[str] = Field(None, description="Reward entry subtitle.")
    points: int = Field(..., description="Points earned or redeemed.")
    type: str = Field(..., description="'earned' | 'redeemed'")
    occurred_at: datetime = Field(..., description="Timestamp of entry.")

    model_config = ConfigDict(from_attributes=True)


class RewardsResponse(BaseModel):
    """User rewards summary including ledger history."""

    redeemable_points: int = Field(..., description="Currently available redeemable points.")
    total_earned: int = Field(..., description="Lifetime earned reward points.")
    ledger: List[RewardLedgerResponse] = Field(default_factory=list, description="Recent reward activity entries.")

    model_config = ConfigDict(from_attributes=True)
