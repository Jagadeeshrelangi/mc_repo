# CONVERSATION OWNERSHIP RECON REPORT

**Sprint 2 | Task 4: Conversation Ownership**
**Stage 0: Read-Only Reconnaissance & Architecture Decision**
**Date:** 2026-08-15

> **Scope: reconnaissance only — NO IMPLEMENTATION WAS PERFORMED.** No code,
> routes, schemas, models, services, migrations, frontend files, dependencies,
> or configuration were created or modified. The only artifact produced is this
> report file. The application codebase is unchanged from the Task 3 checkpoint
> (250 tests / 14 OpenAPI paths).

---

## 1. Executive Summary

- Conversation sessions are today a **process-local, unowned, anonymous dict**:
  `ChatService.sessions: Dict[str, SessionMemory]` keyed by a client-supplied
  opaque `session_id`. There is **no `user_id`**, **no PostgreSQL persistence**,
  and **no ownership enforcement** — authentication (Task 3 Stage 8) gates the
  route, but any authenticated user who knows a `session_id` can read/write any
  session.
- The authoritative `docs/backend/database/schema.sql` **already defines**
  owner-bound `conversations` (`user_id REFERENCES users(id)`) and
  `chat_messages` (`conversation_id REFERENCES conversations(id)`) tables that
  fit the desired ownership model **without inventing fields**.
- Recommended architecture: **OPTION B — PostgreSQL persistence replacing the
  in-memory session store**, with ownership enforced by repository queries
  filtered on **both** conversation ID and authenticated `user_id`. Never trust
  a client-supplied `session_id` alone.
- Next migration: **`0003_conversation_ownership`** creating the **minimum
  viable schema** (`conversations` + `chat_messages` only). `diagnoses` is
  deferred (the diagnosis endpoint is stateless and persists nothing today).
- `0001_baseline.py` and `0002_authentication_foundation.py` **remain
  immutable**; the new revision is purely additive.
- The Flutter AI module is a **pure mock** (no HTTP, no token), so persisting
  the backend is **not a breaking change** for the current UI; the breaking
  surface is the future real HTTP repository, which must add token injection.

---

## 2. Current Conversation Architecture

Source: `backend/app/services/chat_service.py`,
`backend/app/api/v1/conversation.py`, `backend/app/schemas/chat.py`.

### 2.1 Session creation
- `POST /api/v1/conversation/session` → `chat_service.create_session()`
  (conversation.py:34–39).
- `create_session` (chat_service.py:54–58):
  ```python
  session_id = f"session_{uuid.uuid4().hex[:12]}"
  self.sessions[session_id] = SessionMemory()
  ```
  Generates `session_` + 12 hex chars (a 20-char opaque token), stores a new
  `SessionMemory` in the module-level singleton dict, returns the id.

### 2.2 `session_id` generation
- `session_{uuid4().hex[:12]}` (chat_service.py:55). Opaque, unguessable-ish
  (48 bits), but **not a UUID**; there is no owner and no DB row behind it.

### 2.3 Session storage
- `ChatService.sessions: Dict[str, SessionMemory]` (chat_service.py:34).
- `ChatService` is a **module-level singleton**: `chat_service = ChatService()`
  (chat_service.py:255). All API requests share one process-local dict.

### 2.4 Message storage
- `SessionMemory.history: List[Dict[str, str]]` of
  `{"role": "user"|"assistant", "content": "..."}` (chat_service.py:16–30).
- `add_message` appends and **caps history at 12 turns** (chat_service.py:22–23):
  ```python
  if len(self.history) > 12:
      self.history = self.history[-12:]
  ```

### 2.5 History retrieval
- `GET /api/v1/conversation/history?session_id=X` →
  `chat_service.get_session_history(X)` (conversation.py:48–57).
- `get_session_history` (chat_service.py:60–66) raises a FastAPI
  `HTTPException(404)` when the key is absent, else returns
  `self.sessions[session_id].history`.

### 2.6 Unknown `session_id` handling
- **Auto-create on chat:** `handle_chat` (chat_service.py:73–74):
  ```python
  if session_id not in self.sessions:
      self.sessions[session_id] = SessionMemory()
  ```
  Any client can invent a `session_id` and it silently becomes a new session.
- **404 on history:** `get_session_history` 404s for unknown keys.

### 2.7 Session ownership
- **None.** No `user_id` anywhere in `ChatService`, `ChatRequest`, or the
  schemas. Ownership does not exist.

### 2.8 Session persistence
- **None.** Purely in-memory; nothing touches PostgreSQL.

### 2.9 After process restart
- **All sessions are lost.** `ChatService.sessions` is rebuilt empty at import.

### 2.10 Maximum conversation memory
- 12 turns (chat_service.py:22–23). The LLM prompt uses
  `SessionMemory.get_formatted_history()` (chat_service.py:25–30) which renders
  `User:…/Engineer:…` lines.

### 2.11 Clean convertibility to repository-backed storage
- **Yes, with restructuring.** The storage seam is small (one dict + one list
  per session). `SessionMemory` can become a pure prompt-formatting helper; the
  dict/session + append logic moves to a `ConversationRepository` /
  `ChatMessageRepository`. `create_session`, `handle_chat`, and
  `get_session_history` become **async** and accept the authenticated
  `user_id`. The orchestration logic (`_classify_intent`,
  `_orchestrate_diagnosis`, `_orchestrate_rag`, `_orchestrate_conversation`)
  can remain unchanged (see §12).

### 2.12 Every place `session_id` enters the system
1. `ChatRequest.session_id` (chat.py:6) — client-supplied, required.
2. `POST /chat` payload → `chat_service.handle_chat(payload)`.
3. `GET /history?session_id=` query param → `get_session_history(session_id)`.
4. `SessionResponse.session_id` (chat.py:23) — returned by `/session`.
5. `ChatResponse.session_id` (chat.py:17) — echoed by `/chat`.
6. `HistoryResponse.session_id` (chat.py:31) — echoed by `/history`.
7. Frontend `AiProvider`/`AiRepository` conversation ids (mock only, no HTTP).

---

## 3. Current Security Gap

- **Authentication exists** (Stage 8): all five AI routes require a valid
  access token via `Depends(get_current_user)`.
- **Ownership does not exist:** after auth, `get_current_user().id` is
  **discarded** by the conversation routes — no handler reads it.
- **Concrete attack:** User B authenticates, then calls
  `GET /history?session_id=<User-A's-session-id>` or
  `POST /chat {session_id: <User-A's-id>}`. Because sessions are keyed solely
  by the opaque `session_id`, B reads/writes A's conversation.
- **Volatility:** all history is lost on restart (no durability).
- **Scale/multi-worker:** in a multi-process deployment each worker holds its
  own `sessions` dict; requests routed to different workers see different state.
- **Therefore authentication alone does not provide conversation privacy.**
  Ownership binding (user_id) + durable storage are required.

---

## 4. Authoritative Schema Analysis

Source: `docs/backend/database/schema.sql` (lines 396–430). The schema is the
frozen blueprint derived from the mock model — **it is the natural
implementation target**, and comparison below confirms the current application
can map onto it without inventing fields.

### 4.1 `conversations` (schema.sql:396–403)

| Column | Type | Null | Notes / mapping |
|---|---|---|---|
| `id` | `TEXT` | PK | Maps to current `session_id` (string) |
| `user_id` | `UUID NOT NULL` | no | `REFERENCES users(id)` — the ownership FK |
| `title` | `TEXT NOT NULL` | no | No current equivalent; derive from first user message |
| `is_pinned` | `BOOLEAN DEFAULT false` | no | Frontend `Conversation.isPinned` (not in backend schemas today) |
| `created_at` | `TIMESTAMPTZ DEFAULT now()` | no | Frontend `Conversation.createdAt` |
| `updated_at` | `TIMESTAMPTZ DEFAULT now()` | no | Frontend `Conversation.updatedAt` |

No index on `user_id` in schema.sql → the migration should add
`ix_conversations_user_id`.

### 4.2 `chat_messages` (schema.sql:405–413)

| Column | Type | Null | Notes / mapping |
|---|---|---|---|
| `id` | `TEXT` | PK | Frontend `ChatMessage.id` |
| `conversation_id` | `TEXT NOT NULL` | no | `REFERENCES conversations(id)` |
| `role` | `TEXT NOT NULL` | no | `CHECK (role IN ('user','assistant'))` → `MessageRole` |
| `content` | `TEXT` | yes | `ChatMessage.content` / `MessageLog.content` |
| `timestamp` | `TIMESTAMPTZ DEFAULT now()` | no | `ChatMessage.timestamp`; order key |
| `response` | `JSONB` | yes | Optional; could store structured `ChatResponse`/`AiResponse` extras |

No index on `conversation_id` in schema.sql → the migration should add
`ix_chat_messages_conversation_id`. No `ON DELETE` clause → default is
`NO ACTION`; the migration **should** add `ON DELETE CASCADE` for privacy
cleanup (flagged as a deliberate, approvable deviation — see §10).

### 4.3 `diagnoses` (schema.sql:415–430)

| Column | Type | Null |
|---|---|---|
| `id` | `TEXT` | PK |
| `user_id` | `UUID NOT NULL REFERENCES users(id)` | no |
| `vehicle_name`, `vehicle_type`, `problem` | `TEXT` | yes |
| `symptoms`, `possible_causes` | `JSONB` | yes |
| `severity`, `recommended_action`, `recommended_service` | `TEXT` | yes |
| `estimated_cost` | `NUMERIC(12,2)` | yes |
| `should_drive` | `BOOLEAN` | yes |
| `confidence` | `SMALLINT` | yes |
| `created_at` | `TIMESTAMPTZ DEFAULT now()` | no |

Maps to `DiagnosisResponse` (diagnosis.py:22–28: predicted_fault/confidence/
estimated_cost/repair_time/safety_advice/diagnosis_mode) and the frontend
`Diagnosis` model. **The diagnosis endpoint is stateless today**
(`diagnosis_service.predict_fault` returns a response, persists nothing) — so
`diagnoses` is a **future/optional** persistence table, NOT required for
conversation ownership.

### 4.4 Schema ↔ current contracts

- `conversations.id` ↔ `SessionResponse.session_id`, `ChatRequest.session_id`,
  `ChatResponse.session_id`, `HistoryResponse.session_id`.
- `chat_messages.role/content/timestamp` ↔ `MessageLog{role,content}` and the
  `SessionMemory.history` dicts.
- `chat_messages.response` (JSONB) ↔ optional structured payload (e.g.
  `diagnostic_details`, intent, latencies) — currently unused; optional.
- `conversations.title` ↔ frontend `Conversation.title` (backend must derive it
  from the first user message; the frontend already computes a default title
  client-side in `AiProvider._defaultTitle`, ai_provider.dart:505–509).
- `conversations.is_pinned` ↔ frontend `Conversation.isPinned` (no backend
  endpoint sets it today; a future listing endpoint can read it).
- `conversations.created_at/updated_at` ↔ frontend `Conversation.createdAt/
  updatedAt` (no current backend field; new, but schema-supported).

**Conclusion:** the authoritative schema **supports the desired ownership model
without inventing fields.** The `user_id` FKs, role check, and timestamps are
already specified. The current `session_…` string format is compatible with the
`TEXT` PK type.

---

## 5. API Contract Analysis

Source: `backend/app/api/v1/conversation.py`, `backend/app/schemas/chat.py`,
`backend/app/api/deps.py`.

### 5.1 Current contracts

| Route | Method | Request | Response | Auth |
|---|---|---|---|---|
| `/api/v1/conversation/session` | POST | none | `SessionResponse{session_id}` (201) | `get_current_user` |
| `/api/v1/conversation/chat` | POST | `ChatRequest{message, session_id}` | `ChatResponse{response, intent, session_id, diagnostic_details?, latency_ms, llm_latency_ms?}` (200) | `get_current_user` |
| `/api/v1/conversation/history` | GET | `?session_id=X` | `HistoryResponse{session_id, history:[{role, content}]}` (200) | `get_current_user` |

### 5.2 Authentication dependency / current user availability
- Router-level `dependencies=[Depends(get_current_user)]` (conversation.py:9)
  runs for all three routes. `get_current_user` returns the resolved `User`
  (deps.py:56–80), but **the handlers never declare
  `user: User = Depends(get_current_user)`**, so the authenticated `user_id`
  is available but unused.

### 5.3 Current ownership behavior
- None (see §3).

### 5.4 Current error behavior
- `/chat` with unknown `session_id`: **auto-creates** a session (no error).
- `/history` with unknown `session_id`: FastAPI `HTTPException(404)` with the
  literal message `Conversation session 'X' not found.` — this leaks the exact
  session string (acceptable today; must become generic under ownership, see
  §9).
- `/session`: always 201 with a fresh id.
- Auth failures: `UnauthorizedException` → 401 generic (deps.py).

### 5.5 Compatibility issues with persistent storage
1. **Handlers must become `async`** to await repository I/O (they are sync
   today because the service is in-memory).
2. **`user_id` must flow** from `Depends(get_current_user)` into the service
   methods — the payload must NOT carry it.
3. **Auto-create must be removed** from `/chat`; unknown `session_id` under
   persistence must be a scoped miss (generic 404) rather than silent creation.
4. **No conversation listing endpoint exists** (`GET /conversations`). The
   frontend mock's `fetchConversations` has no backend counterpart. A future
   listing endpoint (owner-scoped) is needed for the real HTTP swap — optional
   in the ownership stage, required for frontend integration.
5. The 12-turn memory cap becomes a **query limit** (`ORDER BY timestamp DESC
   LIMIT 12` then reversed) instead of an in-list trim.
6. Response payloads stay wire-compatible; no contract break for existing
   callers of the three routes.

---

## 6. ChatService Analysis

Source: `backend/app/services/chat_service.py` (255 lines).

| Aspect | Current | Under Option B (target) |
|---|---|---|
| `create_session` | sync; dict insert | async; creates `Conversation` row (user_id, title derived) in one transaction |
| `session_id` generation | `session_{uuid4().hex[:12]}` | keep format; id = PK string |
| storage | `sessions: Dict[str, SessionMemory]` | `conversations` + `chat_messages` tables |
| message append | `session.add_message(role, content)` | `ChatMessageRepository.create(...)` flush |
| history read | dict lookup | query `chat_messages` by `conversation_id` (+`user_id` join/guard) `ORDER BY timestamp` |
| unknown id | auto-create (chat) / 404 (history) | owner-scoped miss → generic 404 for both |
| ownership | none | enforced in repository by `(conversation_id, user_id)` filter |
| persistence | none | durable PostgreSQL |
| restart | all lost | survives |
| max memory | 12-turn list trim (chat_service.py:22) | `ORDER BY timestamp DESC LIMIT 12` reversed |
| `_classify_intent` | unchanged | **unchanged** |
| `_orchestrate_diagnosis` | unchanged | **unchanged** (still calls `diagnosis_service.predict_fault`) |
| `_orchestrate_rag` | unchanged | **unchanged** (still calls `rag_service.query_rag`) |
| `_orchestrate_conversation` | uses `SessionMemory.get_formatted_history()` | load persisted history into the same formatter (or a pure helper) |
| `_fallback_chat_reply` | unchanged | **unchanged** |
| LLM init | `_initialize_llm` at construction | unchanged (import-time singleton) |

### 6.1 Clean convertibility verdict
**Yes.** The orchestration core (intent classification + dispatch) is already
separated from storage. Only three public methods change signature/behavior
(`create_session`, `handle_chat`, `get_session_history`), and `SessionMemory`
degrades to a pure prompt formatter. The service would gain repository
injection (constructor) and async semantics. See §12 for the detailed design.

---

## 7. Ownership Options A / B / C

### OPTION A — Keep in-memory sessions, attach `user_id`
`ChatService.sessions: Dict[str, Tuple[str, SessionMemory]]` keyed by
`session_id`, storing owner.

| Criterion | A |
|---|---|
| Privacy | **Improved** — owner check before read/write |
| Durability | **No** — still lost on restart |
| Complexity | Low |
| Scalability | **Poor** — per-process state; multi-worker inconsistent |
| Restart behavior | All history lost |
| Multi-worker behavior | **Broken** (sticky state per worker) |
| Consistency | Best-effort only |
| Testing | Easy (in-memory) |
| Flutter compatibility | Wire-identical |
| Migration complexity | None |
| Fit with schema.sql | **None** (schema already specifies DB tables) |
| Fit with architecture | Poor (no-Redis, DB-backed app already has repositories) |

### OPTION B — PostgreSQL `conversations` + `chat_messages` replace in-memory store
Implement the authoritative tables; repository-scoped ownership; persistence of
every message.

| Criterion | B |
|---|---|
| Privacy | **Strong** — owner filter in repository |
| Durability | **Yes** — survives restart |
| Complexity | Moderate (repos + async service + migration) |
| Scalability | **Good** — shared DB; any worker serves any session |
| Restart behavior | **Complete** history restore |
| Multi-worker behavior | **Correct** (single source of truth) |
| Consistency | Strong (FKs, transactions) |
| Testing | Good — fake session/repo pattern already proven (Stage 7/8) |
| Flutter compatibility | Wire-identical (contracts unchanged) |
| Migration complexity | One additive revision (`0003`) |
| Fit with schema.sql | **Exact** — implements the authoritative tables |
| Fit with architecture | **Best** — repository/service pattern already established |

### OPTION C — Hybrid: PostgreSQL persistence + bounded in-memory cache
Write-through to Postgres; keep hot `SessionMemory` in a bounded LRU.

| Criterion | C |
|---|---|
| Privacy | Strong (same as B) |
| Durability | Yes (write-through) |
| Complexity | **Highest** — cache invalidation + eviction + read-your-writes |
| Scalability | Good, but cache is per-worker (inconsistent across workers) |
| Restart behavior | Good (cache warm-up from DB) |
| Multi-worker behavior | **Cache inconsistency risk** (no Redis allowed by D1/D10) |
| Consistency | Needs careful write-through + timestamp ordering |
| Testing | Hardest (cache races) |
| Flutter compatibility | Wire-identical |
| Migration complexity | Same as B |
| Fit with schema.sql | Exact (as B) |
| Fit with architecture | **Poor** — D1/D10 explicitly exclude Redis; a per-worker cache reintroduces the multi-worker problem B removes |

### Comparison summary

| Criterion | A | B | C |
|---|---|---|---|
| Privacy | medium | **strong** | strong |
| Durability | no | **yes** | yes |
| Complexity | low | moderate | **high** |
| Scalability | poor | **good** | good |
| Restart | loses | **restores** | restores |
| Multi-worker | broken | **correct** | risky |
| Consistency | weak | **strong** | medium |
| Testing | easy | good | hard |
| Flutter compat | identical | **identical** | identical |
| Migration | none | **one additive** | one additive |
| schema.sql fit | none | **exact** | exact |
| architecture fit | poor | **best** | poor |

### Recommendation
**RECOMMENDED: OPTION B.** It delivers real durability and privacy, matches the
authoritative schema exactly, reuses the established repository/service
pattern, and avoids the multi-worker/cache hazards of C and the
non-durability/non-scalability of A. C is explicitly rejected because the
architecture excludes Redis (D1/D10) and a per-worker cache reintroduces the
exact inconsistency B eliminates, with no material benefit at this stage.

---

## 8. Recommended Architecture

```
JWT
 └─ get_current_user()  → authenticated User (deps.py)
     └─ conversation router (APIRouter dependencies) — already applied (Stage 8)
         └─ handlers now async: user: User = Depends(get_current_user)
             └─ ChatService methods become async and take user.id
                 └─ ConversationRepository / ChatMessageRepository (new)
                     └─ PostgreSQL: conversations, chat_messages (migration 0003)
```

Components (design only, not created):
- `backend/app/models/conversation.py` — `Conversation` ORM
  (`conversations` table).
- `backend/app/models/chat_message.py` — `ChatMessage` ORM
  (`chat_messages` table).
- `backend/app/repositories/conversations.py` — owner-scoped session CRUD.
- `backend/app/repositories/chat_messages.py` — message append/read, ordering,
  page cap.
- `backend/app/services/chat_service.py` — refactor: async methods, repository
  injection, orchestration preserved.
- `backend/app/api/v1/conversation.py` — handlers declare
  `user: User = Depends(get_current_user)` and pass `user.id`.
- `backend/alembic/versions/0003_conversation_ownership.py` — additive
  migration (see §10).

---

## 9. Ownership Enforcement Design

### 9.1 Principle
Never trust a client-supplied `session_id` alone. The repository filters on
**both** the conversation id **and** the authenticated `user_id`:

```
ConversationRepository.get_owned(conversation_id, user_id) -> Optional[Conversation]
ChatMessageRepository.list_for_conversation(conversation_id, user_id) -> [...]
```

### 9.2 `GET /conversation/history?session_id=X`
- Resolve `user = get_current_user()`.
- `conversation = repo.get_owned(X, user.id)`.
- If `conversation is None` → **generic NOT_FOUND** (404,
  `EntityNotFoundException("Conversation not found.")`), regardless of whether
  X is nonexistent or owned by another user. **Do not reveal whether another
  user's session exists.** (Today the handler leaks the literal id in the 404
  detail; the generic message removes that leak.)

### 9.3 `POST /conversation/chat {session_id: X}`
- Resolve `user = get_current_user()`.
- `conversation = repo.get_owned(X, user.id)`.
- If `conversation is None` → **generic 404** (same message as history). No
  auto-create (removes the silent cross-user session creation of
  chat_service.py:73–74).
- Else append user message, run orchestration, append assistant message, commit.

### 9.4 `POST /conversation/session`
- Resolve `user = get_current_user()`.
- `conversation = Conversation(user_id=user.id, title=…)`; persist; return id.
- First user message (when sent) can update the title; or title defaults to a
  placeholder until the first message is stored.

### 9.5 Non-enumeration guarantee
- Both read (`history`) and write (`chat`) paths return the **same generic
  404** for "not found" vs "not yours". No timing/status differentiation is
  exposed by the API layer (one DB query decides).

---

## 10. Migration Strategy

### 10.1 Name
**`0003_conversation_ownership`** (revision `0003`, `down_revision = "0002"`).
`0001_baseline.py` and `0002_authentication_foundation.py` are **immutable** —
unchanged, per D15.

### 10.2 Minimum viable schema (create ONLY these two tables)
1. `conversations` — `id TEXT PK`, `user_id UUID NOT NULL
   REFERENCES users(id)`, `title TEXT NOT NULL`, `is_pinned BOOLEAN DEFAULT
   false`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ
   DEFAULT now()`.
2. `chat_messages` — `id TEXT PK`, `conversation_id TEXT NOT NULL
   REFERENCES conversations(id)`, `role TEXT NOT NULL CHECK(role IN
   ('user','assistant'))`, `content TEXT`, `timestamp TIMESTAMPTZ DEFAULT
   now()`, `response JSONB`.

### 10.3 Indexes
- `ix_conversations_user_id` on `conversations(user_id)` (owner filter).
- `ix_chat_messages_conversation_id` on `chat_messages(conversation_id)`
  (history read). Optionally composite `(conversation_id, timestamp)` for
  ordered paging.

### 10.4 Cascade decision (deliberate, approvable deviation)
schema.sql declares no `ON DELETE` clause (default NO ACTION). For privacy
cleanup, the migration should add **`ON DELETE CASCADE`** on
`chat_messages.conversation_id → conversations(id)` and
`conversations.user_id → users(id)` so deleting a user/conversation cleans its
history. This is a strengthening of the frozen schema's intent and must be
recorded as a decision in the implementation stage.

### 10.5 What NOT to create
- **`diagnoses` is NOT required** for conversation ownership. The diagnosis
  route is stateless today (persists nothing). It stays a **future/optional**
  table for a separate diagnosis-persistence module.
- Do **not** implement the other 39 business tables (vehicles, orders, fuel,
  marketplace, etc.) — D13/D15 scope discipline: business tables arrive in
  their own modules.

### 10.6 Validation (read-only, allowed now / run at implementation)
- `alembic upgrade head --sql` produces an offline SQL script (no DB needed).
- **Do NOT execute a live migration** without explicit approval.

---

## 11. Repository Design

Following the `BaseRepository` convention (base.py:28–78): session injected via
constructor, writes flush without committing (caller owns the transaction).

### `ConversationRepository(BaseRepository[Conversation])`
- `model = Conversation`
- `async create_owned(user_id: str, title: str) -> Conversation` — flush only.
- `async get_owned(conversation_id: str, user_id: str) -> Optional[Conversation]`
  — `WHERE id = :cid AND user_id = :uid` (the ownership guard; read-only).
- `async list_for_user(user_id: str, *, offset, limit) -> Sequence[Conversation]`
  — for the future listing endpoint; `ORDER BY updated_at DESC`.
- `async update_title(conversation, title)` — flush only.
- `async touch(conversation)` — set `updated_at = now()`; flush only.

### `ChatMessageRepository(BaseRepository[ChatMessage])`
- `model = ChatMessage`
- `async append(conversation_id: str, role: str, content: str, response: Any = None) -> ChatMessage`
  — flush only; returns the row (id/timestamp materialized).
- `async list_for_conversation(conversation_id: str, *, limit: int = 12) -> Sequence[ChatMessage]`
  — `ORDER BY timestamp ASC` after fetching the latest `limit` (12-turn cap).
- `async count_for_conversation(conversation_id: str) -> int` — optional paging.

All reads never commit; all writes flush only; the service owns `commit()`/
`rollback()` via the request session from `get_db`.

---

## 12. ChatService Design

### 12.1 Constructor (design)
```python
def __init__(self, conversations: ConversationRepository,
             messages: ChatMessageRepository, llm=None): ...
```
`llm` init (`_initialize_llm`) unchanged; singleton `chat_service` becomes a
factory/instantiation wired per request (or an app-lifespan singleton that
receives repos) — decision for the implementation stage.

### 12.2 Methods that must change
| Method | Change |
|---|---|
| `create_session(user_id: str)` | async; create `Conversation(user_id, title)`; return id; commit |
| `handle_chat(payload: ChatRequest, user_id: str)` | async; `get_owned(session_id, user_id)` → 404 generic on miss; append user msg (flush); orchestrate; append assistant msg (flush); commit; build `ChatResponse` |
| `get_session_history(session_id: str, user_id: str)` | async; `get_owned` guard; load messages; return list |

### 12.3 Methods that can remain (with small edits)
- `_classify_intent`, `_orchestrate_diagnosis`, `_orchestrate_rag`,
  `_fallback_chat_reply` — **unchanged**.
- `_orchestrate_conversation` — signature keeps `(message, session)`; the
  `session` argument becomes a light wrapper/`SessionMemory` built from loaded
  history, or a plain list feeding `get_formatted_history` (pure formatting).

### 12.4 Where repository access belongs
Inside `ChatService` methods (service owns business flow + transaction), never
in the route handlers. Handlers only extract `user.id` and call the service.

### 12.5 Where `user_id` enters
From `get_current_user().id` at the **route handler**, passed as an argument to
the service. Never read from the request body or the `session_id`.

### 12.6 How history is loaded
`ChatMessageRepository.list_for_conversation(conversation_id, limit=12)` —
owner guard resolved by the conversation lookup first.

### 12.7 How new messages are persisted
- User message: append before LLM dispatch (so a crash still records intent).
- Assistant message: append after orchestration (even fallback/error text is
  persisted — the error reply in the `except` branch is a legitimate
  assistant turn).
- Both in one transaction; `commit()` at the end of `handle_chat`.

### 12.8 How AI response generation interacts with persistence
- Orchestration reads persisted history (prompt context), runs
  `_classify_intent`/dispatch, produces `response_text` (+ optional
  `DiagnosticSummary`), then persistence appends the assistant turn.
- If the LLM fails and fallback is enabled, the fallback text is persisted
  (graceful). If fallback is disabled, `InferenceException` propagates →
  `INFERENCE_FAILED` (422); the service should still roll back the assistant
  turn but may keep the user turn (decision: keep user turn, it was accepted
  input).

### 12.9 Transaction boundaries
One request session (from `get_db`) per request. `handle_chat` = single
transaction: conversation check + user append + assistant append. `create_session`
= single transaction. `get_session_history` = read-only, no commit.

### 12.10 Failure behavior
- Owner miss → generic `EntityNotFoundException` (404, no existence leak).
- DB error → rollback via `get_db` (database.py:88–95), generic 500.
- Inference failure → `InferenceException` (422) after rollback of partial
  assistant append.

---

## 13. API Design

### 13.1 Route changes (design)
```python
@router.post("/chat", ...)
async def chat_interaction(payload: ChatRequest, user: User = Depends(get_current_user)):
    return await chat_service.handle_chat(payload, user_id=user.id)

@router.post("/session", ...)
async def create_session(user: User = Depends(get_current_user)):
    return SessionResponse(session_id=await chat_service.create_session(user_id=user.id))

@router.get("/history", ...)
async def get_history(session_id: str = Query(...), user: User = Depends(get_current_user)):
    return await chat_service.get_session_history(session_id, user_id=user.id)
```

### 13.2 Contract compatibility
- Request/response **schemas unchanged**: `ChatRequest`, `ChatResponse`,
  `SessionResponse`, `HistoryResponse` (chat.py) remain wire-identical.
- Router-level auth dependency stays; handlers additionally bind the user.
- New (optional, future): `GET /api/v1/conversations` → owner-scoped list to
  back the frontend `fetchConversations`; `DELETE /api/v1/conversations/{id}`
  → owner-scoped delete (supports the UI delete + cascade). Not required for
  the ownership core.

### 13.3 OpenAPI impact
Routes stay at 14 paths; handlers become async (no schema change); each
protected path keeps `security: [{HTTPBearer: []}]` (already true after Stage
8). A listing/delete endpoint would add 1–2 paths in a later stage.

---

## 14. Frontend Impact

Source: `frontend/lib/features/ai/**`, `frontend/lib/features/auth/**`.

### 14.1 The AI module is a pure mock
- `AiRepository` (ai_repository.dart) never does HTTP; it returns seeded
  conversations and canned replies. `AiService`/`DiagnosisService` call the
  mock. No `http`/`dio`/`Authorization`/`Bearer` anywhere under
  `frontend/lib/features/ai/`.
- `AuthRepository` (auth_repository.dart:7) is a dev-only mock that always
  returns `true`; `AuthProvider` persists only booleans
  (`is_logged_in`, `remember_me_email`) via SharedPreferences — **no access or
  refresh token stored** (auth_provider.dart:25–33).
- **No frontend code calls the backend AI/auth routes.** Only
  `geocoding_service.dart` performs real HTTP (external, anonymous).

### 14.2 Backend persistence is NOT a breaking change today
Because the app never calls the backend conversation routes, converting the
backend to PostgreSQL does not change any current UI behavior or test.

### 14.3 Session expectations (current UI)
- The UI manages its own conversation store (`AiProvider._conversations`,
  ai_provider.dart:63); it generates local ids (`ai-<micros>`), derives titles
  client-side (`_defaultTitle`), and never requests a `session_id` from the
  backend.

### 14.4 Contract mapping for the future HTTP swap
- `Conversation{id, title, createdAt, updatedAt, isPinned, messages}`
  (conversation.dart) ↔ `conversations` row + `chat_messages` list.
- `ChatMessage{id, role, content, timestamp, response}` (chat_message.dart) ↔
  `chat_messages` columns (`response` JSONB → `AiResponse` blocks).
- `AiResponse` (blocks + action buttons) is composed **client-side** by
  `AiService._buildReply` from the raw text — the backend `ChatResponse`'s flat
  fields map onto `content`; no backend change needed for rich blocks.
- `Diagnosis` (diagnosis.dart) ↔ `DiagnosisResponse` (diagnosis.py) or the
  future `diagnoses` table.

### 14.5 Changes eventually required for real HTTP integration (NOT this stage)
1. Real `AuthRepository`: `POST /auth/login` → store `access_token` +
   `refresh_token`; `POST /auth/refresh` on expiry; `GET /auth/me` to restore
   the user (replaces boolean-only restoration).
2. Secure token storage (flutter_secure_storage or equivalent) — keep tokens
   out of SharedPreferences plaintext.
3. Real `AiRepository`: attach `Authorization: Bearer <access>` to
   diagnosis/knowledge/conversation calls; call
   `POST /conversation/session` to obtain a real `session_id`, then
   `POST /conversation/chat`, `GET /conversation/history`; a
   `GET /conversations` listing endpoint (future backend addition).
4. Token-expiry/refresh interceptor so AI calls re-auth transparently.
This is the **frontend/AI-integration sprint**, not Task 4 Stage 0.

---

## 15. Testing Strategy (design — not implemented)

Backend tests (mirroring the Stage 7/8 lightweight-app pattern: fake session +
dependency overrides, no live PostgreSQL):

1. **User A creates conversation** → 201, `SessionResponse`, row bound to
   `user_id = A`.
2. **User A sends message** → 200, user + assistant turns persisted.
3. **User A reads own history** → 200, ordered `MessageLog` list.
4. **User B attempts User A's session** (`/chat` + `/history`) → **generic 404**.
5. **User B cannot infer existence** → same 404 body/message for "B's own
   unknown id" and "A's real id" (assert identical responses).
6. **Unknown session** → generic NOT_FOUND for both `/chat` and `/history`;
   no auto-create (session not created).
7. **Restart durability** (Option B) → create + message via repo-backed service
   against a fake/real session store; re-instantiate service; history present.
8. **Message ordering** → `timestamp` ascending in history; 12-turn cap applied
   (limit query keeps newest 12).
9. **Concurrent requests** → two simultaneous `handle_chat` calls on the same
   conversation append in order without losing turns (transaction isolation).
10. **AI service context** → `_orchestrate_conversation` receives the loaded
    history (patch `ChatGoogleGenerativeAI`/LLM, assert prompt contains prior
    turns) — mirror Stage 8 module-boundary patching.
11. **Authentication remains required** → missing/invalid/expired/refresh-as-
    access token → 401 on all three conversation routes.
12. **`/health` remains public** → 200 without a token.

Also: repository unit tests (owner filter, cascade delete), migration offline
validation (`alembic upgrade head --sql`), and OpenAPI path count stays 14.

---

## 16. Security Considerations

- **Owner-scoped queries only:** every read/write is filtered by
  `(conversation_id, user_id)`; a client-supplied `session_id` is never trusted
  alone.
- **Generic 404:** identical responses for "not found" and "not yours" prevent
  session-existence enumeration on both `/history` and `/chat`.
- **No user_id in payloads:** ownership comes exclusively from the verified
  JWT via `get_current_user` (D12 Bearer transport).
- **Remove silent auto-create** (chat_service.py:73–74) — eliminates the
  cross-user session-creation hole.
- **Durability/privacy:** history is private per user and survives restarts;
  `ON DELETE CASCADE` (deliberate deviation, §10.4) ensures cleanup.
- **No new secrets/deps:** uses the existing asyncpg engine, repositories, and
  JWT stack; no Redis (D1/D10).
- **DB dependency:** protected routes already require a configured
  `DATABASE_URL` (Stage 8 finding); ownership deepens this — documented, not a
  defect.
- **Rate limiting:** conversation endpoints remain unprotected by D10 (auth
  endpoints only); F3 global/AI rate limiting stays future work.

---

## 17. Performance / Scalability Considerations

- **Shared DB is the single source of truth** — any worker serves any session;
  multi-worker consistency (Option B).
- History reads: indexed `conversation_id` (+ optional `timestamp` composite)
  keeps 12-turn loads cheap.
- Write path: two inserts + one conversation touch per `handle_chat`, in one
  transaction — negligible vs the LLM latency that dominates the request.
- No per-worker cache (Option C rejected) avoids cache-invalidation and
  read-your-writes races.
- Ownership filter uses `user_id` index on `conversations`; history lookup is
  conversation-scoped (one row) then message-scoped (small).
- Memory: no unbounded process-local growth (current `sessions` dict grows
  without limit); durable storage removes the 12-turn-only memory guarantee
  (full history persists; prompt still uses the cap).
- Future listing endpoint: `ORDER BY updated_at DESC` with `LIMIT/OFFSET`
  (paginated), `user_id` filtered.

---

## 18. Scope Boundaries

### Mandatory (for ownership)
- Migration `0003_conversation_ownership` (conversations + chat_messages).
- `Conversation` + `ChatMessage` ORM models.
- `ConversationRepository` + `ChatMessageRepository` (owner-scoped).
- `ChatService` refactor to async repository-backed (create/chat/history).
- Route handlers bind `Depends(get_current_user)` user and pass `user.id`.
- Generic 404 ownership enforcement; remove auto-create.
- Tests (12 scenarios, §15) + offline migration validation.

### Optional / future work
- `GET /api/v1/conversations` listing + `DELETE /api/v1/conversations/{id}`
  (frontend integration).
- `conversations.title` derivation from first message + `is_pinned` support.
- `diagnoses` table + diagnosis persistence (separate module).
- `response` JSONB structured payload usage.
- Frontend real HTTP repository + token storage + refresh interceptor
  (frontend-integration sprint).

### Explicitly out of scope
- Role restrictions (none needed — Task 3 §6 conclusion).
- Any other schema.sql business table (39-table blueprint stays deferred).
- Redis / global rate limiting / caching (D1/D10, F3/F4).
- Modifying `0001`/`0002` migrations (D15 immutable).
- Executing a live migration or live-DB tests in this stage.

---

## 19. Required Future Files (for implementation, NOT created now)

Backend:
- `backend/app/models/conversation.py`
- `backend/app/models/chat_message.py`
- `backend/app/repositories/conversations.py`
- `backend/app/repositories/chat_messages.py`
- `backend/alembic/versions/0003_conversation_ownership.py`
- Modified: `backend/app/services/chat_service.py`,
  `backend/app/api/v1/conversation.py`,
  `backend/app/api/deps.py` (optional wiring if needed)
- Tests: `backend/tests/test_conversation_ownership.py` (or split per area)
- Report: `docs/backend/architecture/CONVERSATION_OWNERSHIP_IMPLEMENTATION_REPORT.md`

---

## 20. Implementation Plan (proposed order, gated)

1. **Stage 1** — Models: `Conversation`, `ChatMessage` (match schema.sql).
2. **Stage 2** — Migration `0003_conversation_ownership`; offline validation
   `alembic upgrade head --sql`.
3. **Stage 3** — Repositories (`ConversationRepository`,
   `ChatMessageRepository`) with owner scoping + tests.
4. **Stage 4** — `ChatService` refactor (async, repo-backed, ownership, remove
   auto-create) + orchestration preserved + tests.
5. **Stage 5** — Route handlers bind user; generic 404; API tests (12
   scenarios) + full suite + OpenAPI (14 paths).
6. **Stage 6** — Optional future: listing/delete endpoints, title/pin.
7. **Stage 7** — Frontend integration (separate sprint) — real HTTP + tokens.
Each stage delivered with its own report and mandatory verify cycle; no live
migration without approval.

---

## 21. Validation

Read-only checks performed in this Stage 0 (no writes, no DB):

| Check | Method | Result |
|---|---|---|
| ChatService storage | read `chat_service.py` | `sessions: Dict[str, SessionMemory]`, singleton, no owner, 12-turn cap |
| Route contracts | read `conversation.py` | 3 routes, auth via router dependency, user id unused |
| Schemas | read `schemas/chat.py` | `ChatRequest/Response`, `SessionResponse`, `HistoryResponse`; no user_id |
| Auth deps | read `api/deps.py` | `get_current_user` returns `User`; available for binding |
| DB foundation | read `core/database.py` | `get_db` async session, rollback on error, no commit policy in repos |
| Repositories | read `repositories/base.py`, `users.py` | flush-not-commit convention confirmed |
| Migrations | read `0001_baseline.py`, `0002_authentication_foundation.py` | `0001` empty root; `0002` additive; both immutable |
| Authoritative schema | read `schema.sql:396–430` | `conversations`/`chat_messages`/`diagnoses` owner-bound; fits without new fields |
| Frontend | read `ai_repository.dart`, `ai_provider.dart`, `ai_service.dart`, `chat_screen.dart`, `auth_repository.dart`, `auth_provider.dart` | pure mock; no HTTP/token; persistence is non-breaking |
| Existing reports | read `TASK3_AUTHENTICATION_DECISIONS.md`, `TASK3_STAGE8_*` reports | scope rules (D13/D15), auth-integration findings confirmed |
| Git | `git status --short` before writing this report | repo had only Task 3 files (nothing new) at inspection time |

---

## 22. Git Status

`git status --short` was captured before and after this reconnaissance. The
only repository change attributable to this Stage 0 is **this report file
itself** (`docs/backend/architecture/CONVERSATION_OWNERSHIP_RECON_REPORT.md`,
new/untracked). All other entries are pre-existing Task 3 files (auth
implementation + Stage 1–8 reports). No code, schema, migration, frontend, or
configuration file was created or modified. No commits, pushes, resets, or
reverts performed. No migration executed.

---

## 23. Final Recommendation

**RECOMMENDED ARCHITECTURE: OPTION B — PostgreSQL persistence
(`conversations` + `chat_messages`) replacing the in-memory session store,
with repository-scoped ownership filtered on both conversation id and
authenticated `user_id`.**

- **Why:** durable (survives restart), correct under multi-worker deployment,
  exact fit with the authoritative `schema.sql`, reuses the proven
  repository/service pattern, and delivers the privacy guarantee that
  authentication alone cannot — with minimal complexity and no Redis.
- **Mandatory:** migration `0003_conversation_ownership`, two ORM models, two
  owner-scoped repositories, async `ChatService` refactor, handler user
  binding, generic 404 (no existence leak), removal of auto-create, and the 12
  test scenarios.
- **Optional/future:** conversation listing/delete endpoints, title/pin
  support, `diagnoses` persistence, `response` JSONB, and the frontend real-HTTP
  + token integration.
- **Out of scope:** role restrictions, the other 39 business tables, Redis /
  global rate limiting, modification of `0001`/`0002`, and any live migration.
- `0001` and `0002` **must remain immutable**; the next migration is the
  additive **`0003_conversation_ownership`** creating only `conversations` and
  `chat_messages`.

**NO IMPLEMENTATION WAS PERFORMED.** This report is reconnaissance only;
implementation awaits explicit approval.

---

*Predecessors: `TASK3_AUTHENTICATION_DECISIONS.md`,
`TASK3_STAGE8_AUTH_INTEGRATION_RECON_REPORT.md`,
`TASK3_STAGE8_AUTH_ROUTE_PROTECTION_REPORT.md`,
`docs/backend/database/schema.sql`.*