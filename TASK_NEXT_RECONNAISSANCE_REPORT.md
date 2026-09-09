# MECHA CONNECT — NEXT TASK RECONNAISSANCE REPORT

**Date:** September 9, 2026  
**Author:** Senior Software Architect / Technical Lead / QA Lead  
**Repository:** `Jagadeeshrelangi/mc_repo`  
**Branch:** `main`  
**Status:** RECONNAISSANCE ONLY — NO IMPLEMENTATION PERFORMED

---

## 1. Executive Summary

Mecha Connect is a mature Flutter + FastAPI monorepo delivering on-demand vehicle care, AI diagnostics, mechanic booking, fuel delivery, and auto-parts marketplace. The application has completed **Phase 1 (3 tasks)** of a Bengaluru pilot hardening cycle on top of a robust **Sprint 2 backend** (6 Alembic migrations, 34 SQLAlchemy models, 14 API routers, 704 backend tests, 242/247 Flutter tests passing).

**Critical findings:**
1. The `DATABASE_URL`, `JWT_SECRET_KEY`, and `GEMINI_API_KEY` are all configured in `backend/.env`. The older `WORKFLOW_NEXT_TASK_RECON.md` document stating "DATABASE_URL absent" is **STALE** — this blocker has been resolved.
2. The Fuel Delivery and Marketplace backend domains are **fully implemented** (models, repositories, services, API routes, schemas) per Task 8 Stage 1 report. They are NOT "NOT STARTED" as the old `WORKFLOW_NEXT_TASK_RECON.md` claims.
3. AI diagnosis persistence is **already implemented** (migration `0005_diagnoses`, `DiagnosisRepository`, `DiagnosisService.create_diagnosis`, `/diagnosis/history`, `/diagnosis/{id}` endpoints). The old TASK7 recommendation for "AI persistence" is **partially stale**.
4. Conversation ownership and chat persistence are **complete** (migration `0003`, `ChatService`, `ConversationRepository`, `ChatMessageRepository`).
5. One Flutter test is failing: `marketplace_module_test.dart` → "Home Quick Service Parts opens the Marketplace, not a snackbar" (242 pass, 1 fail).
6. The end-to-end service booking lifecycle (vehicle form → booking → live tracking → job completion → rating → booking history) has been verified on a live Android emulator with real Supabase database writes.

**Recommended next task: Push Notifications Infrastructure** — implementing Firebase Cloud Messaging (FCM) for booking status updates, mechanic assignment alerts, and order status notifications. This is the highest-value gap remaining after the service booking lifecycle is complete.

---

## 2. Repository / Git State

| Property | Value |
|:---|:---|
| **Branch** | `main` |
| **HEAD** | `0568d07` `feat: harden service booking ux and production flow` |
| **origin/main** | `0568d07` (in sync) |
| **Working tree** | Clean — `nothing to commit, working tree clean` |
| **Remote** | `https://github.com/Jagadeeshrelangi/mc_repo.git` |

### Recent Commits (20)
1. `0568d07` — feat: harden service booking ux and production flow
2. `b9ca3d9` — feat: implement service booking lifecycle and live tracking integration
3. `22736b5` — docs: update Phase 1 Task 1 final verification report
4. `28a3f45` — feat: seed production pilot catalog
5. `950d0fb` — fix: stabilize profile rewards auth and integration flows
6. `df9b937` — feat: implement mechanic rating and review system
7. `b489633` — Implement unified orders management
8. `983187b` — Integrate AI conversation session management
9. `ce7e8fb` — feat(ai): implement conversation session lifecycle
10. `499729b` — feat(backend): complete diagnosis history CRUD and marketplace coupons catalog
11. `349af94` — fix(repositories): enforce truthful empty catalogs
12. `b8094ee` — fix(auth): wire AuthProvider.logout
13. `e5ff9da` — Hardening pass: E2E integrity
14. `dd847f1` — feat: complete full persistence integration
15. `d23612d` — feat: implement Supabase persistence layer
16. `901fa80` — feat(backend): complete mechanics module
17. `8e2dbd1` — feat(backend): add users profile APIs
18. `22f19e1` — feat(backend): add authentication and conversation ownership
19. `b6eaa60` — feat(backend): sprint 2 database foundation
20. `c801688` — feat(repo): freeze monorepo architecture

---

## 3. Current Architecture

```
Flutter Client (Provider state management, ApiClient HTTP layer)
    │
    ▼ HTTP / JSON / Bearer JWT
FastAPI Application (Async, Uvicorn, Python 3.13)
    ├── 14 API Routers under /api/v1
    ├── 14 Services (business logic & transaction boundaries)
    ├── 13 Repositories (async SQLAlchemy data access)
    └── 34 SQLAlchemy ORM Models
    │
    ▼ AsyncPG Connection Pool (configured & live)
Supabase PostgreSQL 15 (41+ tables, Alembic head 0006)
    │
    ├── AI: XGBoost fault classifier + FAISS RAG + Gemini gemini-2.5-flash
    └── Seed Data: 8 mechanics, 6 fuel stations, 18 products (Bengaluru pilot)
```

### Backend Structure (`backend/app/`)
| Layer | Files | Description |
|:---|:---|:---|
| `main.py` | 1 | FastAPI app factory, CORS, exception handlers, health check |
| `core/` | 7 | config, database, security (JWT/bcrypt), exceptions, logging, rate limiting |
| `api/v1/` | 14 routers | auth, users, vehicles, addresses, wallet, mechanic, fuel, marketplace, orders, conversation, diagnosis, knowledge, notification_settings |
| `models/` | 34 | All SQLAlchemy ORM models (user, mechanic, fuel, marketplace, diagnosis, etc.) |
| `schemas/` | 14 | Pydantic v2 request/response schemas per domain |
| `repositories/` | 13 | Async data access per domain |
| `services/` | 14 | Business logic orchestration |

### Frontend Structure (`frontend/lib/`)
| Layer | Modules |
|:---|:---|
| Features | ai, auth, fuel_delivery, home, marketplace, mechanic, orders, profile |
| Services | api_client, location_service, location_provider, geocoding_service |
| Shared | theme, widgets, bottom_bar, starting_screen, homescreen |

### API Router Mounts
| Prefix | Module | Public Routes | Protected Routes |
|:---|:---|:---|:---|
| `/auth` | Authentication | register, login, refresh, verify, forgot/reset | me, logout |
| `/users` | Users & Profile | — | GET/PATCH /me |
| `/vehicles` | Vehicles | — | CRUD |
| `/addresses` | Addresses | — | CRUD |
| `/wallet` | Wallet & Rewards | — | balance, transactions, rewards |
| `/mechanic` | Mechanics | list, featured, detail, services, reviews, categories | bookings CRUD, status, events, rating |
| `/fuel` | Fuel Delivery | stations, price-estimate | orders CRUD, tracking, invoice |
| `/marketplace` | Marketplace | categories, brands, products, offers, coupons | orders, reviews |
| `/orders` | Orders | — | list, detail |
| `/conversation` | AI Chat | — | chat, session, history, list, detail |
| `/diagnosis` | AI Diagnosis | — | diagnose, history, detail, delete |
| `/knowledge` | RAG Search | — | query |
| `/notification-settings` | Notifications | — | GET/PATCH |
| `/health` | System | health check | — |

---

## 4. Current Database State

### Alembic Migrations (6, all applied)
| Revision | Name | Tables/Changes |
|:---|:---|:---|
| `0001` | baseline | Initial schema baseline |
| `0002` | authentication_foundation | `users`, `refresh_tokens` |
| `0003` | conversation_ownership | `conversations`, `chat_messages` |
| `0004` | mechanics | 11 mechanics tables (mechanics, bookings, events, ratings, services, categories, etc.) |
| `0005` | diagnoses | `diagnoses` table with user FK |
| `0006` | persistence_foundation_indexes | 17 indexes across fuel, marketplace, orders, vehicles, addresses, wallet tables |

### Environment Configuration
| Key | Status |
|:---|:---|
| `DATABASE_URL` | ✅ **Configured** (Supabase PostgreSQL, asyncpg) |
| `JWT_SECRET_KEY` | ✅ **Configured** |
| `GEMINI_API_KEY` | ✅ **Configured** (real key) |
| `GEMINI_MODEL` | `gemini-2.5-flash` |
| `ENABLE_FALLBACK` | `True` |
| `CORS_ORIGINS` | localhost:3000, 8080 |

> **IMPORTANT:** The `WORKFLOW_NEXT_TASK_RECON.md` document (HEAD `901fa80`) states `DATABASE_URL` is absent. This is **STALE**. All three critical environment variables are now configured.

---

## 5. Backend State

### Models (34 SQLAlchemy ORM models)
- **Auth:** `User`, `RefreshToken`
- **Conversation:** `Conversation`, `ChatMessage`
- **Diagnosis:** `Diagnosis`
- **Mechanic:** `Mechanic`, `MechanicSkill`, `MechanicLanguage`, `MechanicWorkingHour`, `MechanicCategory`, `MechanicService`, `MechanicReview`, `MechanicBooking`, `BookingEvent`, `Rating`, `MechanicStatus`
- **Fuel:** `FuelOrder`, `PriceEstimate`, `FuelStation`, `FuelPartner`, `TrackingEvent`, `Invoice`
- **Marketplace:** `Category`, `Brand`, `Product`, `ProductSpecification`, `ProductVehicleType`, `ProductCompatibility`, `ProductReview`, `Offer`, `Coupon`, `Order`, `OrderItem`, `OrderEntry`
- **Profile:** `Address`, `Vehicle`, `Wallet`, `NotificationSetting`

### Services (14)
| Service | Status | DB Persistence |
|:---|:---|:---|
| `AuthService` | ✅ Complete | ✅ Users + refresh tokens |
| `ChatService` | ✅ Complete | ✅ Conversations + messages (12-turn cap) |
| `DiagnosisService` | ✅ Complete | ✅ Diagnoses table (CRUD + history) |
| `RAGService` | ✅ Complete | ❌ No query result persistence |
| `MechanicService` | ✅ Complete | ✅ Bookings + events + ratings |
| `FuelService` | ✅ Complete | ✅ Orders + tracking + invoices |
| `MarketplaceService` | ✅ Complete | ✅ Products + orders + reviews |
| `OrderService` | ✅ Complete | ✅ Unified orders |
| `UserService` | ✅ Complete | ✅ Profile (whitelisted fields) |
| `VehicleService` | ✅ Complete | ✅ CRUD |
| `AddressService` | ✅ Complete | ✅ CRUD |
| `WalletService` | ✅ Complete | ✅ Transactions + rewards |
| `NotificationService` | ✅ Complete | ✅ Settings only (get/update toggle) |
| `notification_service` | ⚠️ Stub | ❌ No push notification delivery |

### Repositories (13)
All repositories follow async SQLAlchemy pattern with session injection, flush-only writes, single commit at service level. Owner-scoped queries with generic 404 for missing/foreign entities (no existence leak).

### Test Suite
```
704 passed, 151 warnings in 55.90s
```
31 test files covering all major domains. Warnings are deprecation notices (HTTP_422_UNPROCESSABLE_ENTITY → CONTENT). No failures.

---

## 6. Flutter State

### Feature Modules (8)
| Module | Screens | Provider | Repository | Status |
|:---|:---|:---|:---|:---|
| **AI** | 5 screens (home, chat, diagnosis, conversation history/detail) | `AiProvider` | `AiRepository` | ✅ Complete (backend-connected + local fallback) |
| **Auth** | Login, Register, OTP, Forgot Password | `AuthProvider` | `AuthRepository` | ✅ Complete |
| **Mechanic** | 11 screens (home, details, service select, vehicle form, booking summary/confirmation, live tracking, job completed, rating, booking history) | `MechanicProvider` | `MechanicRepository` | ✅ Complete & hardened |
| **Fuel Delivery** | Screens present | `FuelProvider` | `FuelRepository` | ✅ UI complete, backend-connected |
| **Marketplace** | Screens present | `MarketplaceProvider` | `MarketplaceRepository` | ✅ UI complete, backend-connected |
| **Orders** | Orders list | `OrdersProvider` | `OrdersRepository` | ✅ Complete |
| **Profile** | Profile, settings, notifications | `ProfileProvider` | `ProfileRepository` | ✅ Complete |
| **Home** | Dashboard | `HomeProvider` | `HomeRepository` | ✅ Complete |

### Test Suite
```
242 passed, 1 failed
```
13 test files + 2 integration tests. **1 failure:** `marketplace_module_test.dart` → "Home Quick Service Parts opens the Marketplace, not a snackbar".

### Static Analysis
```
flutter analyze: No issues found! (0 issues)
```

---

## 7. AI / RAG State

| Component | Status | Persistence |
|:---|:---|:---|
| XGBoost fault classifier | ✅ Loaded from `ai/models/fault_classifier.joblib` | ✅ Results persist to `diagnoses` table |
| FAISS vector store | ✅ Loaded from `ai/knowledge_base/faiss_index/` | ❌ Query results not persisted |
| Gemini LLM (gemini-2.5-flash) | ✅ Configured with real API key | Chat turns persist to `chat_messages` |
| HuggingFace embeddings | ✅ `sentence-transformers/all-MiniLM-L6-v2` | N/A |
| Conversation ownership | ✅ Owner-scoped, generic 404, 12-turn cap | ✅ `conversations` + `chat_messages` tables |
| Diagnosis history | ✅ CRUD endpoints (create, list, detail, delete) | ✅ `diagnoses` table (migration 0005) |

---

## 8. Completed Features

### Phase 0 (Sprint 2 Backend Foundation) ✅
- [x] Dev env setup (SQLAlchemy, asyncpg, Alembic, pytest)
- [x] Core + database engine + session DI
- [x] Authentication (JWT access/refresh, bcrypt, rate limiting, RBAC)
- [x] Base repositories + per-domain repositories
- [x] Users & Profile APIs (whitelisted fields, IDOR prevention)
- [x] Mechanics module (15 API routes, 11 models, state machine)
- [x] Fuel Delivery module (models, repos, services, routes)
- [x] Marketplace & Orders module (models, repos, services, routes)
- [x] AI persistence (diagnosis history, conversation ownership)
- [x] Vehicles, Addresses, Wallet, Notification Settings

### Phase 1 Task 1: Production Pilot Catalog Seeding ✅
- [x] Idempotent seed script (`seed_pilot_catalog.py`)
- [x] 8 mechanics, 8 categories, 8 services (Bengaluru locations)
- [x] 4 fuel partners, 6 fuel stations
- [x] 8 marketplace categories, 12 brands, 18 products, 3 coupons, 3 offers
- [x] Cross-layer contract fixes (Pydantic validators, Flutter brand deserialization)
- [x] Verified on live Supabase database

### Phase 1 Task 2: Service Booking Lifecycle & Live Tracking ✅
- [x] Server-side state machine (requested → accepted → mechanicAssigned → enRoute → arrived → completed / cancelled)
- [x] `PATCH /bookings/{id}/status` endpoint for lifecycle transitions
- [x] Truthful live tracking (replaced mock timers with backend polling)
- [x] Booking event audit trail persistence
- [x] Post-service rating and review (persisted to database)
- [x] Cross-layer order synchronization
- [x] Verified on Android emulator with live database writes

### Phase 1 Task 3: Service Booking UX/UI & Production Flow Hardening ✅
- [x] Zero mock fallback policy (removed silent mock booking creation)
- [x] Pilot simulator isolation (collapsible testing controls)
- [x] Itemized invoice (labor, consumables, platform fee, GST)
- [x] Booking history modal bottom sheet (view invoice, rate service)
- [x] Scheduled booking support (date/time picker)
- [x] Double-submission prevention
- [x] RenderFlex overflow fixes
- [x] Session expiry handling ("Log In Again" button)
- [x] Verified with 704 backend + 247 Flutter tests + emulator verification

---

## 9. Incomplete Features / Known Gaps

| Gap | Layer | Priority | Notes |
|:---|:---|:---|:---|
| **Push Notifications (FCM)** | Backend + Flutter | HIGH | `NotificationService` is a settings-only stub; no actual push delivery mechanism exists |
| **Payment Integration** | Backend + Flutter | HIGH | No payment gateway; invoices display static amounts |
| **Real-time WebSocket Updates** | Backend + Flutter | MEDIUM | Live tracking uses HTTP polling, not WebSocket |
| **Mechanic-Side App / Portal** | Backend + Flutter | MEDIUM | No mechanic login/dashboard; status advances via pilot controls or API |
| **RAG Query Persistence** | Backend | LOW | Knowledge query results not stored; chat messages are |
| **Global Rate Limiting** | Backend | LOW | Rate limit only on auth endpoints; not global |
| **Security Headers Middleware** | Backend | LOW | CORS configured; no X-Frame-Options, CSP, etc. |
| **Docker / CI / CD** | Ops | MEDIUM | No Dockerfile, no docker-compose, no CI pipeline |
| **1 Failing Flutter Test** | Frontend | LOW | `marketplace_module_test.dart` navigation test |

---

## 10. Documentation Conflicts / Stale Documents

### STALE: `WORKFLOW_NEXT_TASK_RECON.md` (Git HEAD `901fa80`, now at `0568d07`)
- **Claims** `DATABASE_URL` is absent → **FALSE**: `DATABASE_URL` is configured and pointing to live Supabase
- **Claims** "Fuel Module: NOT STARTED" → **FALSE**: Fuel models, repos, services, routes are all implemented and tested
- **Claims** "Marketplace & Orders: NOT STARTED" → **FALSE**: Fully implemented
- **Claims** "AI persistence: PARTIAL" → **PARTIALLY STALE**: Diagnosis persistence is complete (migration 0005, CRUD endpoints); conversation persistence is complete; only RAG query persistence is genuinely missing
- **Recommends** "Task 7 — AI Services Full Persistence" → **STALE**: Most of this work is already done
- **Git state section** references HEAD `901fa80` → **STALE**: HEAD is now `0568d07` (7 commits ahead)

### STALE: `TASK7_STAGE1_COMPLETE.md`
- Written at an earlier project state
- Claims "28 total paths" → **FALSE**: Many more routes exist now
- Claims "111 tests" → **FALSE**: 704 backend tests now
- Recommendations about "Stage 2" AI persistence → Diagnosis persistence is already done

### Current / Accurate Documents:
- `TASK_PHASE1_TASK1_RECONNAISSANCE_REPORT.md` — ✅ Accurate for Task 1 scope
- `TASK_PHASE1_TASK1_FINAL_VERIFICATION_REPORT.md` — ✅ Accurate
- `TASK_PHASE1_TASK2_RECONNAISSANCE_REPORT.md` — ✅ Accurate for Task 2 scope
- `TASK_PHASE1_TASK2_FINAL_VERIFICATION_REPORT.md` — ✅ Accurate
- `TASK_PHASE1_TASK3_RECONNAISSANCE_REPORT.md` — ✅ Accurate for Task 3 scope
- `TASK_PHASE1_TASK3_FINAL_VERIFICATION_REPORT.md` — ✅ Accurate
- `docs/backend/architecture/TASK8_STAGE1_MODELS_SCHEMAS_REPORT.md` — ✅ Accurate
- `docs/backend/architecture/SPRINT_2_ROADMAP.md` — ⚠️ Historical plan; implementation order was different

---

## 11. Current Test & Verification State

### Backend (`pytest`)
```
704 passed, 151 warnings in 55.90s (Python 3.13.5, pytest 9.1.1)
```
- 31 test files covering all major domains
- Warnings are deprecation notices (HTTP_422_UNPROCESSABLE_ENTITY → CONTENT)
- No failures

### Flutter (`flutter test`)
```
242 passed, 1 failed
```
- 13 test files + 2 integration tests
- **1 failure:** `marketplace_module_test.dart` → `Home Quick Service Parts opens the Marketplace, not a snackbar`

### Flutter Static Analysis
```
flutter analyze: No issues found! (0 issues)
```

### Manual Verification
- Phase 1 Tasks 1-3 verified on Android emulator (`emulator-5554`, 1080x1920, Android 14)
- Live Supabase database writes confirmed
- Screenshots captured for complete booking lifecycle (11 verification images in repo root)

---

## 12. Security Observations

| Aspect | Status | Notes |
|:---|:---|:---|
| JWT Authentication | ✅ | 15m access + 7d refresh, bcrypt cost 12, SHA-256 refresh digest |
| RBAC | ✅ | customer/mechanic/admin roles |
| Owner-scoped queries | ✅ | Generic 404 for missing/foreign (no existence leak) |
| IDOR prevention | ✅ | No `/users/{user_id}` endpoint; identity always from token |
| Rate limiting | ⚠️ | Auth-only (10 req/min per IP); not global |
| Security headers | ⚠️ | CORS configured; no CSP, X-Frame-Options, HSTS |
| Input validation | ✅ | Pydantic `extra="forbid"`, whitelisted profile fields |
| Password hashing | ✅ | bcrypt with cost factor 12 |
| Token rotation | ✅ | Refresh token rotation on use |
| Session expiry UI | ✅ | "Log In Again" button on 401 |
| Secrets in repo | ✅ | `.env` in `.gitignore`; no secrets committed |

---

## 13. Production Readiness Observations

| Area | Ready? | Gap |
|:---|:---|:---|
| Authentication | ✅ | — |
| Database | ✅ | Live Supabase with migrations applied |
| Mechanic booking lifecycle | ✅ | Verified E2E on emulator |
| Catalog data | ✅ | 8 mechanics, 6 fuel stations, 18 products seeded |
| AI Diagnosis | ✅ | XGBoost + Gemini + persistence |
| Push Notifications | ❌ | No delivery mechanism |
| Payment Gateway | ❌ | No payment processing |
| CI/CD Pipeline | ❌ | No automated deployment |
| Docker | ❌ | No containerization |
| Real-time Updates | ❌ | HTTP polling only |
| Mechanic Portal | ❌ | No mechanic-side interface |

---

## 14. Recommended Next Task

### Push Notifications Infrastructure (FCM Integration)

---

## 15. WHAT / WHY / CURRENT STATE / GAP

### A. Task Name
**Push Notifications Infrastructure — Firebase Cloud Messaging Integration**

### B. WHAT
Implement end-to-end push notification delivery using Firebase Cloud Messaging (FCM):
1. Backend: FCM token registration endpoint, notification dispatch service, booking/order status change triggers
2. Frontend: FCM SDK integration, token registration on login, notification permission handling, foreground/background notification display, deep-link navigation from notification taps
3. Database: FCM device token storage (per-user, multi-device support)

### C. WHY
After the complete service booking lifecycle is verified (Phase 1 Tasks 1-3), the single highest-impact missing feature is **proactive user notification**. Currently:
- When a mechanic accepts a booking, the customer must manually refresh or poll to discover the status change
- When a booking transitions (enRoute, arrived, completed), the customer has no awareness unless they're actively watching the tracking screen
- Fuel delivery and marketplace order status updates are similarly silent
- The `NotificationService` exists but only manages a boolean push toggle — it delivers nothing

Push notifications are the bridge between a functional backend and a production-grade user experience. Without them, the Bengaluru pilot requires users to constantly check the app manually.

### D. CURRENT STATE
- `backend/app/services/notification_service.py`: 46-line stub managing only `push` toggle persistence
- `backend/app/models/notification_setting.py`: Model with `user_id` FK and `push` boolean
- `backend/app/api/v1/notification_settings.py`: GET/PATCH for toggle
- `frontend/.env`: `FIREBASE_PROJECT_ID=YOUR_FIREBASE_PROJECT_IDx` (placeholder)
- `backend/app/core/config.py`: `FIREBASE_CREDENTIALS_PATH: Optional[str] = None`
- No FCM SDK in Flutter `pubspec.yaml`
- No device token table in database
- No notification dispatch logic anywhere in the codebase

### E. GAP
| Component | Gap |
|:---|:---|
| **Database** | No `device_tokens` table for FCM token storage |
| **Backend Model** | No `DeviceToken` SQLAlchemy model |
| **Backend Service** | `NotificationService` lacks FCM dispatch, token management, notification creation |
| **Backend Routes** | No token registration endpoint, no notification history endpoint |
| **Backend Triggers** | `MechanicService`, `FuelService`, `MarketplaceService` don't emit notifications on status changes |
| **Flutter SDK** | No `firebase_messaging` or `firebase_core` dependency |
| **Flutter Integration** | No FCM token registration, no permission handling, no notification display |
| **Flutter Navigation** | No deep-link from notification tap to relevant screen |
| **Migration** | No Alembic migration for device tokens table |

---

## 16. Required Layers & Files

### Database
- **[NEW]** Migration `0007_device_tokens.py` — `device_tokens` table (id, user_id FK, fcm_token, device_type, created_at, updated_at)
- **[NEW]** Migration `0007` may also add `notifications` table for notification history

### Backend Models
- **[NEW]** `backend/app/models/device_token.py` — DeviceToken SQLAlchemy model
- **[MODIFY]** `backend/app/models/__init__.py` — register new model

### Backend Repositories
- **[NEW]** `backend/app/repositories/device_token.py` — CRUD for device tokens
- **[MODIFY]** `backend/app/repositories/__init__.py` — register new repository

### Backend Services
- **[MODIFY]** `backend/app/services/notification_service.py` — Add FCM dispatch, token management, notification creation
- **[MODIFY]** `backend/app/services/mechanic_service.py` — Emit notifications on booking status changes
- **[MODIFY]** `backend/app/services/fuel_service.py` — Emit notifications on fuel order status changes (if applicable)

### API Schemas
- **[MODIFY]** `backend/app/schemas/notification_setting.py` — Add device token and notification schemas

### API Routes
- **[MODIFY]** `backend/app/api/v1/notification_settings.py` — Add token registration, notification history endpoints

### Backend Configuration
- **[MODIFY]** `backend/app/core/config.py` — Add Firebase admin SDK configuration
- **[MODIFY]** `backend/requirements.txt` — Add `firebase-admin` dependency

### Flutter
- **[MODIFY]** `frontend/pubspec.yaml` — Add `firebase_messaging`, `firebase_core` dependencies
- **[MODIFY]** `frontend/android/app/build.gradle` — Firebase configuration
- **[NEW]** `frontend/lib/services/notification_service.dart` — FCM token management, permission handling
- **[MODIFY]** `frontend/lib/main.dart` — Firebase initialization, notification setup
- **[MODIFY]** `frontend/lib/services/api_client.dart` — Token registration on auth
- **[MODIFY]** `frontend/lib/features/auth/providers/auth_provider.dart` — Register FCM token on login

### Tests
- **[NEW]** `backend/tests/test_device_tokens.py` — Device token CRUD tests
- **[NEW]** `backend/tests/test_notification_dispatch.py` — Notification dispatch tests
- **[NEW]** `frontend/test/notification_test.dart` — Flutter notification integration tests

### Documentation
- **[NEW]** Architecture decision document for notifications

---

## 17. What Must Not Be Changed

- Booking lifecycle state machine (Phase 1 verified)
- Mechanic discovery and catalog (seeded and verified)
- Authentication / JWT infrastructure (fully tested)
- Conversation ownership and chat persistence
- Diagnosis persistence and history endpoints
- Alembic migrations 0001-0006 (applied to production database)
- Existing test suites (must remain passing)
- API contracts for existing endpoints (no breaking changes)
- Vehicle form and booking summary UX (hardened in Phase 1 Task 3)

---

## 18. Dependencies

| Dependency | Status | Required For |
|:---|:---|:---|
| Firebase project setup | ❌ Needs configuration | FCM token delivery |
| Firebase Admin SDK (Python) | ❌ Not installed | Backend FCM dispatch |
| `firebase_messaging` Flutter package | ❌ Not installed | Frontend FCM registration |
| `firebase_core` Flutter package | ❌ Not installed | Firebase initialization |
| `google-services.json` for Android | ❌ Not present | Android FCM |
| `GoogleService-Info.plist` for iOS | ❌ Not present | iOS APNS (if needed) |
| Service account JSON for backend | ❌ Not present | Backend Firebase Admin SDK |
| DATABASE_URL | ✅ Configured | New migration |
| JWT_SECRET_KEY | ✅ Configured | Auth for token registration |

---

## 19. Risks

| Risk | Probability | Impact | Mitigation |
|:---|:---|:---|:---|
| Firebase project not set up | HIGH | HIGH | Requires user to create Firebase project and provide credentials |
| FCM token expiry / rotation | MEDIUM | MEDIUM | Implement token refresh on app startup; handle `onTokenRefresh` |
| Notification spam / rate limiting | LOW | MEDIUM | Rate limit notifications per user per booking |
| Background notification handling on Android 13+ | MEDIUM | MEDIUM | Request POST_NOTIFICATIONS permission at runtime |
| iOS APNS configuration complexity | MEDIUM | LOW | iOS is secondary for Bengaluru pilot; Android first |
| Breaking existing tests | LOW | HIGH | Run full suite before and after |
| Database migration on production | LOW | HIGH | Additive-only migration (new table); no existing table modifications |

---

## 20. Verification Strategy

### Automated Tests
- `pytest tests/ -q` — full backend suite (must maintain 704+ passing)
- New `test_device_tokens.py` — device token CRUD
- New `test_notification_dispatch.py` — FCM dispatch mocking
- `flutter test` — full Flutter suite (must maintain 242+ passing, fix existing 1 failure)
- `flutter analyze` — must remain 0 issues

### Migration Validation
- `alembic upgrade head --sql` — verify additive-only DDL
- Verify no existing table modifications
- Confirm `device_tokens` table creation with correct FKs and indexes

### API Validation
- POST `/api/v1/notification-settings/device-token` — register token
- DELETE `/api/v1/notification-settings/device-token` — unregister on logout
- GET `/api/v1/notification-settings/notifications` — notification history (if implemented)
- Verify OpenAPI schema includes new endpoints

### Manual Runtime Verification
- Register FCM token on login (Android emulator)
- Trigger booking status change → verify push notification received
- Tap notification → verify deep-link navigation to correct screen
- Test foreground vs background notification handling
- Test permission denial graceful degradation
- Verify notification toggle (push=false) suppresses delivery

### Regression Testing
- Full booking lifecycle remains functional
- Existing API contracts unchanged
- No performance degradation on booking status changes

### Security Verification
- FCM tokens are user-scoped (authenticated endpoints only)
- No cross-user token leakage
- Token cleanup on logout/account deletion
- Firebase Admin SDK credentials not exposed

---

## 21. Final Recommendation

### Primary Recommendation: Push Notifications Infrastructure

**Push notifications are the highest-value, lowest-risk next engineering task** because:

1. **Product Impact**: The booking lifecycle is complete but silent. Users have no way to know when their mechanic is en route or has arrived without manually checking. This is the #1 UX gap for the Bengaluru pilot.

2. **Architecture Fit**: The notification infrastructure slot already exists (`NotificationService`, `notification_settings` endpoints, `notification_setting` model) — it's a stub waiting to be filled.

3. **Cross-Domain Value**: Once built, push notifications benefit all three domains (mechanics, fuel delivery, marketplace) — not just one feature.

4. **Low Regression Risk**: The implementation is additive (new table, new service logic, new Flutter package). Existing booking/fuel/marketplace flows are not modified.

5. **Dependency Reality**: Requires Firebase project setup, which is a blocking prerequisite the user must provide.

### Alternative Recommendation (if Firebase is not available):
**Fix the 1 Failing Flutter Test + Global Rate Limiting + Security Headers Middleware** — a lower-impact but zero-dependency hardening task that improves production readiness without external service requirements.

---

**END OF RECONNAISSANCE REPORT**

**Confirmation:**
- ✅ Reconnaissance completed
- ✅ NO implementation performed
- ✅ NO code modified
- ✅ NO database changed
- ✅ NO migrations created
- ✅ NO commits made
- ✅ NO pushes made
