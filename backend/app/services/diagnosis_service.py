import os
import joblib
import numpy as np
from app.core.exceptions import InferenceException
from app.core.logging import logger
from app.schemas.diagnosis import DiagnosisInput, DiagnosisResponse
from ai.metadata import DIAGNOSIS_METADATA

class DiagnosisService:
    def __init__(self) -> None:
        self.model_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "ai", "models", "fault_classifier.joblib"
        )
        self.model_data = None
        self._load_model()
        
    def _load_model(self) -> None:
        try:
            if not os.path.exists(self.model_path):
                logger.error(f"Inference classifier model not found at {self.model_path}")
                raise FileNotFoundError(f"Model file missing: {self.model_path}")
                
            self.model_data = joblib.load(self.model_path)
            logger.info("XGBoost vehicle fault classifier loaded successfully.")
        except Exception as e:
            logger.critical(f"Failed to load fault classifier model: {str(e)}")
            self.model_data = None
            
    def predict_fault(self, data: DiagnosisInput) -> DiagnosisResponse:
        # Determine diagnosis mode based on payload
        is_telemetry = (
            data.engine_temp is not None and
            data.vibration_level is not None and
            data.battery_voltage is not None and
            data.oil_pressure is not None
        )
        
        if is_telemetry:
            return self._diagnose_telemetry(data)
        else:
            return self._diagnose_symptoms(data)

    def _diagnose_telemetry(self, data: DiagnosisInput) -> DiagnosisResponse:
        if self.model_data is None:
            raise InferenceException("Diagnosis telemetry model is currently unavailable.")
            
        try:
            model = self.model_data["model"]
            obd_mapping = self.model_data["obd_mapping"]
            reverse_label_mapping = self.model_data["reverse_label_mapping"]
            
            # Safely encode the OBD error code using mapping
            obd_code = data.obd_error_code or "None"
            encoded_obd = obd_mapping.get(obd_code, obd_mapping.get("None", 0))
            
            # Format feature vector
            features = np.array([[
                data.engine_temp,
                data.vibration_level,
                data.battery_voltage,
                data.oil_pressure,
                data.mileage,
                encoded_obd
            ]])
            
            # Run prediction
            pred_class = int(model.predict(features)[0])
            pred_label = reverse_label_mapping[pred_class]
            
            # Calculate probability/confidence
            probabilities = model.predict_proba(features)[0]
            confidence = float(probabilities[pred_class])
            
            # Look up metadata
            meta = DIAGNOSIS_METADATA.get(pred_label, DIAGNOSIS_METADATA["Normal"])
            
            return DiagnosisResponse(
                predicted_fault=pred_label,
                confidence=round(confidence, 4),
                estimated_cost=meta["estimated_cost"],
                repair_time=meta["repair_time"],
                safety_advice=meta["safety_advice"],
                diagnosis_mode="telemetry"
            )
            
        except Exception as e:
            logger.error(f"Error executing vehicle telemetry diagnosis: {str(e)}")
            raise InferenceException(f"Failed to process telemetry: {str(e)}")

    def _diagnose_symptoms(self, data: DiagnosisInput) -> DiagnosisResponse:
        try:
            symptoms = [s.lower() for s in (data.symptoms or [])]
            obd = (data.obd_error_code or "").upper()
            
            predicted_fault = "Normal"
            confidence = 1.0
            
            # 1. Rule-based checks using symptoms and OBD trouble codes
            if "flat tyre" in symptoms or "flat tire" in symptoms:
                predicted_fault = "Flat Tyre / Puncture"
                confidence = 0.99
            elif "brake noise" in symptoms:
                predicted_fault = "Brake Pad Wear / Brake Fault"
                confidence = 0.95
            elif "overheating" in symptoms or obd == "P0115":
                predicted_fault = "Overheating Engine"
                confidence = 0.92 if obd == "P0115" else 0.85
            elif "engine won't start" in symptoms or "clicking sound" in symptoms or "battery light on" in symptoms or obd == "P0562":
                predicted_fault = "Alternator or Battery Failure"
                confidence = 0.95 if obd == "P0562" else 0.88
            elif "engine vibration" in symptoms or "low pickup" in symptoms or "black smoke" in symptoms or obd == "P0300":
                predicted_fault = "Engine Misfire"
                confidence = 0.95 if obd == "P0300" else 0.82
            elif "white smoke" in symptoms or obd == "P0299":
                predicted_fault = "Low Oil Pressure / Oil Leak"
                confidence = 0.90 if obd == "P0299" else 0.80
            elif len(symptoms) > 0:
                predicted_fault = "General Mechanical Fault"
                confidence = 0.70
            
            # Look up metadata mapping
            meta = DIAGNOSIS_METADATA.get(predicted_fault, DIAGNOSIS_METADATA["Normal"])
            
            return DiagnosisResponse(
                predicted_fault=predicted_fault,
                confidence=confidence,
                estimated_cost=meta["estimated_cost"],
                repair_time=meta["repair_time"],
                safety_advice=meta["safety_advice"],
                diagnosis_mode="symptom"
            )
            
        except Exception as e:
            logger.error(f"Error executing vehicle symptom diagnosis: {str(e)}")
            raise InferenceException(f"Failed to process symptoms: {str(e)}")

# Singleton Service Instance
diagnosis_service = DiagnosisService()
