# Module Knowledge: Auth (`lib/features/auth/`)

> Phase 5 · Pre-shell. Source: FRONTEND_ARCHITECTURE §5.6, API_CONTRACT §3, FEATURE_SPECIFICATIONS §3.

## Purpose
Login / SignUp / ForgotPassword gates. Local-only session at RC1
(SharedPreferences `is_logged_in`); no credential storage.

## Inventory
| Layer | Items |
|---|---|
| Models | none (dead `user.dart` removed in 1.9b) |
| Provider | `AuthProvider` (`AuthService(AuthRepository())` — root graph #3) |
| Repositories | `AuthRepository` |
| Services | `AuthService` |
| Screens (3) | `LoginScreen`, `SignUpScreen`, `ForgotPasswordScreen` |
| Widgets (1) | password strength indicator |

## Key Behavior
- Validation: email format, password length ≥ 6, confirm-match.
- Google Sign-In listed in spec (not yet wired).
- Success → push `BottomNavigation`; logout is the only reverse path
  (`pushAndRemoveUntil(LoginScreen)`).

## Tests
Covered by `widget_test.dart` + integration; splash decision in vehicle_location test coverage area.

## Backend Relation (Sprint 2)
Firebase Auth + JWT; `users.password_hash`; `is_logged_in` stays an on-device flag.
