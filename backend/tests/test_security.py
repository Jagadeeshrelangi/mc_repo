"""Unit tests for the security engine (Sprint 2, Task 3, Stage 2).

Covers ONLY `app.core.security`:
- bcrypt password hashing at cost factor 12 (D4)
- JWT creation/verification with required claims (D5)
- token-type enforcement (access vs refresh)
- SHA-256 refresh-token digest (D2)

No database and no PostgreSQL are required.
"""

import hashlib
from datetime import timedelta

import pytest

import app.core.security as security
from app.core.config import settings
from app.core.security import (
    TOKEN_TYPE_ACCESS,
    TOKEN_TYPE_CLAIM,
    TOKEN_TYPE_REFRESH,
    ExpiredTokenError,
    SecurityConfigurationError,
    TokenTypeError,
    TokenVerificationError,
    create_access_token,
    create_refresh_token,
    hash_password,
    hash_refresh_token,
    verify_access_token,
    verify_password,
    verify_refresh_token,
)

TEST_USER_ID = "4f2c8a45-63a0-4b8e-9c9d-3f0b5f7a1c28"

TEST_JWT_SECRET = "test-jwt-secret-for-pytest-only"


@pytest.fixture(autouse=True)
def _fixed_security_config(monkeypatch: pytest.MonkeyPatch) -> None:
    """Pin a deterministic non-production test secret + lifetimes.

    The default ``settings.JWT_SECRET_KEY`` is None (no .env secret), so tests
    that create JWT tokens need a controlled value.
    """
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)
    monkeypatch.setattr(settings, "JWT_ALGORITHM", "HS256")
    monkeypatch.setattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES", 15)
    monkeypatch.setattr(settings, "REFRESH_TOKEN_EXPIRE_DAYS", 7)


# --- Password hashing -------------------------------------------------------


def test_hash_password_succeeds() -> None:
    hashed = hash_password("Correct Horse Battery Staple")
    assert isinstance(hashed, str)
    assert hashed.startswith("$2b$12$")
    assert "Correct Horse Battery Staple" not in hashed


def test_correct_password_verifies() -> None:
    hashed = hash_password("S3cret-P@ssword!")
    assert verify_password("S3cret-P@ssword!", hashed) is True


def test_incorrect_password_fails() -> None:
    hashed = hash_password("S3cret-P@ssword!")
    assert verify_password("wrong-password", hashed) is False


def test_bcrypt_cost_factor_is_12() -> None:
    hashed = hash_password("any")
    # $2b$<cost>$...
    assert hashed.split("$")[2] == "12"


def test_hash_rejects_empty_password() -> None:
    with pytest.raises(ValueError):
        hash_password("")
    with pytest.raises(ValueError):
        hash_password(None)


def test_hash_rejects_over_72_byte_password() -> None:
    with pytest.raises(ValueError):
        hash_password("a" * 73)


def test_verify_password_with_invalid_inputs_returns_false() -> None:
    hashed = hash_password("valid-password")
    assert verify_password("", hashed) is False
    assert verify_password(None, hashed) is False
    assert verify_password("valid-password", "") is False
    assert verify_password("valid-password", None) is False


# --- JWT creation & claims --------------------------------------------------


def test_create_access_token_and_required_claims() -> None:
    token = create_access_token(TEST_USER_ID)
    payload = verify_access_token(token)
    assert payload["sub"] == TEST_USER_ID
    assert payload[TOKEN_TYPE_CLAIM] == TOKEN_TYPE_ACCESS
    for claim in ("sub", "iat", "exp", "jti", TOKEN_TYPE_CLAIM):
        assert claim in payload


def test_create_refresh_token_and_required_claims() -> None:
    token = create_refresh_token(TEST_USER_ID)
    payload = verify_refresh_token(token)
    assert payload["sub"] == TEST_USER_ID
    assert payload[TOKEN_TYPE_CLAIM] == TOKEN_TYPE_REFRESH
    for claim in ("sub", "iat", "exp", "jti", TOKEN_TYPE_CLAIM):
        assert claim in payload


def test_access_token_expiration_is_about_15_minutes() -> None:
    token = create_access_token(TEST_USER_ID)
    payload = verify_access_token(token)
    lifetime_seconds = payload["exp"] - payload["iat"]
    assert 14 * 60 <= lifetime_seconds <= 16 * 60


def test_refresh_token_expiration_is_about_7_days() -> None:
    token = create_refresh_token(TEST_USER_ID)
    payload = verify_refresh_token(token)
    lifetime_seconds = payload["exp"] - payload["iat"]
    assert 7 * 24 * 60 * 60 - 120 <= lifetime_seconds <= 7 * 24 * 60 * 60 + 120


def test_jti_is_unique_across_tokens() -> None:
    token_a = create_access_token(TEST_USER_ID)
    token_b = create_access_token(TEST_USER_ID)
    jti_a = verify_access_token(token_a)["jti"]
    jti_b = verify_access_token(token_b)["jti"]
    assert jti_a != jti_b


def test_timestamps_are_utc_epoch_seconds() -> None:
    token = create_access_token(TEST_USER_ID)
    payload = verify_access_token(token)
    assert payload["iat"] == int(payload["iat"])
    assert payload["exp"] == int(payload["exp"])
    # iat should be in the past (issued at creation), exp in the future.
    import time

    now = int(time.time())
    assert payload["iat"] <= now
    assert payload["exp"] > now


# --- Token-type enforcement -------------------------------------------------


def test_access_token_type_is_correct() -> None:
    token = create_access_token(TEST_USER_ID)
    assert verify_access_token(token)[TOKEN_TYPE_CLAIM] == TOKEN_TYPE_ACCESS


def test_refresh_token_type_is_correct() -> None:
    token = create_refresh_token(TEST_USER_ID)
    assert verify_refresh_token(token)[TOKEN_TYPE_CLAIM] == TOKEN_TYPE_REFRESH


def test_refresh_token_rejected_as_access() -> None:
    token = create_refresh_token(TEST_USER_ID)
    with pytest.raises(TokenTypeError):
        verify_access_token(token)


def test_access_token_rejected_as_refresh() -> None:
    token = create_access_token(TEST_USER_ID)
    with pytest.raises(TokenTypeError):
        verify_refresh_token(token)


# --- JWT verification failures ----------------------------------------------


def test_invalid_token_rejected() -> None:
    with pytest.raises(TokenVerificationError):
        verify_access_token("not-a-real-token")
    with pytest.raises(TokenVerificationError):
        verify_refresh_token("not-a-real-token")


def test_empty_token_rejected() -> None:
    with pytest.raises(TokenVerificationError):
        verify_access_token("")
    with pytest.raises(TokenVerificationError):
        verify_refresh_token(None)


def test_expired_token_rejected() -> None:
    token = create_access_token(TEST_USER_ID, expires_in=timedelta(seconds=-60))
    with pytest.raises(ExpiredTokenError):
        verify_access_token(token)


def test_tampered_signature_rejected() -> None:
    token = create_access_token(TEST_USER_ID)
    header, payload, _signature = token.split(".")
    forged = f"{header}.{payload}.forged-signature"
    with pytest.raises(TokenVerificationError):
        verify_access_token(forged)


def test_wrong_secret_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    token = create_access_token(TEST_USER_ID)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "a-different-secret")
    with pytest.raises(TokenVerificationError):
        verify_access_token(token)


def test_missing_jwt_secret_fails_safely(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", None)
    with pytest.raises(SecurityConfigurationError):
        create_access_token(TEST_USER_ID)
    with pytest.raises(SecurityConfigurationError):
        create_refresh_token(TEST_USER_ID)


# --- Refresh-token digest (D2) ----------------------------------------------


def test_sha256_digest_is_hexadecimal() -> None:
    digest = hash_refresh_token("plaintext.refresh.token")
    assert len(digest) == 64
    int(digest, 16)  # valid hex


def test_same_token_produces_same_digest() -> None:
    token = "plaintext.refresh.token"
    assert hash_refresh_token(token) == hash_refresh_token(token)


def test_digest_is_deterministic_across_calls() -> None:
    token = "second.refresh.token"
    expected = hashlib.sha256(token.encode("utf-8")).hexdigest()
    assert hash_refresh_token(token) == expected


def test_different_tokens_produce_different_digests() -> None:
    assert hash_refresh_token("token-aaa") != hash_refresh_token("token-bbb")


def test_digest_does_not_contain_plaintext_token() -> None:
    token = "super-secret-refresh-token-value"
    digest = hash_refresh_token(token)
    assert token not in digest