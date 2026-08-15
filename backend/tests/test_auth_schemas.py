"""Tests for auth/user Pydantic schemas (Sprint 2, Task 3, Stage 5).

Pure validation-contract tests — no database, no JWT, no hashing. Both
accepted and rejected inputs are exercised per schema.
"""

import pytest
from pydantic import ValidationError

from app.schemas.auth import (
    CurrentUserResponse,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LogoutRequest,
    LogoutResponse,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    ResetPasswordResponse,
    TokenResponse,
    VerifyRequest,
)
from app.schemas.user import UserOut

VALID_REGISTER = {
    "name": "Jagadeesh Gowda",
    "email": "jagadeesh@example.com",
    "phone": "+919876543210",
    "password": "StrongPass123",
}


def assert_validation_error(schema, payload: dict) -> None:
    with pytest.raises(ValidationError):
        schema.model_validate(payload)


# --- Register ---------------------------------------------------------------


def test_register_valid() -> None:
    r = RegisterRequest.model_validate(VALID_REGISTER)
    assert r.name == "Jagadeesh Gowda"
    assert r.email == "jagadeesh@example.com"
    assert r.phone == "+919876543210"
    assert r.password == "StrongPass123"


def test_register_rejects_missing_name() -> None:
    payload = {k: v for k, v in VALID_REGISTER.items() if k != "name"}
    assert_validation_error(RegisterRequest, payload)


def test_register_rejects_short_name() -> None:
    assert_validation_error(RegisterRequest, {**VALID_REGISTER, "name": "A"})


def test_register_rejects_missing_email() -> None:
    payload = {k: v for k, v in VALID_REGISTER.items() if k != "email"}
    assert_validation_error(RegisterRequest, payload)


def test_register_rejects_invalid_email() -> None:
    for bad in ("not-an-email", "a@b", "a@@b.com", ""):
        assert_validation_error(RegisterRequest, {**VALID_REGISTER, "email": bad})


def test_register_email_matches_frontend_regex_contract() -> None:
    """The pattern mirrors frontend AuthService.validateEmail exactly."""
    import re

    from app.schemas.auth import EMAIL_PATTERN

    assert re.fullmatch(EMAIL_PATTERN, "a@b..com") is not None
    assert re.fullmatch(EMAIL_PATTERN, "a@b.com") is not None


def test_register_rejects_missing_phone() -> None:
    payload = {k: v for k, v in VALID_REGISTER.items() if k != "phone"}
    assert_validation_error(RegisterRequest, payload)


def test_register_rejects_invalid_phone() -> None:
    for bad in ("123", "abc", "+", "12345678901234567890"):
        assert_validation_error(RegisterRequest, {**VALID_REGISTER, "phone": bad})


def test_register_rejects_missing_password() -> None:
    payload = {k: v for k, v in VALID_REGISTER.items() if k != "password"}
    assert_validation_error(RegisterRequest, payload)


def test_register_rejects_short_password() -> None:
    assert_validation_error(RegisterRequest, {**VALID_REGISTER, "password": "short"})
    assert_validation_error(RegisterRequest, {**VALID_REGISTER, "password": ""})


def test_register_rejects_overlong_password() -> None:
    assert_validation_error(RegisterRequest, {**VALID_REGISTER, "password": "x" * 129})


def test_register_accepts_empty_email_trim_boundary() -> None:
    # Whitespace-only is rejected (min_length 3 after pattern still fails).
    assert_validation_error(RegisterRequest, {**VALID_REGISTER, "email": "   "})


# --- Login ------------------------------------------------------------------


def test_login_valid_with_email() -> None:
    lr = LoginRequest.model_validate(
        {"identifier": "jagadeesh@example.com", "password": "StrongPass123"}
    )
    assert lr.identifier == "jagadeesh@example.com"


def test_login_valid_with_phone() -> None:
    lr = LoginRequest.model_validate(
        {"identifier": "+919876543210", "password": "StrongPass123"}
    )
    assert lr.identifier == "+919876543210"


def test_login_rejects_missing_identifier() -> None:
    assert_validation_error(LoginRequest, {"password": "StrongPass123"})


def test_login_rejects_missing_password() -> None:
    assert_validation_error(LoginRequest, {"identifier": "jagadeesh@example.com"})


def test_login_rejects_short_password() -> None:
    assert_validation_error(
        LoginRequest, {"identifier": "jagadeesh@example.com", "password": "x"}
    )


def test_login_rejects_invalid_identifier() -> None:
    for bad in ("not-an-email", "a@b", "123", "abc"):
        assert_validation_error(LoginRequest, {"identifier": bad, "password": "StrongPass123"})


# --- Token response ---------------------------------------------------------


def test_token_response_valid() -> None:
    t = TokenResponse.model_validate(
        {
            "access_token": "eyJhbGciOiJIUzI1NiJ9.abc.def",
            "refresh_token": "eyJhbGciOiJIUzI1NiJ9.ghi.jkl",
            "token_type": "bearer",
            "expires_in": 900,
        }
    )
    assert t.token_type == "bearer"
    assert t.expires_in == 900


def test_token_response_rejects_missing_access_token() -> None:
    payload = {
        "refresh_token": "rt",
        "token_type": "bearer",
        "expires_in": 900,
    }
    assert_validation_error(TokenResponse, payload)


def test_token_response_rejects_missing_refresh_token() -> None:
    payload = {
        "access_token": "at",
        "token_type": "bearer",
        "expires_in": 900,
    }
    assert_validation_error(TokenResponse, payload)


def test_token_response_rejects_invalid_token_type() -> None:
    payload = {
        "access_token": "at",
        "refresh_token": "rt",
        "token_type": "basic",
        "expires_in": 900,
    }
    assert_validation_error(TokenResponse, payload)


def test_token_response_rejects_non_positive_expires_in() -> None:
    for bad in (0, -5):
        payload = {
            "access_token": "at",
            "refresh_token": "rt",
            "token_type": "bearer",
            "expires_in": bad,
        }
        assert_validation_error(TokenResponse, payload)


# --- Refresh ----------------------------------------------------------------


def test_refresh_request_valid() -> None:
    r = RefreshRequest.model_validate({"refresh_token": "some.refresh.token"})
    assert r.refresh_token == "some.refresh.token"


def test_refresh_request_rejects_missing_token() -> None:
    assert_validation_error(RefreshRequest, {})


def test_refresh_request_rejects_empty_token() -> None:
    assert_validation_error(RefreshRequest, {"refresh_token": ""})


# --- Logout -----------------------------------------------------------------


def test_logout_request_valid() -> None:
    r = LogoutRequest.model_validate({"refresh_token": "some.refresh.token"})
    assert r.refresh_token == "some.refresh.token"


def test_logout_request_rejects_missing_token() -> None:
    assert_validation_error(LogoutRequest, {})


def test_logout_response_valid() -> None:
    r = LogoutResponse.model_validate({"message": "Successfully logged out"})
    assert r.message == "Successfully logged out"


# --- Verify -----------------------------------------------------------------


def test_verify_request_valid() -> None:
    r = VerifyRequest.model_validate({"token": "verify-token-123"})
    assert r.token == "verify-token-123"


def test_verify_request_rejects_missing_token() -> None:
    assert_validation_error(VerifyRequest, {})


def test_verify_request_rejects_empty_token() -> None:
    assert_validation_error(VerifyRequest, {"token": ""})


# --- Forgot password --------------------------------------------------------


def test_forgot_password_request_valid_with_email() -> None:
    r = ForgotPasswordRequest.model_validate({"identifier": "jagadeesh@example.com"})
    assert r.identifier == "jagadeesh@example.com"


def test_forgot_password_request_valid_with_phone() -> None:
    r = ForgotPasswordRequest.model_validate({"identifier": "+919876543210"})
    assert r.identifier == "+919876543210"


def test_forgot_password_request_rejects_missing_identifier() -> None:
    assert_validation_error(ForgotPasswordRequest, {})


def test_forgot_password_request_rejects_invalid_identifier() -> None:
    assert_validation_error(ForgotPasswordRequest, {"identifier": "not-valid"})


def test_forgot_password_response_is_generic() -> None:
    r = ForgotPasswordResponse.model_validate(
        {"message": "If an account exists, a password reset link has been sent."}
    )
    assert "If an account exists" in r.message


# --- Reset password ---------------------------------------------------------


def test_reset_password_request_valid() -> None:
    r = ResetPasswordRequest.model_validate(
        {"token": "reset-token-123", "new_password": "NewStrongPass456"}
    )
    assert r.token == "reset-token-123"
    assert r.new_password == "NewStrongPass456"


def test_reset_password_request_rejects_missing_token() -> None:
    assert_validation_error(ResetPasswordRequest, {"new_password": "NewStrongPass456"})


def test_reset_password_request_rejects_missing_new_password() -> None:
    assert_validation_error(ResetPasswordRequest, {"token": "reset-token-123"})


def test_reset_password_request_rejects_short_new_password() -> None:
    assert_validation_error(
        ResetPasswordRequest, {"token": "t", "new_password": "short"}
    )


def test_reset_password_response_valid() -> None:
    r = ResetPasswordResponse.model_validate({"message": "Password has been reset successfully"})
    assert r.message == "Password has been reset successfully"


# --- Safe user response / current user -------------------------------------


def _user_payload() -> dict:
    return {
        "id": "11111111-1111-1111-1111-111111111111",
        "name": "Jagadeesh Gowda",
        "email": "jagadeesh@example.com",
        "phone": "+919876543210",
        "role": "customer",
        "is_active": True,
        "is_verified": False,
        "membership_tier": "free",
        "joined_at": "2026-08-15T00:00:00Z",
    }


def test_user_out_exposes_only_safe_fields() -> None:
    u = UserOut.model_validate(_user_payload())
    assert u.role == "customer"
    assert u.email == "jagadeesh@example.com"


def test_user_out_rejects_unknown_role() -> None:
    assert_validation_error(UserOut, {**_user_payload(), "role": "superadmin"})


def test_user_out_accepts_all_roles() -> None:
    for role in ("customer", "mechanic", "admin"):
        u = UserOut.model_validate({**_user_payload(), "role": role})
        assert u.role == role


def test_user_out_rejects_missing_required_fields() -> None:
    for field in ("id", "name", "email", "phone", "role", "joined_at"):
        payload = {k: v for k, v in _user_payload().items() if k != field}
        assert_validation_error(UserOut, payload)


def test_current_user_response_matches_user_out() -> None:
    cu = CurrentUserResponse.model_validate(_user_payload())
    assert cu.id == _user_payload()["id"]
    assert cu.role == "customer"


# --- Secret-leak boundaries -------------------------------------------------


def test_user_out_model_has_no_password_hash_field() -> None:
    assert "password_hash" not in UserOut.model_fields


def test_user_out_model_has_no_refresh_token_digest_field() -> None:
    assert "token_digest" not in UserOut.model_fields
    assert "refresh_token" not in UserOut.model_fields


def test_user_out_model_has_no_internal_security_fields() -> None:
    for secret in ("failed_login_attempts", "lockout_at", "last_login_at", "jwt", "secret"):
        assert secret not in UserOut.model_fields


def test_current_user_response_has_no_password_hash_field() -> None:
    assert "password_hash" not in CurrentUserResponse.model_fields


def test_user_out_ignores_unknown_extra_fields() -> None:
    # Extra payload keys are ignored (default extra=ignore) rather than leaking.
    u = UserOut.model_validate({**_user_payload(), "password_hash": "$2b$12$secret"})
    assert "password_hash" not in u.model_dump()


def test_token_schemas_cannot_decode_or_hash() -> None:
    """TokenResponse is a passive container — no decoding occurs in schemas."""
    t = TokenResponse.model_validate(
        {
            "access_token": "not.a.real.jwt",
            "refresh_token": "not.a.real.jwt",
            "token_type": "bearer",
            "expires_in": 900,
        }
    )
    assert t.access_token == "not.a.real.jwt"
    assert t.refresh_token == "not.a.real.jwt"