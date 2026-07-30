# Sprint D5 — Repository Hygiene Report

**Date:** 2026-07-29  
**Status:** ✅ Complete  

---

## Build Health

`flutter analyze` — **Clean**  
Zero errors, zero warnings (25 info-level only).

---

## Completed Tasks

| ID | Description | Status |
|----|------------|--------|
| B1 | Delete `reports/` (28 legacy files) and update sprint doc references | ✅ Done |
| B2 | Rename `lib/Starting_screen/` → `lib/starting_screen/`, `Login.dart` → `login.dart` | ✅ Done |
| B3 | Rename `lib/home/mock_data.dart` → `lib/home/home_data.dart` | ✅ Done |
| B5 | Move `ui_blueprint.html` → `docs/source/` | ✅ Done |
| B6 | Compress 9 oversized PNGs (>2 MB, saved ~1.73 MB) | ✅ Done |
| C1 | Add `venv/` to `.gitignore` | ✅ Done |
| C2 | Scan for unused assets | ✅ Done |

---

## Unused Assets Found (C2)

5 files, ~3 MB reclaimable:

| File | Size |
|------|------|
| `assets/fuelbg.jpg` | 1.4 MB |
| `assets/tr.jpg` | 1.37 MB |
| `assets/petrol.jpg` | 133 KB |
| `assets/logo.jpg` | 78 KB |
| `assets/mech.jpg` | 6 KB |

---

## Git Diff Summary

- **122 files changed**, 735 insertions, 151,486 deletions
- Net line reduction reflects D4 restructure (split doc removal) + D5 cleanup
- No breaking changes to imports or build

---

## Files Modified (D5 only)

| File | Change |
|------|--------|
| `.gitignore` | Added `venv/`, uncommented `.vscode/` |
| `docs/02_architecture/PROJECT_ARCHITECTURE.md` | Sprint table → relative paths |
| `docs/04_sprints/SPRINT_1_1.md` | Removed `reports/` link |
| `docs/04_sprints/SPRINT_1_2.md` | Removed `reports/` link |
| `docs/04_sprints/SPRINT_1_3.md` | Removed `reports/` link |
| `docs/04_sprints/SPRINT_1_4.md` | Removed `reports/` link |
| `docs/04_sprints/SPRINT_1_5.md` | Removed `reports/` link |
| `lib/starting_screen/login.dart` | Added (moved from `Starting_screen/Login.dart`, renamed) |
| `lib/starting_screen/home.dart` | Added (moved from `Starting_screen/home.dart`) |
| `lib/starting_screen/screens.dart` | Moved, import path updated |
| `lib/main.dart` | Import path updated |
| `lib/bottom_bar/bottom_navigation.dart` | Import path updated |
| `lib/home/home_data.dart` | Renamed from `mock_data.dart` |
| `lib/bottom_bar/OrderScreen.dart` | Import path updated |
| `lib/bottom_bar/chatboard.dart` | Import path updated |
| `lib/bottom_bar/profile_screen.dart` | Import path updated |
| `lib/homescreen/drawerscreen.dart` | Import path updated |
| `lib/homescreen/mechanic_screen.dart` | Import path updated |
| `lib/homescreen/petrol_page.dart` | Import path updated |
| `assets/battery.png` | Compressed (4.43 → 4.25 MB) |
| `assets/break pads.png` | Compressed (5.50 → 5.34 MB) |
| `assets/engine oil.png` | Compressed (4.00 → 3.80 MB) |
| `assets/helmet lock.png` | Compressed (4.29 → 4.06 MB) |
| `assets/radiator.png` | Compressed (4.34 → 4.07 MB) |
| `assets/side_mirror.png` | Compressed (2.58 → 2.33 MB) |
| `assets/spark plugs.png` | Compressed (5.66 → 5.50 MB) |
| `assets/tool kit.png` | Compressed (4.89 → 4.73 MB) |
| `assets/wipers.png` | Compressed (2.25 → 2.13 MB) |
