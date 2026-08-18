"""Tests for Task 6 Stage 1 — Mechanics models + migration contract.

Validates the *model contract* (columns, types, nullability, defaults, PKs,
FKs, indexes, CHECK constraints, relationships) by inspecting SQLAlchemy
metadata and by compiling DDL against the PostgreSQL dialect — no live
PostgreSQL database is required or used.

Also validates the ``0004_mechanics`` migration contract (revision chain,
additive-only, and the D6-1 guarantee that ``mechanic_bookings.vehicle_id``
carries NO foreign key to a nonexistent ``vehicles`` table).

Limitation (documented, not faked): PostgreSQL server-side behaviours such as
actual ``gen_random_uuid()`` execution, ``ON DELETE CASCADE`` enforcement, and
constraint firing are only verifiable against a real database. Those are out of
scope for this DB-agnostic suite.
"""

import inspect

import pytest
from sqlalchemy.dialects.postgresql import dialect as postgresql_dialect
from sqlalchemy.orm import RelationshipProperty
from sqlalchemy.schema import CreateTable

from app.core.database import Base
from app.models import (
    BookingEvent,
    BookingStatus,
    Mechanic,
    MechanicBooking,
    MechanicCategory,
    MechanicLanguage,
    MechanicReview,
    MechanicService,
    MechanicServiceOffered,
    MechanicSkill,
    MechanicWorkingHour,
    Rating,
)

MECHANIC_TABLES = {
    "mechanics",
    "mechanic_skills",
    "mechanic_languages",
    "mechanic_working_hours",
    "mechanic_services",
    "mechanic_service_offered",
    "mechanic_categories",
    "mechanic_reviews",
    "mechanic_bookings",
    "booking_events",
    "ratings",
}


# ============================================================================
# Metadata registration
# ============================================================================


def test_all_mechanic_tables_registered() -> None:
    tables = set(Base.metadata.tables)
    assert MECHANIC_TABLES <= tables


def test_no_vehicles_table_in_metadata() -> None:
    """D6-1: the vehicles table must not exist yet in this module."""
    assert "vehicles" not in Base.metadata.tables


def test_models_are_declarative() -> None:
    for model in (
        Mechanic,
        MechanicSkill,
        MechanicLanguage,
        MechanicWorkingHour,
        MechanicService,
        MechanicServiceOffered,
        MechanicCategory,
        MechanicReview,
        MechanicBooking,
        BookingEvent,
        Rating,
    ):
        assert issubclass(model, Base)


# ============================================================================
# BookingStatus enum (single canonical representation, D6-4)
# ============================================================================


def test_booking_status_values_match_frozen_frontend_states() -> None:
    assert BookingStatus.VALUES == (
        "requested",
        "accepted",
        "mechanicAssigned",
        "enRoute",
        "arrived",
        "completed",
        "cancelled",
    )


def test_booking_status_is_str_enum() -> None:
    assert isinstance(BookingStatus.REQUESTED, str)
    assert BookingStatus.REQUESTED == "requested"


def test_no_extra_statuses() -> None:
    assert len(BookingStatus) == 7


# ============================================================================
# mechanics
# ============================================================================


def test_mechanic_columns_and_types() -> None:
    cols = Mechanic.__table__.columns
    assert set(cols.keys()) == {
        "id",
        "name",
        "rating",
        "review_count",
        "experience_years",
        "distance_km",
        "eta_minutes",
        "is_available",
        "price_starting",
        "phone",
        "about",
        "is_verified",
    }
    assert cols["id"].primary_key is True
    assert cols["id"].type.length == 255 or cols["id"].type.__class__.__name__ == "Text"
    assert cols["name"].nullable is False
    assert str(cols["rating"].type) == "NUMERIC(3, 2)"
    assert str(cols["distance_km"].type) == "NUMERIC(6, 2)"
    assert str(cols["price_starting"].type) == "NUMERIC(12, 2)"


def test_mechanic_boolean_defaults() -> None:
    assert Mechanic.__table__.c.is_available.server_default.arg.text == "true"
    assert Mechanic.__table__.c.is_verified.server_default.arg.text == "false"


# ============================================================================
# mechanic_skills / mechanic_languages / mechanic_working_hours
# ============================================================================


def test_mechanic_skills_composite_pk_and_fk() -> None:
    table = MechanicSkill.__table__
    pk = [c.name for c in table.primary_key.columns]
    assert pk == ["mechanic_id", "skill"]
    fk = table.c.mechanic_id.foreign_keys
    assert len(fk) == 1
    assert next(iter(fk)).column.table.name == "mechanics"
    assert next(iter(fk)).ondelete == "CASCADE"


def test_mechanic_languages_composite_pk_and_fk() -> None:
    table = MechanicLanguage.__table__
    assert [c.name for c in table.primary_key.columns] == ["mechanic_id", "language"]
    fk = table.c.mechanic_id.foreign_keys
    assert next(iter(fk)).column.table.name == "mechanics"
    assert next(iter(fk)).ondelete == "CASCADE"


def test_mechanic_working_hours_composite_pk_and_fk() -> None:
    table = MechanicWorkingHour.__table__
    assert [c.name for c in table.primary_key.columns] == ["mechanic_id", "day"]
    fk = table.c.mechanic_id.foreign_keys
    assert next(iter(fk)).column.table.name == "mechanics"
    assert next(iter(fk)).ondelete == "CASCADE"
    assert table.c.open.nullable is True
    assert table.c.close.nullable is True


# ============================================================================
# mechanic_services / mechanic_service_offered
# ============================================================================


def test_mechanic_service_columns() -> None:
    cols = MechanicService.__table__.columns
    assert "id" in cols and cols["id"].primary_key is True
    assert cols["name"].nullable is False
    assert str(cols["price"].type) == "NUMERIC(12, 2)"
    assert cols["price"].nullable is True


def test_mechanic_service_offered_junction() -> None:
    table = MechanicServiceOffered.__table__
    assert [c.name for c in table.primary_key.columns] == ["mechanic_id", "service_id"]
    targets = {fk.column.table.name for fk in table.foreign_keys}
    assert targets == {"mechanics", "mechanic_services"}
    for fk in table.foreign_keys:
        assert fk.ondelete == "CASCADE"


# ============================================================================
# mechanic_categories
# ============================================================================


def test_mechanic_category_columns() -> None:
    cols = MechanicCategory.__table__.columns
    assert cols["id"].primary_key is True
    assert cols["name"].nullable is False
    assert cols["sort_order"].server_default.arg.text == "0"


def test_mechanic_category_has_no_service_fk() -> None:
    """Standalone lookup — no invented category→service link."""
    assert len(MechanicCategory.__table__.foreign_keys) == 0


# ============================================================================
# mechanic_reviews
# ============================================================================


def test_mechanic_review_columns_and_fk() -> None:
    cols = MechanicReview.__table__.columns
    assert cols["id"].primary_key is True
    assert str(cols["rating"].type) == "NUMERIC(3, 2)"
    fk = cols["mechanic_id"].foreign_keys
    assert len(fk) == 1
    assert next(iter(fk)).column.table.name == "mechanics"
    assert next(iter(fk)).ondelete == "CASCADE"


# ============================================================================
# mechanic_bookings
# ============================================================================


def test_mechanic_booking_identity_and_types() -> None:
    cols = MechanicBooking.__table__.columns
    assert cols["id"].primary_key is True
    assert cols["id"].server_default is not None
    assert cols["user_id"].nullable is False
    assert str(cols["lat"].type) == "NUMERIC(9, 6)"
    assert str(cols["lng"].type) == "NUMERIC(9, 6)"


def test_mechanic_booking_vehicle_id_nullable_without_fk() -> None:
    """D6-1: vehicle_id is nullable and has NO FK to a nonexistent table."""
    col = MechanicBooking.__table__.c.vehicle_id
    assert col.nullable is True
    assert len(col.foreign_keys) == 0


def test_mechanic_booking_fks_target_existing_tables() -> None:
    targets = {fk.column.table.name for fk in MechanicBooking.__table__.foreign_keys}
    assert targets == {"users", "mechanics", "mechanic_services"}
    assert "vehicles" not in targets


def test_mechanic_booking_user_fk_cascades() -> None:
    fk = next(
        f
        for f in MechanicBooking.__table__.foreign_keys
        if f.column.table.name == "users"
    )
    assert fk.ondelete == "CASCADE"


def test_mechanic_booking_status_check_exists() -> None:
    check_names = {c.name for c in MechanicBooking.__table__.constraints if c.name}
    assert "ck_mechanic_bookings_status" in check_names
    constraint = next(
        c
        for c in MechanicBooking.__table__.constraints
        if getattr(c, "name", "") == "ck_mechanic_bookings_status"
    )
    for state in BookingStatus.VALUES:
        assert state in str(constraint.sqltext)


def test_mechanic_booking_indexes() -> None:
    index_names = {idx.name for idx in MechanicBooking.__table__.indexes}
    assert {
        "ix_mechanic_bookings_user_id",
        "ix_mechanic_bookings_mechanic_id",
        "ix_mechanic_bookings_service_id",
    } <= index_names


# ============================================================================
# booking_events
# ============================================================================


def test_booking_event_columns() -> None:
    cols = BookingEvent.__table__.columns
    assert cols["id"].primary_key is True
    assert cols["booking_id"].nullable is False
    assert str(cols["payload"].type) == "JSONB"
    fk = cols["booking_id"].foreign_keys
    assert next(iter(fk)).column.table.name == "mechanic_bookings"
    assert next(iter(fk)).ondelete == "CASCADE"
    assert "ix_booking_events_booking_id" in {idx.name for idx in BookingEvent.__table__.indexes}


# ============================================================================
# ratings (1-1 with a booking)
# ============================================================================


def test_rating_booking_id_is_pk() -> None:
    table = Rating.__table__
    assert [c.name for c in table.primary_key.columns] == ["booking_id"]
    fk = table.c.booking_id.foreign_keys
    assert next(iter(fk)).column.table.name == "mechanic_bookings"
    assert next(iter(fk)).ondelete == "CASCADE"
    assert str(table.c.rating.type) == "NUMERIC(3, 2)"


# ============================================================================
# Relationships
# ============================================================================


def test_mechanic_relationship_graph() -> None:
    mapper = Mechanic.__mapper__
    assert {k for k in mapper.relationships.keys()} >= {
        "skills",
        "languages",
        "working_hours",
        "services_offered",
        "reviews",
        "bookings",
    }


def test_mechanic_booking_relationship_graph() -> None:
    mapper = MechanicBooking.__mapper__
    assert {k for k in mapper.relationships.keys()} >= {
        "user",
        "mechanic",
        "service",
        "events",
        "rating",
    }


def test_mechanic_rating_is_one_to_one() -> None:
    rel: RelationshipProperty = MechanicBooking.__mapper__.relationships["rating"]
    assert rel.uselist is False


def test_booking_event_booking_relationship() -> None:
    rel: RelationshipProperty = BookingEvent.__mapper__.relationships["booking"]
    assert rel.mapper.class_ is MechanicBooking


# ============================================================================
# Migration contract — DDL compiled against PostgreSQL dialect
# ============================================================================


def test_mechanic_booking_ddl_has_no_vehicles_reference() -> None:
    """D6-1: compiled DDL must not reference a nonexistent vehicles table."""
    ddl = str(CreateTable(MechanicBooking.__table__).compile(dialect=postgresql_dialect()))
    assert "vehicles" not in ddl
    assert "REFERENCES vehicles" not in ddl


def test_mechanic_booking_ddl_check_and_cascade() -> None:
    ddl = str(CreateTable(MechanicBooking.__table__).compile(dialect=postgresql_dialect()))
    assert "CHECK (status IN ('requested', 'accepted', 'mechanicAssigned', 'enRoute', 'arrived', 'completed', 'cancelled'))" in ddl
    assert "REFERENCES users (id) ON DELETE CASCADE" in ddl
    assert "REFERENCES mechanics (id)" in ddl
    assert "REFERENCES mechanic_services (id)" in ddl


def test_booking_events_ddl_jsonb_and_cascade() -> None:
    ddl = str(CreateTable(BookingEvent.__table__).compile(dialect=postgresql_dialect()))
    assert "JSONB" in ddl
    assert "REFERENCES mechanic_bookings (id) ON DELETE CASCADE" in ddl


def test_migration_revision_chain() -> None:
    """0004 must be the single head after 0003, additive-only."""
    import alembic.config
    import alembic.script

    cfg = alembic.config.Config("alembic.ini")
    script = alembic.script.ScriptDirectory.from_config(cfg)

    heads = set(script.get_heads())
    assert heads == {"0004"}

    revisions = list(script.walk_revisions())
    assert [r.revision for r in revisions] == ["0004", "0003", "0002", "0001"]

    assert script.get_base() == "0001"


def test_migration_0004_creates_only_mechanic_tables() -> None:
    """The migration module must only create the intended mechanic tables."""
    mod = _load_migration("0004_mechanics")
    assert mod.revision == "0004"
    assert mod.down_revision == "0003"

    import re

    source = inspect.getsource(mod.upgrade)
    created = set(
        re.findall(r'op\.create_table\(\s*\n\s*"([^"]+)"', source)
    )
    assert created == MECHANIC_TABLES
    assert "vehicles" not in created


def _load_migration(name: str):
    import importlib.util
    from pathlib import Path

    here = Path(__file__).resolve().parent.parent
    path = here / "alembic" / "versions" / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def test_existing_migrations_unchanged() -> None:
    """0001/0002/0003 revision ids and down_revisions must be untouched."""
    m0001 = _load_migration("0001_baseline")
    m0002 = _load_migration("0002_authentication_foundation")
    m0003 = _load_migration("0003_conversation_ownership")

    assert (m0001.revision, m0001.down_revision) == ("0001", None)
    assert (m0002.revision, m0002.down_revision) == ("0002", "0001")
    assert (m0003.revision, m0003.down_revision) == ("0003", "0002")