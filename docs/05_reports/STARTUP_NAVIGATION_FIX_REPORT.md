# Startup Navigation Fix Report

**Date:** 2026-07-30  
**Status:** ✅ Fixed

---

## Startup Widget Sequence (Before Fix)

```
main.dart
  └── SplashScreen (main.dart:76)
       └── _navigateToNext() checks onboarding_completed in SharedPreferences
            └── always false (never saved) → OnboardingScreen
                 └── OnboardingScreen (starting_screen/screens.dart:6)
                      └── "Skip" or "Get Started" → _navigateToLogin()
                           └── UserLoginScreen (starting_screen/login.dart:9) ← OLD
                                └── Login success → BottomNavigation
```

## Startup Widget Sequence (After Fix)

```
main.dart
  └── SplashScreen
       └── _navigateToNext() checks onboarding_completed
            └── false (first launch) → OnboardingScreen
            |    └── "Skip" or "Get Started" → saves onboarding_completed=true
            |         └── LoginScreen (auth/login_screen.dart) ← NEW
            |              └── Login/Continue as Guest → saves onboarding_completed=true
            |                   └── BottomNavigation
            |
            └── true (subsequent launches) → LoginScreen (auth/login_screen.dart) ← NEW
                 └── Login/Continue as Guest → BottomNavigation
```

## Navigation Flow

```
START
  ↓
[SplashScreen] — 2.5s animation
  ↓ (SharedPreferences: onboarding_completed?)
  ├── false → [OnboardingScreen] — 3 slides (Fuel, Mechanic, AI)
  │               ↓ Skip / Get Started (saves onboarding_completed=true)
  │               ↓
  │               └── [LoginScreen] ← NEW (auth/login_screen.dart)
  │                      ↓ Login / Continue as Guest (saves onboarding_completed=true)
  │                      ↓
  │                      └── [BottomNavigation]
  │                             ├── Tab 0: HomeDashboard (home/home_screen.dart)
  │                             ├── Tab 1: ServiceSelectionScreen (starting_screen/home.dart)
  │                             ├── Tab 2: Orderscreen (bottom_bar/OrderScreen.dart)
  │                             ├── Tab 3: ChatBot (bottom_bar/chatboard.dart)
  │                             └── Tab 4: ProfileScreen (bottom_bar/profile_screen.dart)
  │
  └── true → [LoginScreen] ← NEW (auth/login_screen.dart)
               ↓ Login / Continue as Guest
               ↓
               └── [BottomNavigation]
```

## Root Cause

Three independent issues:

### Issue A — Wrong import in OnboardingScreen
**File:** `lib/starting_screen/screens.dart`
- Line 2 imported `package:mecha_connect/starting_screen/login.dart` (OLD `UserLoginScreen`)
- Line 46 navigated to `UserLoginScreen()` instead of `LoginScreen()` (NEW)

### Issue B — `onboarding_completed` never persisted
- `SplashScreen._navigateToNext()` reads `onboarding_completed` from SharedPreferences
- No screen in the entire codebase ever writes `true` to this key
- Result: splash ALWAYS shows onboarding on every launch

### Issue C — `lib/auth/` directory untracked
- The new `LoginScreen` at `lib/auth/login_screen.dart` existed on disk but was never committed to git
- All auth components (auth_scaffold, auth_header, auth_text_field, primary_button, social_button, etc.) were built but unreachable

## Files Modified

| File | Change |
|------|--------|
| `lib/starting_screen/screens.dart` | Import changed from `starting_screen/login.dart` → `auth/login_screen.dart`. Added SharedPreferences save of `onboarding_completed=true`. Navigation target changed from `UserLoginScreen()` → `LoginScreen()`. |
| `lib/auth/login_screen.dart` | Added SharedPreferences save of `onboarding_completed=true` in both `_handleLogin()` and `_continueAsGuest()`. |

## Why Legacy Screens Were Loading

- **OLD login** (`starting_screen/login.dart` → `UserLoginScreen`): Loaded because `OnboardingScreen` had a hardcoded import and navigation to it. The new `LoginScreen` in `auth/` was never wired into the navigation chain.
- **OLD onboarding** (the original `lib/screens.dart`): Had already been replaced by the current `starting_screen/screens.dart` in a prior refactor. The current `OnboardingScreen` IS the new version.

## Why Fuel Screen Was Blank

Separate root cause identified in Sprint 1.7A:
- `Geolocator.getCurrentPosition` with `LocationAccuracy.high` hangs indefinitely on devices without GPS
- No timeout was set, so `_fuelLocationStatus` remained `loading` forever
- Fix applied: 10s `LocationSettings.timeLimit` + 12s `Future.timeout` + "Set Manually" fallback button

## Flutter Analyze Result

```
0 errors, 0 warnings
25 info-level issues (all pre-existing: avoid_print in tests, file_names, etc.)
```
