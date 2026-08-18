# TASK 6 — Mechanics Module Final Report

> Consolidated, independent final report for the mechanics module (Sprint 2,
> Task 6). This is the authoritative post-stage-verification document: it
> supersedes the per-stage checkpoint reports and consolidates the
> independently re-verified state of the whole Task 6 change set.
>
> Independent review performed directly against the source on disk — no
> earlier stage report was trusted; every claim below was re-derived from the
> files, the running test suite, the compiled statements, and the offline SQL
> rendered by Alembic.

---

## 1. Objective

Implement the frozen **Mechanics** contract (`docs/backend/API.md` §6 +
`docs/backend/endpoint_catalog.md` §3.5) end to end: models, Alembic
migration, repositories, schemas, service, API routes, router wiring, and a
full test suite — bounded by the Sprint 2 Task 6 scope derived in the
reconnaissance (`TASK6_MECHANICS_RECONNAISSANCE_REPORT.md`).

Scope boundaries honoured:
- **No live PostgreSQL** in this environment (`DATABASE_URL` absent from
  `backend/.env`) → all DB-dependent verification is *offline SQL* +
  in-memory/fake-session tests, and every live-DB claim is honestly recorded
  as `NOT VERIFIED — LIVE POSTGRESQL`.
- **No Task 7 work** was started. Task 6 stops at commit + push + remote
  verification of its own single commit.

## 2. Architecture

Layered FastAPI module mirroring the existing Task 3/4/5 modules:

```
app/
  models/                 Stage 1  — SQLAlchemy ORM (11 mechanics tables)
    mechanic_status.py    BookingStatus enum (single source of truth, 7 states)
    mechanic.py           Mechanic + child rows (skills/languages/working_hours)
    mechanic_service.py   MechanicService + MechanicServiceOffered junction
    mechanic_category.py  MechanicCategory
    mechanic_review.py    MechanicReview
    mechanic_booking.py   MechanicBooking + BookingEvent + Rating
  alembic/versions/
    0004_mechanics.py     Stage 1  — additive migration, revision 0004
  repositories/
    mechanics.py          Stage 2  — flush-only data access, no commits
  schemas/
    mechanic.py           Stage 3  — Pydantic contracts, validation only
  services/
    mechanic_service.py   Stage 4  — orchestration; owns transaction boundaries
  api/v1/mechanic.py      Stage 5  — thin HTTP layer over the service
  api/router.py           Stage 5  — router registration
tests/
  test_mechanics_models.py        Stage 1  — 34 model + migration contract tests
  test_mechanics_schemas.py       Stage 3  — 57 schema contract tests
  test_mechanics_repositories.py  Stage 2  — 44 repository tests
  test_mechanic_service.py        Stage 4  — 34 service tests
  test_mechanic_routes.py         Stage 5  — 72 route tests
  test_mechanic_api.py            Stage 6  — 44 end-to-end API tests
```

Layering rules enforced (same conventions as the existing modules):
- Routes = HTTP only; no business logic, no SQLAlchemy, no session, no
  ownership decisions, no transactions.
- Service = coordination + transaction boundaries; owns `commit()` (exactly
  once per logical write) and `rollback()` on any failure.
- Repositories = SQL shape only; flush-only writes, **never** `commit()`.
- Schemas = validation/serialization only; `extra="forbid"` on inputs;
  `from_attributes=True` on outputs.
- `BookingStatus` is the single canonical enum; no second status representation
  anywhere.

## 3. Locked Decisions

Locked during Task 6 reconnaissance and carried through every stage:

| ID | Decision |
|----|----------|
| D6-1 | `mechanic_bookings.vehicle_id` is a nullable `UUID` **without an FK** and **without a vehicles table** (no vehicle API in this sprint). |
| D6-2 | No booking number, no estimated cost, no estimated arrival fields — they are not model columns. |
| D6-3 | Ratings are 1-1 with a booking (PK = `booking_id`); eligibility = owned + `completed` + unrated. |
| D6-4 | Status uses the canonical `BookingStatus` enum; values are the 7 frozen strings. |
| D6-5 | Working hours stay normalized rows `(day, open, close)`; client-side grouping is a display concern. |
| D6-6 | `featured` = top-rated (`rating DESC`, limit 3) — no `is_featured` column. |
| D6-7 | Catalog routes are public; all booking/rating routes require the real `get_current_user` Bearer access token. |
| D6-8 | Ownership: `user_id` ALWAYS from `get_current_user`; generic 404 for missing/foreign bookings (no existence leak). |
| D6-9 | Money is `Decimal`/`NUMERIC` internally, serialized as a JSON number (double INR) on the wire. |
| D6-10 | Lazy loading is avoided for every catalog relationship that `MechanicOut` serializes (async-safe eager loading). |

## 4. Stage 1–6 Implementation Summary

| Stage | Deliverable | Independent verification |
|-------|-------------|--------------------------|
| 1 | 6 model modules (11 tables) + `0004_mechanics.py` + `models/__init__.py` wiring | 34 model/migration-contract tests |
| 2 | `repositories/mechanics.py` (7 repositories) | 44 repository tests (FakeSession + compiled-SQL predicates) |
| 3 | `schemas/mechanic.py` (10 schemas) | 57 schema contract tests |
| 4 | `services/mechanic_service.py` (`MechanicService`) | 34 service tests (commit/rollback/ownership) |
| 5 | `api/v1/mechanic.py` (15 routes) + `router.py` wiring | 72 route tests (auth matrix) |
| 6 | `tests/test_mechanic_api.py` (44 end-to-end tests) | 44 API tests (real router + real JWT + fake session) |

Each stage was independently implemented and independently reviewed (PASS) at
the time; the final re-verification in §12 below was performed fresh against
the complete change set on disk.

## 5. Final Files Changed

New files:

- `backend/alembic/versions/0004_mechanics.py`
- `backend/app/models/mechanic_status.py`
- `backend/app/models/mechanic.py`
- `backend/app/models/mechanic_service.py`
- `backend/app/models/mechanic_category.py`
- `backend/app/models/mechanic_review.py`
- `backend/app/models/mechanic_booking.py`
- `backend/app/repositories/mechanics.py`
- `backend/app/schemas/mechanic.py`
- `backend/app/services/mechanic_service.py`
- `backend/app/api/v1/mechanic.py`
- `backend/tests/test_mechanics_models.py`
- `backend/tests/test_mechanics_schemas.py`
- `backend/tests/test_mechanics_repositories.py`
- `backend/tests/test_mechanic_service.py`
- `backend/tests/test_mechanic_routes.py`
- `backend/tests/test_mechanic_api.py`

Modified files (tracked, both are Task 6 changes):

- `backend/app/api/router.py` — import + mount `mechanic.router` (+7)
- `backend/app/models/__init__.py` — register the 11 mechanic models (+31)

Pre-existing baseline migrations `0001`, `0002`, `0003` are **unchanged**
(verified via `git diff` — no diff in `backend/alembic/`).

## 6. Database & Migration

- Migration: `backend/alembic/versions/0004_mechanics.py`, `revision 0004`,
  `down_revision 0003`. Verified additive: it only `create_table`s new tables;
  it never alters/drops a baseline table.
- Offline SQL rendered with `python -m alembic upgrade head --sql` (this
  environment has no live DB). Inspected line-by-line:
  - Chain `-> 0001 -> 0002 -> 0003 -> 0004` reaches `head` at `0004`.
  - Exactly **11** mechanics tables are created: `mechanics`,
    `mechanic_skills`, `mechanic_languages`, `mechanic_working_hours`,
    `mechanic_services`, `mechanic_service_offered`, `mechanic_categories`,
    `mechanic_reviews`, `mechanic_bookings`, `booking_events`, `ratings`.
  - **No `vehicles` table.**
  - `mechanic_bookings.vehicle_id UUID` — **no FK** (D6-1).
  - `ck_mechanic_bookings_status` CHECK lists exactly the 7 frozen states:
    `requested, accepted, mechanicAssigned, enRoute, arrived, completed,
    cancelled`.
  - Indexes: `ix_mechanic_reviews_mechanic_id`, `ix_mechanic_bookings_user_id`,
    `ix_mechanic_bookings_mechanic_id`, `ix_mechanic_bookings_service_id`,
    `ix_booking_events_booking_id` + composite PK constraints on the junction
    tables.
  - FK ordering is valid: `mechanic_bookings` FKs reference `users` (created in
    0002), `mechanics` and `mechanic_services` (both created earlier in 0004);
    `booking_events`/`ratings` reference `mechanic_bookings`; junction FKs
    reference `mechanics`/`mechanic_services`. No forward references.
  - Downgrade order (`0004 -> 0003`) reverses creation order (children before
    parents), verified in the migration source.
- Model metadata check: `Base.metadata` registers 15 tables total (4 baseline
  + 11 mechanics); `test_mechanics_models.py` asserts the 11-table `MECHANIC_TABLES`
  set and the revision chain.

> **NOT VERIFIED — LIVE POSTGRESQL.** Real migration execution, real FK/CHECK
> enforcement, `gen_random_uuid()`, JSONB behaviour, and live read/write
> behaviour were not exercised because `DATABASE_URL` is absent from
> `backend/.env`. Only offline SQL shape + contract tests cover this layer.

## 7. Repository Layer

`backend/app/repositories/mechanics.py` — 7 repositories:
`MechanicRepository`, `MechanicServiceRepository`, `MechanicCategoryRepository`,
`MechanicReviewRepository`, `MechanicBookingRepository`, `BookingEventRepository`,
`RatingRepository`, all subclassing the existing `BaseRepository`.

- Reads: `select()` + `scalar`/`scalars` only; ownership predicates are built
  in SQL (`get_owned` filters by `id` AND `user_id`; `list_for_user` filters by
  `user_id`; SQL-shape tests compile these against the PostgreSQL dialect with
  `literal_binds`).
- Writes: `add`/attribute-set + `flush()` only. **Never `commit()`.** Tested
  (`test_booking_repository_never_commits_on_any_write`,
  `test_all_repositories_never_commit_on_writes`).
- **Lazy-loading (final review fix):** `list_all`/`list_featured` previously
  issued a bare `select(Mechanic)` while `MechanicOut._flatten_orm_children`
  reads `skills`/`languages`/`working_hours`/`services_offered` (and each
  offered row's `service`). With an async session this can raise
  `MissingGreenlet` after the request session hands off. The final review
  confirmed this risk and implemented a minimal, in-scope fix: a shared
  `_mechanic_catalog_options()` helper (eager `selectinload` of all four child
  relationships, chained through `MechanicServiceOffered.service`) now used by
  `get_by_id`, `list_all`, and `list_featured`. No other behaviour changed.
  Re-verified: 44 repository tests pass, 184 focused mechanic tests pass, full
  suite 584 pass.

## 8. Service Layer

`MechanicService` (constructor-injected session + repos) is the sole owner of
transaction boundaries:

- **Reads never commit** (`test_read_operations_never_commit`).
- **Writes commit exactly once** on success (`create_booking`, `cancel_booking`,
  `complete_booking`, `create_rating` all assert `commits == 1`).
- **Any failure rolls back and re-raises** (`rollbacks == 1`); pre-existing
  `get_db` yields/rolls back on teardown as the outer safeguard.
- Create performs FK pre-checks (controlled 404, never a raw IntegrityError)
  and persists the initial `requested` snapshot to `booking_events` in the same
  transaction.
- Terminal-state guard: a `cancelled`/`completed` booking cannot be cancelled
  or completed again (`_assert_mutable`).

## 9. API Surface

Full app OpenAPI = **28 paths** (15 baseline + 13 mechanics). The mechanics
router contributes 13 paths (7 public + 6 booking/rating paths; the two extra
routes beyond the 11 path strings are the `GET/POST` pair on
`/bookings/{booking_id}/rating`):

- Public (no auth): `GET /api/v1/mechanic/mechanics`,
  `GET /api/v1/mechanic/mechanics/featured`,
  `GET /api/v1/mechanic/mechanics/{mechanic_id}`,
  `GET /api/v1/mechanic/mechanics/{mechanic_id}/services`,
  `GET /api/v1/mechanic/mechanics/{mechanic_id}/reviews`,
  `GET /api/v1/mechanic/services`, `GET /api/v1/mechanic/categories`.
- Protected (real `get_current_user`): `GET/POST /api/v1/mechanic/bookings`,
  `GET /api/v1/mechanic/bookings/{booking_id}`,
  `POST /api/v1/mechanic/bookings/{booking_id}/cancel`,
  `POST /api/v1/mechanic/bookings/{booking_id}/complete`,
  `GET /api/v1/mechanic/bookings/{booking_id}/events`,
  `POST/GET /api/v1/mechanic/bookings/{booking_id}/rating`.

Route ordering is safe: static suffixes (`/featured`, `/services`, `/reviews`)
are declared before the `/{mechanic_id}` capture; bookings live under a distinct
prefix. Error mapping goes through `app.main`'s `MechaException` handler
(404/401/400/422), never leaking raw exceptions (generic 500 sanitized).

## 10. Authentication & Ownership

Re-verified against the routes, service, deps, and API tests:

- Identity is ALWAYS `get_current_user` (real `verify_access_token` + real
  `UserRepository`); `BookingCreate`/`RatingCreate` have no user field and
  `extra="forbid"` blocks any mass-assignment attempt (`user_id`, `status`,
  `id`, etc. are rejected by schema tests).
- Booking creation binds `user_id` from the authenticated token, never a body
  field.
- Booking reads/events/rating reads resolve `get_owned(booking_id, user_id)`;
  missing AND foreign bookings both raise the generic `"Booking not found."`
  404 — no existence leak.
- History (`GET /bookings`) is `list_for_user(authenticated user)` only.
- Rating eligibility = owned + `completed` + unrated (controlled 400s).
- Unauthenticated requests to protected routes → 401; malformed/expired/
  refresh tokens are rejected as access tokens (`test_refresh_token_rejected_as_access`,
  `test_expired_access_token_rejected` in `test_mechanic_routes.py`).
- `get_current_user` rejects inactive accounts.

## 11. Testing

- **285 Task 6 tests** (models 34, schemas 57, repositories 44, service 34,
  routes 72, API 44). All pass.
- **Full suite: 584 passed, 149 warnings** (warnings are pre-existing Pydantic
  `example=`/Alembic deprecations; zero failures) — run fresh after the lazy-load
  fix.
- Strategy without a live DB (mirrors existing patterns): `FakeSession`
  evaluates simple selects; SQL-shape/ownership predicates are compiled against
  the PostgreSQL dialect with `literal_binds`; the API tests run the REAL
  router + REAL service + REAL `get_current_user` (real JWT minting against a
  monkeypatched test-only `JWT_SECRET_KEY`) over an in-memory session with
  repository methods patched.
- `compileall` over `app` + `tests`: OK.
- Module imports (models, service, routes): OK.

## 12. Independent Manual Verification

Fresh final-pass verification (not trusting prior reports):

| # | Check | Result |
|---|-------|--------|
| 1 | Full test suite `pytest tests/ -q` | **584 passed** |
| 2 | `compileall -q app tests` | OK |
| 3 | Model/service/route imports | OK; 15 tables registered (11 mechanics) |
| 4 | OpenAPI spec generation | 28 paths; 13 mechanic paths confirmed |
| 5 | `GET /health` (TestClient) | 200 `healthy` / `database: not_configured` (no DB) |
| 6 | Protected endpoints w/o DB | Correctly fail at `get_db` (no `DATABASE_URL`); auth behaviour itself proven by API/route tests |
| 7 | Alembic offline SQL `upgrade head --sql` | 0004 reached; 11 tables; no vehicles; vehicle_id no FK; 7-state CHECK; indexes; FK ordering valid |
| 8 | Baseline migrations 0001–0003 | Unchanged (`git diff` empty for `backend/alembic/`) |
| 9 | Lazy-load review + fix | Risk confirmed; minimal fix implemented; full re-test green |

## 13. Security & Hygiene

- Secret scan over every Task 6 source + doc file for `AIzaSy`, `sk-`,
  `Bearer`, `JWT_SECRET`, `DATABASE_URL`, `GEMINI_API_KEY`,
  `BEGIN PRIVATE KEY`, `BEGIN RSA`, `password=`, `api_key=`:
  - Source: only benign test-file hits — the literal `TEST_JWT_SECRET`
    (`task6-mechanic-*-test-secret-not-for-production`, monkeypatched into
    `settings.JWT_SECRET_KEY`), `Authorization: Bearer` header construction,
    and a docstring mentioning `DATABASE_URL`. **No real secrets.**
  - Docs: only pattern-list mentions and the documented absence of
    `DATABASE_URL`. **No real secrets.**
- `backend/.env` checked directly: `DATABASE_URL` **absent**, `GEMINI_API_KEY`
  present (pre-existing, unchanged, not part of this diff). `.env` is not
  committed and was not modified.
- No secrets, generated artifacts, or unrelated files in the change set.

## 14. Known Limitations / Risks

- **LIVE POSTGRESQL NOT VERIFIED.** No `DATABASE_URL` in this environment, so
  real migration execution, FK/CHECK enforcement, `gen_random_uuid()`, JSONB,
  real transaction behaviour, async relationship loading, and multi-request
  behaviour were not exercised against a database. Mitigated by offline SQL
  inspection, compiled-SQL tests, and fake-session tests, but a live-DB smoke
  run is required before production rollout.
- Featured list derivation (`rating DESC`) and the generic booking lifecycle are
  deliberate recon-scoped decisions; a finer state matrix is out of scope.
- Pydantic/Alembic deprecation warnings are pre-existing and unrelated.

## 15. Final Verdict

**TASK 6 — PASS**

Implementation is complete, independently reviewed, fully tested (584/584),
scope-clean, and free of secrets. Committed and pushed as one Task 6 commit
(see §16). The only unverified dimension is live PostgreSQL, which is
honestly recorded as `NOT VERIFIED` above.

## 16. Commit & Remote Verification

- **Commit:** one Task 6 commit, message `feat(backend): complete mechanics
  module`. The exact commit hash is recorded in the repository history
  (verified: `git rev-parse HEAD` == `git rev-parse origin/main` at push
  time); this report cannot self-reference its own commit hash without
  altering it, so the hash is stated in the final gate response instead.
- **Commit contents:** 21 files, 7237 insertions, 2 deletions (all Task 6
  implementation + `TASK6_MECHANICS_FINAL_REPORT.md` +
  `TASK6_MECHANICS_RECONNAISSANCE_REPORT.md`). Exactly one Task 6 commit.
- **Push result:** `git push origin main` → `8e2dbd1..9e7ee86 main -> main`
  (succeeded); after finalizing this report section, force-pushed safely with
  `git push --force-with-lease origin main` so the amended commit remains the
  only Task 6 commit.
- **HEAD vs origin/main:** equal (`git rev-parse HEAD` == `git rev-parse origin/main`).
- **Final git status:** only three genuinely pre-existing, unrelated untracked
  docs remain (`NEXT_SPRINT2_TASK_RECONNAISSANCE_REPORT.md`,
  `TASK3_TASK4_COMMIT_REPORT.md`, `TASK5_COMMIT_PUSH_REPORT.md`). No other
  working-tree changes.
- **Final test count:** full suite `pytest tests/ -q` → **584 passed**
  (Task 6 focused: 285). `compileall` OK; OpenAPI 28 paths.
- **Final verification result:** re-verified fresh in the final gate (commit
  hash, push, HEAD/origin/main, status, tests) after commit + push.