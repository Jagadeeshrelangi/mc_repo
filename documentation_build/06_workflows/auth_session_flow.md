# Workflow: Auth & Session

> Modules: auth · splash/onboarding (starting_screen)

## Mermaid

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant S as SplashScreen
    participant A as AuthProvider
    participant AR as AuthRepository (local)
    participant PREFS as SharedPreferences

    S->>PREFS: read is_logged_in
    S->>S: 450ms fade decision
    alt is_logged_in
        S->>S: BottomNavigation (5-tab shell)
    else onboarding done
        S->>S: LoginScreen
    else first launch
        S->>S: OnboardingScreen
    end
    U->>A: login / signup / forgot password
    A->>AR: validate (email format, password >= 6, confirm match)
    A->>PREFS: set is_logged_in = true
    A->>A: push BottomNavigation
    U->>A: logout (Profile)
    A->>PREFS: set is_logged_in = false
    A->>A: pushAndRemoveUntil LoginScreen
```

## Narrative
1. Auth screens: Login / SignUp / ForgotPassword, linked to each other.
2. Google Sign-In is in the spec; at RC1 auth is local-only (SharedPreferences `is_logged_in`).
3. Splash route decision is the only entry gate; no dev flags remain.

## Decision / Failure / Recovery
- **Validation errors:** email format, password length ≥ 6, confirm-match.
- **Not authenticated:** session flag false → login screen after onboarding.
- **Logout:** confirm dialog → `pushAndRemoveUntil(LoginScreen)` — the only reverse path.

## Backend Notes (Sprint 2)
- Firebase Auth + JWT; `users.password_hash`; credentials never stored at RC1.
- `is_logged_in` remains an on-device flag for splash routing.
