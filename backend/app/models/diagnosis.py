"""Diagnosis model (``diagnoses`` table).

Implements the authoritative ``schema.sql`` table
``diagnoses``: id TEXT PK, user_id UUID FK → users(id), problem, symptoms JSONB,
possible_causes JSONB, severity, estimated_cost, recommended_action, should_drive,
recommended_service, confidence, vehicle_name, vehicle_type, created_at.

Ownership
---------
Every diagnosis is bound to its owning user via ``user_id``. The FK
``ondelete=CASCADE`` is a deliberate strengthening of the frozen schema's
default (NO ACTION) so deleting a user cleans their diagnoses (approved
architecture decision).

``id`` is app-generated (``diag-<12 hex>``, preserving the pre-Task-4 diagnostic
id wire format); the authoritative schema declares ``TEXT PRIMARY KEY`` with no
server default, so no server_default is added.
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Text, Uuid, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def _generate_diag_id() -> str:
    """Generate an opaque diagnostic id matching the pre-Task-4 wire format."""
    return f"diag-{uuid.uuid4().hex[:12]}"


class Diagnosis(Base):
    """A user-owned diagnosis result (authoritative ``diagnoses``)."""

    __tablename__ = "diagnoses"

    __table_args__ = (
        Index("ix_diagnoses_user_id", "user_id"),
    )

    id: Mapped[str] = mapped_column(
        Text,
        primary_key=True,
        default=_generate_diag_id,
    )

    # Owning user (diagnosis ownership FK). Matches ``users.id`` (UUID column).
    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("users.id", name="fk_diagnoses_user_id_users", ondelete="CASCADE"),
        nullable=False,
    )

    vehicle_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vehicle_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    problem: Mapped[str] = mapped_column(Text, nullable=False)
    # Symptoms extracted from the telemetry/symptom payload (JSONB).
    symptoms: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB, nullable=True)
    # Possible causes identified by the diagnosis engine (JSONB).
    possible_causes: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB, nullable=True)
    severity: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    estimated_cost: Mapped[Optional[float]] = mapped_column(nullable=True)
    recommended_action: Mapped[Optional[str]] = mapped_column(nullable=True)
    should_drive: Mapped[Optional[bool]] = mapped_column(nullable=True)
    recommended_service: Mapped[Optional[str]] = mapped_column(nullable=True)
    confidence: Mapped[Optional[int]] = mapped_column(nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
        default=lambda: datetime.now(timezone.utc),
    )

    # --- Relationships ---
    user: Mapped["User"] = relationship(
        "User",
        back_populates="diagnoses",
        passive_deletes=True,
    )