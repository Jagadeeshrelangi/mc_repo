# GAP_ANALYSIS — Mecha Connect

> **Documentation Build v2.1 · AI Knowledge Optimization · 2026-08-05**
> Doc-vs-code drift, missing coverage, and PENDING items.

## 1. Doc-vs-Code Drift (verified against source)

| Claim in docs | Code reality | Status |
|---|---|---|
| 162/162 tests | Confirmed (test files total 162) | ✅ Consistent |
| Flutter 3.29.2 | `pubspec.lock`/environment | ✅ Consistent |
| 40 products / 10 categories / 15 brands / 3 offers / 3 coupons | `kMarketplaceProducts` seed | ✅ Consistent |
| 4 mechanics, 3 featured, reviews r1–r8 | `kMechanics` seed | ✅ Consistent |
| 5 seed conversations, 2 pinned | `AiRepository._seed()` | ✅ Consistent |
| 5-tab shell Home/Services/Orders/AI/Profile | `bottom_navigation.dart` | ✅ Consistent |
| Jagadeesh Gowda / Pro / wallet 1200 / 2450 pts | `ProfileRepository._seedProfile()` | ✅ Consistent |
| AI chat is keyword engine at RC1 | `AiRepository._composeRawReply()` | ✅ Consistent |
| Backend scaffold: FastAPI, FAISS, XGBoost | `backend/` verified | ✅ Consistent |
| `lib/auth/` holds 8 auth widgets | Confirmed (auth_divider, auth_header, etc.) | ✅ Consistent |
| `orderStore`/`ordersList` singletons | `lib/parts/order_data.dart` | ✅ Consistent |
| `IndexedStack` keeps all 5 tabs alive | `bottom_navigation.dart` | ✅ Consistent |
| AI module shares ONE AiRepository | `app_wiring.dart` root #6 | ✅ Consistent |
| Mechanic VehicleForm uses AI DiagnosisService | `vehicle_form_screen.dart` | ✅ Consistent |
| `failForFirstCalls` in AiRepository + ProfileRepository | Confirmed | ✅ Consistent |
| `failForFirstCalls` in MechanicRepository | **NOT present** | ⚠️ Drift (FLUTTER_AUDIT W5) |
| `failForFirstCalls` in FuelRepository | **NOT present** | ⚠️ Drift (FLUTTER_AUDIT W5) |
| `failForFirstCalls` in MarketplaceRepository | **NOT present** | ⚠️ Drift (FLUTTER_AUDIT W5) |
| `failForFirstCalls` in HomeRepository | **NOT present** | ⚠️ Drift (FLUTTER_AUDIT W5) |
| `failForFirstCalls` in AuthRepository | **NOT present** | ⚠️ Drift (FLUTTER_AUDIT W5) |
| `FuelProvider` constructor-injectable | **NOT** — hardcodes repo/service | ⚠️ Drift (FLUTTER_AUDIT W6) |
| Fonts (Inter/Space Grotesk) bundled | **NOT in pubspec** | ⚠️ Drift (UI_UX_AUDIT W2) |
| Auth module tests | **Zero** | ⚠️ Drift (TESTING_AUDIT W2) |
| Backend tests | **Zero** | ⚠️ Drift (BACKEND_AUDIT W1) |
| `ordersList` typed model | **Map<String, dynamic>** | ⚠️ Drift (FLUTTER_AUDIT W2) |
| `AuthProvider` stores plaintext password | **Confirmed** | ⚠️ Drift (SECURITY_AUDIT W1) |
| CORS allow-all + credentials | **Confirmed** | ⚠️ Drift (SECURITY_AUDIT W4) |
| No Alembic migrations | **Confirmed** | ⚠️ Drift (DATABASE_AUDIT W4) |
| No CI/CD pipeline | **Confirmed** | ⚠️ Drift (PRODUCTION) |
| No Dockerfile | **Confirmed** | ⚠️ Drift (BACKEND_AUDIT W4) |
| No auth middleware | **Confirmed** | ⚠️ Drift (BACKEND_AUDIT W3) |
| Root README stale (Flutter 3.19.0) | **Confirmed** | ⚠️ Drift (DOCUMENTATION_AUDIT W1) |
| 4 active docs link into archive | **Confirmed** | ⚠️ Drift (DOCUMENTATION_AUDIT W2) |
| Docs migration plan pending | **Confirmed** | ⚠️ Drift (DOCUMENTATION_AUDIT W4) |

## 2. Missing Coverage (summary)

| Area | Coverage | Gap |
|---|---|---|
| Auth module tests | 0 | Critical security path untested |
| Backend tests | 0 | FastAPI + AI pipeline unverified |
| Golden/screenshot tests | 0 | No visual regression guard |
| Mechanic/Fuel/Marketplace/Home failure injection | 0 | No `failForFirstCalls` |
| Coverage measurement | 0 | No lcov/coverage gate |
| Backend CI/CD | 0 | No pipeline |
| Backend Dockerfile | 0 | No containerization |
| Backend auth | 0 | No JWT/Firebase middleware |
| Backend rate limiting | 0 | No throttling |
| Backend model versioning | 0 | No MLflow/experiment tracking |
| Backend seed data | 0 | No INSERT migrations |
| Backend updated_at trigger | 0 | No auto-update |
| Backend FK indexes | 0 | No explicit indexes |
| Backend pagination | 0 | No pagination |
| Backend localization | 0 | English only |
| Backend analytics | 0 | No analytics |
| Backend crash reporting | 0 | No Sentry/Crashlytics |
| Backend notifications | 0 | No FCM |
| Backend remote config | 0 | No |
| Backend feature flags | 0 | No |
| Backend monitoring/APM | 0 | No |
| Backend error tracking | 0 | No |
| App store readiness | 0 | No icons/splash verified |
| Accessibility | partial | Semantics + 44px tested; some gaps |
| Cert pinning | 0 | No |
| Partner onboarding | 0 | Sprint 4 |
| Admin dashboard | 0 | Sprint 5 |
| Payment gateway | partial | UPI listed, no real gateway |
| IP protection | 0 | No patents/trademarks |

## 3. PENDING Items (forward-looking, not in scope for v2.1)

| Item | Location | Status |
|---|---|---|
| Screenshots (0/54) | `08_screenshots/` | PENDING — no automatic capture possible |
| Handbook Version 2 enrichment | `docs/07_rc1_certification/` | PENDING — prepared in build workspace, applied later |
| Repository cleanup (Phase 6) | `docs/` structure | PENDING — migration plan approved, execution deferred |
| Git milestone (Phase 7) | repo root | PENDING — no commits without explicit approval |
| Sprint 2 backend integration | `backend/` | PENDING — blocked on audit P0 items |
| Production polish (Phase 9) | repo root | PENDING |

## 4. Summary

- **Consistent claims:** 24 (all core product/architecture/data facts verified)
- **Drift items:** 16 (all documented in the audit reports with P0–P2 priorities)
- **Missing coverage:** 29 areas (mostly backend/ops, deferred to Sprint 2+)
- **Pending:** 6 forward-looking items (screenshots, handbook v2, cleanup, git, Sprint 2, polish)

All drift items are traceable to the approved Phase 0 Engineering Audit reports.
</tool_call>