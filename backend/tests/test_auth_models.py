"""Tests for the authentication models (Sprint 2, Task 3, Stage 3).

Validates the *model contract* (columns, defaults, nullability, indexes,
constraints, relationships) by inspecting SQLAlchemy metadata — no live
PostgreSQL database is required or used.

Limitation (documented, not faked): PostgreSQL server-side behaviours such as
actual ``gen_random_uuid()`` execution, ``ON DELETE CASCADE`` enforcement, and
constraint firing are only verifiable against a real database. Those are out of
scope for this DB-agnostic suite.
"""

import pytest
from sqlalchemy.orm import RelationshipProperty

from app.core.database import Base
from app.models import User, UserRole, RefreshToken


def test_metadata_contains_expected_tables() -> None:
    tables = set(Base.metadata.tables)
    assert {"users", "refresh_tokens"} <= tables


def test_user_model_contains_required_auth_fields() -> None:
    columns = set(User.__table__.columns.keys())
    required = {
        "role",
        "is_active",
        "is_verified",
        "last_login_at",
        "failed_login_attempts",
        "lockout_at",
    }
    assert required <= columns


def test_user_contains_identity_fields() -> None:
    columns = set(User.__table__.columns.keys())
    required = {"id", "name", "email", "phone", "password_hash", "created_at", "updated_at"}
    assert required <= columns


def test_user_role_default_is_customer() -> None:
    assert User.__table__.c.role.server_default.arg.text == "'customer'"


def test_user_role_values() -> None:
    assert UserRole.VALUES == ("customer", "mechanic", "admin")


def test_user_is_active_default_true() -> None:
    assert User.__table__.c.is_active.server_default.arg.text == "true"


def test_user_is_verified_default_false() -> None:
    assert User.__table__.c.is_verified.server_default.arg.text == "false"


def test_user_failed_login_attempts_default_zero() -> None:
    assert User.__table__.c.failed_login_attempts.server_default.arg.text == "0"


def test_user_timestamps_are_nullable() -> None:
    assert User.__table__.c.last_login_at.nullable is True
    assert User.__table__.c.lockout_at.nullable is True


def test_user_role_check_constraint_exists() -> None:
    check_names = {c.name for c in User.__table__.constraints if c.name}
    assert "ck_users_role" in check_names
    assert "ck_users_membership_tier" in check_names


def test_refresh_token_contains_token_digest() -> None:
    assert "token_digest" in RefreshToken.__table__.columns
    assert RefreshToken.__table__.c.token_digest.nullable is False


def test_token_digest_uniqueness_represented() -> None:
    unique_indexes = {
        idx.name: idx
        for idx in RefreshToken.__table__.indexes
        if idx.unique and "token_digest" in [c.name for c in idx.columns]
    }
    assert "uq_refresh_tokens_token_digest" in unique_indexes


def test_user_refresh_token_relationship_exists() -> None:
    rel: RelationshipProperty = User.__mapper__.relationships["refresh_tokens"]
    assert rel.mapper.class_ is RefreshToken
    assert rel.direction.name == "ONETOMANY"


def test_refresh_token_user_relationship_exists() -> None:
    rel: RelationshipProperty = RefreshToken.__mapper__.relationships["user"]
    assert rel.mapper.class_ is User
    assert rel.direction.name == "MANYTOONE"


def test_refresh_token_foreign_key_points_to_users() -> None:
    fk = RefreshToken.__table__.c.user_id.foreign_keys
    assert len(fk) == 1
    target = next(iter(fk)).column
    assert target.table.name == "users"
    assert target.name == "id"


def test_refresh_token_rotation_column_exists() -> None:
    assert "replaced_by_id" in RefreshToken.__table__.columns
    assert RefreshToken.__table__.c.replaced_by_id.nullable is True


def test_plaintext_refresh_token_not_represented() -> None:
    """The model must store only the digest, never the plaintext token."""
    column_names = set(RefreshToken.__table__.columns.keys())
    assert "token" not in column_names
    assert "refresh_token" not in column_names
    assert "plaintext_token" not in column_names
    assert not hasattr(RefreshToken, "token")


def test_no_access_token_or_jwt_secret_fields() -> None:
    """RefreshToken must not carry access tokens or JWT secrets."""
    column_names = set(RefreshToken.__table__.columns.keys())
    assert "access_token" not in column_names
    assert "jwt_secret" not in column_names


def test_user_model_is_declarative() -> None:
    assert issubclass(User, Base)
    assert issubclass(RefreshToken, Base)