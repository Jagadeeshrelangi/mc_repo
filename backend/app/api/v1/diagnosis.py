from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.diagnosis import DiagnosisInput, DiagnosisResponse
from app.services.diagnosis_service import diagnosis_service
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio

# Stage 8: auth-only protection (no role restriction). Any authenticated
# user (customer/mechanic/admin) may diagnose a vehicle.
router = APIRouter(dependencies=[Depends(get_current_user)])

@router.post(
    "/diagnose",
    response_model=DiagnosisResponse,
    status_code=status.HTTP_200_OK,
    summary="Diagnose Vehicle Telemetry",
    description="Accepts real-time vehicle sensor metrics and returns predicted faults, confidence, repair costs, and safety advice. "
                "Diagnosis results are persisted to the user's diagnosis history."
)
async def diagnose_vehicle(
    payload: DiagnosisInput,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Submit vehicle telemetry measurements:

    - **engine_temp**: Current engine coolant temperature (Celsius).
    - **vibration_level**: Engine vibration level (G-Force).
    - **battery_voltage**: Battery terminal potential (Volts).
    - **oil_pressure**: System oil pressure (PSI).
    - **mileage**: Total odometer reading (km).
    - **obd_error_code**: Present OBD diagnostic trouble code.

    The diagnosis result is persisted to the user's diagnosis history
    after successful inference.
    """
    # 1. Inference (synchronous method call, path unchanged)
    result = diagnosis_service.predict_fault(payload)

    # 2. Persist diagnosis to history asynchronously (after inference)
    symptoms_payload = {"items": payload.symptoms} if payload.symptoms else None
    vehicle_name = f"{payload.brand or ''} {payload.model or ''}".strip() or None

    await diagnosis_service.create_diagnosis(
        session=session,
        user_id=user.id,
        predicted_fault=getattr(result, "predicted_fault", "Unknown"),
        confidence=getattr(result, "confidence", None),
        diagnosis_mode=getattr(result, "diagnosis_mode", "symptom"),
        symptoms=symptoms_payload,
        possible_causes=None,
        severity=None,
        estimated_cost=getattr(result, "estimated_cost", None),
        recommended_action=getattr(result, "safety_advice", None),
        should_drive=getattr(result, "should_drive", None),
        recommended_service=getattr(result, "recommended_service", None),
        vehicle_name=vehicle_name,
        vehicle_type=getattr(payload, "vehicle_type", None),
    )

    return result