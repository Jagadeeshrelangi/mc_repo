# Sprint 1.7 — Fuel Delivery

**Version:** 1.0  
**Last Updated:** 2026-07-30  
**Status:** 🔄 In Progress (Sprint 1.7A complete)  
**Owner:** Engineering Team

---

## Sub-Sprints

| Sub-Sprint | Status | Description |
|------------|--------|-------------|
| 1.7A | ✅ Complete | Investigation + Foundation (models, repo, services, providers, home screen) |
| 1.7B | 🔲 Planned | Booking Flow, Live Tracking, Payment Integration |
| 1.7C | 🔲 Planned | Backend Integration, Partner App connectivity |

---

## Sprint 1.7A — Completed

### P1 — Blank Screen Fix
- **Root cause:** GPS hang with no timeout
- **Fix:** 10s location timeLimit + 12s Future.timeout + "Set Manually" fallback
- **Files:** `lib/homescreen/petrol_page.dart`

### P2 — Foundation
- Folder structure: `lib/features/fuel_delivery/`
- 9 models, 1 repository, 4 services, 3 providers, 1 screen, 7 widgets
- Error handling for: loading, error, no internet, no GPS, empty partners

### Verification
- `flutter analyze`: ✅ 0 errors, 0 warnings
- Report: `docs/05_reports/SPRINT_1_7A_REPORT.md`

---

## Sprint 1.7B — Planned Scope

- Fuel order booking screen (address, vehicle selection, confirm)
- Real-time tracking with map integration
- Order history detail view
- Invoice viewer
- Payment integration (Razorpay/UPI)
- Pull-to-refresh + polling for live status updates

---

## Related Documents

- [PROJECT_STATUS.md](../01_product/PROJECT_STATUS.md)
- [CHANGELOG.md](../03_development/CHANGELOG.md#120--2026-07-30--sprint-17a)
- [SPRINT_1_7A_REPORT.md](../05_reports/SPRINT_1_7A_REPORT.md)
- [Fuel Home Screen](../../lib/features/fuel_delivery/screens/fuel_home_screen.dart)
