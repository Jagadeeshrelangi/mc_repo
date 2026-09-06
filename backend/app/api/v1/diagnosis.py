from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.diagnosis import DiagnosisInput, DiagnosisResponse, DiagnosisRecordResponse
from app.services.diagnosis_service import diagnosis_service
from sqlalchemy.ext.asyncio import AsyncSession

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
        user_id=str(user.id),
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
    if hasattr(session, "commit") and callable(session.commit):
        await session.commit()

    return result


@router.get(
    "/history",
    response_model=List[DiagnosisRecordResponse],
    status_code=status.HTTP_200_OK,
    summary="List User's Diagnosis History",
    description="Returns previously executed vehicle diagnoses for the authenticated user, newest first.",
)
async def get_diagnosis_history(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> List[DiagnosisRecordResponse]:
    """Fetch previously stored diagnostic reports for the caller."""
    diagnoses = await diagnosis_service.list_user_diagnoses(
        session=session,
        user_id=str(user.id),
        offset=offset,
        limit=limit,
    )
    return [DiagnosisRecordResponse.model_validate(d) for d in diagnoses]


@router.get(
    "/{diagnosis_id}",
    response_model=DiagnosisRecordResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Specific Diagnosis Report",
    description="Fetch a diagnostic report by ID, verifying caller ownership.",
)
async def get_diagnosis_detail(
    diagnosis_id: str,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DiagnosisRecordResponse:
    """Fetch a specific owned diagnosis report; returns 404 if missing or unauthorized."""
    record = await diagnosis_service.get_user_diagnosis(
        session=session,
        diagnosis_id=diagnosis_id,
        user_id=str(user.id),
    )
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diagnosis record not found",
        )
    return DiagnosisRecordResponse.model_validate(record)


@router.delete(
    "/{diagnosis_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Diagnosis Record",
    description="Delete a diagnostic report by ID, verifying caller ownership.",
)
async def delete_diagnosis_record(
    diagnosis_id: str,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> None:
    """Delete an owned diagnosis report; returns 404 if missing or unauthorized."""
    deleted = await diagnosis_service.delete_user_diagnosis(
        session=session,
        diagnosis_id=diagnosis_id,
        user_id=str(user.id),
    )
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diagnosis record not found",
        )
    if hasattr(session, "commit") and callable(session.commit):
        await session.commit()