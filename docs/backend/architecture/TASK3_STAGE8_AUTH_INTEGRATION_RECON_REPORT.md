# TASK3_STAGE8_AUTH_INTEGRATION_RECON_REPORT.md

**Sprint 2 | Task 3: Authentication Foundation**
**Stage 8: Auth ↔ AI Route Integration Reconnaissance (READ-ONLY)**
**Date:** 2026-08-15

> **Scope: reconnaissance only.** No code, routes, migrations, frontend, or AI
> services were modified. This report describes how the Stage 1–7 auth stack
> (deps/get_current_user/role_required/rate limit) could later protect the
> existing AI endpoints, based on actual source.

---

## 1. Executive Summary

- The 6 existing AI endpoints are **stateless and anonymous** today: no
  `get_current_user`, no `role_required`, no `Authorization` header, no rate
  limiting. All 6 run on **in-memory** state (AI models + a process-local
  `ChatService.sessions` dict); none touch PostgreSQL or a user record.
- The **Flutter AI module is a pure mock**: `AiRepository` and
  `AuthRepository` never perform HTTP calls — the AI screens and the auth
  screens never send an access token, never set an `Authorization` header, and
  never talk to the backend at all. Only `geocoding_service.dart` performs real
  HTTP (an external geocoding API, unrelated to auth).
- **No endpoint consumes user-specific data today** and **no endpoint has any
  notion of user/session ownership**. `conversation` sessions are keyed by an
  opaque client-supplied `session_id` in a process-local dict — anonymous,
  unowned, and volatile.
- **Recommended classification:** conversation endpoints **B/A (should/must
  require auth — privacy)**; diagnosis **B (should require auth)**; knowledge
  query **B (should require auth for the customer app)**. **No role
  restriction is genuinely required** for any endpoint — protecting routes with
  `role_required` would be speculative.
- **Protecting the AI routes is NOT a breaking change for the current Flutter
  app** because the app never calls the AI backend (mock). The breaking-change
  surface is the **future real HTTP repository**, which must add token
  injection (D12 Bearer), a token store, and auth-state restoration before it
  can call protected AI endpoints.
- **Ownership is the real architectural gap:** conversation history is
  user-private by nature, but there is **no `user_id` anywhere** in
  `chat_service`, `ChatRequest`, or the schemas. Binding sessions to users
  requires a schema change + repository + migration (beyond D13 auth scope) —
  documented here, **not implemented**.
- OpenAPI paths unchanged at **14**; full suite still **209 passed**; nothing
  was created, modified, or executed against a DB.

---

## 2. Existing AI Route Inventory

Source: `backend/app/api/v1/{diagnosis,knowledge,conversation}.py`,
`backend/app/api/router.py`, `backend/app/main.py`.

| Method | Path | Request schema | Response schema | Handler | State access | State mutation |
|---|---|---|---|---|---|---|
| POST | `/api/v1/diagnosis/diagnose` | `DiagnosisInput` | `DiagnosisResponse` | `diagnosis_service.predict_fault(payload)` | none | none (stateless model) |
| POST | `/api/v1/knowledge/query` | `KnowledgeQuery` | `KnowledgeResponse` | `rag_service.query_rag(payload)` | none | none (stateless RAG) |
| POST | `/api/v1/conversation/chat` | `ChatRequest` | `ChatResponse` | `chat_service.handle_chat(payload)` | `ChatService.sessions[session_id]` (in-memory) | **yes** — appends user+assistant turns to session memory |
| POST | `/api/v1/conversation/session` | — (no body) | `SessionResponse` | `chat_service.create_session()` | `ChatService.sessions` | **yes** — creates new in-memory session |
| GET | `/api/v1/conversation/history` | `session_id` query | `HistoryResponse` | `chat_service.get_session_history(session_id)` | `ChatService.sessions[session_id]` | none (read) |
| GET | `/health` | — | JSON | `health_check()` | `settings.DATABASE_URL` | none |

Notes from actual source:

- **diagnosis.py:5** — `router = APIRouter()` (no dependencies). `diagnose_vehicle`
  (diagnosis.py:14) calls `diagnosis_service.predict_fault(payload)` — a pure
  XGBoost/rule inference over telemetry/symptoms; no session, no user.
- **knowledge.py:5** — `router = APIRouter()` (no dependencies). `query_knowledge_base`
  (knowledge.py:14) calls `rag_service.query_rag(payload)` — FAISS + Gemini;
  no session, no user.
- **conversation.py:5** — `router = APIRouter()` (no dependencies). Three
  handlers:
  - `chat_interaction` (conversation.py:14) — `chat_service.handle_chat(payload)`.
  - `create_session` (conversation.py:30) — `chat_service.create_session()`.
  - `get_history` (conversation.py:44) — `chat_service.get_session_history(session_id)`
    then maps to `MessageLog` (role/content only).
- **chat_service.py** — `ChatService.sessions: Dict[str, SessionMemory]` is a
  **module-level singleton** (`chat_service = ChatService()` at chat_service.py:255),
  purely in-memory, lost on restart, **no user_id / owner column**, keyed by a
  client-supplied opaque `session_id` string. Session memory caps at 12 turns
  (chat_service.py:22). `create_session` generates `session_{uuid4().hex[:12]}`
  (chat_service.py:55); `handle_chat` **auto-creates** a session if the
  `session_id` is unknown (chat_service.py:73–74) — an anonymous client can
  read any session whose ID it knows.
- **router.py** — AI routers mounted at `/diagnosis`, `/knowledge`,
  `/conversation`; the auth router at `/auth` (Stage 7). No AI router carries a
  dependency on `get_current_user` / `role_required`.
- **main.py:93** — `app.include_router(api_router, prefix=settings.API_V1_STR)`.
  MechaException handler maps `UNAUTHORIZED→401`, `NOT_FOUND→404`,
  `BAD_REQUEST→400`, `INFERENCE_FAILED→422`; generic Exception → 500.

---

## 3. Existing Flutter API Contracts

Source: `frontend/lib/features/ai/**`, `frontend/lib/features/auth/**`,
`frontend/lib/services/geocoding_service.dart`.

**The AI module never performs an HTTP call.** `AiRepository` (ai_repository.dart)
is a mock backend: seeded in-memory conversations, simulated 900 ms latency,
failure injection; its methods (`fetchConversations`, `sendMessage`,
`diagnoseVehicle`) return canned data. `AiService` and `DiagnosisService`
call the mock repository. There are **no** `http`, `dio`, `Uri.parse`,
`Authorization`, or `Bearer` references anywhere under
`frontend/lib/features/ai/`.

| Frontend call | HTTP? | Path | Method | Headers | Payload | Response expectation | Session/owner |
|---|---|---|---|---|---|---|---|
| `AiRepository.sendMessage` | **no (mock)** | n/a | n/a | n/a | message text | raw string | mock conversation id |
| `AiRepository.diagnoseVehicle` | **no (mock)** | n/a | n/a | n/a | vehicleType/problem/symptoms | raw map | none |
| `AiRepository.fetchConversations` | **no (mock)** | n/a | n/a | n/a | — | seeded list | none |
| `AuthRepository.login/register/forgotPassword` | **no (mock)** | n/a | n/a | n/a | credentials | `true` | none |
| `GeocodingService` | **yes** | external geocoding API | GET | n/a | address | coordinates | none (external) |

Auth state today (`auth_provider.dart`, `auth_repository.dart`,
`auth_service.dart`):

- `AuthRepository` (auth_repository.dart:7) is a **dev-only mock** that "always
  returns `true`" and performs **no credential verification**; the file header
  states it "MUST be replaced by a real HTTP repository (backend auth) before
  any production deployment."
- `AuthProvider` stores **no access token**. It persists only a boolean
  `is_logged_in` and (optionally) `remember_me_email` via `SharedPreferences`
  (auth_provider.dart:27–31, 62, 118). There is no token storage, no refresh
  handling, and no `/auth/me` restoration call.
- **No frontend code sets `Authorization: Bearer`** anywhere. The only real HTTP
  is geocoding (external, anonymous).

Conclusion: **the current Flutter app expects anonymous AI access and cannot
send a token** — because it never calls the backend AI routes at all. This is
the decisive fact for the breaking-change analysis.

---

## 4. Authentication State of Each Endpoint

| Endpoint | Auth dependency today | `Authorization` expected | Auth enforced | Rate limited |
|---|---|---|---|---|
| `POST /diagnosis/diagnose` | none | no | **no** | no |
| `POST /knowledge/query` | none | no | **no** | no |
| `POST /conversation/chat` | none | no | **no** | no |
| `POST /conversation/session` | none | no | **no** | no |
| `GET /conversation/history` | none | no | **no** | no |
| `GET /health` | none | no | **no** | no |

Auth enforcement today exists **only** on the 8 `/auth` routes (Stage 7:
`get_auth_rate_limit` at router level; `get_current_user` on `/auth/me`).
`get_current_user` / `role_required` are **implemented but unused** by AI
routes (deps.py) — Stage 7 wired them into `deps.py` and the auth router; no AI
router imports them.

---

## 5. User/Session Ownership Analysis

- **No ownership concept exists.** `ChatRequest` = `{ message, session_id }`
  (chat.py:4). There is **no `user_id`** in any chat/diagnosis/knowledge schema,
  model, or repository, and no user FK on any **implemented** table outside the
  auth foundation (`users`, `refresh_tokens`). (The authoritative 39-table
  `docs/backend/database/schema.sql` references `users(id)` from 12 business
  tables, but those tables are NOT implemented in this Task-3 codebase —
  see D13.)
- `ChatService.sessions` is a **process-local dict keyed by a client-supplied
  opaque `session_id`**. Whoever knows a `session_id` can read that session's
  history (`get_session_history`) — including sessions created by other clients.
  There is no cross-user isolation.
- Sessions are **ephemeral**: lost on process restart; capped at 12 turns;
  auto-created on first use. No persistence to PostgreSQL.
- Because conversation history is **user-private by nature**, a future
  protected design must bind sessions to the authenticated `user_id`
  (`get_current_user().id`) at creation and enforce ownership on every
  `/conversation/chat` and `/conversation/history` access.
- Diagnosis and knowledge are **stateless inference**: they consume no user
  data and return no stored state — no ownership field is relevant.

---

## 6. Role Analysis

The task instructs: do NOT add role restrictions merely because
`role_required` exists. Application contract review:

- **customer** — the AI endpoints are customer-facing features (driver
  diagnosis, manual lookup, chat). They must work for the default role.
- **mechanic** — no AI endpoint today is mechanic-specific; nothing in
  `diagnosis_service`, `rag_service`, or `chat_service` branches on a role.
- **admin** — no admin-only AI surface exists.

**Conclusion: no AI endpoint genuinely needs `role_required`.** All three roles
may legitimately call all six AI endpoints in the current application contract.
Adding `role_required("customer")` would lock mechanics/admins out of tools
they plausibly need; adding `role_required("admin")` would break the customer
app. **Recommended: authenticate only (`Depends(get_current_user)`), never
role-gate.**

---

## 7. Breaking-Change Analysis

| Concern | Finding |
|---|---|
| Calls currently without `Authorization` header | **All AI calls** (mock) and all auth calls (mock) send no header; only geocoding does HTTP and it is external/anonymous. |
| Endpoints assuming anonymous access | All 6 AI endpoints; `/health` is public by design and should stay public. |
| Where token injection would be required | In the **future real** `AiRepository`/`AuthRepository` HTTP clients: add `Authorization: Bearer <access>` to diagnosis/knowledge/conversation requests; add `POST /auth/login` → store `access_token` + `refresh_token`; add `POST /auth/refresh` on 401/expiry; add `GET /auth/me` to restore the session on app start. |
| Is auth-state restoration implemented? | **No.** `AuthProvider._loadSavedCredentials` (auth_provider.dart:25) reads only `is_logged_in`/`remember_me_email` booleans; it never validates a token or restores a user from `/auth/me`. |
| Does Flutter AuthService store/send the access token? | **No.** `AuthService` (auth_service.dart) only forwards mock booleans; there is no token field, no storage, no header. |
| Impact on the running app today | **None.** The Flutter app is fully mocked and never calls the AI backend, so protecting the backend AI routes cannot break the current app UI/tests. |
| Real risk | The **next Sprint-2 step that swaps `AiRepository`/`AuthRepository` for real HTTP** must introduce token injection, storage, refresh, and restoration in the same change, or authenticated AI calls will 401. |

---

## 8. Endpoint Classification

| Endpoint | Class | Rationale (from the actual contract) |
|---|---|---|
| `POST /conversation/history` | **A — MUST require auth** | Reads private dialogue content; without auth any client knowing a `session_id` reads others' history (chat_service.py:60–66). Ownership binding is also needed (see §9). |
| `POST /conversation/chat` | **A — MUST require auth** | Writes private dialogue content and consumes per-user history; part of the same private conversation surface. |
| `POST /conversation/session` | **B — SHOULD require auth** | Session creation is a prerequisite for the private conversation surface; auth here lets the server bind `user_id` to the new session. |
| `POST /diagnosis/diagnose` | **B — SHOULD require auth** | Vehicle telemetry + repair-cost estimation is user-sensitive data; stateless, so auth is purely access control (no data binding needed). |
| `POST /knowledge/query` | **B — SHOULD require auth** | Part of the customer AI surface; stateless generic RAG (public manuals), so auth is access control only — it could remain public, but for a gated customer app, auth is consistent. |
| `GET /health` | **C — CAN REMAIN PUBLIC** | Ops/liveness probe; must stay unauthenticated (used by deployment/uptime checks). |

No endpoint is **D (needs architectural decision)** in the auth-sense except the
**ownership design itself**, which is a DB/schema decision rather than an
auth decision and is covered in §9/§11.

---

## 9. Recommended Backend Changes

(Design only — **not implemented**.)

- **Add `Depends(get_current_user)` to the AI routers** at the router level
  (like `get_auth_rate_limit` on the auth router), so all AI endpoints require a
  valid Bearer access token:
  - `diagnosis.router`, `knowledge.router`, `conversation.router` →
    `APIRouter(dependencies=[Depends(get_current_user)])`.
  - `get_current_user` already handles missing/malformed/wrong-type tokens →
    generic 401, inactive user → 401, unknown `sub` → 404.
- **Do NOT add `role_required`** to any AI endpoint (see §6).
- **Conversation ownership (requires approval beyond D13):**
  - Add `user_id` to session creation: `POST /conversation/session` binds
    `get_current_user().id`.
  - Enforce ownership on `/conversation/chat` and `/conversation/history`
    (owner-only) — this changes `ChatService` from a plain dict keyed by
    `session_id` to an owner-keyed structure.
  - This is a **business-data** change, not auth plumbing.
- **Health stays public** (`/health`).
- **Additive only:** no change to `auth.py`, `deps.py` core behavior, or the
  existing AI service logic. The AI services themselves (`diagnosis_service`,
  `rag_service`, `chat_service`) remain untouched in any purely-auth integration.

---

## 10. Recommended Frontend Changes

(Design only — **not implemented**.)

- Replace the mock `AuthRepository` with a real HTTP client:
  - `POST /api/v1/auth/login` (email/phone + password) → store
    `TokenResponse{access_token, refresh_token, expires_in}`.
  - `POST /api/v1/auth/refresh` to rotate on expiry/401.
  - `GET /api/v1/auth/me` on app start to restore the authenticated user
    (replaces the current boolean-only `is_logged_in` restoration).
  - Persist tokens securely (flutter_secure_storage or equivalent) and keep
    the token out of `SharedPreferences` plaintext.
- Replace the mock `AiRepository` with a real HTTP client that attaches
  `Authorization: Bearer <access_token>` to diagnosis/knowledge/conversation
  calls and maps the backend response schemas (`DiagnosisResponse`,
  `KnowledgeResponse`, `ChatResponse`, `SessionResponse`, `HistoryResponse`).
- Add a token-expiry/refresh interceptor so AI calls transparently re-auth
  instead of surfacing 401s to the UI.
- This work belongs to the **AI/frontend-integration sprint**, not Task 3.

---

## 11. Database / Migration Implications

- **Auth-only integration (protecting routes):** zero schema changes — the
  auth foundation (`users` + `refresh_tokens`, migration `0002`) already
  provides identity; `get_current_user` needs no new columns.
- **Conversation ownership (required for real privacy):** the authoritative
  39-table `docs/backend/database/schema.sql` ALREADY defines owner-bound
  `conversations` (`user_id REFERENCES users(id)`, schema.sql:396) and
  `chat_messages` (`conversation_id REFERENCES conversations(id)`, schema.sql:405),
  plus an owner-bound `diagnoses` table (schema.sql:415) — none of which are
  implemented in this Task-3 codebase (D13). A future ownership step would
  implement those tables as:
  1. **Schema change** — implement `conversations` + `chat_messages` (and
     optionally `diagnoses`) per the authoritative schema, each with the
     `user_id` FK → `users.id`.
  2. **Repository changes** — owner-scoped session/message data access.
  3. **Migration** — a new additive revision (e.g. `0003_conversation_sessions`);
     **D15 rule preserved** (`0001`/`0002` untouched).
  - This is **out of Task 3 scope** (D13 restricts Task 3 to the auth
    foundation: `users` auth fields + `refresh_tokens`). It is a Sprint 2
    Conversation-module decision and must be explicitly approved before any
    schema work.
- Diagnosis/knowledge need **no schema** (stateless inference).

---

## 12. Security Considerations

- **Authenticating AI routes** closes the anonymous-abuse surface (unbounded
  Gemini/FAISS spend, history sniffing by `session_id` guessing). D10 rate
  limiting currently applies only to `/auth`; **global/AI rate limiting is F3
  (future)** and remains out of scope.
- **Ownership enforcement** is the privacy-critical piece: without binding
  `user_id` to sessions, requiring auth still lets one authenticated user read
  another's history by guessing an opaque `session_id` (chat_service.py:60–66).
- Keep `Authorization: Bearer` transport (D12), refresh tokens in the body
  (D12), and the generic-failure contract — AI route 401s must not reveal why
  (missing vs. expired vs. inactive).
- **No new secrets/deps:** protecting AI routes adds no dependency; JWT secret
  remains required via `.env` (`JWT_SECRET_KEY`) before protected routes can
  serve traffic.
- `get_current_user` is DB-backed (`UserRepository.get`), so protected AI
  routes will now depend on a configured `DATABASE_URL` — currently the
  documented Postgres limitation.

---

## 13. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Protecting AI routes before a real frontend HTTP client exists | High (next integration sprint) | AI app calls 401 | Ship token injection + refresh + `/auth/me` restoration with the real repository swap (§10) |
| `session_id` guess → cross-user history read | Medium | Privacy breach | Ownership binding (`user_id`) per §9/§11, approved separately |
| In-memory sessions lost on restart | Certain (current design) | User-visible history loss | Durable conversation tables (future module) |
| AI rate-limit abuse if left unauthed/ungated | Medium | Gemini/FAISS cost | F3 global/AI rate limiting (future); auth alone reduces but does not stop authenticated abuse |
| DB dependency for protected AI routes | High (no `DATABASE_URL`) | 500s until env set | Document; configure `.env` at deployment |
| Unauthorized-scope creep (adding role_required) | Low | Locks legit users out | Per §6: authenticate only |

---

## 14. Recommended Stage 8 Implementation Scope

(If/when approved as an implementation stage — **not performed here**.)

1. **Protect AI routes with auth only** — add `Depends(get_current_user)` at the
   router level to `diagnosis`, `knowledge`, `conversation`. `/health` stays
   public. **No `role_required`.**
2. **No schema/migration** for the auth-only step. Conversation **ownership**
   (user binding) is explicitly **out of Stage 8** and deferred to the
   Conversation module with its own decision/migration.
3. **Tests** — API tests for each AI endpoint: missing/invalid/expired/refresh-
   type token → 401; valid access token → 200; `/health` still public; AI
   services unchanged (patch at class level, mirroring the Stage 7 test
   pattern).
4. **Real-app verification** — import OK, route count still 14, OpenAPI shows
   the security requirement on AI paths.
5. **Frontend stays untouched** in this stage; the breaking-change work (token
   injection, refresh, `/auth/me` restoration) is documented for the
   frontend-integration sprint.
6. Report with the mandatory save/open/read/verify/reopen cycle; git safety
   (no add/commit/push/reset/revert); no live migration.

---

## 15. Files Inspected

Backend:
- `backend/app/api/v1/diagnosis.py`
- `backend/app/api/v1/knowledge.py`
- `backend/app/api/v1/conversation.py`
- `backend/app/api/v1/auth.py`
- `backend/app/api/router.py`
- `backend/app/api/deps.py`
- `backend/app/main.py`
- `backend/app/services/diagnosis_service.py`
- `backend/app/services/rag_service.py`
- `backend/app/services/chat_service.py`
- `backend/app/services/auth_service.py`
- `backend/app/schemas/diagnosis.py`, `knowledge.py`, `chat.py`, `auth.py`, `user.py`
- `backend/app/core/database.py`, `config.py`, `security.py`, `exceptions.py`

Frontend:
- `frontend/lib/features/ai/repositories/ai_repository.dart`
- `frontend/lib/features/ai/services/ai_service.dart`
- `frontend/lib/features/ai/services/diagnosis_service.dart`
- `frontend/lib/features/ai/providers/ai_provider.dart`
- `frontend/lib/features/auth/repositories/auth_repository.dart`
- `frontend/lib/features/auth/services/auth_service.dart`
- `frontend/lib/features/auth/providers/auth_provider.dart`
- `frontend/lib/services/geocoding_service.dart`

Reports:
- `TASK3_AUTHENTICATION_DECISIONS.md`, `TASK3_STAGE1..7_AUTH_*.md`,
  `PRE_TASK3_AUTH_RECONNAISSANCE_REPORT.md`

---

## 16. Files NOT Changed

**Nothing was created or modified in Stage 8.** Specifically untouched:
- `backend/app/api/**`, `backend/app/api/router.py`, `backend/app/api/deps.py`
- `backend/app/services/**`, `backend/app/schemas/**`, `backend/app/models/**`
- `backend/app/core/**`, `backend/app/main.py`
- `backend/ai/**`, `backend/alembic/**` (no migration)
- `frontend/**`
- `backend/requirements*.txt`, `backend/.env.example`, `backend/.env`
- No commits, pushes, resets, or reverts.

---

## 17. Validation

| Check | Command / method | Result |
|---|---|---|
| App imports | `from app.main import app` | OK (~17 s; benign faiss warning, pre-existing) |
| OpenAPI paths | `app.openapi()` | **14** paths (8 auth + 3 conversation + diagnosis + knowledge + health) — unchanged |
| AI routes present | OpenAPI | all 6 AI paths present, unsecured |
| Auth routes present | OpenAPI | all 8 `/api/v1/auth` paths present |
| Frontend HTTP surface | grep `http.|HttpClient|Authorization|Bearer|localhost` in `frontend/lib` | only external geocoding; **no backend AI/auth HTTP, no Bearer** |
| Auth token storage | read `auth_provider.dart` / `auth_repository.dart` | boolean-only; no access/refresh token |
| Full suite | `python -m pytest tests/ -q` | **209 passed** (unchanged from Stage 7 checkpoint) |
| Live migration | — | **NOT executed** |
| Git | `git status --short` | only expected Task 3 files (Stage 1–7) + this report |

---

## 18. Next Step

- **Review this reconnaissance.** If approved, the implementation of Stage 8
  (auth-only protection of AI routes, no ownership, no role gating, no
  migration) can proceed under the same gated workflow, followed by its own
  report. Conversation **ownership** is a separate, explicitly-approved
  decision that belongs to the Conversation module (schema + migration
  `0003`-era), not to this auth integration.
- **Waiting for approval.**