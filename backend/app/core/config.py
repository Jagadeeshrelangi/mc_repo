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

    # PostgreSQL async connection string for SQLAlchemy.
    # Format: postgresql+asyncpg://user:password@host:port/database
    # Leave unset until the database is provisioned; the app must still boot
    # (and serve /health + AI endpoints) without a live database.
    DATABASE_URL: Optional[str] = None

    # --- Authentication (Sprint 2, Task 3, Stage 1) ---
    # JWT signing secret. MUST come from the environment (backend/.env or a
    # secret store). No default/fallback secret is hardcoded here. Any
    # development/test fallback must be opt-in and live outside this file
    # (e.g. a guarded test fixture), never a real production secret.
    JWT_SECRET_KEY: Optional[str] = None

    # JWT signing algorithm (configurable, e.g. HS256 for symmetric signing).
    JWT_ALGORITHM: str = "HS256"

    # Access-token lifetime in minutes (D5: 15 minutes).
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15

    # Refresh-token lifetime in days (D5: 7 days).
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

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
