"""baseline empty migration

Revision ID: 0001
Revises:
Create Date: 2026-08-07

This baseline exists so the migration chain has a root. Models are added in
later Sprint 2 tasks (Task 3+: users, vehicles, mechanics, fuel,
marketplace/orders, AI conversations/diagnoses). This migration intentionally
creates no tables.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa  # noqa: F401

# revision identifiers, used by Alembic.
revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass