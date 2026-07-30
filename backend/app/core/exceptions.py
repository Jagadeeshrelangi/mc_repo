from typing import Any, Dict, Optional

class MechaException(Exception):
    """Base exception for all Mecha Connect domain errors."""
    def __init__(self, message: str, code: str = "INTERNAL_ERROR", details: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details or {}

class EntityNotFoundException(MechaException):
    """Raised when a requested resource is missing."""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, code="NOT_FOUND", details=details)

class UnauthorizedException(MechaException):
    """Raised on authentication failures."""
    def __init__(self, message: str = "Unauthorized access", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, code="UNAUTHORIZED", details=details)

class InvalidInputException(MechaException):
    """Raised when request payloads contain validation errors."""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, code="BAD_REQUEST", details=details)

class InferenceException(MechaException):
    """Raised when the ML model inference fails."""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, code="INFERENCE_FAILED", details=details)
