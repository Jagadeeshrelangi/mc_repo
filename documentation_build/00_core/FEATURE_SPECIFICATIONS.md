# Mecha Connect — Feature Specifications

**Version:** 1.1  
**Status:** Locked  
**Last Updated:** 2026-07-29  
**Owner:** Product Team  

---

## 1. Feature: Splash Screen

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.1) |
| **File** | `lib/Starting_screen/screens.dart` |
| **States** | Idle (logo + breathing glow), Loading (auto-transition) |
| **Transitions** | Onboarding (first launch) or Home (returning user) |
| **Acceptance** | Warm gradient + logo center, orange breathing glow, 60 FPS, 85/85 QA |

### Details
- 3 AnimationControllers: glow opacity, scale, rotation
- 2 CustomPainters (glow ring, gradient background)
- Navigates to Onboarding (first run) or Home
- No text, no circle overlay, no texture

---

## 2. Feature: Onboarding

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.2) |
| **File** | `lib/Onboarding/` |
| **Screens** | 3 pages + Get Started button |
| **States** | Page 1 (Welcome), Page 2 (Features), Page 3 (Get Started) |

---

## 3. Feature: Authentication

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.2) |
| **File** | `lib/Auth/screens/` |
| **Methods** | Email/Password, Google Sign-In |
| **Validations** | Email format, password length ≥ 6, confirm match |

---

## 4. Feature: Home Dashboard

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.3) |
| **File** | `lib/home/home_screen.dart` |
| **Sections** | Quick Services Grid, Recent Bookings, Service History, Profile |
| **States** | Loading (skeleton), Loaded (cards), Empty (no bookings) |

---

## 5. Feature: Mechanic Booking

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.4–1.6) |
| **Files** | `lib/mechanic/` (9 screens, 7 widgets) |

### 5.1 Flow Steps
| Step | Screen | Purpose |
|------|--------|---------|
| 1 | Home → Mechanic | Entry point |
| 2 | Nearby List | Browse mechanics with distance |
| 3 | Mechanic Details | Rating, services, availability |
| 4 | Select Service | Choose from mechanic's menu |
| 5 | Booking Summary | Cost breakdown, confirm |
| 6 | Confirmation | ETA, mechanic info |
| 7 | Live Tracking | Map with mechanic marker |
| 8 | Service Complete | "Done" button trigger |
| 9 | Review | Rating + feedback |

### 5.2 States per Screen
| State | Behavior |
|-------|----------|
| Loading | Skeleton loaders for Featured + Nearby |
| Error | Retry button with message |
| Empty | "No mechanics found" illustration |
| Denied Location | Permission request dialog |
| GPS Disabled | Settings redirect prompt |
| Ready | Full UI |

### 5.3 Live Tracking States
| State | UI |
|-------|----|
| Connecting | Spinner overlay |
| Searching | "Finding nearest mechanic..." |
| Assigned | Mechanic name + ETA + map |
| En Route | Moving marker, progress bar |
| Arrived | "Mechanic has arrived" banner |
| In Progress | Timer + status |
| Service Completed | "Service Completed" button (line 273+) |

---

## 6. Feature: Vehicle Service Request

| Property | Value |
|----------|-------|
| **Priority** | P1 |
| **Status** | ✅ Done (Sprint 1.5) |
| **File** | `lib/vehicle_service/` |
| **Sub-features** | Vehicle Registration, Service History |
| **Media** | Camera/Gallery attachment supported |

---

## 7. Feature: Dark Mode

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.3) |
| **File** | `lib/core/theme/` |
| **Toggle** | Settings screen |
| **Persistence** | Hive/shared_preferences |

---

## 8. Feature: Responsive Layout

| Property | Value |
|----------|-------|
| **Priority** | P0 |
| **Status** | ✅ Done (Sprint 1.6.2) |
| **Files** | `lib/core/utils/responsive.dart`, `ConstrainedContent` widget |
| **Breakpoints** | mobile < 600px, tablet 600–1024px, desktop >= 1024px |
| **Behavior** | ConstrainedContent on all screens, AppResponsive scaling |

---

## 9. Feature: Spare Parts Marketplace

| Property | Value |
|----------|-------|
| **Priority** | P2 |
| **Status** | 🔲 Partial (UI scaffolds) |
| **Files** | `lib/parts/parts_screen.dart`, `lib/parts/cart_screen.dart`, `lib/parts/order_data.dart` |
| **Widgets** | `product_card.dart`, `cart_item_card.dart`, `marketplace_card.dart` |
| **Details** | Parts listing, cart screen, order data models. Product display and cart UI exist but no backend. |

---

## 10. Backend Integration (Upcoming)

| Property | Value |
|----------|-------|
| **Priority** | P1 |
| **Status** | 🔲 Planned (Sprint 2) |
| **Stack** | FastAPI + PostgreSQL + Redis |
| **Auth** | Firebase Auth + JWT |

---

## 11. Related Documents

- [PRODUCT_REQUIREMENTS_DOCUMENT.md](PRODUCT_REQUIREMENTS_DOCUMENT.md)
- [UI_DESIGN_SYSTEM.md](../02_architecture/UI_DESIGN_SYSTEM.md)
- [API_CONTRACT.md](../04_api/API_CONTRACT.md)
- [TEST_PLAN.md](TEST_PLAN.md)

