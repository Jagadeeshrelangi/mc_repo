"""persistence foundation indexes

Revision ID: 0006
Revises: 0005

The deployed Supabase database already contains the profile, vehicle, fuel,
wallet, and marketplace tables.  They predate this repository's Alembic
history, so this migration deliberately does not recreate or alter them.

It adds the owner and relation indexes required by the repositories and by
foreign-key cascade/delete paths.  The existing foreign keys and domain
constraints remain untouched: changing their historic names or semantics
would be unrelated and unnecessarily risky on a populated database.
"""
from typing import Sequence, Union

from alembic import op


revision: str = "0006"
down_revision: Union[str, None] = "0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index("ix_addresses_user_id", "addresses", ["user_id"])
    op.create_index("ix_addresses_user_is_default", "addresses", ["user_id", "is_default"])
    op.create_index("ix_vehicles_user_id", "vehicles", ["user_id"])
    op.create_index("ix_wallet_transactions_user_id", "wallet_transactions", ["user_id"])
    op.create_index("ix_wallet_transactions_occurred_at", "wallet_transactions", ["occurred_at"])
    op.create_index("ix_reward_ledger_user_id", "reward_ledger", ["user_id"])
    op.create_index("ix_reward_ledger_occurred_at", "reward_ledger", ["occurred_at"])
    op.create_index("ix_fuel_orders_user_id", "fuel_orders", ["user_id"])
    op.create_index("ix_fuel_orders_status", "fuel_orders", ["status"])
    op.create_index("ix_tracking_events_order_id", "tracking_events", ["order_id"])
    op.create_index("ix_orders_user_id", "orders", ["user_id"])
    op.create_index("ix_orders_status", "orders", ["status"])
    op.create_index("ix_order_items_order_id", "order_items", ["order_id"])
    op.create_index("ix_order_entries_user_id", "order_entries", ["user_id"])
    op.create_index("ix_products_brand_id", "products", ["brand_id"])
    op.create_index("ix_products_category_id", "products", ["category_id"])
    op.create_index("ix_product_reviews_product_id", "product_reviews", ["product_id"])
    op.create_index("ix_product_specifications_product_id", "product_specifications", ["product_id"])


def downgrade() -> None:
    op.drop_index("ix_product_specifications_product_id", table_name="product_specifications")
    op.drop_index("ix_product_reviews_product_id", table_name="product_reviews")
    op.drop_index("ix_products_category_id", table_name="products")
    op.drop_index("ix_products_brand_id", table_name="products")
    op.drop_index("ix_order_entries_user_id", table_name="order_entries")
    op.drop_index("ix_order_items_order_id", table_name="order_items")
    op.drop_index("ix_orders_status", table_name="orders")
    op.drop_index("ix_orders_user_id", table_name="orders")
    op.drop_index("ix_tracking_events_order_id", table_name="tracking_events")
    op.drop_index("ix_fuel_orders_status", table_name="fuel_orders")
    op.drop_index("ix_fuel_orders_user_id", table_name="fuel_orders")
    op.drop_index("ix_reward_ledger_occurred_at", table_name="reward_ledger")
    op.drop_index("ix_reward_ledger_user_id", table_name="reward_ledger")
    op.drop_index("ix_wallet_transactions_occurred_at", table_name="wallet_transactions")
    op.drop_index("ix_wallet_transactions_user_id", table_name="wallet_transactions")
    op.drop_index("ix_vehicles_user_id", table_name="vehicles")
    op.drop_index("ix_addresses_user_is_default", table_name="addresses")
    op.drop_index("ix_addresses_user_id", table_name="addresses")
