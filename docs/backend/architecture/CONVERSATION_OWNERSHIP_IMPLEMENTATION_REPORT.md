# Task 4 — Conversation Ownership: Implementation Report

**Stage:** Implementation (Option B — PostgreSQL persistence)
**Date:** 2026-08-15
**Status:** Implementation complete; verification below (per the owner's
mandatory manual-verification directive — nothing is claimed "READY/ALL GOOD"
without the checks in this report having actually run).

---

## 1. Decision recap (from the approved recon report)

OPTION B: replace the in-memory `ChatService.sessions` dict with two persistent,
owner-scoped tables (`conversations`, `chat_messages`) created by migration
`0003_conversation_ownership`. Ownership is enforced at the repository level
(`WHERE id = :cid AND user_id = :uid`) and surfaced as a generic 404 by the
service — identical for "not found" and "not yours" (no existence leak).

---

## 2. What was implemented

### New models
- `backend/app/models/conversation.py` — `Conversation` (id TEXT PK, `user_id`
  UUID FK → `users.id` `ON DELETE CASCADE`, title, is_pinned, created_at,
  updated_at). `id` is app-generated as `session_<12 hex>` preserving the
  pre-Task-4 wire format; the authoritative schema declares `TEXT PK` with no
  server default, so none was added.
- `backend/app/models/chat_message.py` — `ChatMessage` (id TEXT PK,
  `conversation_id` TEXT FK → `conversations.id` `ON DELETE CASCADE`, role with
  `CHECK (role IN ('user','assistant'))`, content, timestamp, `response` JSONB).
- `backend/app/models/__init__.py` — registers both models on `Base.metadata`
  for Alembic discovery.

### Migration
- `backend/alembic/versions/0003_conversation_ownership.py` — creates ONLY the
  two tables + `ix_conversations_user_id` + `ix_chat_messages_conversation_id`.
  **Deliberate, recorded deviation** (§10.4 of the recon): both FKs use
  `ON DELETE CASCADE` (schema.sql omits `ON DELETE`, i.e. NO ACTION by default)
  so deleting a user/conversation cleans its history. `0001`/`0002` untouched.

### Repositories (flush-only, per the Stage 4 convention)
- `backend/app/repositories/conversations.py` — `ConversationRepository`:
  `create_owned(user_id, title)`, `get_owned(id, user_id)` (ownership guard),
  `list_for_user(user_id, offset, limit)` (`ORDER BY updated_at DESC`),
  `update_title`, `touch`.
- `backend/app/repositories/chat_messages.py` — `ChatMessageRepository`:
  `append(conversation_id, role, content, response)`, and
  `list_for_conversation(conversation_id, limit=12)` — the 12-turn cap is now a
  **query limit** (`ORDER BY timestamp DESC LIMIT 12`, reversed to ascending),
  replacing the old in-memory `SessionMemory` trim.

### Service refactor
- `backend/app/services/chat_service.py` — `ChatService` is now **request
  scoped** (mirrors `AuthService`): constructed per request with the
  `AsyncSession`, receives its repositories via constructor injection, and owns
  the transaction boundary (single `commit()` per write flow).
  - `create_session(user_id)` → persists `Conversation(user_id, title)`; returns id.
  - `handle_chat(payload, user_id)` → `get_owned(session_id, user_id)`, generic
    404 on miss, **no auto-create** (removed the old cross-user session-creation
    hole), persists user + assistant turns and touches the conversation in ONE
    transaction, derives the title from the first user message.
  - `get_session_history(session_id, user_id)` → owner-guarded read-only.
  - `_classify_intent`, `_orchestrate_*`, `_fallback_chat_reply` are unchanged
    in behavior; `SessionMemory` is now a pure formatter built from loaded
    history. The Gemini client is a shared, lazily-initialized class attribute
    (never re-initialized per request).

### Routes
- `backend/app/api/v1/conversation.py` — thin HTTP layer. All handlers are
  `async`, bind `user: User = Depends(get_current_user)` and
  `session: AsyncSession = Depends(get_db)`, construct `ChatService(session)`
  per request and pass `user.id` (ownership NEVER comes from the request body).

### Tests
- `backend/tests/test_conversation_ownership.py` — **23 tests** covering the 12
  recon scenarios (§15) + repository unit tests + offline migration DDL checks.
- `backend/tests/test_auth_ai_route_protection.py` — updated to the
  request-scoped wiring (patching the `ChatService` class boundary instead of
  the removed module singleton); all 41 Stage 8 tests still pass.

---

## 3. Verification performed (this session)

| Check | Result |
|---|---|
| New/changed files opened and inspected (models, repos, service, routes, migration, tests) | ✅ done |
| `app.models` + `app.services.chat_service` + repositories import cleanly | ✅ |
| `pytest tests/test_conversation_ownership.py` | ✅ **23 passed** |
| `pytest tests/test_auth_ai_route_protection.py` (updated Stage 8) | ✅ **41 passed** |
| Full backend suite `pytest -q` | ✅ **273 passed** (250 baseline + 23 new) |
| Migration offline SQL `alembic upgrade head --sql` | ✅ creates `conversations` + `chat_messages`, cascade FKs, CHECK constraint, both indexes; matches schema.sql |
| Model DDL compiled against PostgreSQL dialect vs migration DDL | ✅ consistent |
| Real app import + `app.openapi()` | ✅ **14 paths**; all 3 conversation paths declare `security`; `/health` public |
| Live probes: `/health` | ✅ 200 |
| Live probes: `/session` `/chat` `/history` | ⚠️ `RuntimeError: Database is not configured. Set DATABASE_URL in backend/.env.` — documented env limitation (identical to Stage 7/8); **not exercised against a live DB** |
| Ownership A-vs-B, unknown-session, no-auto-create, durability, ordering, concurrency, AI context, auth-required, health-public | ✅ covered by the fake-session tests above |
| `git status` / diff | ✅ only intended files; 0001/0002 untouched; no commits/pushes performed |

---

## 4. Final verification report (owner's required format)

### A. IMPLEMENTED
- `Conversation` + `ChatMessage` ORM models (registered for Alembic).
- Migration `0003_conversation_ownership` (conversations + chat_messages only;
  cascade FKs; indexes; CHECK constraint).
- `ConversationRepository` (owner-scoped) + `ChatMessageRepository`
  (12-turn query cap).
- `ChatService` refactored to async, request-scoped, repository-backed; generic
  404 on owner miss; silent auto-create removed; `user_id` always from
  `get_current_user()`.
- Routes updated to async handler + `Depends(get_current_user)` + per-request
  `ChatService(session)`.
- 23 new ownership tests + Stage 8 test file updated.

### B. MANUALLY VERIFIED
- Full test suite: **273 passed** (ran live this session).
- Migration offline SQL generation: correct, deterministic, matches schema.sql.
- Real-app `openapi()`: 14 paths, security on all 3 conversation routes,
  `/health` public.
- `/health` live probe: 200.
- No live-DB-dependent claim is asserted anywhere in tests (fake sessions only).

### C. NOT VERIFIED (environment-limited — MUST be flagged honestly)
- **No live PostgreSQL run.** `DATABASE_URL` is unset in `backend/.env`
  (existing repo state), so real-table existence, real cascade deletes, real
  FK behavior, and real multi-request durability could NOT be exercised.
  Protected endpoints return `RuntimeError` at `get_db` until a database is
  provisioned — this is the pre-existing, documented Stage 7/8 limitation, not
  a Task 4 regression.
- No live Gemini call; LLM path exercised only via the captured-prompt fake.

**Conclusion:** Task 4 code + tests are complete and green. The two NOT-VERIFIED
items (live-DB execution, real Gemini) are environment-constrained and match the
project's established Stage 7/8 posture. Nothing was committed or pushed.

*Report ends. Verified 2026-08-15.*