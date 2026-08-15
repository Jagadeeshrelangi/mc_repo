# Task 3, Stage 8 — Auth-Only Protection of AI Routes

**Author:** Mecha Connect backend working session
**Date:** 2026-08-15
**Status:** Complete (implementation, tests, OpenAPI verification, manual verification)
**Prerequisite report:** `TASK3_STAGE8_AUTH_INTEGRATION_RECON_REPORT.md`

---

## 1. Executive Summary

Stage 8 protects the three existing AI routers (`diagnosis`, `knowledge`,
`conversation`) with the Stage 7 authentication layer. Every AI endpoint now
requires a valid, non-expired **access** token via the real
`get_current_user` dependency (`backend/app/api/deps.py`). The change is
auth-only:

- **No** role restrictions were introduced — any authenticated user
  (customer/mechanic/admin) may use all five AI endpoints.
- **No** AI service, schema, model, or route handler logic changed.
- **No** database schema change, migration, or ownership model added.
- **No** frontend change.

Verification: 250 tests pass (209 pre-existing + 41 new Stage 8 tests), the
real application's OpenAPI schema marks all five AI paths as requiring
`HTTPBearer`, and `/health` remains public.

## 2. Approved Scope

Per the user-approved Stage 8 directive:

- Protect ONLY:
  - `POST /api/v1/diagnosis/diagnose`
  - `POST /api/v1/knowledge/query`
  - `POST /api/v1/conversation/chat`
  - `POST /api/v1/conversation/session`
  - `GET /api/v1/conversation/history`
- Reuse the existing `get_current_user` dependency; do not add role checks.
- Do not modify AI services, the frontend, or the Stage 7 auth implementation.
- Keep `/health` public; leave auth routes unchanged.
- No tables, migrations, ownership, repositories, schemas, auth-service,
  new dependencies, Redis, or global rate limiting.

## 3. Routes Protected

| Route | Method | Router module | Protection |
|---|---|---|---|
| `/api/v1/diagnosis/diagnose` | POST | `app/api/v1/diagnosis.py` | `Depends(get_current_user)` |
| `/api/v1/knowledge/query` | POST | `app/api/v1/knowledge.py` | `Depends(get_current_user)` |
| `/api/v1/conversation/chat` | POST | `app/api/v1/conversation.py` | `Depends(get_current_user)` |
| `/api/v1/conversation/session` | POST | `app/api/v1/conversation.py` | `Depends(get_current_user)` |
| `/api/v1/conversation/history` | GET | `app/api/v1/conversation.py` | `Depends(get_current_user)` |

All five paths now declare the `HTTPBearer` security requirement in the real
application's OpenAPI schema.

## 4. Dependency Implementation

Each protected router was changed at the router level:

```python
router = APIRouter(dependencies=[Depends(get_current_user)])
```

This is the auth-only pattern: the dependency runs for every route in the
router but contains no auth logic itself — all token verification and user
resolution live in `app.api.deps.get_current_user` (unchanged from Stage 7).
`get_current_user` rejects:

- Missing / malformed `Authorization` header → 401 (generic).
- Expired, tampered, or wrong-secret tokens → 401 (generic).
- Refresh tokens used as access tokens → 401 (generic).
- Unknown users → 404 (NOT_FOUND).
- Inactive accounts → 401 (generic).

## 5. AI Service Preservation

No AI service code was modified:

- `backend/app/services/diagnosis_service.py` — unchanged.
- `backend/app/services/rag_service.py` — unchanged.
- `backend/app/services/chat_service.py` — unchanged.

Route handlers still call the original service singletons
(`diagnosis_service.predict_fault`, `rag_service.query_rag`,
`chat_service.handle_chat` / `create_session` / `get_session_history`).
Tests prove the services are still invoked after successful authentication
(see §7).

## 6. Conversation Ownership Limitation

Explicitly **not** implemented in this stage. As established in the recon
report (§5/§11), conversation sessions are **process-local and unowned** —
there is no `user_id` on sessions today, and any authenticated user can
supply any `session_id`. Authentication does **not** imply session ownership.

Authoritative tables already exist in `docs/backend/database/schema.sql`
(`conversations`, `chat_messages`, `diagnoses` reference `users(id)`), so
ownership remains available as a future stage that binds requests to their
authenticated user.

## 7. Tests Added

New file: `backend/tests/test_auth_ai_route_protection.py` (41 tests).

Testing strategy mirrors Stage 7: a lightweight FastAPI app mounts the three
real AI routers plus `/health` and the auth router, registers the same
`MechaException` mapping as the real app, overrides `get_db` with a fake
session, and patches the AI service singletons at the router-module boundary
(no live model / FAISS / Gemini loading, no live PostgreSQL).

For EVERY protected endpoint, the following matrix is covered:

| Scenario | Expected |
|---|---|
| Missing `Authorization` header | 401 |
| Malformed `Authorization` header | 401 |
| Invalid / tampered JWT | 401 |
| Expired access token | 401 |
| Refresh token used as access token | 401 |
| Inactive user with valid token | 401 |
| Valid access token | passes auth |

Additional coverage:

- `/health` stays public (no auth).
- All 8 auth endpoints remain registered and reachable.
- OpenAPI for the lightweight app marks the 5 AI paths with `security` and
  leaves `/health` without it.
- `diagnosis_service.predict_fault` is still called after auth.
- `chat_service.handle_chat` is still called after auth.
- Session creation + history retrieval flow works end-to-end when
  authenticated.

## 8. Full Test Results

Command: `python -m pytest tests/ -q` (in `backend/`)

**Result: 250 passed** (209 pre-existing + 41 new Stage 8 tests).

Warnings are pre-existing deprecations (Pydantic `example` kwarg, Starlette
`HTTP_422_UNPROCESSABLE_ENTITY`) and are unrelated to this change.

## 9. Real-App OpenAPI Verification

Command: `from app.main import app; app.openapi()` (real app, full service
stack).

- Total paths: **14** (unchanged — no new routes added).
- 8 auth paths + 5 AI paths + `/health`.
- All 5 AI paths now list `security: [{"HTTPBearer": []}]`.
- `/health` has **no** security requirement.
- `app.routes` is NOT used for counting because FastAPI 0.139 exposes lazy
  `_IncludedRouter` objects; `app.openapi()['paths']` is authoritative.

## 10. Manual Verification Performed

- Opened and read every modified router source file after editing
  (`diagnosis.py`, `knowledge.py`, `conversation.py`); confirmed the
  router-level dependency, the unchanged handlers, and the preservation of
  service imports.
- Ran the new test file in isolation (41 passed), then the full suite
  (250 passed).
- Inspected `app.openapi()` output for the real app (14 paths, security on
  AI paths, `/health` public).
- Live TestClient probes against the real app:
  - `GET /health` → **200**.
  - AI endpoints without credentials → **500** (see §16: the real app's
    `get_db` raises `RuntimeError: Database is not configured` because
    `DATABASE_URL` is unset in `backend/.env`; this is an environment
    limitation identical to Stage 7 — it does not indicate a defect).

## 11. Files Created

- `backend/tests/test_auth_ai_route_protection.py` — 41 auth-matrix tests.
- `docs/backend/architecture/TASK3_STAGE8_AUTH_ROUTE_PROTECTION_REPORT.md`
  (this report).

## 12. Files Modified

- `backend/app/api/v1/diagnosis.py` — added `Depends` / `get_current_user`
  imports + `APIRouter(dependencies=[Depends(get_current_user)])`.
- `backend/app/api/v1/knowledge.py` — same pattern.
- `backend/app/api/v1/conversation.py` — same pattern (plus ownership
  limitation comment).

## 13. Files NOT Changed

- `backend/app/api/router.py` — mounts unchanged (routers gained protection
  internally, no new mounts).
- `backend/app/api/deps.py` — unchanged (reused as-is from Stage 7).
- `backend/app/core/security.py`, `backend/app/services/*` — unchanged.
- `backend/app/schemas/*` — unchanged.
- All migration files — unchanged; no new migration created.
- `frontend/**` — unchanged.

## 14. Database Status

- **No schema change** and **no migration** in this stage.
- No live PostgreSQL was used: tests use a fake session via
  `dependency_overrides[get_db]`, exactly as in Stage 7.
- Existing authoritative ownership tables (`conversations`,
  `chat_messages`, `diagnoses` in `docs/backend/database/schema.sql`)
  remain untouched for a future ownership stage.

## 15. Git Status

Captured via `git status --short` before and after the change. The diff is
limited to the three router files (modified) plus the new test file and this
report (untracked). No commits, pushes, resets, or reverts were performed.

## 16. Security Considerations

- Only `HTTPBearer` access tokens are accepted; refresh tokens are rejected
  as access tokens (Stage 7 `verify_access_token`).
- Generic 401 messaging never reveals whether the header, token, user, or
  account state caused the failure.
- The auth layer is the **only** gate: no auth logic was added to route
  handlers, so behavior is consistent and centralized in `deps.py`.
- **Environment note:** with `DATABASE_URL` unset, the real app returns 500
  for protected endpoints because `get_db` refuses to start an unconfigured
  database. The 401/404 semantics are verified in the lightweight-app test
  suite; a full live-DB authenticated request is NOT exercised in this
  environment. This is explicitly distinguished:
  - AUTH DEPENDENCY TESTED: YES (41 tests).
  - LIVE DATABASE REQUEST TESTED: NO (no `DATABASE_URL`).

## 17. Known Limitations

- **Conversation ownership is not implemented**: authenticated users can
  read/write any `session_id`; sessions remain process-local and unowned.
  This is out of scope for Stage 8 and reserved for a future stage.
- Real-app authenticated end-to-end flow requires `DATABASE_URL` and a
  seeded user; not exercised here.
- AI responses themselves are unchanged — this stage gates access, it does
  not personalize or filter content.

## 18. Next Stage

A follow-up stage (pending user approval) could implement **conversation
ownership**: binding `session_id` to the authenticated user via the
authoritative `conversations` / `chat_messages` / `diagnoses` tables, which
would also make sessions durable across restarts. No further work is
performed without an explicit directive.