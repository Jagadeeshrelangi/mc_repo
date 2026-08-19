"""Diagnosis repository (core SQLAlchemy, no new ORM model needed).

Provides data-access methods for the ``diagnoses`` table.
All operations use ``AsyncSession`` injected by the caller; flush-only
(no intermediate commit) consistent with Task 4 ``handle_chat`` pattern.

Public methods
--------------
  create_diagnosis(session, user_id, problem, symptoms, possible_causes,
                   severity, estimated_cost, recommended_action, should_drive,
                   recommended_service, confidence, vehicle_name, vehicle_type)
    -> Diagnosis

  get_diagnoses_by_user(session, user_id) -> list[Diagnosis]

  get_diagnosis_by_id(session, diagnosis_id, user_id) -> Diagnosis | None
    (ownership-checked: returns None if the diagnosis belongs to another user)
"""
import uuid
from typing import Any, Optional, Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import Base
from app.models.diagnosis import Diagnosis


class DiagnosisRepository:
    """Repository for ``diagnoses`` — core SQLAlchemy, no ORM model subclass needed."""

    model: type[Diagnosis] = Diagnosis

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create_diagnosis(
        self,
        *,
        user_id: str,
        problem: str,
        symptoms: Optional[dict[str, Any]],
        possible_causes: Optional[dict[str, Any]],
        severity: Optional[str],
        estimated_cost: Optional[float],
        recommended_action: Optional[str],
        should_drive: Optional[bool],
        recommended_service: Optional[str],
        confidence: Optional[int],
        vehicle_name: Optional[str],
        vehicle_type: Optional[str],
    ) -> Diagnosis:
        """Persist a new diagnosis (flush; commit owned by the caller)."""
        obj = Diagnosis(
            id=f"diag-{uuid.uuid4().hex[:12]}",
            user_id=user_id,
            problem=problem,
            symptoms=symptoms,
            possible_causes=possible_causes,
            severity=severity,
            estimated_cost=estimated_cost,
            recommended_action=recommended_action,
            should_drive=should_drive,
            recommended_service=recommended_service,
            confidence=confidence,
            vehicle_name=vehicle_name,
            vehicle_type=vehicle_type,
        )
        self.session.add(obj)
        await self.session.flush()
        return obj

    async def get_diagnoses_by_user(
        self, user_id: str, *, offset: int = 0, limit: int = 200
    ) -> Sequence[Diagnosis]:
        """List diagnoses owned by *user_id* (read-only, never commits)."""
        stmt = select(self.model).where(self.model.user_id == user_id)
        stmt = stmt.order_by(self.model.id.desc()).offset(offset).limit(limit)
        result = await self.session.scalars(stmt)
        return list(await result.all())

    async def get_diagnosis_by_id(
        self, diagnosis_id: str, user_id: str
    ) -> Optional[Diagnosis]:
        """Fetch a diagnosis by ID, verifying ownership.

        Returns ``None`` if the diagnosis does not exist *or* belongs to
        a different user (follows the Task 4 ``get_owned() / generic 404`` pattern).
        """
        stmt = select(self.model).where(
            self.model.id == diagnosis_id,
            self.model.user_id == user_id,
        )
        result = await self.session.scalars(stmt)
        return result.one_or_none()