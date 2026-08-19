"""Tests for Task 7 Stage 3 Diagnosis Persistence and Field Mapping.

Verifies:
1. Symptoms are correctly extracted and persisted into JSONB structure.
2. Confidence floats (0.95, 0.88, 0.70, 0.0, 1.0, None) are properly converted to integer percentages.
3. DiagnosisResponse.safety_advice maps to Diagnosis.recommended_action.
4. brand + model combinations map cleanly to vehicle_name.
5. User ownership: user_id is derived from authenticated session, never request body.
6. DiagnosisRepository is flush-only; caller manages commit boundary.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
import pytest
from fastapi import FastAPI, status
from fastapi.testclient import TestClient

from app.api import deps
from app.api.deps import get_db
from app.api.v1.diagnosis import router as diagnosis_router
from app.core import security
from app.core.config import settings
from app.models.diagnosis import Diagnosis
from app.models.user import User
from app.repositories.diagnosis import DiagnosisRepository
from app.schemas.diagnosis import DiagnosisInput, DiagnosisResponse
from app.services.diagnosis_service import DiagnosisService

TEST_JWT_SECRET = "stage3-diagnosis-persistence-secret"
USER_ID = "77777777-7777-7777-7777-777777777777"
NOW = datetime(2026, 8, 19, 12, 0, 0, tzinfo=timezone.utc)


class FakeAsyncSession:
    """Async session spy for testing repository flush-only behavior and captured objects."""

    def __init__(self) -> None:
        self.added: List[Any] = []
        self.flushed = False
        self.committed = False
        self.rolled_back = False

    def add(self, obj: Any) -> None:
        self.added.append(obj)

    async def flush(self) -> None:
        self.flushed = True

    async def commit(self) -> None:
        self.committed = True

    async def rollback(self) -> None:
        self.rolled_back = True

    async def get(self, model: Any, entity_id: Any) -> Optional[User]:
        if model is User and str(entity_id) == USER_ID:
            return User(
                id=USER_ID,
                name="Test Driver",
                email="driver@example.com",
                phone="+919876543210",
                password_hash="$2b$12$irrelevant",
                role="customer",
                is_active=True,
                is_verified=True,
                failed_login_attempts=0,
                membership_tier="free",
                joined_at=NOW,
                created_at=NOW,
                updated_at=NOW,
            )
        return None


# ============================================================================
# Unit Tests for Confidence Mapping & Scaling
# ============================================================================


@pytest.mark.anyio
@pytest.mark.parametrize(
    "input_conf,expected_stored",
    [
        (0.95, 95),
        (0.88, 88),
        (0.70, 70),
        (0.0, 0),
        (1.0, 100),
        (0.999, 100),
        (0.924, 92),
        (None, None),
    ],
)
async def test_confidence_scaling_in_diagnosis_service(
    input_conf: Optional[float], expected_stored: Optional[int]
) -> None:
    session = FakeAsyncSession()
    await DiagnosisService.create_diagnosis(
        session=session,  # type: ignore[arg-type]
        user_id=USER_ID,
        predicted_fault="Engine Misfire",
        confidence=input_conf,
        diagnosis_mode="telemetry",
    )

    assert len(session.added) == 1
    diag = session.added[0]
    assert isinstance(diag, Diagnosis)
    assert diag.confidence == expected_stored
    assert session.flushed is True
    assert session.committed is False  # Flush only; no repo-level commit


# ============================================================================
# Unit Tests for Repository Flush-Only & Data Fields
# ============================================================================


@pytest.mark.anyio
async def test_diagnosis_repository_create_and_flush_only() -> None:
    session = FakeAsyncSession()
    repo = DiagnosisRepository(session)  # type: ignore[arg-type]

    created = await repo.create_diagnosis(
        user_id=USER_ID,
        problem="Brake Pad Wear / Brake Fault",
        symptoms={"items": ["brake noise", "vibration"]},
        possible_causes=None,
        severity=None,
        estimated_cost=1500.0,
        recommended_action="Inspect pad thickness immediately.",
        should_drive=False,
        recommended_service="Brake Replacement",
        confidence=95,
        vehicle_name="Honda Civic",
        vehicle_type="Car",
    )

    assert created.id.startswith("diag-")
    assert created.user_id == USER_ID
    assert created.problem == "Brake Pad Wear / Brake Fault"
    assert created.symptoms == {"items": ["brake noise", "vibration"]}
    assert created.possible_causes is None
    assert created.severity is None
    assert created.estimated_cost == 1500.0
    assert created.recommended_action == "Inspect pad thickness immediately."
    assert created.should_drive is False
    assert created.confidence == 95
    assert created.vehicle_name == "Honda Civic"
    assert created.vehicle_type == "Car"
    assert session.flushed is True
    assert session.committed is False


# ============================================================================
# Integration Tests: Route Mapping & Persistence
# ============================================================================


@pytest.fixture
def test_app(monkeypatch) -> FastAPI:
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)
    monkeypatch.setattr(settings, "JWT_ALGORITHM", "HS256")

    app = FastAPI()
    app.include_router(diagnosis_router, prefix="/api/v1")

    # Injected fake DB session
    app.state.fake_session = FakeAsyncSession()

    async def override_get_db():
        yield app.state.fake_session

    app.dependency_overrides[get_db] = override_get_db
    return app


def test_diagnose_route_field_mapping_symptoms_and_vehicle_name(test_app: FastAPI, monkeypatch) -> None:
    # Mock inference to verify route field mapping to persistence
    def fake_predict(payload: DiagnosisInput) -> DiagnosisResponse:
        return DiagnosisResponse(
            predicted_fault="Flat Tyre / Puncture",
            confidence=0.99,
            estimated_cost=350,
            repair_time="0.5 hours",
            safety_advice="Pull over safely. Replace with spare wheel.",
            diagnosis_mode="symptom",
        )

    from app.services.diagnosis_service import diagnosis_service
    monkeypatch.setattr(diagnosis_service, "predict_fault", fake_predict)

    token = security.create_access_token(USER_ID)
    client = TestClient(test_app)

    payload = {
        "mileage": 45000,
        "brand": "Toyota",
        "model": "Corolla",
        "vehicle_type": "Car",
        "symptoms": ["flat tyre", "low pressure warning"],
    }

    res = client.post(
        "/api/v1/diagnose",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )

    assert res.status_code == status.HTTP_200_OK
    data = res.json()
    assert data["predicted_fault"] == "Flat Tyre / Puncture"
    assert data["confidence"] == 0.99
    assert data["safety_advice"] == "Pull over safely. Replace with spare wheel."

    # Verify what was persisted in the session
    session: FakeAsyncSession = test_app.state.fake_session
    assert len(session.added) == 1
    persisted: Diagnosis = session.added[0]

    assert persisted.user_id == USER_ID
    assert persisted.problem == "Flat Tyre / Puncture"
    assert persisted.confidence == 99  # 0.99 scaled to 99
    assert persisted.symptoms == {"items": ["flat tyre", "low pressure warning"]}
    assert persisted.recommended_action == "Pull over safely. Replace with spare wheel."
    assert persisted.vehicle_name == "Toyota Corolla"
    assert persisted.vehicle_type == "Car"
    assert persisted.estimated_cost == 350.0


@pytest.mark.parametrize(
    "brand,model,expected_vehicle_name",
    [
        ("Honda", "City", "Honda City"),
        ("Hyundai", None, "Hyundai"),
        (None, "Activa", "Activa"),
        (None, None, None),
        ("", "", None),
    ],
)
def test_vehicle_name_synthesis_combinations(
    test_app: FastAPI, monkeypatch, brand: Optional[str], model: Optional[str], expected_vehicle_name: Optional[str]
) -> None:
    def fake_predict(payload: DiagnosisInput) -> DiagnosisResponse:
        return DiagnosisResponse(
            predicted_fault="Engine Misfire",
            confidence=0.88,
            estimated_cost=1800,
            repair_time="3 hours",
            safety_advice="Check spark plug immediately.",
            diagnosis_mode="symptom",
        )

    from app.services.diagnosis_service import diagnosis_service
    monkeypatch.setattr(diagnosis_service, "predict_fault", fake_predict)

    token = security.create_access_token(USER_ID)
    client = TestClient(test_app)

    payload = {
        "mileage": 60000,
        "brand": brand,
        "model": model,
        "symptoms": ["vibration"],
    }

    test_app.state.fake_session = FakeAsyncSession()
    res = client.post(
        "/api/v1/diagnose",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )

    assert res.status_code == status.HTTP_200_OK
    session: FakeAsyncSession = test_app.state.fake_session
    assert len(session.added) == 1
    persisted: Diagnosis = session.added[0]
    assert persisted.vehicle_name == expected_vehicle_name


def test_telemetry_mode_null_symptoms(test_app: FastAPI, monkeypatch) -> None:
    def fake_predict(payload: DiagnosisInput) -> DiagnosisResponse:
        return DiagnosisResponse(
            predicted_fault="Overheating Engine",
            confidence=0.95,
            estimated_cost=2500,
            repair_time="2 hours",
            safety_advice="Stop driving immediately and shut off engine.",
            diagnosis_mode="telemetry",
        )

    from app.services.diagnosis_service import diagnosis_service
    monkeypatch.setattr(diagnosis_service, "predict_fault", fake_predict)

    token = security.create_access_token(USER_ID)
    client = TestClient(test_app)

    payload = {
        "engine_temp": 115.0,
        "vibration_level": 1.2,
        "battery_voltage": 12.4,
        "oil_pressure": 40.0,
        "mileage": 90000,
        "obd_error_code": "P0115",
    }

    test_app.state.fake_session = FakeAsyncSession()
    res = client.post(
        "/api/v1/diagnose",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )

    assert res.status_code == status.HTTP_200_OK
    session: FakeAsyncSession = test_app.state.fake_session
    assert len(session.added) == 1
    persisted: Diagnosis = session.added[0]

    assert persisted.symptoms is None  # Telemetry without symptoms persists NULL
    assert persisted.confidence == 95
    assert persisted.recommended_action == "Stop driving immediately and shut off engine."
    assert persisted.vehicle_name is None
