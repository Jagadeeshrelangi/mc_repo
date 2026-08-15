"""conversation ownership

Revision ID: 0003
Revises: 0002
Create Date: 2026-08-15

Additive migration (Sprint 2, Task 4 — Conversation Ownership). Creates ONLY
the two tables needed for owner-scoped conversation persistence (recon report
§10.2):

- ``conversations`` — id TEXT PK, user_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL, is_pinned BOOLEAN DEFAULT false, created_at/updated_at
  TIMESTAMPTZ DEFAULT now().
- ``chat_messages`` — id TEXT PK, conversation_id TEXT NOT NULL
  REFERENCES conversations(id), role TEXT NOT NULL CHECK(role IN
  ('user','assistant')), content TEXT, timestamp TIMESTAMPTZ DEFAULT now(),
  response JSONB.

Deliberate deviation from schema.sql (approved §10.4): ``ON DELETE CASCADE``
on both FKs so deleting a user/conversation cleans its history (schema.sql
declares NO ACTION by omission). No diagnoses table and no other business
tables are created (D13/D15 scope). 0001/0002 are NOT modified.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "conversations",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("is_pinned", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_conversations_user_id_users", ondelete="CASCADE"),
    )

    op.create_index("ix_conversations_user_id", "conversations", ["user_id"])

    op.create_table(
        "chat_messages",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("conversation_id", sa.Text(), nullable=False),
        sa.Column("role", sa.Text(), nullable=False),
        sa.Column("content", sa.Text(), nullable=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("response", sa.dialects.postgresql.JSONB(), nullable=True),
        sa.CheckConstraint("role IN ('user', 'assistant')", name="ck_chat_messages_role"),
        sa.ForeignKeyConstraint(["conversation_id"], ["conversations.id"], name="fk_chat_messages_conversation_id", ondelete="CASCADE"),
    )

    op.create_index("ix_chat_messages_conversation_id", "chat_messages", ["conversation_id"])


def downgrade() -> None:
    op.drop_index("ix_chat_messages_conversation_id", table_name="chat_messages")
    op.drop_table("chat_messages")
    op.drop_index("ix_conversations_user_id", table_name="conversations")
    op.drop_table("conversations")