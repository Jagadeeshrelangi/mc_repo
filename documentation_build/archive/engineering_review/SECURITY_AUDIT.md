# Security Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: secrets, env variables, API keys, local storage, authentication, validation, input handling, future JWT, future production security.

## 1. Current State

- **Client:** Flutter app, local-only auth (SharedPreferences flags), zero real HTTP calls at RC1.
- **Backend:** FastAPI scaffold, no auth, CORS allow-all, GEMINI_API_KEY in `.env`.
- **Storage:** `shared_preferences` (theme, auth flag, notification settings, saved addresses, location).
- **Auth:** Local-only `is_logged_in` flag; Firebase Auth planned for Sprint 2.

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **Secrets properly gitignored** | `.env` and `backend/.env` both covered by `.gitignore:48:.env`; `backend/venv/` covered by `venv/` pattern. `git check-ignore` verified. |
| S2 | **API key masked at startup** | `main.py` logs only `key[:4]...key[-4:]` — never the full key |
| S3 | **Pydantic input validation** | `DiagnosisInput` uses `ge`/`le` bounds (engine_temp 0–200, battery 0–24, oil 0–120); `KnowledgeQuery.k` bounded 1–10 |
| S4 | **Session IDs are UUIDs** | `session_{uuid.uuid4().hex[:12]}` — unguessable |
| S5 | **No credentials in code** | No API keys in tracked source; `.env` is untracked |
| S6 | **Auth validation present** | Email regex, phone, password length, confirm-match checks |
| S7 | **Password strength scoring** | `evaluatePasswordStrength` scores weak/fair/good/strong |
| S8 | **`extra="ignore"` in Pydantic** | Unknown env fields are ignored — no accidental config leakage |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **Plaintext password in SharedPreferences** | **P0** | **`AuthProvider` stores plaintext password in SharedPreferences when "remember me" is enabled** (`login()` → `prefs.setString('remember_me_password', password)`). SharedPreferences is not encrypted storage. Anyone with device access (or a rooted device) can read the password. **This is the most critical finding in this audit.** |
| W2 | **`AuthRepository` accepts any credentials** | P1 | `login()`/`register()` always return `true` — zero credential verification. Any email/password logs in. Acceptable for mock at RC1, but must be flagged: the mock auth bypass must NEVER reach production. |
| W3 | **No backend auth** | P1 | No JWT/Firebase Auth middleware. `UnauthorizedException` defined but never raised. All endpoints are open at scaffold. |
| W4 | **CORS allow-all** | P1 | `allow_origins=["*"]` with `allow_credentials=True`. For production this is a misconfiguration (allow-credentials + wildcard origin is invalid/banned by browsers). Must restrict to real origins. |
| W5 | **GEMINI_API_KEY commit risk** | P1 | The key currently sits in `backend/.env` (gitignored). If anyone force-adds or copies `.env` to a tracked path, the key leaks. The key pattern `AQ.` does NOT look like the standard `AIzaSy...` Google key — needs verification of validity/rotation. |
| W6 | **No rate limiting** | P2 | All endpoints are unthrottled — DoS/abuse risk. |
| W7 | **No input sanitization on chat/diagnosis text** | P2 | `ChatService` and `RAGService` pass raw user text into prompts — prompt-injection risk when Gemini is live. No system-prompt guard. |
| W8 | **`remember_me` also stores email** | P2 | Email in SharedPreferences is low-risk, but combined with plaintext password (W1) it forms complete credentials. |
| W9 | **No TLS enforcement on client** | P2 | `http` package (Nominatim geocoding) uses HTTPS — good. But no cert pinning. Acceptable at RC1 (mock), flag for production. |
| W10 | **`allow_dangerous_deserialization=True` in FAISS** | P2 | `FAISS.load_local(..., allow_dangerous_deserialization=True)` — required for pickled index, but the FAISS index files are committed binary blobs. Supply-chain risk if index files are tampered with. Flags in chat_service.py check for `AIzaSyDummyKeyForNow` placeholder. |
| W11 | **No token storage security** | P2 | Future JWT/Firebase tokens must be stored in `flutter_secure_storage`, not SharedPreferences. Not yet implemented (Sprint 2). |
| W12 | **`FIREBASE_CREDENTIALS_PATH` empty** | P1 | Backend references Firebase but no credentials file configured. Firebase Auth cannot work without the service-account JSON. |

## 4. Authentication Audit

| Aspect | Finding | Severity |
|---|---|---|
| Login | Mock — always true | P1 (acceptable RC1, critical for Sprint 2) |
| Registration | Mock — always true | P1 |
| Password storage | **Plaintext in SharedPreferences** | **P0** |
| Password hashing | None (mock) | P1 (Sprint 2: Firebase handles) |
| Session management | SharedPreferences `is_logged_in` bool | P1 (Sprint 2: JWT) |
| Remember-me | Stores plaintext password | **P0** |
| Logout | Clears flag + prefs | ✅ Good |
| Token refresh | N/A at RC1 | P2 |

## 5. Input Validation Audit

| Surface | Validation | Severity |
|---|---|---|
| Email | Regex `^[a-zA-Z0-9._%+-]+@...` | ✅ Good |
| Phone | ≥10 digits | ✅ Good |
| Password | ≥8 chars + strength score | ✅ Good |
| Diagnosis telemetry | Pydantic `ge`/`le` bounds | ✅ Good |
| Knowledge `k` | Pydantic `ge=1, le=10` | ✅ Good |
| Chat message | No length cap | P2 |
| Address/pincode | `_pincodeFromAddress` regex `\b\d{6}\b` | ✅ Good |
| Chat/diagnosis text | No sanitization | P2 (prompt injection) |

## 6. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Plaintext password in SharedPreferences | **P0** | Use `flutter_secure_storage`; or remove remember-password (keep remember-email only) |
| R2 | Mock auth bypasses | P1 | Firewall: Sprint 2 mock repo must be replaced; never ship mock-via-true |
| R3 | Open endpoints | P1 | Add Firebase Auth + JWT middleware |
| R4 | CORS misconfig | P1 | Restrict origins in production |
| R5 | Key leakage | P1 | Verify key is dummy (pattern); rotate if real; add to CI secret scan |
| R6 | Prompt injection | P2 | Add system-prompt guard + input sanitization |

## 7. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | Plaintext password storage | **P0** | 1 hr |
| TD2 | Mock auth bypass | P1 | Sprint 2 replacement |
| TD3 | No auth middleware | P1 | 1 day |
| TD4 | CORS allow-all | P1 | 30 min |
| TD5 | No rate limiting | P2 | 2 hr |
| TD6 | No secure storage for future tokens | P2 | Sprint 2 |

## 8. Recommendations

1. **P0 — Remove plaintext password persistence**: change `AuthProvider.login` to store only email (or use `flutter_secure_storage`); never write `remember_me_password`.
2. **P0 — Verify `GEMINI_API_KEY`**: The `AQ.` prefix is NOT a standard Google AI Studio key (`AIzaSy...`). Confirm it is a dummy/placeholder and rotate/remove it.
3. **P1 — Add JWT/Firebase Auth middleware** in Sprint 2 before exposing real endpoints.
4. **P1 — Restrict CORS** to real origins in production.
5. **P1 — Add CI secret scan** (e.g., `gitleaks` or GitHub secret scanning) to prevent key leakage.
6. **P2 — Add rate limiting** (slowapi).
7. **P2 — Add prompt-injection guard** in ChatService/RAGService.
8. **P2 — Use `flutter_secure_storage`** for any future auth tokens.

## 9. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 2 | W1 (plaintext password), W5 (key verification) |
| P1 | 4 | W2, W3, W4, W12 |
| P2 | 5 | W6, W7, W8, W10, W11 |
| P3 | 1 | W9 (cert pinning) |