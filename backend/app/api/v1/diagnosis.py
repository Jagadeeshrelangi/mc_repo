from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user
from app.schemas.diagnosis import DiagnosisInput, DiagnosisResponse
from app.services.diagnosis_service import diagnosis_service

# Stage 8: auth-only protection (no role restriction). Any authenticated
# user (customer/mechanic/admin) may diagnose a vehicle.
router = APIRouter(dependencies=[Depends(get_current_user)])

@router.post(
    "/diagnose",
    response_model=DiagnosisResponse,
    status_code=status.HTTP_200_OK,
    summary="Diagnose Vehicle Telemetry",
    description="Accepts real-time vehicle sensor metrics and returns predicted faults, confidence, repair costs, and safety advice."
)
def diagnose_vehicle(payload: DiagnosisInput):
    """
    Submit vehicle telemetry measurements:
    
    - **engine_temp**: Current engine coolant temperature (Celsius).
    - **vibration_level**: Engine vibration level (G-Force).
    - **battery_voltage**: Battery terminal potential (Volts).
    - **oil_pressure**: System oil pressure (PSI).
    - **mileage**: Total odometer reading (km).
    - **obd_error_code**: Present OBD diagnostic trouble code.
    """
    return diagnosis_service.predict_fault(payload)
