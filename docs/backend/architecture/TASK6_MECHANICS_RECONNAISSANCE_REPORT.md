# Task 6 — Mechanics Module Reconnaissance Report

**Scope:** READ-ONLY reconnaissance of the CURRENT repository (commit `8e2dbd1`
on `main`) to scope the "Mechanics" module (Sprint 2 Roadmap module 5).
**Date:** 2026-08-15
**Method:** Documents used as context only; every claim below was re-checked
against the actual working tree, code, schema, OpenAPI, migrations, and tests.
**Result:** Task 6 is **READY FOR IMPLEMENTATION** (defined scope below). This
report performs NO implementation, NO DB writes, NO commits/pushes.

---

## 1. Executive Summary

The Mechanics module is **entirely unimplemented on the backend** but has a
**frozen, fully-specified frontend contract** and an **authoritative
`schema.sql`**. The Flutter mechanic feature (list/detail, services,
categories, reviews, booking summary → confirmation → live tracking →
rating, booking history) is complete against in-memory mocks. Backend work is
purely additive: 11 ORM models + 1 migration (`0004_mechanics`) + repositories
+ schemas + one service + one router, mounted under `/api/v1/mechanic`.
All routes require an authenticated user (`get_current_user`); role-based
access is only needed where a mechanic/admin acts (none of the frozen
customer flows require it). One dependency gap exists: `mechanic_bookings`
FKs to `vehicles`, and the `vehicles` table is NOT yet migrated (module 4
remainder) — see §11, §15, §17 for the resolution.

## 2. Current Repository State

- Branch `main` at `8e2dbd1` (`feat(backend): add users profile APIs`), in
  sync with `origin/main` (HEAD == origin/main, verified `git branch -vv`).
- Working tree: **clean tracked tree**; only 3 untracked documentation files
  (untouched, per convention):
  - `docs/backend/architecture/NEXT_SPRINT2_TASK_RECONNAISSANCE_REPORT.md`
  - `docs/backend/architecture/TASK3_TASK4_COMMIT_REPORT.md`
  - `docs/backend/architecture/TASK5_COMMIT_PUSH_REPORT.md`
- Python 3.13.5 (system and `backend/venv`). Full test suite: **299 passed**
  (re-run this session, 20.05s).

## 3. Previous Task Dependency Map

| Task | Status | Notes |
|---|---|---|
| Task 1 — Backend foundation / package cleanup | ✅ committed | — |
| Task 2 — DB foundation | ✅ committed `b6eaa60` | `core/database.py`, alembic scaffold, migration `0001_baseline` |
| Task 3 — Authentication foundation | ✅ committed `22f19e1` | `security.py`, `deps.py` (`get_current_user`, `role_required`), `auth.py`, migration `0002` |
| Task 4 — Conversation ownership/persistence | ✅ committed `22f19e1` | `conversation.py`/`chat_message.py` models, migration `0003`, repos, ChatService refactor |
| Task 5 — Users & Profile APIs | ✅ committed `8e2dbd1` | `users/me` GET/PATCH, `UserService`, `user.py` schemas, 26 tests; 299 total |

Task 6 (Mechanics) depends on Tasks 2 and 3 only, exactly as Roadmap module 5
declares (deps `2,3`). Task 5's `User`/`users` table is the FK anchor for
`mechanic_bookings.user_id`.

## 4. Authoritative Sources Inspected (opened this session)

- `docs/backend/database/schema.sql` (full, 430 lines) — mechanic DDL.
- `docs/backend/API.md` §1 conventions + §6 Mechanic API (entities, mock data,
  method surface).
- `docs/backend/api/endpoint_catalog.md` §3.5 Mechanic + §4 scaffold mapping.
- `docs/backend/database/data_model.md` §2.4 Mechanic + §3 mapping notes.
- `docs/backend/architecture/SPRINT_2_ROADMAP.md` module 5 (Mechanics).
- `frontend/lib/features/mechanic/**` — models, mock data, repository,
  provider, all 11 screens, widgets.
- `backend/app/**` — models, repositories, services, schemas, `api/v1`,
  `api/deps.py`, `api/router.py`, `core`.
- `backend/alembic/versions/0001..0003` — migration chain and FK conventions.
- `backend/tests/` — 14 test files incl. `conftest.py`, `test_users_api.py`.

## 5. Existing Mechanic-Related Database Schema (authoritative `schema.sql`)

All mechanic DDL exists in `schema.sql` but **none of it is modeled or
migrated** in the backend.

| Table | Key columns (schema.sql lines) |
|---|---|
| `mechanics` (L225) | `id` TEXT PK (`m*`), `name`, `rating` NUMERIC(3,2), `review_count`, `experience_years`, `distance_km` NUMERIC(6,2), `eta_minutes`, `is_available` bool default true, `price_starting` NUMERIC(12,2), `phone`, `about`, `is_verified` bool default false |
| `mechanic_skills` (L240) | `mechanic_id` TEXT FK, `skill` TEXT; PK(mechanic_id, skill) |
| `mechanic_languages` (L241) | `mechanic_id` TEXT FK, `language` TEXT; PK(mechanic_id, language) |
| `mechanic_working_hours` (L242) | `mechanic_id` TEXT FK, `day` TEXT, `open`, `close`; PK(mechanic_id, day) |
| `mechanic_services` (L244) | `id` TEXT PK (`svc_*`), `name`, `icon` TEXT, `price` NUMERIC(12,2), `estimated_minutes`, `description` |
| `mechanic_service_offered` (L253) | `mechanic_id` TEXT FK, `service_id` TEXT FK; PK both |
| `mechanic_categories` (L259) | `id` TEXT PK, `name`, `icon` TEXT, `color` TEXT, `bg_color` TEXT, `description`, `sort_order` |
| `mechanic_reviews` (L269) | `id` TEXT PK (`r*`), `mechanic_id` TEXT FK, `reviewer_name`, `rating` NUMERIC(3,2), `comment`, `reviewed_at` DATE, `vehicle` |
| `mechanic_bookings` (L279) | `id` UUID PK, `user_id` UUID FK users, `mechanic_id` TEXT FK mechanics, `service_id` TEXT FK mechanic_services, `vehicle_id` UUID FK vehicles, `status` TEXT **NOT NULL (NO CHECK)**, `address`, `lat` NUMERIC(9,6), `lng` NUMERIC(9,6), `scheduled_at`, `created_at` |
| `booking_events` (L293) | `id` UUID PK, `booking_id` UUID FK mechanic_bookings, `status` TEXT (no CHECK), `occurred_at`, `payload` JSONB |
| `ratings` (L301) | `booking_id` UUID PK (1-1 FK mechanic_bookings), `rating` NUMERIC(3,2), `review` TEXT |

Related but OUT of the mechanic table set: `vehicles` (L26, FK target for
`mechanic_bookings.vehicle_id`, **not migrated**), `order_entries` (L210,
`type` CHECK includes `'mechanic'` — the unified Orders tab).

## 6. Existing Backend Implementation (Mechanics)

**NONE.** A repo-wide grep for
`mechanic|booking|MechanicService|review|rating|category` in `backend/app/**`
returns only incidental matches:
- `schemas/diagnosis.py` "fault category", `schemas/knowledge.py` "folder
  category" — unrelated.
- `services/chat_service.py` keyword branch for "mechanic" (AI responses
  only), `services/rag_service.py` doc metadata "category" — unrelated.
- `models/user.py` — `UserRole.MECHANIC = "mechanic"` (enum only).

No mechanic/booking/review/service/category model, repository, service,
schema, or route exists. `models/__init__.py` registers only `User`,
`RefreshToken`, `Conversation`, `ChatMessage`. `api/router.py` mounts only
`auth`, `diagnosis`, `knowledge`, `conversation`, `users`.

## 7. Existing Flutter Implementation (frozen contract — DO NOT MODIFY)

Full feature at `frontend/lib/features/mechanic/`:

- **Models** (`models/mechanic_models.dart`):
  - `BookingStatus` enum: `requested, accepted, mechanicAssigned, enRoute,
    arrived, completed, cancelled` (labels: Requested / Accepted / Mechanic
    Assigned / Mechanic En Route / Arrived / Completed / Cancelled).
  - `MechanicInfo { id (m*), name, photoUrl, rating, reviewCount,
    experienceYears, distanceKm, etaMinutes, isAvailable, priceStarting,
    phone, skills[], languages[], about, services[], workingHours{},
    isVerified }`.
  - `MechanicService { id (svc_*), name, icon, price, estimatedMinutes,
    description }`.
  - `MechanicCategory { name, icon, color, bgColor, description }` —
    **no `id` field**.
  - `MechanicReview { id (r*), reviewerName, rating, comment, date, vehicle }`
    — `date` is a **String** ("2 days ago", "1 week ago").
  - `BookingRequest { vehicleType, brand, model, fuelType, registration,
    problemDescription, address, isEmergency }` (`vehicleSummary` = brand+model).
  - `Booking { bookingId (MEC*), mechanic, service, vehicle, address,
    estimatedArrival, estimatedCost, status, bookingTime }`.
- **Mock data** (`mock_mechanic_data.dart`): 4 mechanics `m1..m4` (m4
  unavailable), 3 featured (`m1,m4,m2`), 8 categories, 8 services `svc_1..svc_8`
  (`generalServices`), reviews `r1..r8` keyed by mechanic.
- **Repository** (`repositories/mechanic_repository.dart`) — the contract the
  real backend must serve:
  `fetchMechanics()`, `fetchFeaturedMechanics()`, `fetchMechanicById(id)`,
  `fetchReviews(mechanicId)`, `fetchCategories()`, `createBooking(...)`
  (→ status `requested`, id `MEC<8 digits>`, estimatedArrival = now +
  etaMinutes), `getBookingById(id)`, `cancelBooking(id)` (→ `cancelled`),
  `completeBooking(id)` (→ `completed`), `getBookingHistory()`.
  Seeds history `MEC123456`, `MEC234567`, `MEC345678` (completed/cancelled).
  **There is NO rating/review submission method and NO search method.**
- **Provider** (`mechanic_provider.dart`): `loadHome`, `refresh`,
  `loadMechanics`, `selectMechanic`, `selectService`, `setBookingRequest`,
  `loadReviews`, `createBooking`, `loadActiveBooking`, `cancelActiveBooking`,
  `completeActiveBooking`, `loadBookingHistory`, `reset`. Cost passed to
  `createBooking` is `service.price + (isAvailable ? 0 : 100)`.
- **Screens** (`screens/`): `mechanic_home` (categories grid, emergency
  banner, featured, nearby, search bar that shows "Mechanic search coming in
  Sprint 2!"), `nearby_mechanics` (client-side filters Available Now / Rating
  4+ / Under ₹500; sort Nearest / Highest Rated / Lowest Price),
  `mechanic_details` (info + services + reviews), `select_service`
  (+ "Custom Issue" dialog → `svc_custom` service), `vehicle_form`,
  `booking_summary` (cost breakdown: Service Charge, Platform Fee Free,
  GST 18%, Availability Surcharge ₹100; coupon row → "Coupons coming in
  Sprint 2!"), `booking_confirmation` ("Mechanic Assigned"), `live_tracking`
  (self-advancing timeline requested→…→arrived on a 3s timer; Call / Chat
  (SnackBar) / Cancel / Service Completed), `job_completed` (invoice card,
  Download Invoice "coming in Sprint 2", Rate Service), `rating_review`
  (star picker + optional comment; **_submitReview is UI-only — it sets local
  state, it does NOT call the repository_**), `booking_history` (search +
  filter All/Active/Completed/Cancelled, sort newest first).

## 8. Existing API Contracts (frozen)

- `API.md` §6: entities `MechanicCategory`, `MechanicService`, `MechanicInfo`,
  `MechanicReview`, booking/tracking records. Method surface: "List/query
  mechanics, fetch mechanic details + reviews, book service, create booking
  summary → confirmation, track live booking, submit rating/review, booking
  history." 4 mechanics (m4 unavailable), 3 featured, `r1..r8`, shared
  `generalServices`.
- `endpoint_catalog.md` §3.5: same surface + seed counts (8 categories,
  8 services). §4: "Marketplace/mechanic/fuel/profile endpoints are not yet
  scaffolded."
- ID schemes (`API.md` §1): mechanic service `svc_`, mechanic `m`, review `r`
  / `rv-`. **No booking ID scheme is declared**; the mock generates
  `MEC<8 digits>` (and seeds `MEC123456`-style). Money = `double` INR;
  timestamps ISO-8601; base path `/api/v1`; failures as typed exceptions with
  user-facing messages; additive field changes only.
- **Documented-but-unwired gap:** "submit rating/review" is listed in the
  contract method surface but the mock repository has NO method for it and
  `RatingReviewScreen` never calls the repository. The backend can implement
  rating submission, but there is no frontend caller contract to satisfy today.

## 9. Authentication & RBAC Requirements

- All mechanic routes should use `Depends(get_current_user)`
  (`app/api/deps.py:56`), the established pattern (Task 5 users routes).
- `role_required(*roles)` (`deps.py:83`) exists with `UserRole` =
  customer/mechanic/admin (`models/user.py:30`). No frozen customer flow
  requires role restriction. Recommend: customer flows unrestricted beyond
  auth; add `role_required("mechanic","admin")` ONLY where a mechanic/admin
  mutates mechanic-facing state (none required by the frozen contract — keep
  out of Task 6 scope).
- Identity must always come from `get_current_user`; never from request body
  (e.g. `user_id` on booking create must be the authenticated user).

## 10. Mechanic Domain Requirements

Derived from the frozen mock + schema (no invention):
1. List mechanics (all + featured), with availability, rating, price_starting,
   distance/eta, skills/languages, working hours.
2. Mechanic detail by id (includes `services[]` and working hours).
3. Services catalog (`generalServices`, `svc_*`) and 8 categories.
4. Reviews by mechanic (`r*`).
5. Book a service: create booking (requested), with mechanic_id, service_id,
   vehicle summary/registration, address, estimated cost, ETA.
6. Booking lifecycle: get by id, cancel, complete; history for the current
   user, newest first.
7. Live tracking data (status timeline + payload snapshots) via
   `booking_events`/`ratings` per `data_model.md` §3 (WebSocket noted as the
   Sprint 2 live-tracking mechanism — out of scope to build here).
8. Post-service rating/review (backend capability; no frontend caller today).

## 11. Booking Lifecycle Findings

- Frontend `BookingStatus` = 7 states: `requested → accepted →
  mechanicAssigned → enRoute → arrived → completed` (+ `cancelled`).
- `schema.sql` `mechanic_bookings.status` is `TEXT NOT NULL` with **no CHECK
  constraint**; `booking_events.status` likewise. Status values are therefore
  app-level (matches the repo-wide convention of storing status TEXT). The
  backend should define these 7 values as the enum contract (additive; the
  migration should NOT invent a CHECK unless desired — the existing 0002/0003
  use CHECKs for enumerated roles, so a CHECK on status would be consistent,
  but it is a scope decision).
- Mock transitions: `requested` on create; `cancelled` via cancelBooking;
  `completed` via completeBooking; timeline UI animates requested→arrived
  (client-side timer, not server-driven).
- `booking_events` (status + `payload` JSONB) is the persisted tracking
  snapshot table (`data_model.md` §3: "payload JSONB = live-tracking
  snapshots").
- **Dependency gap:** `mechanic_bookings.vehicle_id` FK → `vehicles` (schema
  L280/283) but no `vehicles` model/migration exists (module 4 remainder).
  `vehicle_id` is nullable in schema. See §17.

## 12. Review Findings

- `mechanic_reviews` (id `r*`, reviewer_name, rating, comment, reviewed_at
  DATE, vehicle) — read path: `fetchReviews(mechanicId)`.
- `ratings` (booking_id UUID 1-1, rating NUMERIC(3,2), review) — write path
  for post-service rating, tied to a booking.
- Frontend `date` field is a display string ("2 days ago"); backend should
  return `reviewed_at` as ISO date (additive; client renders/ignores).
- **No wired frontend submit path** (see §8). Backend rating submission is an
  optional capability; if included, bind to a completed booking owned by the
  authenticated user.

## 13. Services & Categories Findings

- `mechanic_services` is a **global lookup** (`svc_*`, no mechanic FK); per-
  mechanic availability is the M:N `mechanic_service_offered` table.
- `mechanic_categories` is a **standalone lookup** (id/name/icon/color/
  bg_color/description/sort_order); **no FK links services to categories**
  (frontend `MechanicCategory` has no id and no service relation — categories
  are only a home-screen grid). Do not invent a category→service link.
- Frontend `MechanicService.icon` is a Flutter `IconData`; schema stores icon
  as TEXT (name string). Backend should serialize icon as a stable string
  name; the client maps to icons itself (additive, no behavior change).

## 14. Pagination / Filtering Findings

- **No pagination** anywhere in the mechanic mock (fetch all).
- Filtering/sorting (availability, rating ≥ 4, price ≤ 500, nearest) is
  **client-side** in `nearby_mechanics_screen.dart`; the backend need not
  implement query params for it (additive optional `is_available` filter).
- Mechanic search is explicitly deferred ("coming in Sprint 2!") — no search
  endpoint required for Task 6.
- Booking history returns all bookings for the user, newest first
  (client sorts by `bookingTime`).

## 15. Migration Requirements

- Head is `0003` (`0001 → 0002 → 0003`; `alembic versions` list confirmed).
- Task 6 requires a new **additive** migration `0004_mechanics` creating:
  `mechanics`, `mechanic_skills`, `mechanic_languages`,
  `mechanic_working_hours`, `mechanic_services`, `mechanic_service_offered`,
  `mechanic_categories`, `mechanic_reviews`, `mechanic_bookings`,
  `booking_events`, `ratings`.
- **FK ordering (critical):** `mechanic_bookings` FKs to `users` (exists in
  `0002`), `mechanics`, `mechanic_services` (same migration), and
  **`vehicles` (NOT migrated)**. Options: (a) include `vehicles` in a
  separate module-4 migration BEFORE Task 6 (recommended, keeps module
  ownership clean), (b) create `vehicles` model+table inside `0004` (violates
  module boundary), or (c) drop the `vehicle_id` FK and store the vehicle as
  TEXT snapshot (schema deviation). Recommend (a); until then, Task 6 must
  declare the FK only if `vehicles` exists, or leave `vehicle_id` as a plain
  nullable UUID column without FK.
- Mirror 0003 conventions: named FKs (`fk_<child>_<col>_<parent>`), `ON
  DELETE CASCADE` on owner-scoped FKs where the schema omits ACTION,
  indexes on FK columns, `now()` server defaults, JSONB for payload.

## 16. Architecture Compatibility

The established stack fits Task 6 unchanged (Roadmap module 5 depends only on
2,3):
`api/v1/mechanic.py` (thin HTTP, `Depends(get_current_user)`) →
`services/mechanic_service.py` (business logic + commit/rollback) →
`repositories/mechanic.py` (AsyncSession-injected, flush-only,
`BaseRepository`) → SQLAlchemy models → PostgreSQL.
- Mirrors Task 5 `UserService` + `api/v1/users.py` and Task 4 repo pattern
  (`repositories/base.py`). No new libraries needed (SQLAlchemy enums via
  Python `enum.Enum` stored as TEXT, Pydantic schemas, `Decimal` for money
  serialized to the client's `double` INR — follow Task 5's money handling).
- `api/router.py` gains one `include_router` mount under `/api/v1/mechanic`.

## 17. Security / Ownership Risks

- **Ownership:** booking create/get/cancel/complete/history must scope to the
  authenticated `user_id` — never trust a client-supplied `user_id`
  (identical posture to Task 5 `users/me` and Task 4 chat ownership).
- **Vehicle FK gap:** `vehicles` not migrated (see §15); a live DB would fail
  to create the FK if declared. Must resolve before/at migration time.
- **Status transitions:** prevent illegal transitions (e.g. completing a
  cancelled booking) in the service layer; enumerate the 7 statuses.
- **Reviews/ratings:** if implemented, only the booking owner may rate, only
  once (1-1 PK), only after `completed`.
- **Secrets/PII:** no new secrets; mechanic phone/about are public catalog
  data (fine to expose), booking address is user PII (owner-scoped only).
- **No mass assignment:** schemas must use allowlists (`extra="forbid"`),
  per Task 5 pattern.

## 18. Testing Requirements

- Follow `test_users_api.py` pattern: fake `AsyncSession` + real
  `get_current_user` (real JWT against test secret) + real service.
- Suggested `test_mechanic_api.py` coverage:
  - list mechanics (all + featured), detail by id, not-found → 404.
  - services + categories reads.
  - reviews by mechanic; review for unknown mechanic → empty/404.
  - create booking sets `requested`, binds authenticated user (client-supplied
    user_id ignored), invalid mechanic/service/vehicle → validation.
  - get booking by id (owner only; other user → 404/401), cancel →
    `cancelled`, complete → `completed`, illegal transitions rejected.
  - booking history = current user's bookings, newest first.
  - all routes require auth (401 without token).
  - OpenAPI path-count update (15 → new count).
- Full suite must stay green (baseline **299 passed**).

## 19. Conflicts / Ambiguities Found

1. **`vehicles` FK not migrated** while `mechanic_bookings.vehicle_id` FKs it
   (§15/§17) — highest-priority decision.
2. **Booking ID scheme undocumented:** API.md ID table has no booking prefix;
   the mock uses `MEC<8 digits>`. Recommend backend generates a human-facing
   booking id (e.g. `MEC-<year>-<0000>` per other domain patterns, or reuse
   the mock `MEC` + counter) while the PK stays UUID — pick one and document.
3. **Rating submission has no frontend caller:** listed in the contract,
   absent from the mock repository; `RatingReviewScreen` is UI-only. Backend
   may implement the write capability, but there is no wire contract to match.
4. **`MechanicCategory` has no `id`** in the frontend model while schema has
   `id` TEXT PK — backend may expose it (additive) or hide it; client ignores
   unknown fields.
5. **`mechanic_working_hours` mapping:** schema stores (day, open, close)
   rows; frontend stores `Map<String,String>` with combined ranges
   ("Mon-Fri" → "8:00 AM - 8:00 PM"). Backend must decide the serialization
   of a grouped schedule (additive; client owns display).
6. **`distance_km`/`eta_minutes`:** stored in schema but `data_model.md` says
   "computed at request time". Store-or-compute is a Task 6 decision
   (recommend storing per schema; additive).
7. **`mechanics` has no `photo_url`** column but `MechanicInfo.photoUrl`
   exists (defaults `''`); `about`, `phone` match. Acceptable additive gap.
8. **Cost semantics:** mock total = `service.price + (isAvailable ? 0 : 100)`
   while the summary breakdown also shows GST 18% — the backend should store
   `estimatedCost` as the mock does (service price + surcharge) and leave
   invoice/GST to a later task; document the convention.
9. **Status CHECK:** schema omits status CHECKs; existing migrations use
   CHECKs for enumerated columns. Decide whether to add `ck_*_status` in
   `0004` (consistent) or keep app-level only.

## 20. Explicitly Out-of-Scope Items

- **Frontend changes** (frozen contract; mocks stay until a wiring task).
- Marketplace, Fuel, Home, AI modules.
- `vehicles`/`addresses`/`wallet`/`rewards`/notification-settings (module 4
  remainder; NOT in Task 6 — only a migration-dependency note).
- `order_entries` unified Orders tab integration for mechanic bookings
  (module 7 concern; note only).
- Real-time WebSocket live tracking, invoice generation/download, mechanic
  search, coupons/discounts on bookings, Gemini/ML integration.
- Admin/mechanic-side dashboards and role-based mutations.

## 21. Recommended Task 6 Implementation Order

1. **Decision gate:** resolve §19.1 (vehicles FK) and §19.2 (booking ID
   scheme) before coding.
2. **Stage 1 — Models & migration:** 11 ORM models + register in
   `models/__init__.py`; author `0004_mechanics` (additive; correct FK
   ordering); verify `alembic upgrade head --sql` is additive and matches
   `schema.sql`.
3. **Stage 2 — Repositories:** `BaseRepository` subclasses: mechanics
   (list/featured/detail), services, categories, reviews, bookings
   (owner-scoped create/get/cancel/complete/history, newest-first), events.
4. **Stage 3 — Schemas:** Pydantic request/response (frontend entity shapes,
   money as INR-compatible numbers, `extra="forbid"`, ISO-8601 dates).
5. **Stage 4 — Service:** `MechanicService` (mirror UserService: ownership
   enforcement, status transitions, commit/rollback).
6. **Stage 5 — Routes:** `app/api/v1/mechanic.py` with `Depends(get_current_user)`;
   mount in `api/router.py`; update OpenAPI path-count expectations.
7. **Stage 6 — Tests:** `test_mechanic_api.py` per §18; full suite green.
8. **Stage 7 — Reports + manual review gate** (implementation + verification).

## 22. Files Expected to Change Later (Task 6, upon approval)

- `backend/app/models/mechanic.py` (or split files: mechanic, service,
  category, review, booking, event, rating) + `models/__init__.py`.
- `backend/alembic/versions/0004_mechanics.py`.
- `backend/app/repositories/mechanic.py` (+ services/categories/reviews/
  bookings/events).
- `backend/app/schemas/mechanic.py`.
- `backend/app/services/mechanic_service.py`.
- `backend/app/api/v1/mechanic.py` + `backend/app/api/router.py`.
- `backend/tests/test_mechanic_api.py`.

## 23. Files That MUST NOT Be Changed

- `backend/alembic/versions/0001_baseline.py`, `0002_authentication_foundation.py`,
  `0003_conversation_ownership.py` (never rewrite applied migrations).
- `frontend/lib/features/mechanic/**` (frozen contract).
- `docs/backend/database/schema.sql`, `docs/backend/API.md`,
  `docs/backend/api/endpoint_catalog.md`, `docs/backend/database/data_model.md`,
  `docs/backend/architecture/SPRINT_2_ROADMAP.md` (authoritative sources).
- `backend/.env` (`DATABASE_URL` intentionally unset).
- The 3 untracked report docs (§2).
- Existing `backend/tests/*` (add new files only).

## 24. Risks

- **Live DB unverified** (DATABASE_URL unset): `alembic current`/live FK
  behavior remain NOT VERIFIED (documented posture).
- **Vehicles FK gap** blocks a clean `0004` unless resolved first (§19.1).
- **Scope creep** risk: rating submission, working-hours serialization, and
  booking ID generation each carry a design decision that must not balloon
  the task; keep them minimal and additive.
- **Ownership bugs** (booking history leaking across users) are the top test
  priority — mirror Task 4's ownership tests.

## 25. Final Recommendation

**READY FOR IMPLEMENTATION** — but approve the following explicit decisions
first:
1. `vehicles` migration ordering (recommend a prior module-4 migration, or
   defer the FK).
2. Booking public ID scheme (recommend `MEC-<year>-<0000>` stored as
   `external_id`-style TEXT column, PK stays UUID).
3. Include post-service rating write (recommend: YES, bound to completed
   booking + owner) or defer (recommend minimal deferral — no frontend
   caller).
4. Status CHECK in `0004` (recommend YES for consistency with 0002/0003).
5. Working-hours serialization shape (recommend grouped
   `{"Mon-Fri": "8:00 AM - 8:00 PM"}` additive string, matching the client).

All 299 baseline tests pass; the tree is clean; no implementation was
performed during this reconnaissance.

---

*Reconnaissance ends. No files modified except this report, no DB touched, no
commits/pushes performed.*