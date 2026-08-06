# Mecha Connect — Release Notes RC1

**Release:** RC1 · Frontend Lock Candidate
**Version:** 1.0.0 (build 1) · Handbook 1.9.2
**Date:** 2026-08-05
**Platform:** Android (Flutter 3.29.2) · iOS not configured at RC1

---

## 1. About This Release

RC1 is the **feature-complete, frozen Flutter frontend** of Mecha Connect —
the AI-powered roadside assistance and vehicle services platform. It is a
release candidate for certification and for Sprint 2 backend integration, not
a production deployment: all data comes from realistic in-memory mock
repositories that simulate production latency and failure.

## 2. What's In This Release

- **Home dashboard** — greeting, vehicle health, quick services, nearby
  services, marketplace teaser, offers, search.
- **Mechanic booking** — complete 9-step flow with live tracking and ratings.
- **Fuel delivery** — station selection, quantity, price estimate, payment,
  live tracking, invoice/receipt, history.
- **Spare parts marketplace** — 40-product catalog, 10 categories, 15 brands,
  cart, checkout, wishlist, coupons, orders.
- **AI assistant** — chat, structured diagnosis with cost estimates, history
  (pin/rename/delete), cross-module actions.
- **Profile** — profile, vehicles, addresses, wallet (₹1,200 balance, 2,450
  reward points), rewards, notification settings, privacy, support.
- **Unified Orders tab** — parts / mechanic / fuel / AI feed from one store.
- **Vehicle location** — GPS with denied/disabled fallback to manual entry.
- **Dark mode** and **responsive layout** (mobile/tablet/desktop).

## 3. Verification Evidence

| Gate | Result |
|---|---|
| `flutter analyze` | **No issues found!** (0 errors, 0 warnings) |
| `flutter test` | **162 / 162 passing** |
| Runtime audit | 0 P0/P1/P2 defects |
| Module walkthrough | All modules PASS |
| Accessibility + responsive | PASS — all safe fixes applied |
| Frontend freeze | Locked per `FRONTEND_LOCK_REPORT.md` |

## 4. Known Limitations

- All data is mock/in-memory; no live backend yet.
- Live tracking and GPS behavior are simulated.
- Coupons are not server-validated; login state is on-device.
- Home teaser cards are intentional static placeholders.
- Accepted brand contrast limits and P3 visual debt (see handbook Ch. 20).

## 5. Sprint 2 Preview

The frozen repository seams and API contract mean Sprint 2 (FastAPI +
PostgreSQL, Firebase Auth + JWT, Gemini AI, real maps) integrates with zero UI
changes.

## 6. How to Run

```bash
flutter pub get
flutter run                     # debug on an attached device/emulator
flutter run -d chrome           # web with Device Preview
flutter test                    # full suite (162)
```

See `docs/03_development/INSTALLATION.md` and `DEPLOYMENT.md`.
