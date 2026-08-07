# Coding Standards — Mecha Connect

> Frozen engineering conventions. Source: `docs/frontend/Architecture.md`,
> `docs/common/DEVELOPMENT_WORKFLOW.md`, and the Sprint 2 backend blueprint.

## 1. Dart / Flutter (frontend)

### Architecture rules (FROZEN)
1. **Layer rule:** Screens → Providers (ChangeNotifier) → Repositories → mock engines.
2. **Repositories are the ONLY data source** — screens never call HTTP directly.
3. **Single provider graph** — `buildRootProviders()` in `frontend/lib/app_wiring.dart`
   is the source of truth; the runtime regression test uses it verbatim.
4. **9 root providers** — Theme, Location, Auth, Home, Mechanic, AI, Profile,
   Fuel, Marketplace.
5. **5-tab shell** — `IndexedStack` keeps all tabs alive; GNav bar.
6. **AI module shares ONE `AiRepository`** across provider/service/diagnosis.
7. **`orderStore`/`ordersList` singletons** power the Orders tab + Profile order history.
8. **ID schemes are frozen** — `MKP-`, `p-`, `ORD-`, `FUEL-`, `veh-`, `addr-`,
   `txn-`, `rew-`, `pay-`, etc. (see `docs/backend/API.md` §1).
9. **Money = `double` INR (₹); timestamps ISO-8601.**
10. **Verification gate:** any change must pass `flutter analyze` (0 issues) +
    `flutter test` (162/162).

### Code conventions
- Feature-first modules under `frontend/lib/features/<module>/` with models,
  repositories, providers, screens, and widgets grouped per module.
- Use the frozen theme tokens (`frontend/lib/theme/`) — no hardcoded hex colors or
  off-scale radii in new code (legacy exceptions tracked in the handbook).
- Prefer `context.read` / `context.select` for narrow rebuilds (e.g. wishlist).
- Default-first ordering for vehicles/addresses so lists never jump between
  screens.
- Additive model changes only; enum changes require a client-matching release.

## 2. Python / FastAPI (backend, Sprint 2)

- **Async SQLAlchemy 2.0** engine; Alembic migrations; UUID primary keys;
  `created_at`/`updated_at` audit fields on all tables; soft deletes via
  `deleted_at` where noted.
- **Repository pattern:** abstract base repository; concrete repositories per
  entity; services depend on repositories, never on the ORM session directly.
- **Pydantic v2 schemas** validate every request/response; exceptions map to
  proper HTTP status codes via the shared exception hierarchy.
- **JWT auth** (access 15 min / refresh 7 days) + bcrypt password hashing;
  role-based access control for customer/mechanic/admin.
- **Structured JSON logging** on all services; security headers on all
  responses; rate limiting (in-memory, no Redis per constraints).
- **Testing:** minimum 80% coverage (100% auth/payment, 90% AI); pytest +
  pytest-asyncio + httpx for API tests.

## 3. Documentation rules

- `docs/` is canonical — one source of truth per topic (see
  `docs/CANONICAL_DOCUMENT_MAP.md`); `docs/archive/` is read-only history.
- Never put confidential, financial, security, or business content in public
  docs; it belongs in the confidential documentation set (excluded from git).
- Do NOT invent architecture, APIs, workflows, screen names, seed data, or
  numbers; do NOT fabricate screenshots.
- Entry order for new contributors/AI: `PROJECT_OVERVIEW` →
  `KNOWLEDGE_GRAPH` → `MASTER_PROJECT_KNOWLEDGE_BASE` →
  `DEVELOPMENT_WORKFLOW`.
