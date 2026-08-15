# Task 5 — Users & Profile APIs: Architecture Decision Document

**Gate:** TASK 5 — ARCHITECTURE / DECISION GATE (reconnaissance + decision only)
**Date:** 2026-08-15
**Status:** DECISION DOCUMENT — **no code was written, no files modified** except
this document. Awaiting owner review.

---

## 1. Executive Summary

Task 3 already delivers a complete, secure, owner-scoped authentication
foundation including a **read-only current-user endpoint** (`GET /auth/me`)
backed by real JWT verification and the `users` table. Task 5 should therefore
be **minimal and additive**: add an owner-scoped **profile read + update**
surface on top of the existing `get_current_user()` / `UserRepository` /
`UserOut` stack, WITHOUT reworking authentication, hashing, JWT, or the
transaction boundary conventions.

- **Recommended scope:** `GET /api/v1/users/me` (profile read) + `PATCH
  /api/v1/users/me` (update safe profile fields).
- **No migration required** — the existing `users` table already contains every
  profile field (verified against `schema.sql` and the ORM model).
- **Deferred (separate tasks):** email/phone change with re-verification,
  password change (security contract), account deletion, admin-scoped profile
  management, notification-settings persistence.
- **No new tables, no Redis, no second user model, no auth rewrite.**

---

## 2. Current User Architecture (verified by opening the files)

Layer flow (already in place, Task 3):

```
Flutter → FastAPI → get_current_user() → (route) → AuthService / UserOut → UserRepository → users table
```

- `backend/app/api/deps.py:get_current_user` — real Bearer verification via
  `security.verify_access_token`, loads `User` via `UserRepository.get(id)`,
  rejects inactive accounts. Returns the ORM `User`.
- `backend/app/services/auth_service.py` — `AuthService(session)` request-scoped
  (constructor-injected `AsyncSession` + repos); owns commit/rollback.
- `backend/app/repositories/users.py` — `UserRepository` (get by id/email/phone,
  create, login bookkeeping) + `RefreshTokenRepository`; flush-only (never
  commits).
- `backend/app/repositories/base.py` — `BaseRepository.get/list/create/update/delete`.
- `backend/app/schemas/user.py:UserOut` — safe projection; `CurrentUserResponse`
  in `schemas/auth.py` **inherits UserOut**.
- `backend/app/api/v1/auth.py` — thin HTTP layer; `GET /me` returns the
  `current_user` ORM object serialized through `CurrentUserResponse`.

## 3. Authoritative Schema Findings (`docs/backend/database/schema.sql` + ORM)

`users` table columns (both sources agree; verified by inspection):

| Column | Type | Null | Default/Constraint | ORM present |
|---|---|---|---|---|
| `id` | UUID PK | no | `gen_random_uuid()` | ✅ |
| `name` | TEXT | no | — | ✅ |
| `email` | TEXT | no | UNIQUE | ✅ (+ index) |
| `phone` | TEXT | no | UNIQUE | ✅ (+ index) |
| `password_hash` | TEXT | yes | — | ✅ |
| `date_of_birth` | DATE | yes | — | ✅ |
| `gender` | TEXT | yes | — | ✅ |
| `membership_tier` | TEXT | no | `'free'` + CHECK free/pro | ✅ |
| `joined_at` | TIMESTAMPTZ | no | `now()` | ✅ |
| `emergency_contact_name` | TEXT | yes | — | ✅ |
| `emergency_contact_relation` | TEXT | yes | — | ✅ |
| `emergency_contact_phone` | TEXT | yes | — | ✅ |
| `created_at` | TIMESTAMPTZ | no | `now()` | ✅ |
| `updated_at` | TIMESTAMPTZ | no | `now()` | ✅ |

**ORM-only additions (Task 3, approved additive):** `role` (CHECK customer/
mechanic/admin, default customer), `is_active` (default true), `is_verified`
(default false), `last_login_at`, `failed_login_attempts` (default 0),
`lockout_at` + unique constraints + indexes.

**Discrepancies:** none blocking. The ORM adds the auth fields on top of
schema.sql — the documented, approved D3 change. **No Task 5 field is missing.**

## 4. Existing Auth/Profile Capabilities (verified)

1. **Profile data already returned by `GET /auth/me`:** `id`, `name`, `email`,
   `phone`, `role`, `is_active`, `is_verified`, `membership_tier`, `joined_at`,
   `date_of_birth`, `gender`, `emergency_contact_name`.
2. **Intentionally hidden (UserOut excludes):** `password_hash`,
   `failed_login_attempts`, `lockout_at`, `last_login_at`, `created_at`,
   `updated_at`, `emergency_contact_relation`, `emergency_contact_phone`,
   refresh-token digests, JWT secret. (Test `test_me_safe_response_fields_only`
   asserts the first five are absent.)
3. **Safely updatable now:** `name`, `date_of_birth`, `gender`,
   `emergency_contact_name`, `emergency_contact_relation`,
   `emergency_contact_phone`.
4. **Password change:** NOT supported (no `current_password` contract; reset is
   a documented 501 boundary — D8).
5. **Email change:** NOT supported; no re-verification infrastructure (D7/F1).
6. **Phone change:** NOT supported by any endpoint; no verification delivery.
7. **Emergency-contact fields:** model + schema exist; relation/phone are NOT
   yet exposed in `UserOut`.
8. **Role/admin fields:** read-only via `UserOut`; never writable by owner;
   `role_required()` exists for admin gating but is unused by profile.
9. **Authentication state fields** (`is_active`, `is_verified`,
   `failed_login_attempts`, `lockout_at`, `last_login_at`): read-only to owner.
10. **Repository data-access:** `get(id/email/phone)`, `create_user`, login
    bookkeeping. No profile-update method yet — `BaseRepository.update` (flush
    only) is sufficient to persist safe-field changes.

## 5. Proposed Task 5 Scope (minimal, secure, maintainable)

| Endpoint | Verdict | Justification |
|---|---|---|
| `GET /api/v1/users/me` | **RECOMMENDED** | Dedicated profile read under the users domain; returns `UserOut` (extended, see §11). Mirrors `GET /auth/me` semantics but in the profile domain (roadmap module 4). |
| `PATCH /api/v1/users/me` | **RECOMMENDED** | Update SAFE profile fields only (§7). Owner identity from `get_current_user()`. |
| `DELETE /api/v1/users/me` | **DEFER** | Account deletion has broad implications (FK cascades, tokens, wallet); separate task. |
| `PATCH /api/v1/users/me/password` | **DEFER** | Security contract (current password, refresh-token revocation, re-auth) — §10. |
| `POST /api/v1/users/me/phone/verify` | **DEFER** | Needs verification-token structure + delivery provider (D7/F1 boundary) — §9. |
| `GET/PUT /users/{user_id}` (arbitrary lookup) | **DO NOT CREATE** | IDOR risk; no admin requirement justifies it in Task 5. |

## 6. Endpoint Decision Matrix

| Endpoint | Method | Auth | Owner-scoped | In Task 5? | Notes |
|---|---|---|---|---|---|
| `/users/me` | GET | HTTPBearer | ✅ (get_current_user) | **YES** | read profile |
| `/users/me` | PATCH | HTTPBearer | ✅ (get_current_user) | **YES** | update safe fields only |
| `/users/me` | DELETE | HTTPBearer | ✅ | NO | deferred |
| `/users/me/password` | PATCH | HTTPBearer | ✅ | NO | deferred (§10) |
| `/users/me/email` | PATCH | HTTPBearer | ✅ | NO | deferred (§9) |
| `/users/me/phone` | PATCH | HTTPBearer | ✅ | NO | deferred (§9) |
| `/users/{id}` | GET | — | ❌ | NO | IDOR; rejected |
| `/users` admin CRUD | — | admin | ❌ | NO | no requirement |

## 7. Field Read/Write Matrix (all User fields, evaluated individually)

**A. SAFE PROFILE FIELDS — owner readable + owner writable:**
| Field | Read owner | Write owner | Write admin | Reason |
|---|---|---|---|---|
| `name` | ✅ | ✅ | ✅ | display name |
| `date_of_birth` | ✅ | ✅ | ✅ | profile data |
| `gender` | ✅ | ✅ | ✅ | profile data |
| `emergency_contact_name` | ✅ | ✅ | ✅ | safety profile |
| `emergency_contact_relation` | ✅ | ✅ | ✅ | safety profile |
| `emergency_contact_phone` | ✅ | ✅ | ✅ | safety profile |

**B. SECURITY / IDENTITY FIELDS — owner read-only (or hidden), never owner-writable:**
| Field | Read owner | Write owner | Write admin | Reason |
|---|---|---|---|---|
| `id` | ✅ (read-only) | ❌ | ❌ | immutable identity |
| `password_hash` | ❌ (hidden) | ❌ | via security path only | never exposed/over-pasted |
| `role` | ✅ (read-only) | ❌ | ❌ (separate RBAC flow) | privilege boundary |
| `is_active` | ✅ (read-only) | ❌ | separate admin flow | account state |
| `is_verified` | ✅ (read-only) | ❌ | separate flow | verification state |
| `failed_login_attempts` | ❌ (hidden) | ❌ | ❌ | internal auth state |
| `lockout_at` | ❌ (hidden) | ❌ | ❌ | internal auth state |
| `last_login_at` | ❌ (hidden) | ❌ | ❌ | internal auth state |

**C. ACCOUNT / BILLING / BUSINESS FIELDS:**
| Field | Read owner | Write owner | Write admin | Reason |
|---|---|---|---|---|
| `membership_tier` | ✅ (read-only) | ❌ | separate flow | billing/business; requires justification |
| `joined_at` | ✅ (read-only) | ❌ | ❌ | audit |
| `created_at` / `updated_at` | read-only (updated_at arguably hidden) | ❌ | ❌ | audit timestamps |
| `email` | ✅ (read-only) | deferred (§9) | deferred | requires re-verification |
| `phone` | ✅ (read-only) | deferred (§9) | deferred | requires verification |

**PATCH contract requirement:** the update schema must contain ONLY safe fields
(`name`, `date_of_birth`, `gender`, emergency-contact trio). FastAPI/Pydantic
model exclusion + explicit assignment prevents mass assignment/over-posting of
`role`, `is_active`, `is_verified`, `password_hash`, `membership_tier`, etc.

## 8. Email / Phone Change Decision

- **Email change:** NOT in Task 5. Safe email change requires re-verification
  (new-email proof), which needs a verification-token persistence structure and
  a delivery provider — both **absent by design** (D7/F1 documented boundary).
  Uniqueness (`uq_users_email`) protects integrity, but a direct swap without
  verification enables account takeover if the mailbox is compromised. →
  **FUTURE / CONFIGURABLE**, pending verification infrastructure.
- **Phone change:** NOT in Task 5. Direct change is lower risk than email, but
  the frozen auth contract uses phone as a login identifier; changing it
  without verification undermines login identity and the OTP flow that the
  frontend expects. → **FUTURE / CONFIGURABLE**, pending an SMS/verification
  provider decision.
- **No email/SMS provider is invented in Task 5.** Both are explicitly
  deferred with reasons.

## 9. Password Change Decision

- **NOT in Task 5.** A safe `current_password + new_password` change needs:
  - verification of `current_password` against `password_hash`
    (`security.verify_password` exists — technically ready);
  - revocation of all existing refresh tokens (DB revoke loop);
  - re-authentication / re-issue of tokens after change;
  - a decision on whether the change invalidates other devices.
- These decisions span authentication security and are **broader than a profile
  API**; the reset-password flow itself is already a documented 501 boundary
  (D8/F2) requiring a reset-token table. Password change should be its **own
  task** that first gets approval for refresh-token revocation + re-auth
  policy. Marked **FUTURE / SEPARATE TASK**.
- Password hashes are NEVER exposed; `hash_password`/`verify_password` remain
  the only hash entry points.

## 10. Admin Scope Decision

- **No admin profile endpoints in Task 5.** `role_required(*roles)` exists
  (`app.api.deps`) and is the correct gate when an admin surface is later
  required, but Task 5 has no such requirement.
- Owner-scoped endpoints remain strictly owner-bound via `get_current_user()`;
  admin scoping, when added, must be a separate router with `role_required` and
  must NOT weaken owner isolation. No `GET /users/{id}` today.

## 11. Response Safety Contract

- **Reuse `UserOut`** — do NOT create a duplicate user response schema.
- **Extend `UserOut` with the emergency-contact trio** so the frontend
  `EmergencyContact {name, relation, phone}` contract (verified in
  `frontend/.../profile/models/emergency_contact.dart`) is fully served;
  `emergency_contact_name` is already present, `_relation`/`_phone` are missing.
- Profile APIs MUST NEVER return: `password_hash`, `token_digest`, `jti`, JWT
  secret, `failed_login_attempts`, `lockout_at`, `last_login_at`, or other
  internal authentication metadata.
- `CurrentUserResponse` (inherits `UserOut`) can remain the auth-domain
  response; profile domain reuses `UserOut` (or a thin alias) to avoid drift.

## 12. Repository Layer Decision

- **Sufficient today:** `UserRepository` + `BaseRepository.update(obj)` (flush
  only) covers safe-field persistence for a PATCH. The route/service loads the
  authenticated `User` (already attached to the request session), assigns safe
  fields, and calls `update`.
- **Optional, not required:** a `update_profile(user, ...)` convenience method
  to encapsulate field assignment. Do NOT add `change_password`,
  `update_phone`, `update_email` — those belong to deferred tasks (§8/§9).
- Convention maintained: repository = data access only, flush, NEVER owns final
  commit; service owns commit/rollback; route = HTTP only.

## 13. Service Layer Decision

- **Option B — a dedicated `UserService`/`ProfileService`** is recommended.
  Rationale: profile update carries real business logic (whitelist-only field
  assignment, protecting security/billing fields, uniqueness/validation on any
  future field) and should NOT be bolted onto `AuthService` (whose concern is
  authentication, not profile editing). It mirrors the established
  request-scoped pattern (`AuthService(session)`): constructor-injected
  `AsyncSession` + `UserRepository`, owns the single `commit()`.
- Rejected: repository-direct-from-route (violates the 3-layer convention);
  extending `AuthService` (mixes concerns, grows an already-cohesive auth
  service).

## 14. Migration Decision

- **NO MIGRATION REQUIRED.** The `users` table (schema.sql + ORM) already
  contains every field Task 5 needs. Verified by direct inspection (§3).
- Do NOT create `0004`; do NOT touch `0001_baseline.py`,
  `0002_authentication_foundation.py`, `0003_conversation_ownership.py`.

## 15. Frontend Integration Boundary

- **Backend Task 5 NOW:** expose `GET`/`PATCH /api/v1/users/me` with the
  extended `UserOut` (emergency-contact trio).
- **Frontend integration LATER (separate task):** the Flutter app is entirely
  mock-backed today (`AuthRepository` always returns `true`; `ProfileRepository`
  serves seeded in-memory data with latency/failure injection — verified in
  `frontend/lib/features/auth/*` and `frontend/lib/features/profile/*`). No
  Dart HTTP layer or token storage exists. Current user data is stored locally
  via SharedPreferences (`is_logged_in`, `remember_me_*`); the profile screens
  expect `UserProfile` (name/email/phone/dateOfBirth/gender/joinedDate/
  membershipTier/emergencyContact). Wiring the real API + HTTP client + token
  storage is **frontend integration later**, out of Task 5 scope.

## 16. Threat Model

| Risk | Existing protection | Task 5 decision | Future work |
|---|---|---|---|
| IDOR / broken object-level authz | `get_current_user()`; no `{user_id}` path params | Keep owner identity from `get_current_user()` only; reject `{user_id}` lookups | admin surface must use `role_required` |
| Privilege escalation | `role` never in update schema; Pydantic excludes it | whitelist-only safe fields | RBAC flows for role changes |
| Role modification | `role` read-only in `UserOut`, not updatable | not writable by owner | admin-only RBAC |
| Account activation manipulation | `is_active` hidden + not updatable | not writable by owner | admin flow |
| Verification-state manipulation | `is_verified` hidden + not updatable | not writable by owner | verification task (D7) |
| Password hash exposure | `UserOut` omits; hash engine central | never returned; update path never touches it | password-change task |
| Email uniqueness | `uq_users_email` | no direct email change in Task 5 | verified-email flow |
| Phone uniqueness | `uq_users_phone` | no direct phone change in Task 5 | verified-phone flow |
| Mass assignment / over-posting | Pydantic request model whitelist + explicit assignment | update schema contains safe fields only | keep whitelist pattern for all future PATCHes |
| Sensitive-field leakage | `UserOut` projection; `test_me_safe_response_fields_only` | extend UserOut with emergency-contact trio only | periodic response review |
| Authentication bypass | `verify_access_token` + `get_current_user` (real JWT) | unchanged; Task 5 does not touch auth | — |
| Stale JWT / account deactivation | access tokens checked against DB `is_active` on every request | unchanged (owner inactive → 401) | token-type/state checks already enforced |

## 17. Manual Verification Results (this session — actually run)

| Check | Result |
|---|---|
| Git status / HEAD / origin | ✅ main @ `22f19e1a2c41fef2b82cb6720b777895517ca705` == origin/main; working tree clean except 2 untracked gate docs |
| Real app import (`app.main`) | ✅ imports successfully (RAG/FAISS/embeddings load) |
| `app.openapi()` | ✅ **14 paths**; `GET /auth/me` security=HTTPBearer; `/health` public |
| `GET /health` (TestClient) | ✅ 200, `database: not_configured` |
| Full test suite `pytest tests/ -q` | ✅ **273 passed** (18.45s, 77 warnings) |
| DB-dependent endpoints | ⚠️ NOT VERIFIED — `DATABASE_URL` unset; live profile CRUD against PostgreSQL cannot be exercised |

## 18. Test Baseline

- `venv python -m pytest tests/ -q` → **273 passed, 77 warnings**.
- Existing `/auth/me` coverage includes missing/malformed/expired/refresh/inactive
  rejection + safe-response-fields assertion (`test_auth_api.py:324-388`).
- No tests were modified. No implementation was performed.

## 19. Explicitly Deferred Items (with reasons)

1. **Email change + re-verification** — needs verification-token structure +
   provider (D7/F1). FUTURE / CONFIGURABLE.
2. **Phone change + verification** — needs provider + login-identity review.
   FUTURE / CONFIGURABLE.
3. **Password change** — needs current-password verification, refresh-token
   revocation, re-auth policy. SEPARATE TASK.
4. **Account deletion** — broad FK/token/wallet implications. SEPARATE TASK.
5. **Admin-scoped profile management** — no requirement; `role_required` ready
   when needed. SEPARATE TASK.
6. **Notification-settings persistence** — `notification_settings` table is in
   schema.sql but out of the strict "user profile" scope; evaluate in a later
   module (frontend already persists locally via SharedPreferences).
7. **Frontend HTTP integration / token storage** — frontend task later.

## 20. Final Decision / Approval Gate

**Task 5 scope (pending owner approval):**
- Add `GET /api/v1/users/me` → extended `UserOut` (add
  `emergency_contact_relation`, `emergency_contact_phone`).
- Add `PATCH /api/v1/users/me` → update ONLY safe fields (name, date_of_birth,
  gender, emergency-contact trio); whitelist via Pydantic; owner identity from
  `get_current_user()`.
- New `UserService`/`ProfileService` (request-scoped, mirrors `AuthService`);
  reuses `UserRepository` (+ optional `update_profile`); `BaseRepository.update`
  covers persistence. **NO new repository-side security methods.**
- **NO migration**, **NO new tables**, **NO auth rewrite**, **NO admin CRUD**,
  **NO email/phone/password/deletion endpoints** in this task.
- Test strategy: mirror `test_auth_api.py` fake-session + real
  `get_current_user`; add safe-field-update, over-posting-rejection, auth-
  required, and safe-response tests; keep full suite green.

**This is a decision document only. No code, migration, schema, route,
repository, service, test, frontend, or config change was made.**

*Document ends. Verified 2026-08-15 against the actual repository files.*