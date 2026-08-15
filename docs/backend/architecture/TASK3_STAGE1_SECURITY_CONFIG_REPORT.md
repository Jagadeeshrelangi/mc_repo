# TASK3 Stage 1 — Security Configuration Report

> **Sprint 2 · Task 3 · Stage 1**
> Dependencies installed + security configuration (JWT settings, env placeholders).
> **Scope:** config only — no routes, schemas, repositories, security lib code,
> migrations, models, or tests added.

---

## 1. Dependencies Added

Installed into `backend/venv` and pinned in `backend/requirements.txt`:

| Package | Version | Purpose |
|---|---|---|
| `python-jose[cryptography]` | 3.5.0 | JWT creation/verification (HS256, symmetric) and RSA/ECDSA via `cryptography` backend |
| `passlib` | 1.7.4 | Password hashing API (bcrypt scheme via `CryptContext`) |
| `bcrypt` | **4.0.1** | bcrypt hashing engine (cost-12 default, D4) |

Transitive (auto-resolved, not directly pinned):

| Package | Version | Note |
|---|---|---|
| `rsa` | 4.9.1 | python-jose dependency |
| `ecdsa` | 0.19.2 | python-jose dependency |
| `pyasn1` | 0.6.3 | already present |
| `cryptography` | 49.0.0 | already present (>=3.4.0 satisfies python-jose extra) |

## 2. Version Selection Rationale (Python 3.13.5)

Inspected the active environment first (`python --version`, `pip list`) and verified
compatibility before pinning — no blind version choices.

- **`python-jose[cryptography]==3.5.0`** — latest `python-jose` release; pure-Python
  package (works on 3.13), `[cryptography]` extra uses the already-installed
  `cryptography 49.0.0` for robust backend. Verified imports + `jose.jwt` cleanly.
- **`passlib==1.7.4`** — latest available (last release, 2020). Required for
  `CryptContext`/bcrypt integration and the D4 default of bcrypt cost 12.
- **`bcrypt==4.0.1`** — **deliberately NOT the latest (5.0.0).** bcrypt ≥4.1 rejects
  secrets longer than 72 bytes, which breaks passlib's backend capability probe
  (`(trapped) error reading bcrypt version`, `_stub_requires_backend`). Verified by
  executing a hash/verify roundtrip. `4.0.1` is the documented passlib-compatible
  pin, ships cp39-abi3 wheels valid on 3.13, and produces `$2b$` cost-12 hashes.

## 3. Configuration Changes — `backend/app/core/config.py`

Added to `Settings` (env-driven via `.env`, section-gated in code):

```python
# --- Authentication (Sprint 2, Task 3, Stage 1) ---
JWT_SECRET_KEY: Optional[str] = None   # MUST come from env; no hardcoded fallback
JWT_ALGORITHM: str = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES: int = 15  # D5: 15-minute access tokens
REFRESH_TOKEN_EXPIRE_DAYS: int = 7     # D5: 7-day refresh tokens
```

- **No default/fallback secret.** `JWT_SECRET_KEY` stays `None` until provided via
  `backend/.env`. Any future dev/test fallback must be opt-in and live outside this
  file (guarded test fixture), never a real production secret.
- `JWT_SECRET_KEY` is read from `.env` automatically by the existing
  `SettingsConfigDict(env_file=...)`; `extra="ignore"` remains.

## 4. `.env.example` JWT Placeholders

Appended (template only — real `.env` is never committed):

```
# JWT authentication (Sprint 2, Task 3). Generating a strong secret:
#   python -c "import secrets; print(secrets.token_urlsafe(64))"
# REQUIRED once auth endpoints go live. No fallback secret is baked into the
# app — auth simply remains unavailable until this is set.
JWT_SECRET_KEY=
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
```

Existing entries unchanged.

## 5. Files Changed

```
M backend/requirements.txt      (+7 lines: auth block, pinned versions)
M backend/app/core/config.py    (+16 lines: JWT settings)
M backend/.env.example          (+9 lines: JWT placeholders)
```

## 6. Files Explicitly NOT Changed

- `backend/app/core/security.py` — **not created** (Stage 2)
- `backend/app/models/` — **not created** (user columns deferred to Stage 3 model step, D3)
- `backend/app/repositories/` — not created
- `backend/app/schemas/` — not created
- `backend/app/api/v1/auth.py` / `api/deps.py` — not created
- `backend/app/db/` schema, Alembic migrations — unchanged
- `backend/app/main.py` — unchanged (no routes registered)
- `backend/tests/` — unchanged
- `frontend/` — unchanged
- `backend/.env` — **not touched** (local, gitignored; not inspected/printed)

## 7. Validation

| Check | Command | Result |
|---|---|---|
| Imports | `python -c "import jose; from jose import jwt"` | ✅ JOSE OK |
| Imports | `python -c "import passlib"` | ✅ PASSLIB OK 1.7.4 |
| Imports | `python -c "import bcrypt"` | ✅ BCRYPT OK 4.0.1 |
| bcrypt+passlib | `CryptContext(...).hash/.verify` roundtrip | ✅ `$2b$12$`, verify True/False |
| Settings | `from app.core.config import settings` | ✅ None/HS256/15/7 as configured |
| App import | `from app.main import app` | ✅ IMPORT OK |
| Routes | openapi paths | ✅ PATH COUNT: 6 (unchanged) |
| Tests | `pytest tests -q` | ✅ 8 passed in 0.07s |

## 8. Verification Notes

- bcrypt hash produced is `$2b$12$...` — cost 12 matches D4 default.
- Known `faiss.swigfaiss_avx2` module warning is pre-existing in the AI layer
  (unrelated; app imports fine and routes are unaffected).
- Passlib emits its benign `(trapped) error reading bcrypt version` line only with
  bcrypt ≥4.1; with `bcrypt==4.0.1` the roundtrip is clean.
- Working-copy line-ending (LF→CRLF) warnings from git are cosmetic only.

## 9. Next Stage

Stage 2 — `backend/app/core/security.py` with bcrypt (D4) and JWT (D5) helpers:
hash/verify password, create/verify access + refresh JWT, SHA-256 digest for refresh
tokens (D2). No routes until the user model/migration land.