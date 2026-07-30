# Mecha Connect — Project Architecture & Development Blueprint

**Version:** 1.1.0  
**Status:** Living Document  
**Project Type:** Startup MVP  
**Last Updated:** 2026-07-29  
**Owner:** Architecture Team  

---

## Table of Contents

1. [Project Vision](#1-project-vision)
2. [Product Ecosystem](#2-product-ecosystem)
3. [Development Roadmap](#3-development-roadmap)
4. [Folder Structure](#4-folder-structure)
5. [Design System](#5-design-system)
6. [Responsive Strategy](#6-responsive-strategy)
7. [Coding Standards](#7-coding-standards)
8. [Sprint Rules](#8-sprint-rules)
9. [Quality Checklist](#9-quality-checklist)
10. [Customer Application Modules](#10-customer-application-modules)
11. [Partner Application Modules](#11-partner-application-modules)
12. [Admin Dashboard](#12-admin-dashboard)
13. [Backend](#13-backend)
14. [AI Roadmap](#14-ai-roadmap)
15. [Database Roadmap](#15-database-roadmap)
16. [API Roadmap](#16-api-roadmap)
17. [Navigation Tree](#17-navigation-tree)
18. [Dependencies](#18-dependencies)
19. [Known Issues](#19-known-issues)
20. [Change Log](#20-change-log)
21. [Related Documents](#21-related-documents)

---  

---

# IMPORTANT

This document is the **single source of truth** for the Mecha Connect project.

Every sprint MUST update this document.

No feature should be implemented without following this architecture.

---

# 1. Project Vision

Mecha Connect is an AI-powered roadside assistance ecosystem connecting vehicle owners, mechanics, fuel partners, spare part sellers, and administrators through a unified platform.

Primary Goal:

> Become the "Uber + Swiggy + AI Assistant" for vehicle services.

---

# 2. Product Ecosystem

```
Customer App       Partner App       Admin Dashboard
(Mecha Connect)    (Mecha Partner)   (Web Portal)
       |                 |                  |
       └─────────────────┼──────────────────┘
                         ▼
                  FastAPI Backend
                         │
               ┌─────────┼─────────┐
               ▼         ▼         ▼
            PostgreSQL  Firestore  AI Services
            (PostGIS)   (Real-time)(Gemini/FAISS)
```

---

# 3. Development Roadmap

## Sprint 1 — Frontend UI

| Sprint | Module | Status |
|--------|--------|--------|
| 1.1 | Splash Screen | ✅ Completed |
| 1.2 | Onboarding | ✅ Completed |
| 1.3 | Authentication | ✅ Completed |
| 1.4 | Registration & Core UI | ✅ Completed |
| 1.5 | Core Application UI Polish | ✅ Completed |
| 1.6 | Mechanic Booking Module <br/>*(incl. bug fixes, responsive, consolidation, QA)* | ✅ Completed |
| 1.7 | Fuel Delivery | 🔲 Pending |
| 1.8 | Marketplace (Spare Parts) | 🔲 Pending |
| 1.9 | AI Assistant | 🔲 Pending |

## Sprint 2 — Backend Integration

| Module | Status |
|--------|--------|
| FastAPI Backend | 🔲 Pending |
| Database Migration | 🔲 Pending |
| API Contract Implementation | 🔲 Pending |
| Auth Integration | 🔲 Pending |

## Sprint 3 — Production Polish

| Module | Status |
|--------|--------|
| Performance Optimization | 🔲 Pending |
| Error Handling | 🔲 Pending |
| Testing | 🔲 Pending |
| Accessibility | 🔲 Pending |

## Sprint 4 — Partner Application

| Module | Status |
|--------|--------|
| Mecha Partner App | 🔲 Pending |

## Sprint 5 — Admin Dashboard

| Module | Status |
|--------|--------|
| Admin Web Portal | 🔲 Pending |

---

# 4. Folder Structure

```
lib/
├── auth/                           # Authentication screens & logic
│   ├── login_screen.dart
│   ├── sign_up_screen.dart
│   ├── forgot_password_screen.dart
│   ├── auth_divider.dart
│   ├── auth_header.dart
│   ├── auth_scaffold.dart
│   ├── auth_text_field.dart
│   ├── bottom_link.dart
│   ├── password_field.dart
│   ├── password_strength.dart
│   ├── primary_button.dart
│   └── social_button.dart
├── home/                           # Home screen
│   ├── home_screen.dart
│   ├── mock_data.dart
│   └── widgets/
│       ├── ai_assistant_card.dart
│       ├── emergency_card.dart
│       ├── home_header.dart
│       ├── location_card.dart
│       ├── marketplace_card.dart
│       ├── nearby_service_card.dart
│       ├── offer_banner.dart
│       ├── quick_service_card.dart
│       ├── recent_activity_card.dart
│       ├── search_bar_widget.dart
│       ├── section_title.dart
│       └── vehicle_card.dart
├── mechanic/                       # Mechanic booking module (canonical)
│   ├── mock_data.dart
│   ├── screens/
│   │   ├── mechanic_home_screen.dart
│   │   ├── mechanic_details_screen.dart
│   │   ├── nearby_mechanics_screen.dart
│   │   ├── select_service_screen.dart
│   │   ├── booking_summary_screen.dart
│   │   ├── booking_confirmation_screen.dart
│   │   ├── live_tracking_screen.dart
│   │   ├── job_completed_screen.dart
│   │   └── rating_review_screen.dart
│   └── widgets/
│       ├── mechanic_card.dart
│       ├── service_chip.dart
│       ├── primary_action_button.dart
│       ├── booking_summary_card.dart
│       ├── invoice_card.dart
│       ├── review_star.dart
│       └── timeline_tile.dart
├── homescreen/                     # Legacy & vehicle request
│   ├── mechanic_screen.dart        # VehicleFormPage (AI diagnosis)
│   ├── petrol_page.dart
│   ├── screens.dart
│   └── drawer.dart
├── bottom_bar/                     # Main navigation
│   ├── bottom_navigation.dart
│   ├── OrderScreen.dart
│   ├── chatboard.dart
│   └── profile_screen.dart
├── Starting_screen/                # Splash & onboarding
│   ├── home.dart
│   ├── Login.dart
│   └── screens.dart
├── parts/                          # Spare parts marketplace
│   ├── parts_screen.dart
│   ├── cart_screen.dart
│   └── order_data.dart
├── theme/                          # Design system
│   ├── app_colors.dart
│   ├── app_spacing.dart
│   ├── app_responsive.dart
│   ├── app_theme.dart
│   ├── app_theme_helpers.dart
│   ├── app_typography.dart
│   └── theme_provider.dart
├── widgets/                        # Shared reusable widgets
│   ├── app_avatar.dart
│   ├── app_badge.dart
│   ├── app_bottom_sheet.dart
│   ├── app_button.dart
│   ├── app_card.dart
│   ├── app_chip.dart
│   ├── app_dialog.dart
│   ├── app_empty_state.dart
│   ├── app_error_state.dart
│   ├── app_input.dart
│   ├── app_loading.dart
│   ├── cart_item_card.dart
│   ├── category_chip.dart
│   ├── chat_bubble.dart
│   ├── chat_input.dart
│   ├── conversation_card.dart
│   ├── diagnosis_card.dart
│   ├── fuel_provider_card.dart
│   ├── fuel_quantity_selector.dart
│   ├── image_gallery.dart
│   ├── invoice_card.dart
│   ├── location_header.dart
│   ├── location_picker_sheet.dart
│   ├── location_search_delegate.dart
│   ├── notification_card.dart
│   ├── order_card.dart
│   ├── price_breakdown_card.dart
│   ├── price_summary_card.dart
│   ├── product_card.dart
│   ├── profile_stat_card.dart
│   ├── pulsing_marker.dart
│   ├── quick_action_card.dart
│   ├── rating_widget.dart
│   ├── settings_tile.dart
│   ├── severity_badge.dart
│   ├── sos_button.dart
│   ├── thinking_indicator.dart
│   ├── timeline_tile.dart
│   ├── tracking_timeline.dart
│   ├── typing_indicator.dart
│   ├── vehicle_card.dart
│   ├── vehicle_report_card.dart
│   ├── wallet_card.dart
│   └── wishlist_button.dart
├── services/                       # API & backend services
│   ├── ai_repository.dart
│   ├── api_client.dart
│   └── location_provider.dart
└── main.dart
```

---

# 5. Design System

| Element | Value |
|---------|-------|
| Primary Color | `#F15A22` (Brand Orange) |
| Secondary | `#FFFFFF` (White) |
| Accent | `#4285F4` (Blue) |
| Error | `#EF4444` (Red) |
| Success | `#10B981` (Green) |
| Display Font | Space Grotesk |
| Body Font | Inter |
| Material 3 | Enabled |
| Rounded Corners | 14–22px |
| Elevation | Soft shadows |
| Icons | Material Symbols Rounded |

See `DESIGN_SYSTEM.md` for complete documentation.

---

# 6. Responsive Strategy

| Device | Width | Strategy |
|--------|-------|----------|
| Mobile | < 600px | Primary target, single column |
| Tablet | 600–1024px | Two-column, larger touch targets |
| Desktop | >= 1024px | Constrained max-width 480px content |

Implemented via `AppResponsive` utilities: `scale()`, `scaleFont()`, `horizontalPadding()`, `ConstrainedContent`.

---

# 7. Coding Standards

Every feature must:
- Use reusable widgets
- Avoid duplicated code
- Use feature-first architecture
- Maintain Material 3
- Follow responsive guidelines
- Use meaningful file names
- Use const constructors where possible
- Pass `dart analyze`
- Build successfully
- Generate Sprint Report

---

# 8. Sprint Rules

Every sprint must:
1. Implement feature
2. Run application
3. Perform runtime verification
4. Fix bugs
5. Run analyzer
6. Run build
7. Generate Sprint Report
8. Update this document
9. Only then mark sprint **LOCKED**

---

# 9. Quality Checklist

- [ ] No RenderFlex overflow
- [ ] No dead buttons
- [ ] No unreachable screens
- [ ] No duplicate widgets
- [ ] No duplicate navigation
- [ ] Responsive layout
- [ ] Accessible
- [ ] Analyzer clean
- [ ] Build successful

---

# 10. Customer Application Modules

| Module | Status |
|--------|--------|
| Home | ✅ Completed |
| Services | ✅ Completed |
| Orders | ✅ Completed |
| Mechanic Booking | ✅ Completed |
| Fuel Delivery | 🔲 Pending |
| Marketplace | 🔲 Pending |
| AI Assistant | ✅ Partially (diagnosis) |
| Notifications | 🔲 Pending |
| Profile | ✅ Completed |
| Wallet | 🔲 Pending |
| Settings | ✅ Completed |
| Search | 🔲 Pending |

---

# 11. Partner Application Modules (Future)

- Partner Login
- Online Status
- Accept Jobs
- Navigation
- Job Progress
- Invoice
- Payments
- Earnings
- Reviews
- History

---

# 12. Admin Dashboard (Future)

- Users
- Partners
- Fuel Partners
- Marketplace
- Orders
- Payments
- Analytics
- Support
- Reports
- AI Monitoring

---

# 13. Backend (Sprint 2)

| Service | Status |
|---------|--------|
| FastAPI Server | 🟡 Scaffolded |
| Authentication | 🔲 |
| Vehicles API | 🔲 |
| Mechanics API | 🔲 |
| Fuel API | 🔲 |
| Marketplace API | 🔲 |
| Orders API | 🔲 |
| Payments API | 🔲 |
| Notifications API | 🔲 |
| AI Inference | 🟡 Running (local) |
| Analytics API | 🔲 |

---

# 14. AI Roadmap

| Feature | Status |
|---------|--------|
| Vehicle Diagnosis (XGBoost/Rules) | ✅ Completed |
| RAG Knowledge Base (FAISS) | ✅ Completed |
| Gemini Chat Integration | ✅ Completed |
| Voice Assistant | 🔲 Pending |
| Predictive Maintenance | 🔲 Pending |
| Smart Recommendations | 🔲 Pending |
| OCR / Image Analysis | 🔲 Pending |
| Chat Assistant | 🔲 Pending |

---

# 15. Database Roadmap

| Collection/Table | Status |
|------------------|--------|
| Users | 🔲 |
| Vehicles | 🔲 |
| Mechanics | 🔲 |
| Fuel Partners | 🔲 |
| Products | 🔲 |
| Orders | 🔲 |
| Bookings | 🔲 |
| Invoices | 🔲 |
| Reviews | 🔲 |
| Notifications | 🔲 |

Currently using mock data in `lib/mechanic/mock_data.dart`.

---

# 16. API Roadmap

| Endpoint Group | Status |
|----------------|--------|
| Authentication | 🔲 |
| Vehicle | 🔲 |
| Mechanic | 🔲 |
| Fuel | 🔲 |
| Marketplace | 🔲 |
| Orders | 🔲 |
| Payments | 🔲 |
| Notifications | 🔲 |
| AI / Chat | 🟡 `POST /api/v1/conversation/chat` |
| Admin | 🔲 |

See `API_SPEC.md` for complete endpoint documentation.

---

# 17. Navigation Tree

```
App Launch
├── Splash Screen
│   └── Onboarding (first launch only)
│       └── Login / Register
│           └── Main Bottom Navigation
│               ├── Home Tab
│               │   ├── Vehicle Service Request (VehicleFormPage)
│               │   │   ├── AI Diagnosis → MechanicHomeScreen
│               │   │   └── Direct → MechanicHomeScreen
│               │   ├── Service Categories
│               │   └── Emergency Banner
│               ├── Orders Tab
│               ├── Chat Tab
│               │   └── AI Chat Assistant
│               └── Profile Tab

Mechanic Booking Flow (Sprint 1.6)
┌─ MechanicHomeScreen
│  ├── Category Chip → NearbyMechanicsScreen (filtered)
│  ├── Featured Mechanic Card → MechanicDetailsScreen
│  ├── Nearby Mechanic Card → MechanicDetailsScreen
│  ├── View All → NearbyMechanicsScreen
│  └── Search (placeholder)
│
├─ MechanicDetailsScreen
│  └── Book Mechanic → SelectServiceScreen
│
├─ SelectServiceScreen
│  └── Continue → BookingSummaryScreen
│
├─ BookingSummaryScreen
│  └── Confirm Booking → BookingConfirmationScreen
│
├─ BookingConfirmationScreen
│  └── Track Mechanic → LiveTrackingScreen
│
├─ LiveTrackingScreen
│  ├── Call Mechanic (Snackbar)
│  ├── Chat Mechanic (placeholder)
│  ├── Cancel Booking → Home
│  └── Service Completed → JobCompletedScreen
│
├─ JobCompletedScreen
│  └── Leave Review → RatingReviewScreen
│
└─ RatingReviewScreen
   └── Submit → Home
```

---

# 18. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK ^3.7.2 | UI Framework |
| flutter_map | ^7.0.0 | Map component |
| latlong2 | ^0.9.1 | Lat/lng coordinate handling |
| geolocator | ^13.0.2 | Device GPS location |
| permission_handler | ^11.3.1 | Runtime permissions |
| flutter_map_tile_caching | ^10.0.0 | Offline map tiles |
| flutter_map_cancellable_tile_provider | ^3.0.0 | Map tile lifecycle |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| google_nav_bar | ^5.0.7 | Bottom navigation bar |
| device_preview | ^1.2.0 | On-device preview/testing |
| flutter_dotenv | ^5.2.1 | Environment variables |
| http | ^1.6.0 | HTTP client |
| provider | ^6.1.2 | State management |
| shared_preferences | ^2.2.3 | Local storage |

---

# 19. Known Issues

| Bug | Priority | Status | Sprint |
|-----|----------|--------|--------|
| Chat feature shows placeholder snackbar | Low | Open | Sprint 1.7+ |
| SOS emergency flow needs polish | Medium | Open | Sprint 1.7+ |
| Wallet UI not implemented | Low | Open | Sprint 1.7+ |
| Images use placeholder icons (no real camera) | Low | Open | Sprint 1.7+ |
| Search is read-only (no results) | Low | Open | Sprint 1.7+ |

---

# 20. Change Log

| Version | Date | Summary |
|---------|------|---------|
| 1.1.0 | 2026-07-29 | Sprint D1 — Documentation audit, sync, Mermaid diagrams |
| 0.6.0 | 2026-07-29 | Sprint 1.6 — Mechanic Booking (incl. bugs, responsive, consolidation, QA) |
| 0.5.0 | 2026-07-28 | Sprint 1.6.2 — Responsive Layout |
| 0.4.0 | 2026-07-28 | Sprint 1.6 — Mechanic Booking UI |
| 0.3.0 | 2026-07-27 | Sprint 1.5 — Core UI Polish (dark mode, splash, premium UI) |
| 0.2.0 | 2026-07-26 | Sprint 1.4 — Navigation & Home Dashboard |
| 0.1.0 | 2026-07-25 | Sprint 1.1–1.3 — Splash, Onboarding, Auth |
| 0.0.1 | 2026-07-20 | Initial project setup |

---

# 21. Sprint Reports

| Sprint | Report |
|--------|--------|
| 1.1 | [`docs/04_sprints/SPRINT_1_1.md`](../04_sprints/SPRINT_1_1.md) |
| 1.2 | [`docs/04_sprints/SPRINT_1_2.md`](../04_sprints/SPRINT_1_2.md) |
| 1.3 | [`docs/04_sprints/SPRINT_1_3.md`](../04_sprints/SPRINT_1_3.md) |
| 1.4 | [`docs/04_sprints/SPRINT_1_4.md`](../04_sprints/SPRINT_1_4.md) |
| 1.5 | [`docs/04_sprints/SPRINT_1_5.md`](../04_sprints/SPRINT_1_5.md) |
| 1.6 | [`docs/04_sprints/SPRINT_1_6.md`](../04_sprints/SPRINT_1_6.md) |

---

# 22. Related Documents

| Document | Description |
|----------|-------------|
| [PRODUCT_REQUIREMENTS_DOCUMENT.md](../01_product/PRODUCT_REQUIREMENTS_DOCUMENT.md) | Vision, personas, market analysis |
| [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) | Mermaid architecture diagrams |
| [BUSINESS_MODEL.md](../01_product/BUSINESS_MODEL.md) | Revenue, unit economics, growth |
| [FEATURE_SPECIFICATIONS.md](../01_product/FEATURE_SPECIFICATIONS.md) | Per-feature spec details |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Colors, typography, components |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Table schemas, indexes |
| [API_SPEC.md](../06_reference/API_SPEC.md) | REST endpoints, request/response |
| [AI_ARCHITECTURE.md](AI_ARCHITECTURE.md) | AI pipeline, model registry |
| [DEPLOYMENT.md](../03_development/DEPLOYMENT.md) | Build, CI/CD, release checklist |
| [TEST_PLAN.md](../03_development/TEST_PLAN.md) | Test strategy, coverage targets |
| [RISK_ANALYSIS.md](../01_product/RISK_ANALYSIS.md) | Risk register, mitigation |
| [THIRD_PARTY_SERVICES.md](../06_reference/THIRD_PARTY_SERVICES.md) | Service inventory, API keys |
| [CONTRIBUTING.md](../03_development/CONTRIBUTING.md) | Dev setup, coding standards |
| [PROJECT_STATUS.md](../01_product/PROJECT_STATUS.md) | Overall status dashboard |
| [ROADMAP.md](../01_product/ROADMAP.md) | Sprint-by-sprint timeline |
| [CHANGELOG.md](../03_development/CHANGELOG.md) | Version history |
| [AUDIT_REPORT.md](../05_reports/AUDIT_REPORT.md) | Documentation quality audit |

---

# 23. Git Standards

**Branch Naming:** `feature/<module-name>`

**Commit Format:**
- `feat:` — New feature
- `fix:` — Bug fix
- `refactor:` — Code restructure
- `docs:` — Documentation
- `test:` — Tests
- `style:` — Formatting

**Example:** `feat(mechanic): complete booking module`

---

# 24. Future Integrations

| Integration | Status |
|-------------|--------|
| Firebase Auth | 🔲 |
| Google Maps | 🔲 |
| MapMyIndia | 🔲 |
| Razorpay | 🔲 |
| PhonePe | 🔲 |
| FCM (Push) | 🔲 |
| Gemini AI | 🟡 Integrated (local) |
| OCR | 🔲 |
| Voice | 🔲 |

---

# 25. Success Criteria (MVP Complete)

- [ ] Customer App completed
- [ ] Partner App completed
- [ ] Admin Dashboard completed
- [ ] Backend connected
- [ ] Authentication working
- [ ] Payments working
- [ ] Maps working
- [ ] AI working
- [ ] Notifications working
- [ ] Production ready

---

# 26. Document Maintenance Rules

This document MUST be updated:
- After every sprint
- After every architecture change
- After every major refactor
- After every dependency addition
- After every folder restructuring

Never allow this document to become outdated. It is the official engineering blueprint for Mecha Connect.

