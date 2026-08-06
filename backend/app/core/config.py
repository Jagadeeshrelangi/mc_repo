import os
from typing import List, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Mecha Connect Backend"
    API_V1_STR: str = "/api/v1"
    LOG_LEVEL: str = "INFO"
    GEMINI_API_KEY: Optional[str] = None
    GEMINI_MODEL: str = "gemini-2.5-flash"
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    ENABLE_FALLBACK: bool = True

    # Default vehicle mileage (km) used for symptom-mode diagnosis when the
    # caller does not supply a telemetry odometer reading.
    DEFAULT_VEHICLE_MILEAGE: int = 80000

    # Explicit CORS origins. `allow_credentials` is incompatible with "*",
    # so keep this a concrete allow-list. Comma-separated in .env.
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://127.0.0.1:3000"]

    # Load configuration from .env file
    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
