from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core.logging import logger, setup_logging
from app.core.exceptions import MechaException
from app.api.router import api_router

# Initialize system logger
setup_logging()

import os
env_file_path = settings.model_config.get("env_file")
env_loaded = os.path.exists(env_file_path) if env_file_path else False
logger.info(f"Startup Config | env_file located at: {env_file_path} | Exists: {env_loaded}")

key = settings.GEMINI_API_KEY
if key:
    masked_key = f"{key[:4]}...{key[-4:]}" if len(key) > 8 else "****"
    logger.info(f"Startup Config | GEMINI_API_KEY exists (Masked: {masked_key})")
else:
    logger.warning("Startup Config | GEMINI_API_KEY is missing or null.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Production-grade backend services for the Mecha Connect on-demand vehicle care ecosystem.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Enable CORS for Flutter Web client access.
# Origins are an explicit allow-list from settings (never "*" with credentials).
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global Exception Middleware for Mecha Domain Exceptions
@app.exception_handler(MechaException)
async def mecha_exception_handler(request: Request, exc: MechaException):
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    
    if exc.code == "NOT_FOUND":
        status_code = status.HTTP_404_NOT_FOUND
    elif exc.code == "UNAUTHORIZED":
        status_code = status.HTTP_401_UNAUTHORIZED
    elif exc.code == "BAD_REQUEST":
        status_code = status.HTTP_400_BAD_REQUEST
    elif exc.code == "INFERENCE_FAILED":
        status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
        
    logger.warning(f"Domain exception raised [{exc.code}]: {exc.message}")
    
    return JSONResponse(
        status_code=status_code,
        content={
            "error_code": exc.code,
            "message": exc.message,
            "details": exc.details
        }
    )

# Generic system error handler
@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled server crash: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error_code": "INTERNAL_SERVER_ERROR",
            "message": "An unexpected error occurred on the server.",
            "details": {}
        }
    )

# Mount API Routers
app.include_router(api_router, prefix=settings.API_V1_STR)

# Server Health Checker
@app.get(
    "/health",
    status_code=status.HTTP_200_OK,
    tags=["System"],
    summary="API Server Health Check"
)
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": "1.0.0"
    }

logger.info(f"FastAPI initialization complete for {settings.PROJECT_NAME}.")
