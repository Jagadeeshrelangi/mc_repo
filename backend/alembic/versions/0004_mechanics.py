"""mechanics module

Revision ID: 0004
Revises: 0003
Create Date: 2026-08-15

Additive migration (Sprint 2, Task 6 — Mechanics module). Creates ONLY the 11
Mechanics tables from the authoritative ``docs/backend/database/schema.sql``
(§mechanics … §ratings):

- ``mechanics`` (id TEXT PK, name, rating, review_count, experience_years,
  distance_km, eta_minutes, is_available, price_starting, phone, about,
  is_verified).
- ``mechanic_skills`` / ``mechanic_languages`` / ``mechanic_working_hours`` —
  composite-key (mechanic_id, …) child attribute tables.
- ``mechanic_services`` (id TEXT PK ``svc_*``) + M:N junction
  ``mechanic_service_offered``.
- ``mechanic_categories`` (standalone lookup, no service FK).
- ``mechanic_reviews`` (id TEXT PK ``r*``, FK → mechanics).
- ``mechanic_bookings`` (id UUID PK ``gen_random_uuid()``, FK → users/mechanics/
  mechanic_services, status TEXT NOT NULL with CHECK of the seven frozen
  states, address, lat/lng, scheduled_at, created_at).
- ``booking_events`` (id UUID PK, FK → mechanic_bookings, status, occurred_at,
  payload JSONB) — live-tracking snapshots.
- ``ratings`` (booking_id UUID PK, 1-1 FK → mechanic_bookings, rating, review).

Task 6 decisions applied (see TASK6_MECHANICS_RECONNAISSANCE_REPORT §25):

- **D6-1 (vehicles FK):** ``mechanic_bookings.vehicle_id`` is a nullable UUID
  column with NO foreign key — the ``vehicles`` table is not migrated yet and
  an FK to a nonexistent table is forbidden. The Vehicles module's future
  migration may add the FK.
- **D6-2 (booking identifier):** UUID primary key preserved; no invented
  booking-number system.
- **D6-4 (booking status):** TEXT + ``ck_mechanic_bookings_status`` CHECK for
  the seven frozen states (mirrors ``ck_users_role`` / ``ck_chat_messages_role``).
- **D6-3 (rating):** ``ratings`` table created per the authoritative schema
  (1-1 booking PK); no API surface added.

Owner-scoped FKs use ``ON DELETE CASCADE`` (Task 4 convention):
``mechanic_bookings.user_id``, ``booking_events.booking_id``,
``ratings.booking_id``, and the mechanic-owned child tables.
``mechanic_bookings.mechanic_id``/``service_id`` keep the schema's default
(NO ACTION) so bookings are never silently orphaned by catalog changes.

0001/0002/0003 are NOT modified.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "mechanics",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("rating", sa.Numeric(3, 2), nullable=True),
        sa.Column("review_count", sa.Integer(), nullable=True),
        sa.Column("experience_years", sa.Integer(), nullable=True),
        sa.Column("distance_km", sa.Numeric(6, 2), nullable=True),
        sa.Column("eta_minutes", sa.Integer(), nullable=True),
        sa.Column("is_available", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("price_starting", sa.Numeric(12, 2), nullable=True),
        sa.Column("phone", sa.Text(), nullable=True),
        sa.Column("about", sa.Text(), nullable=True),
        sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "mechanic_skills",
        sa.Column("mechanic_id", sa.Text(), nullable=False),
        sa.Column("skill", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("mechanic_id", "skill", name="pk_mechanic_skills"),
        sa.ForeignKeyConstraint(
            ["mechanic_id"], ["mechanics.id"],
            name="fk_mechanic_skills_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
    )

    op.create_table(
        "mechanic_languages",
        sa.Column("mechanic_id", sa.Text(), nullable=False),
        sa.Column("language", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("mechanic_id", "language", name="pk_mechanic_languages"),
        sa.ForeignKeyConstraint(
            ["mechanic_id"], ["mechanics.id"],
            name="fk_mechanic_languages_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
    )

    op.create_table(
        "mechanic_working_hours",
        sa.Column("mechanic_id", sa.Text(), nullable=False),
        sa.Column("day", sa.Text(), nullable=False),
        sa.Column("open", sa.Text(), nullable=True),
        sa.Column("close", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("mechanic_id", "day", name="pk_mechanic_working_hours"),
        sa.ForeignKeyConstraint(
            ["mechanic_id"], ["mechanics.id"],
            name="fk_mechanic_working_hours_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
    )

    op.create_table(
        "mechanic_services",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("icon", sa.Text(), nullable=True),
        sa.Column("price", sa.Numeric(12, 2), nullable=True),
        sa.Column("estimated_minutes", sa.Integer(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
    )

    op.create_table(
        "mechanic_service_offered",
        sa.Column("mechanic_id", sa.Text(), nullable=False),
        sa.Column("service_id", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("mechanic_id", "service_id", name="pk_mechanic_service_offered"),
        sa.ForeignKeyConstraint(
            ["mechanic_id"], ["mechanics.id"],
            name="fk_mechanic_service_offered_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["service_id"], ["mechanic_services.id"],
            name="fk_mechanic_service_offered_service_id_mechanic_services",
            ondelete="CASCADE",
        ),
    )

    op.create_table(
        "mechanic_categories",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("icon", sa.Text(), nullable=True),
        sa.Column("color", sa.Text(), nullable=True),
        sa.Column("bg_color", sa.Text(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default=sa.text("0")),
    )

    op.create_table(
        "mechanic_reviews",
        sa.Column("id", sa.Text(), primary_key=True),
        sa.Column("mechanic_id", sa.Text(), nullable=False),
        sa.Column("reviewer_name", sa.Text(), nullable=True),
        sa.Column("rating", sa.Numeric(3, 2), nullable=True),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("reviewed_at", sa.Date(), nullable=True),
        sa.Column("vehicle", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(
            ["mechanic_id"], ["mechanics.id"],
            name="fk_mechanic_reviews_mechanic_id_mechanics",
            ondelete="CASCADE",
        ),
    )

    op.create_index("ix_mechanic_reviews_mechanic_id", "mechanic_reviews", ["mechanic_id"])

    op.create_table(
        "mechanic_bookings",
        sa.Column("id", sa.Uuid(), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("mechanic_id", sa.Text(), nullable=False),
        sa.Column("service_id", sa.Text(), nullable=True),
        # D6-1: nullable UUID without FK — vehicles table not migrated yet.
        sa.Column("vehicle_id", sa.Uuid(), nullable=True),
        sa.Column("status", sa.Text(), nullable=False),
        sa.Column("address", sa.Text(), nullable=True),
        sa.Column("lat", sa.Numeric(9, 6), nullable=True),
        sa.Column("lng", sa.Numeric(9, 6), nullable=True),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.CheckConstraint(
            "status IN ('requested', 'accepted', 'mechanicAssigned', 'enRoute', "
            "'arrived', 'completed', 'cancelled')",
            name="ck_mechanic_bookings_status",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"],
            name="fk_mechanic_bookings_user_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["mechanic_id"], ["mechanics.id"],
            name="fk_mechanic_bookings_mechanic_id_mechanics",
        ),
        sa.ForeignKeyConstraint(
            ["service_id"], ["mechanic_services.id"],
            name="fk_mechanic_bookings_service_id_mechanic_services",
        ),
    )

    op.create_index("ix_mechanic_bookings_user_id", "mechanic_bookings", ["user_id"])
    op.create_index("ix_mechanic_bookings_mechanic_id", "mechanic_bookings", ["mechanic_id"])
    op.create_index("ix_mechanic_bookings_service_id", "mechanic_bookings", ["service_id"])

    op.create_table(
        "booking_events",
        sa.Column("id", sa.Uuid(), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("booking_id", sa.Uuid(), nullable=False),
        sa.Column("status", sa.Text(), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("payload", postgresql.JSONB(), nullable=True),
        sa.ForeignKeyConstraint(
            ["booking_id"], ["mechanic_bookings.id"],
            name="fk_booking_events_booking_id_mechanic_bookings",
            ondelete="CASCADE",
        ),
    )

    op.create_index("ix_booking_events_booking_id", "booking_events", ["booking_id"])

    op.create_table(
        "ratings",
        sa.Column("booking_id", sa.Uuid(), primary_key=True),
        sa.Column("rating", sa.Numeric(3, 2), nullable=True),
        sa.Column("review", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(
            ["booking_id"], ["mechanic_bookings.id"],
            name="fk_ratings_booking_id_mechanic_bookings",
            ondelete="CASCADE",
        ),
    )


def downgrade() -> None:
    op.drop_table("ratings")
    op.drop_index("ix_booking_events_booking_id", table_name="booking_events")
    op.drop_table("booking_events")
    op.drop_index("ix_mechanic_bookings_service_id", table_name="mechanic_bookings")
    op.drop_index("ix_mechanic_bookings_mechanic_id", table_name="mechanic_bookings")
    op.drop_index("ix_mechanic_bookings_user_id", table_name="mechanic_bookings")
    op.drop_table("mechanic_bookings")
    op.drop_index("ix_mechanic_reviews_mechanic_id", table_name="mechanic_reviews")
    op.drop_table("mechanic_reviews")
    op.drop_table("mechanic_categories")
    op.drop_table("mechanic_service_offered")
    op.drop_table("mechanic_services")
    op.drop_table("mechanic_working_hours")
    op.drop_table("mechanic_languages")
    op.drop_table("mechanic_skills")
    op.drop_table("mechanics")