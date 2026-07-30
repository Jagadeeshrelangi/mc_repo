# Older Repository Investigation Report

**Date:** 2026-07-30  
**Repository:** `https://github.com/Jagadeeshrelangi/mecha_connect` (forked from `Mohannakka04/mecha_connect`)  
**Status:** Complete — Not Found

---

## Comparison: mecha_connect (older) vs mc_repo (current)

| Aspect | `mecha_connect` (older) | `mc_repo` (current) |
|--------|------------------------|---------------------|
| Commits | 11 (no 7543ca4, no b4a3dc2) | 13 (includes 2 new commits) |
| `screens.dart` | 3 slides, placeholder URLs, raw `Colors.blue` | Current 4-slide premium |
| `main.dart` | Basic splash (fade+scale, 3s, no premium) | Premium splash (grid painter, stagger, brand message) |
| Login | Old `UserLoginScreen` in `Starting_screen/` | New `LoginScreen` in `auth/` |
| Theme | Inline `AppColors` in `main.dart` | Separate `lib/theme/app_colors.dart` |
| Responsive | None | `lib/theme/app_responsive.dart` |
| Design blueprint | None | `ui_blueprint.html` |
| QA docs | None | `SPLASH_SCREEN_QA.md` |
| `auth/` directory | Does not exist | Exists with new login |
| `features/` directory | Does not exist | Exists (fuel delivery) |
| `docs/` directory | Does not exist | Exists |
| `lib/theme/` directory | Does not exist | Exists |

---

## Searches in Older Repository

### Git log searches (`git log --all -S`)

| Search String | Found? |
|---|---|
| `"Your Smart Vehicle Companion"` | ❌ Never |
| `"Roadside Help in Minutes"` | ❌ Never |
| `"Everything Your Vehicle Needs"` | ❌ Never |
| `"Ready to Drive Smarter?"` | ❌ Never |
| `"Continue as Guest"` | ❌ Never |
| `onboarding_completed` | ❌ Never |
| `SharedPreferences` | ❌ Never |
| `BackdropFilter` / `glass` | ❌ Never |

### File Content Searches

- `lib/Starting_screen/screens.dart` — 3 slides (`Fuel On-Demand`, `Instant Mechanic Help`, `Genuine Parts Delivery`) with `placeholder.com` URLs and raw `Colors.blue.shade400`
- `lib/Starting_screen/Login.dart` — Old `UserLoginScreen` with hardcoded credentials list, no SharedPreferences, no "Continue as Guest"
- `lib/main.dart` — Basic splash, inline `AppColors` class, no premium animations

### Files Present (13 .dart files)

```
lib/main.dart
lib/Starting_screen/screens.dart
lib/Starting_screen/Login.dart
lib/Starting_screen/home.dart
lib/bottom_bar/bottom_navigation.dart
lib/bottom_bar/chatboard.dart
lib/bottom_bar/OrderScreen.dart
lib/homescreen/drawerscreen.dart
lib/homescreen/mechanic_screen.dart
lib/homescreen/petrol_page.dart
lib/parts/cart_screen.dart
lib/parts/order_data.dart
lib/parts/parts_screen.dart
```

No `lib/auth/`, no `lib/theme/`, no `lib/features/`, no `lib/starting_screen/` (lowercase).

---

## Conclusion

**The premium 4-page onboarding does not exist in the older `mecha_connect` repository either.**

The older repo is the **ancestor** of the current `mc_repo`. It only contains the original 3-slide placeholder onboarding with `placeholder.com` image URLs — the same version found in the early commits of `mc_repo`. The entire premium codebase (splash, theme system, dark mode, new login, responsive utilities, fuel delivery, `ui_blueprint.html`) was added to `mc_repo` in the later commits (`7543ca4` and `b4a3dc2`) that don't exist in the older repo.

The screenshots showing 4 premium onboarding pages with "Your Smart Vehicle Companion", "Roadside Help in Minutes", "Everything Your Vehicle Needs", "Ready to Drive Smarter?" and "Continue as Guest" must be from a **design mockup (Figma/XD/design tool)** that was never translated into Flutter code in either repository.
