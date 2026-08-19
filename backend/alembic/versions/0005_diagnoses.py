"""diagnoses persistence

Revision ID: 0005
Revises: 0004
Create Date: 2026-08-19

Additive migration (Sprint 2, Task 7 — Diagnosis Persistence). Creates the
``diagnoses`` table matching ``docs/backend/database/schema.sql`` and
``app/models/diagnosis.py``:

- ``diagnoses`` (id TEXT PK, user_id UUID FK → users(id) ON DELETE CASCADE,
  vehicle_name TEXT, vehicle_type TEXT, problem TEXT NOT NULL,
  symptoms JSONB, possible_causes JSONB, severity TEXT,
  estimated_cost NUMERIC(12, 2), recommended_action TEXT,
  should_drive BOOLEAN, recommended_service TEXT, confidence SMALLINT,
  created_at TIMESTAMPTZ DEFAULT now()).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0005"
down_revision: Union[str, None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "diagnoses",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("vehicle_name", sa.Text(), nullable=True),
        sa.Column("vehicle_type", sa.Text(), nullable=True),
        sa.Column("problem", sa.Text(), nullable=False),
        sa.Column("symptoms", postgresql.JSONB(), nullable=True),
        sa.Column("possible_causes", postgresql.JSONB(), nullable=True),
        sa.Column("severity", sa.Text(), nullable=True),
        sa.Column("estimated_cost", sa.Numeric(12, 2), nullable=True),
        sa.Column("recommended_action", sa.Text(), nullable=True),
        sa.Column("should_drive", sa.Boolean(), nullable=True),
        sa.Column("recommended_service", sa.Text(), nullable=True),
        sa.Column("confidence", sa.SmallInteger(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"],
            name="fk_diagnoses_user_id_users",
            ondelete="CASCADE",
        ),
    )

    op.create_index("ix_diagnoses_user_id", "diagnoses", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_diagnoses_user_id", table_name="diagnoses")
    op.drop_table("diagnoses")
