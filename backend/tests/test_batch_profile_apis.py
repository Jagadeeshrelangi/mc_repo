"""Unit and API tests for Address, Wallet, Rewards, and Notification Settings APIs."""

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, List, Optional
import uuid
import pytest
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.api.deps import get_current_user, get_db
from app.api.v1.addresses import router as addresses_router
from app.api.v1.notification_settings import router as notification_router
from app.api.v1.wallet import router as wallet_router
from app.core.exceptions import EntityNotFoundException, MechaException
from app.models.address import Address
from app.models.notification_setting import NotificationSetting
from app.models.user import User, UserRole
from app.models.wallet import RewardLedger, Wallet, WalletTransaction


class FakeBatchSession:
    """In-memory async session fake for fast isolated unit testing."""

    def __init__(self) -> None:
        self.addresses: List[Address] = []
        self.wallets: List[Wallet] = []
        self.transactions: List[WalletTransaction] = []
        self.rewards: List[RewardLedger] = []
        self.notification_settings: List[NotificationSetting] = []
        self.flushes = 0

    async def execute(self, stmt: Any) -> Any:
        stmt_str = str(stmt).lower()

        # Handle Address updates (e.g. unset_all_defaults)
        if "update addresses" in stmt_str and "is_default = :is_default" in stmt_str:
            target_user = None
            if hasattr(stmt, "compile"):
                compiled = stmt.compile()
                for col, val in compiled.params.items():
                    if "user_id" in col:
                        target_user = str(val)
            if target_user:
                for a in self.addresses:
                    if str(a.user_id) == target_user:
                        a.is_default = False

        # Select queries
        class FakeResult:
            def __init__(self, items: List[Any], scalar_val: Any = None):
                self._items = items
                self._scalar_val = scalar_val

            def scalars(self):
                class FakeScalars:
                    def __init__(self, it):
                        self._it = it
                    def all(self):
                        return self._it
                    def first(self):
                        return self._it[0] if self._it else None
                return FakeScalars(self._items)

            def scalar_one_or_none(self):
                return self._items[0] if self._items else None

            def scalar(self):
                return self._scalar_val if self._scalar_val is not None else (len(self._items) if self._items else 0)

        # Address count query
        if "count(addresses.id)" in stmt_str:
            return FakeResult([], scalar_val=len(self.addresses))

        # Reward sum query
        if "coalesce(sum(reward_ledger.points)" in stmt_str:
            total = sum(r.points for r in self.rewards if r.type == "earned")
            return FakeResult([], scalar_val=total)

        # Address list/get
        if "from addresses" in stmt_str:
            return FakeResult(self.addresses)

        # Wallet get
        if "from wallet" in stmt_str and "from wallet_transactions" not in stmt_str:
            return FakeResult(self.wallets)

        # Wallet transactions
        if "from wallet_transactions" in stmt_str:
            return FakeResult(self.transactions)

        # Reward ledger
        if "from reward_ledger" in stmt_str:
            return FakeResult(self.rewards)

        # Notification settings
        if "from notification_settings" in stmt_str:
            return FakeResult(self.notification_settings)

        return FakeResult([])

    def add(self, obj: Any) -> None:
        if isinstance(obj, Address):
            if not hasattr(obj, "id") or obj.id is None:
                obj.id = uuid.uuid4()
            if not hasattr(obj, "created_at") or obj.created_at is None:
                obj.created_at = datetime.now(timezone.utc)
            if not hasattr(obj, "updated_at") or obj.updated_at is None:
                obj.updated_at = datetime.now(timezone.utc)
            self.addresses.append(obj)
        elif isinstance(obj, Wallet):
            self.wallets.append(obj)
        elif isinstance(obj, WalletTransaction):
            if not hasattr(obj, "id") or obj.id is None:
                obj.id = uuid.uuid4()
            if not hasattr(obj, "occurred_at") or obj.occurred_at is None:
                obj.occurred_at = datetime.now(timezone.utc)
            self.transactions.append(obj)
        elif isinstance(obj, RewardLedger):
            if not hasattr(obj, "id") or obj.id is None:
                obj.id = uuid.uuid4()
            if not hasattr(obj, "occurred_at") or obj.occurred_at is None:
                obj.occurred_at = datetime.now(timezone.utc)
            self.rewards.append(obj)
        elif isinstance(obj, NotificationSetting):
            self.notification_settings.append(obj)

    async def flush(self) -> None:
        self.flushes += 1

    async def commit(self) -> None:
        self.flushes += 1

    async def refresh(self, obj: Any) -> None:
        pass

    async def delete(self, obj: Any) -> None:
        if isinstance(obj, Address) and obj in self.addresses:
            self.addresses.remove(obj)


def create_batch_test_app(fake_session: FakeBatchSession, current_user: Optional[User] = None) -> TestClient:
    app = FastAPI()

    @app.exception_handler(MechaException)
    async def mecha_exception_handler(request, exc: MechaException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.message, "error_code": exc.error_code},
        )

    app.include_router(addresses_router, prefix="/api/v1")
    app.include_router(wallet_router, prefix="/api/v1")
    app.include_router(notification_router, prefix="/api/v1")

    async def override_get_db():
        yield fake_session

    async def override_get_current_user():
        if current_user is None:
            raise MechaException("Unauthorized", status_code=401)
        return current_user

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    return TestClient(app)


def test_address_creation_auto_default() -> None:
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    client = create_batch_test_app(session, user)

    # First address created should automatically become is_default=True
    res = client.post("/api/v1/addresses", json={
        "label": "home",
        "address": "Flat 402, Green Meadows, Indiranagar",
        "latitude": "12.9716",
        "longitude": "77.5946",
        "is_default": False
    })
    assert res.status_code == 201
    data = res.json()
    assert data["is_default"] is True
    assert data["label"] == "home"
    assert data["user_id"] == str(user.id)


def test_address_cannot_mass_assign_user_id() -> None:
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    client = create_batch_test_app(session, user)

    # Attempting to supply user_id should fail with 422 Unprocessable Entity
    res = client.post("/api/v1/addresses", json={
        "user_id": str(uuid.uuid4()),
        "label": "office",
        "address": "Tech Park, Outer Ring Road",
    })
    assert res.status_code == 422


def test_wallet_get_and_topup() -> None:
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    client = create_batch_test_app(session, user)

    # Get initial wallet -> auto-initialized to 0
    res = client.get("/api/v1/wallet")
    assert res.status_code == 200
    data = res.json()
    assert float(data["balance"]) == 0.0
    assert data["reward_points"] == 0

    # Topup wallet with 500
    topup_res = client.post("/api/v1/wallet/topup", json={
        "amount": 500.0,
        "payment_method": "UPI"
    })
    assert topup_res.status_code == 200
    topup_data = topup_res.json()
    assert float(topup_data["balance"]) == 500.0
    assert len(topup_data["transactions"]) == 1
    assert topup_data["transactions"][0]["title"] == "Recharge"


def test_rewards_summary() -> None:
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    # Seed a reward entry
    session.rewards.append(RewardLedger(
        id=uuid.uuid4(),
        user_id=user.id,
        title="Fuel Booking Reward",
        subtitle="10L Diesel",
        points=50,
        type="earned",
        occurred_at=datetime.now(timezone.utc),
    ))
    session.wallets.append(Wallet(
        user_id=user.id,
        balance=Decimal("100.0"),
        reward_points=50,
    ))

    client = create_batch_test_app(session, user)
    res = client.get("/api/v1/rewards")
    assert res.status_code == 200
    data = res.json()
    assert data["redeemable_points"] == 50
    assert data["total_earned"] == 50
    assert len(data["ledger"]) == 1


def test_notification_settings_get_and_patch() -> None:
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    client = create_batch_test_app(session, user)

    # Initial settings
    res = client.get("/api/v1/notification-settings")
    assert res.status_code == 200
    assert res.json()["push"] is True

    # Update to False
    patch_res = client.patch("/api/v1/notification-settings", json={"push": False})
    assert patch_res.status_code == 200
    assert patch_res.json()["push"] is False


def test_rewards_missing_wallet_initializes_and_repeated_get_is_idempotent() -> None:
    """Missing wallet is initialized with 0 balance, and repeated GET /rewards is safe/idempotent."""
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    client = create_batch_test_app(session, user)

    # First call: missing wallet initialized
    res1 = client.get("/api/v1/rewards")
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["redeemable_points"] == 0
    assert data1["total_earned"] == 0

    # Second call: repeated GET is idempotent
    res2 = client.get("/api/v1/rewards")
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["redeemable_points"] == 0
    assert data2["total_earned"] == 0


def test_rewards_preserves_existing_wallet_balance_and_points() -> None:
    """Existing wallet records are preserved on GET /rewards without duplicate insert."""
    session = FakeBatchSession()
    user = User(
        id=uuid.uuid4(),
        name="Test User",
        email="test@example.com",
        phone="+919999999999",
        role=UserRole.CUSTOMER,
    )
    session.wallets.append(Wallet(
        user_id=user.id,
        balance=Decimal("250.75"),
        reward_points=120,
    ))
    client = create_batch_test_app(session, user)

    res = client.get("/api/v1/rewards")
    assert res.status_code == 200
    data = res.json()
    assert data["redeemable_points"] == 120
    assert data["total_earned"] == 120
    # Confirm wallet balance was not overwritten
    assert len(session.wallets) == 1
    assert session.wallets[0].balance == Decimal("250.75")

