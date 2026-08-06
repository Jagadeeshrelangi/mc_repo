# Repository Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: complete repository structure, naming, duplicates, dead/legacy/temp files.

## 1. Current State

### 1.1 Top-level structure
```
mecha_connect/
├── lib/                    # Flutter app (233 dart files)
├── test/                   # 9 test files (162 tests)
├── backend/                # FastAPI scaffold + AI pipeline
├── docs/                   # Official documentation (97 files)
├── documentation_build/    # AI documentation workspace (170 files)
├── assets/                 # 18 app images
├── android/ ios/ web/ windows/ linux/ macos/   # platform shells
├── build/                  # Flutter build artifacts (gitignored)
├── .dart_tool/             # Dart tooling (gitignored)
├── .git/                   # Git metadata
├── .vscode/                # Editor config
├── pubspec.yaml            # Flutter manifest
├── analysis_options.yaml   # Lint config
├── .gitignore              # Git ignore rules
└── .env                    # Frontend env (gitignored)
```

### 1.2 lib/ structure
```
lib/
├── main.dart               # Entry point
├── app_wiring.dart         # Provider graph source of truth
├── theme/                  # Design tokens, AppTheme, ThemeProvider, responsive
├── bottom_bar/             # 5-tab shell + orders tab
├── parts/order_data.dart   # Global order store + list
├── starting_screen/        # Splash, onboarding, service selection
├── homescreen/             # Drawer (legacy location)
├── services/               # Location, geocoding services
├── widgets/                # Shared widgets (loading, location, order card)
├── auth/                   # Auth widget components (8 files)
└── features/
    ├── ai/                 # AI Assistant module
    ├── auth/               # Auth module (screens, provider, repo, service)
    ├── fuel_delivery/      # Fuel Delivery module
    ├── home/               # Home Dashboard module
    ├── marketplace/        # Marketplace module
    ├── mechanic/           # Mechanic module
    └── profile/            # Profile module
```

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **Feature-first architecture** | All 7 modules under `lib/features/` follow the same `models/providers/repositories/screens/services/widgets` pattern |
| S2 | **Consistent module structure** | Every module has identical sub-folder layout — high navigability |
| S3 | **Single source of truth** | `app_wiring.dart` is the only provider-graph definition; `main.dart` and tests both use it |
| S4 | **Clean separation** | `lib/auth/` (widgets) vs `lib/features/auth/` (module) — though naming is confusing (see W1) |
| S5 | **Proper gitignore** | `.env`, `backend/.env`, `backend/venv/`, `build/`, `.dart_tool/` all correctly ignored |
| S6 | **No tracked build artifacts** | `build/` and `.dart_tool/` are gitignored; git status clean apart from untracked docs |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **`lib/auth/` vs `lib/features/auth/` naming collision** | P2 | `lib/auth/` holds 8 widget files (auth_divider, auth_header, etc.) that are actively imported by `lib/features/auth/screens/*`. The `features/auth/widgets/` folder only has `password_strength.dart`. This splits auth widgets across two locations. |
| W2 | **`lib/homescreen/` is a legacy single-file folder** | P3 | Contains only `drawerscreen.dart` — a legacy location that should be under `features/home/` or `widgets/`. |
| W3 | **`lib/starting_screen/` mixes concerns** | P2 | Contains splash, onboarding, AND `home.dart` (ServiceSelectionScreen) — the service selection is a core feature, not a "starting screen". |
| W4 | **`lib/parts/` is a legacy folder** | P3 | Only `order_data.dart` — the global order store. Should be under a shared/state location. |
| W5 | **`lib/features/auth/models/` is empty** | P3 | The auth module has no models folder content (auth uses no models at RC1). |
| W6 | **`backend/venv/` exists on disk** | P2 | Not tracked by git (correctly ignored), but occupies ~1.3GB and is a hygiene risk if someone force-adds it. |
| W7 | **`build/` exists on disk** | P3 | Gitignored, but present. Normal Flutter behavior. |
| W8 | **`__pycache__/` in backend** | P3 | `backend/app/api/v1/__pycache__/` exists — gitignored but present. |

## 4. Duplicate / Dead / Legacy Files

| # | File | Status | Detail |
|---|---|---|---|
| D1 | `lib/auth/*` (8 files) | **Active** | Imported by `features/auth/screens/*`. Not dead, but misplaced (see W1). |
| D2 | `lib/homescreen/drawerscreen.dart` | **Active** | Imported by `starting_screen/home.dart`. Legacy location. |
| D3 | `lib/parts/order_data.dart` | **Active** | Imported by marketplace, profile, orders tab. Legacy location. |
| D4 | `lib/starting_screen/home.dart` | **Active** | ServiceSelectionScreen — core feature in wrong folder. |
| D5 | `lib/features/auth/models/` | **Empty** | No files. Dead folder. |
| D6 | `lib/features/auth/widgets/` | **Partial** | Only `password_strength.dart`. The other 8 auth widgets live in `lib/auth/`. |
| D7 | `docs/archive/` (43 files) | **Archived** | Correctly archived per audit plan. |
| D8 | `docs/05_reports/` (5 sprint reports) | **To-archive** | Per `docs-audit-migration-plan.md`, these should move to `archive/`. |

## 5. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | `lib/auth/` vs `lib/features/auth/` confusion | P2 | Consolidate auth widgets into `features/auth/widgets/` during Sprint 2 cleanup |
| R2 | `backend/venv/` bloat | P2 | Add `backend/venv/` to gitignore explicitly (already covered by `venv/` pattern) |
| R3 | Legacy folder names mislead new devs | P3 | Rename during Phase 6 repository cleanup |

## 6. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | Auth widgets split across `lib/auth/` and `features/auth/widgets/` | P2 | 1 hr |
| TD2 | `starting_screen/` mixes splash/onboarding/service-selection | P2 | 2 hr |
| TD3 | `homescreen/` and `parts/` legacy folders | P3 | 1 hr |
| TD4 | Empty `features/auth/models/` folder | P3 | 5 min |

## 7. Recommendations

1. **P2 — Consolidate auth widgets**: Move `lib/auth/*.dart` → `lib/features/auth/widgets/` and update imports. This aligns with the feature-first convention.
2. **P2 — Reorganize `starting_screen/`**: Move `ServiceSelectionScreen` to `features/home/` or a new `features/services/` module.
3. **P3 — Remove empty folders**: Delete `features/auth/models/` (empty).
4. **P3 — Legacy folder cleanup**: Move `homescreen/drawerscreen.dart` → `features/home/widgets/`; move `parts/order_data.dart` → a shared `state/` or `core/` location.
5. **P2 — Verify venv hygiene**: Ensure `backend/venv/` is never force-added; consider deleting it from disk to save space.

## 8. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 0 | — |
| P1 | 0 | — |
| P2 | 4 | W1, W3, W6, R1, R2, TD1, TD2 |
| P3 | 5 | W2, W4, W5, W7, W8, TD3, TD4 |