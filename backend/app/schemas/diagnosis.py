from typing import List, Optional
from pydantic import BaseModel, Field

class DiagnosisInput(BaseModel):
    # Telemetry fields (Optional, but used to trigger Telemetry-based Mode)
    engine_temp: Optional[float] = Field(None, description="Engine temperature in Celsius.", ge=0.0, le=200.0, example=95.0)
    vibration_level: Optional[float] = Field(None, description="Engine vibration level in G-force units.", ge=0.0, le=10.0, example=0.5)
    battery_voltage: Optional[float] = Field(None, description="Battery terminal voltage in Volts.", ge=0.0, le=24.0, example=12.6)
    oil_pressure: Optional[float] = Field(None, description="Engine oil system pressure in PSI.", ge=0.0, le=120.0, example=45.0)
    
    # Common fields
    mileage: int = Field(..., description="Total vehicle odometer reading in kilometers.", ge=0, example=85000)
    obd_error_code: Optional[str] = Field(None, description="Diagnostic trouble code (e.g., P0300, None).", example="None")

    # Symptom-based fields (Optional, used to trigger Symptom-based Mode)
    vehicle_type: Optional[str] = Field(None, description="Vehicle type (e.g., Bike, Car).", example="Car")
    brand: Optional[str] = Field(None, description="Vehicle manufacturer brand.", example="Honda")
    model: Optional[str] = Field(None, description="Vehicle model name.", example="Civic")
    fuel_type: Optional[str] = Field(None, description="Fuel type (e.g., Petrol, Diesel).", example="Petrol")
    symptoms: Optional[List[str]] = Field(None, description="List of observed symptoms (e.g., Engine won't start).", example=["Engine won't start", "Clicking sound"])

class DiagnosisResponse(BaseModel):
    predicted_fault: str = Field(..., description="The predicted vehicle system fault category.")
    confidence: float = Field(..., description="Prediction confidence score.")
    estimated_cost: int = Field(..., description="Estimated repair cost in INR.")
    repair_time: str = Field(..., description="Estimated time duration required to fix the fault.")
    safety_advice: str = Field(..., description="Immediate safety recommendations for the driver.")
    diagnosis_mode: str = Field(..., description="The mode used for diagnosis ('telemetry' or 'symptom').")
