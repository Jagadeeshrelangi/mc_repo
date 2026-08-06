# UI/UX Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: every screen — layout, design, responsive, typography, color, component reuse, navigation flow, accessibility, states, animations.

## 1. Current State

### 1.1 Screen inventory (50 screens)
| Module | Screens | Count |
|---|---|---|
| AI | ai_home, chat, conversation_detail, conversation_history, diagnosis | 5 |
| Auth | login, sign_up, forgot_password | 3 |
| Fuel | fuel_home, fuel_booking, live_tracking, order_complete, order_confirmation, order_history, payment, receipt | 8 |
| Home | home_screen, home_search | 2 |
| Marketplace | marketplace_home, product_detail, category, search, cart, checkout, wishlist, order_success | 8 |
| Mechanic | mechanic_home, nearby_mechanics, mechanic_details, select_service, vehicle_form, booking_summary, booking_confirmation, live_tracking, job_completed, rating_review, booking_history | 11 |
| Profile | profile, edit_profile, my_vehicles, vehicle_detail, saved_addresses, wallet, rewards, order_history, notification_settings, privacy_security, support, about | 12 |
| Shell | splash, onboarding, service_selection, orders_tab | 4 |

### 1.2 Design system
- **Theme:** Material 3, `ColorScheme.fromSeed(brandOrange)`, light + dark.
- **Typography:** Space Grotesk (display/headline) + Inter (body) — 13 text styles.
- **Colors:** `app_colors.dart` — brandOrange (#F15A22), brandBlue, grey scale, dark palette (#0E1117).
- **Spacing:** `app_spacing.dart` — consistent 4/8/12/16/24/32 scale.
- **Responsive:** `app_responsive.dart` — breakpoints 600/1024, clamped scaling, `ConstrainedContent` wrapper.
- **Shared widgets:** `widgets/` (loading, location header/banner/picker, order card) + per-module widgets.

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **Consistent design tokens** | All modules consume `ThemeHelpers` context extensions (`context.cardBg`, `context.accent`, etc.) — no hardcoded colors in screens |
| S2 | **Full dark mode** | `AppTheme.dark` mirrors light; `ThemeProvider` persists `theme_mode` |
| S3 | **Responsive system** | `AppResponsive` breakpoints + `ConstrainedContent` max-width wrapper for large screens |
| S4 | **Complete state handling** | Every module has loading (skeleton/shimmer), error (retry), empty states |
| S5 | **Accessibility semantics** | `RatingStars` merges to single semantics; tooltips on icon buttons; ≥44px touch targets (verified by tests) |
| S6 | **Consistent transitions** | Fade-through 220ms routes across AI/Marketplace/Profile |
| S7 | **Premium splash** | Layered gradient + radial light + breathing glow — polished brand intro |
| S8 | **Staggered animations** | Service selection uses staggered fade-in; splash uses timed animation sequence |
| S9 | **Pull-to-refresh everywhere** | All list screens support `RefreshIndicator` with last-known-good state preservation |
| S10 | **Empty/error states per module** | Marketplace has `marketplace_empty_state`/`marketplace_error_view`; AI has `empty_state`/`error_state`; Profile has `profile_empty`/`profile_error` |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **No golden/screenshot tests** | P2 | 0/54 screenshot captures; no golden tests. Visual regression is unguarded. |
| W2 | **`fontFamily: 'Inter'` not bundled** | P1 | `pubspec.yaml` has NO `fonts:` section. `AppTheme` sets `fontFamily: 'Inter'` and `'Space Grotesk'` but neither font is declared as an asset. On devices without these fonts, Flutter falls back to Roboto — the design system silently degrades. |
| W3 | **`ServiceSelectionScreen` is 912 lines** | P2 | Single file with staggered animations + all service cards + drawer. Should be split into widgets. |
| W4 | **`SplashScreen` is 388 lines in `main.dart`** | P2 | Splash + painters + animation logic all in `main.dart`. Should be a separate file. |
| W5 | **`OnboardingScreen` hardcodes `_lightBg`** | P3 | `static const Color _lightBg = Color(0xFFFEF7FF)` — bypasses the theme system. |
| W6 | **No localization** | P2 | English-only hardcoded strings. No `intl`/`l10n`. Excludes non-English users (India has 22 official languages). |
| W7 | **No semantic labels on some icon-only buttons** | P2 | Some icon buttons rely on tooltips only; screen readers need `Semantics` labels. |
| W8 | **`DevicePreview` in debug** | P3 | Adds a debug banner/overlay in dev builds — acceptable, but should be stripped in release. |
| W9 | **No loading skeletons for Home** | P3 | Home uses `home_loading_skeleton` — actually present. (Corrected: present.) |
| W10 | **`ordersList` renders untyped maps** | P1 | Orders tab renders `Map<String, dynamic>` — no typed `OrderEntry` model, so UI can't validate fields at compile time. |

## 4. Accessibility Audit

| Aspect | Finding | Severity |
|---|---|---|
| Touch targets | ≥44px verified by tests (ProductCard buttons) | ✅ Good |
| Semantics | RatingStars merged; tooltips present | ⚠️ Partial |
| Screen reader labels | Some icon-only buttons lack explicit `Semantics` | P2 |
| Text scaling | `AppResponsive.scaleFont` clamps 0.88–1.2 — may not respect system font scaling | P2 |
| Color contrast | Brand orange on white — needs verification for AA | P2 |
| Dark mode | Full implementation | ✅ Good |
| Focus indicators | Default Material focus — not customized | P3 |

## 5. Responsive Audit

| Aspect | Finding | Severity |
|---|---|---|
| Breakpoints | 600 (tablet) / 1024 (desktop) | ✅ Good |
| Grid columns | 2/3/4 responsive | ✅ Good |
| Content max-width | 480px on large screens | ✅ Good |
| Clamped scaling | `scale` 0.85–1.3, `scaleFont` 0.88–1.2 | ⚠️ May fight system text scaling |
| Landscape | Not explicitly tested | P3 |
| Web | `flutter build web` passes | ✅ Good |

## 6. State Handling Audit

| State | Coverage | Detail |
|---|---|---|
| Loading | ✅ All modules | Skeletons/shimmer/loading widgets |
| Error | ✅ All modules | Retry views with error message |
| Empty | ✅ Most modules | Marketplace, AI, Profile, Fuel have empty states |
| Refresh | ✅ All list screens | Pull-to-refresh with last-known-good |
| Failure injection | ⚠️ Partial | Ai/Profile/Marketplace have `failForFirstCalls`; Mechanic/Fuel don't |

## 7. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Fonts not bundled → design degradation | P1 | Add `fonts:` section to pubspec with Inter + Space Grotesk assets |
| R2 | No visual regression tests | P2 | Add golden tests or screenshot CI in Sprint 3 |
| R3 | No localization | P2 | Add `flutter_localizations` + `intl` in Sprint 3 |
| R4 | System font scaling conflict | P2 | Use `MediaQuery.textScaler` instead of custom clamp |

## 8. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | Fonts not declared in pubspec | P1 | 30 min |
| TD2 | `ServiceSelectionScreen` 912 lines | P2 | 3 hr |
| TD3 | `SplashScreen` in `main.dart` | P2 | 1 hr |
| TD4 | No localization | P2 | 2 days |
| TD5 | No golden tests | P2 | 1 day |

## 9. Recommendations

1. **P1 — Bundle fonts**: Add `fonts:` section to `pubspec.yaml` with Inter + Space Grotesk. This is the highest-impact UI fix.
2. **P2 — Split `ServiceSelectionScreen`** into feature widgets.
3. **P2 — Extract `SplashScreen`** from `main.dart` into `starting_screen/splash_screen.dart`.
4. **P2 — Add localization** in Sprint 3 (Hindi + Telugu first, given target market).
5. **P2 — Add golden tests** for key screens in Sprint 3.
6. **P2 — Use `MediaQuery.textScaler`** instead of custom font clamp.
7. **P3 — Add `Semantics` labels** to remaining icon-only buttons.

## 10. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 0 | — |
| P1 | 2 | W2 (fonts), W10 (untyped orders), R1, TD1 |
| P2 | 7 | W1, W3, W4, W6, W7, R2, R3, R4, TD2, TD3, TD4, TD5 |
| P3 | 3 | W5, W8, W9 |