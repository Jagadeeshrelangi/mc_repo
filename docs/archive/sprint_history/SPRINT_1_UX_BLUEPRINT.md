# Mecha Connect — Sprint 1: UX/Product Blueprint (Complete Report)

**Status:** v2 — Revised based on founder feedback | **Sprint:** Sprint 1 — UX Architecture | **Date:** July 2026

---

## Table of Contents

1. Executive Summary
2. Current State Analysis
3. Problems Found (Risks for Greenfield)
4. Improvement Suggestions
5. User Types & Definitions
6. Complete Screen Inventory
7. Navigation Flows
8. Core Modules (Platform + AI + Business + Startup)
9. Reusable UI Components
10. Design System Proposal
11. Customer Journey (Full Flow)
12. Mechanic Journey (Full Flow)
13. Admin Journey (Full Flow)
14. Module Architecture (True Monorepo)
15. Folder Structure Recommendation
16. Risk Analysis
17. Migration Plan
18. Development Roadmap
19. Complete Documentation Roadmap
20. Appendix A: Screen Mapping Summary
21. Appendix B: Technology Stack Recommendations (Python-First)

---

## 1. Executive Summary

Mecha Connect is a full-stack roadside assistance and vehicle services platform: Customer Mobile App, Mechanic Mobile App, Admin Dashboard, Landing Website, Customer Portal, Backend APIs, AI Services, and future Web Platform.

**Current state:** Greenfield project — no Flutter code, backend, database, or design assets exist.

**Sprint 1 goal:** Define complete UX architecture, navigation flows, design system, and roadmap before any code is written.

**Key decisions:**
- Flutter (mobile apps), Next.js (web), FastAPI (Python backend), PostgreSQL + Redis
- Material 3 design system with custom brand theming
- True monorepo structure with apps/, backend/, packages/ separation
- AI as cross-cutting service layer — not an isolated module, powers Vehicle Diagnosis, Mechanic Recommendation, Maintenance Prediction, Repair Estimation, Smart Search, Customer Support, and Knowledge Engine
- Offline-first architecture for low-connectivity roadside scenarios
- Python throughout the backend for simplified development and AI integration

---

## 2. Current State Analysis

| Area | Status |
|------|--------|
| Flutter project | Not initialized (planned) |
| Backend (FastAPI) | Existing work — Python/FastAPI codebase started |
| AI Services | Existing work — RAG pipeline, Python AI services |
| Database | PostgreSQL — needs schema design |
| Design assets | Not created |
| Documentation | This document + prior PRD/SRS needed |
| Tests | None |
| Git | Not initialized |

---

## 3. Problems Found (Risks for Greenfield)

### Structural Risks
1. No monorepo structure — risk of disconnected codebases
2. No design system — risk of UI inconsistency across apps
3. No shared component library — duplicate work
4. No offline strategy — critical for roadside scenarios
5. No error tracking

### UX Risks
1. No user research — untested assumptions
2. No accessibility baseline — legal risk
3. No localization strategy
4. No loading/error/empty states defined

### Technical Risks
1. No CI/CD pipeline
2. No API contract-first approach
3. No testing strategy
4. No environment configuration

---

## 4. Improvement Suggestions

### Process
1. API-first development — define OpenAPI specs before implementation
2. Feature branches + PR reviews
3. Design review checklist as quality gate
4. Weekly UX audits

### Architecture
1. Modular monorepo with clear package boundaries
2. Shared `mecha_design_system` package
3. API client SDK generated from OpenAPI specs
4. Offline-first data layer — SQLite + sync engine
5. Feature flags for gradual rollout

### UX
1. Low-fidelity wireframes before coding
2. Design system first — tokens, components, patterns
3. User flow testing before dev
4. WCAG 2.1 AA minimum accessibility
5. Dark mode from day one

---

## 5. User Types & Definitions

### 5.1 Customer

| Attribute | Definition |
|-----------|------------|
| Goal | Get roadside assistance quickly, track service, manage vehicles, pay seamlessly |
| Permissions | Profile CRUD, manage vehicles, request services, pay, chat, rate |
| Primary Actions | Request help, SOS, manage vehicles, track mechanic, pay, rate |
| Frustrations | Long wait times, unclear ETA, payment confusion, no status updates |
| Device | Smartphone (Android/iOS) |
| Tech literacy | Low to medium |

**Journey:** App Open → Auth → Home → Select Service → Confirm Location → Choose Vehicle → Make Payment → Track Mechanic → Service Complete → Rate & Review

### 5.2 Mechanic

| Attribute | Definition |
|-----------|------------|
| Goal | Get job leads, navigate to customer, complete service, get paid |
| Permissions | Set availability, view/accept/reject jobs, navigate, complete, view earnings |
| Primary Actions | Toggle availability, accept job, navigate, complete service, view earnings |
| Frustrations | False alarms, long drives, payment delays, unclear job details |
| Device | Smartphone (Android/iOS) |
| Tech literacy | Low — large buttons, minimal text, voice features |

**Journey:** App Open → Auth → Toggle Available → Receive Job Alert → Review → Accept → Navigate → Start Service → Complete → Receive Payment

### 5.3 Admin

| Attribute | Definition |
|-----------|------------|
| Goal | Manage platform operations, approve mechanics, view analytics, resolve disputes |
| Permissions | Full CRUD users/mechanics/orders, view analytics, manage support |
| Primary Actions | Approve/reject mechanics, manage orders, view analytics, handle tickets |
| Frustrations | Too many manual approvals, poor data viz, no real-time monitoring |
| Device | Desktop/laptop |
| Tech literacy | Medium to high |

**Journey:** Login → Dashboard → Manage Requests → Approve/Reject → Monitor Orders → View Reports → Handle Escalations

### 5.4 Guest (Unauthenticated)

| Attribute | Definition |
|-----------|------------|
| Goal | Explore services, download apps, become a mechanic, contact support |
| Permissions | View landing page, browse services, submit contact form |
| Primary Actions | Browse services, download app, submit become-a-mechanic form |
| Frustrations | Can't see pricing, can't check availability without signup |
| Device | Desktop/mobile — website |
| Tech literacy | Low to medium |

**Journey:** Visit Website → Browse Services → Learn About → Download App → (Optional) Become a Mechanic

---

## 6. Complete Screen Inventory

### 6.1 Authentication Screens

| # | Screen | User | Pri | Description |
|---|--------|------|-----|-------------|
| A1 | Splash | All | P0 | Brand animation, auto-login check, 2s display |
| A2 | Onboarding | Guest | P1 | 3-4 page carousel, skip + next + get started |
| A3 | Login | Guest | P0 | Phone/email + password, social login, forgot password |
| A4 | OTP Verification | Guest | P0 | 6-digit OTP, auto-submit, resend timer, voice fallback |
| A5 | Registration | Guest | P0 | Name, phone, email, password, role selection |
| A6 | Forgot Password | Guest | P1 | Phone/email → OTP → new password |
| A7 | Role Selection | Guest | P0 | Customer vs Mechanic toggle on registration |
| A8 | Profile Setup | Customer | P1 | Photo, address, language, emergency contact |

### 6.2 Customer App Screens

| # | Screen | Pri | Description |
|---|--------|-----|-------------|
| C1 | Customer Home | P0 | Map, quick actions (SOS, Fuel, Tyre, Towing, Battery), active booking card, notifications |
| C2 | Vehicle Garage | P0 | Saved vehicles list, add FAB, default badge |
| C3 | Vehicle Details | P0 | Make, model, year, color, plate, fuel type, insurance, default toggle |
| C4 | Add/Edit Vehicle | P0 | Form with fields, photo upload |
| C5 | Service Selection | P0 | Categorized grid of services |
| C6 | Booking — Location | P0 | Map with drag pin, address auto-fill |
| C7 | Booking — Mechanic | P0 | Nearby mechanics list, distance, rating, ETA, price |
| C8 | Booking — Vehicle | P0 | Choose from garage or add new |
| C9 | Booking — Details | P0 | Issue description, photos, preferred time |
| C10 | Booking — Price | P0 | Fees, promo code, total, proceed to payment |
| C11 | Booking — Payment | P0 | Wallet, card, UPI, cash options |
| C12 | Booking Confirmation | P0 | Booking ID, mechanic info, ETA, Cancel |
| C13 | Tracking / Live Map | P0 | Real-time mechanic location, ETA, call/SMS |
| C14 | SOS Alert | P0 | Emergency button, share location, auto-dial |
| C15 | Orders — Active | P0 | Active orders with status, ETA, actions |
| C16 | Orders — History | P0 | Past orders, filters (date, type, status) |
| C17 | Order Detail | P0 | Full info, mechanic, timeline, invoice, re-book |
| C18 | Invoice | P1 | Itemized bill, digital receipt, download/share |
| C19 | Rating & Review | P0 | Stars 1-5, comment, photo, tip |
| C20 | Wallet | P1 | Balance, transactions, top-up, payment methods |
| C21 | Notifications | P0 | List grouped by date, read/unread, tap to navigate |
| C22 | Profile | P0 | Photo, name, phone, email, address |
| C23 | Settings | P0 | Language, theme, notifications, emergency contacts |
| C24 | Help & Support | P1 | FAQ, chat, call, report issue |
| C25 | AI Assistant Chat | P1 | Chatbot, service booking via chat, troubleshooting |
| C26 | Promotions | P2 | Offers, promo codes, referral program |

### 6.3 Mechanic App Screens

| # | Screen | Pri | Description |
|---|--------|-----|-------------|
| M1 | Dashboard | P0 | Online/offline toggle, earnings today, jobs, alerts |
| M2 | Incoming Job Alert | P0 | Full-screen: customer, distance, service type, accept/reject |
| M3 | Job Details | P0 | Customer info, vehicle, issue, photos, map |
| M4 | Navigation | P0 | Turn-by-turn, integrated map, ETA |
| M5 | Active Job | P0 | Status steps, timer, notes, photos |
| M6 | Service Completion | P0 | Parts used, charges, signature, invoice |
| M7 | Completed Jobs | P1 | Past jobs, filterable, payment status |
| M8 | Earnings | P1 | Daily/weekly/monthly, pending/completed payouts |
| M9 | Withdrawal | P2 | Bank setup, withdrawal request, history |
| M10 | Profile | P0 | Photo, name, phone, certifications, vehicle, area |
| M11 | Settings | P0 | Language, notifications, availability schedule |
| M12 | Support | P1 | FAQs, chat with admin, call support |

### 6.4 Admin Dashboard Screens

| # | Screen | Pri | Description |
|---|--------|-----|-------------|
| D1 | Admin Login | P0 | Secure login with 2FA |
| D2 | Dashboard | P0 | Active jobs, users, mechanics, revenue, approvals, activity |
| D3 | Users — List | P0 | Searchable/filterable customer list |
| D4 | Users — Detail | P0 | Info, order history, tickets, status |
| D5 | Mechanics — List | P0 | Searchable/filterable, pending approval badge |
| D6 | Mechanics — Detail | P0 | Profile, documents, verification, ratings, earnings |
| D7 | Mechanic Approval | P0 | Document review, checklist, approve/reject |
| D8 | Orders — All | P0 | Filters, search, status, export |
| D9 | Orders — Detail | P0 | Full view, assign mechanic, refund, status override |
| D10 | Analytics | P0 | Charts: revenue, orders, users, heat map |
| D11 | Reports | P2 | Exportable financial/operational reports |
| D12 | Support Tickets | P1 | List, assign, respond, resolve, escalate |
| D13 | Promotions | P2 | Create/edit/disable promo codes |
| D14 | Service Areas | P1 | Define serviceable areas on map, pricing zones |
| D15 | Service Pricing | P1 | Set pricing per service type |
| D16 | System Settings | P1 | Version, maintenance, feature flags, API keys |
| D17 | Audit Log | P2 | Admin action history |

### 6.5 Website Screens

| # | Screen | Pri | Description |
|---|--------|-----|-------------|
| W1 | Landing | P0 | Hero, features, how it works, download links, trust badges |
| W2 | About Us | P1 | Story, mission, team, milestones |
| W3 | Services | P0 | All services listed with icons, pricing |
| W4 | Service Detail | P0 | Individual service page |
| W5 | Download App | P0 | App Store + Play Store links, QR codes |
| W6 | Become a Mechanic | P0 | Form with info, experience, documents |
| W7 | Contact Us | P1 | Form, email, phone, address, map |
| W8 | FAQ | P1 | Categorized accordion |
| W9 | Privacy Policy | P2 | Legal |
| W10 | Terms of Service | P2 | Legal |
| W11 | Blog | P3 | Articles, tips, news |

### 6.6 Shared / Overlay Screens

| # | Screen | Users | Pri | Description |
|---|--------|-------|-----|-------------|
| S1 | In-App Notification | All | P0 | Slide-down banner |
| S2 | Chat | C+M | P0 | Real-time chat with images |
| S3 | Call UI | C+M | P0 | In-app call overlay |
| S4 | Full-Screen Map | C+M | P0 | Full map with layers |
| S5 | Emergency Contacts | C | P1 | Manage emergency contacts |
| S6 | Language Selection | All | P1 | Language picker overlay |
| S7 | Photo Viewer | All | P1 | Full-screen zoomable photo |

---

## 7. Navigation Flows

### 7.1 Customer Navigation

```
                    [Splash — Auto-login check]
                              |
                    [Onboarding (1x only)]
                              |
                    [Auth — Login / Register]
                     /                    \
                    /                      \
       [Vehicle Garage]              [Customer Home]
       (if no vehicles)          (Map + Quick Actions)
                                        |        \
                               [Service Select]  [Active Booking]
                                        |             |
                               [Booking Flow] <--------/
                                1. Location Pick
                                2. Vehicle Select
                                3. Service Detail
                                4. Price Estimate
                                5. Payment
                                6. Confirmation
                                        |
                               [Tracking / Live Map]
                                        |
                               [Service Complete]
                               → Rate & Review
                               → Invoice

  Bottom Nav Bar (5 tabs): Home | Orders | Notifications | Wallet | Profile
```

### 7.2 Mechanic Navigation

```
                    [Splash — Auto-login check]
                              |
                    [Mechanic Dashboard]
                    (Online/Offline toggle)
                     /                    \
                    /                      \
          [Incoming Job Alert]         [Earnings]
                 |                          |
           [Job Details]              [Withdrawal]
                 |
           [Navigation / Map]
                 |
           [Active Job]
           (Arrived → Diagnosing → Repairing → Complete)
                 |
           [Service Completion]
           (Parts, charges, signature, invoice)
                 |
           [Back to Dashboard]

  Bottom Nav Bar (4 tabs): Dashboard | Jobs | Earnings | Profile
```

### 7.3 Admin Navigation

```
                    [Admin Login (2FA)]
                            |
                    [Admin Dashboard]
                     /    |    |    \
                    /     |    |     \
              [Users] [Mechanics] [Orders] [Analytics]
                |        |          |         |
           [Detail]  [Detail]   [Detail]  [Reports]
                        |
                  [Approval]
  
  Sidebar Nav: Dashboard | Users | Mechanics | Orders | Analytics | 
               Reports | Support | Promotions | Service Areas | 
               Pricing | Settings | Audit Log
```

### 7.4 Website Navigation

```
                    [Landing Page]
                     /    |    \
                    /     |     \
              [About] [Services] [Download]
                |        |          |
           [Service Detail]    [App Store / Play Store]
                    
              [Become a Mechanic] → Form
              [Contact Us] → Form
              [FAQ]
              [Blog]
              [Privacy / Terms]
```

### 7.5 Booking Flow — Detailed (Customer)

```
Home → Service Selection → Location Setup → Vehicle Selection → 
Service Details → Price Estimate → Payment → Confirmation → 
Tracking → Service Complete → Rating & Invoice
```

### 7.6 SOS Flow (Customer)

```
Any Screen → SOS Button (floating / dedicated) → 
Confirm SOS → Share Live Location → 
Alert Nearest Mechanics → Auto-call Emergency Contacts → 
Tracking Screen
```

---

## 8. Core Modules

### 8.1 Platform Modules

| # | Module | Apps | Description |
|---|--------|------|-------------|
| 1 | Authentication | All | Login, register, OTP, session, role-based auth, social login |
| 2 | Vehicles | Customer | CRUD garage, vehicle details, default vehicle, photos |
| 3 | Bookings | Customer, Admin | Full booking pipeline: select → locate → pay → track → complete |
| 4 | Mechanics | Customer, Mechanic, Admin | Profiles, availability, ratings, assignment |
| 5 | Fuel Delivery | Customer | Specialized fuel delivery booking flow |
| 6 | Payments | Customer, Mechanic | Wallet, cards, UPI, cash, payout processing |
| 7 | Wallet | Customer, Mechanic | Balance, top-up, transactions, withdrawal |
| 8 | Notifications | All | Push, in-app, SMS, email; real-time updates |
| 9 | Profile | All | CRUD personal info, settings, preferences |
| 10 | Analytics | Admin | Charts, reports, KPIs, export |
| 11 | Support | All | Tickets, FAQ, chat, call center integration |
| 12 | Maps & Location | Customer, Mechanic | Geocoding, real-time tracking, routing, geofencing |
| 13 | SOS / Emergency | Customer | Emergency alert, live sharing, auto-dispatch |

### 8.2 AI Services (Cross-Cutting — powers all platform modules)

| # | AI Service | Description |
|---|------------|-------------|
| AI-1 | Vehicle Diagnosis | Analyze symptoms + photos → predict likely issues using ML models |
| AI-2 | Mechanic Recommendation | Match customer issue + location + rating → optimal mechanic assignment |
| AI-3 | Maintenance Prediction | Predict upcoming maintenance needs based on vehicle model, mileage, history |
| AI-4 | Repair Estimation | Generate price estimates based on diagnosis, parts, labor in region |
| AI-5 | Smart Search | Natural language search across services, FAQs, mechanics |
| AI-6 | Customer Support | AI-powered chatbot and ticket triage with human handoff |
| AI-7 | Knowledge Engine | RAG-powered technical manuals, troubleshooting guides, parts database |

### 8.3 Business Modules (Growth & Monetization)

| # | Module | Description |
|---|--------|-------------|
| B-1 | Inventory Management | Track mechanic parts stock, auto-reorder, supplier management |
| B-2 | Spare Parts Marketplace | Customers/mechanics browse and order spare parts directly |
| B-3 | Vendor Management | Onboard and manage parts suppliers, negotiate pricing |
| B-4 | Subscriptions | Recurring service plans for customers (monthly/yearly) |
| B-5 | Memberships | Tiered membership (Basic, Premium, Pro) with benefits |
| B-6 | Coupons | Discount coupon engine with rules and expiry |
| B-7 | Referral | Referral tracking, rewards, payout for customers and mechanics |
| B-8 | Loyalty | Points-based loyalty program with redeemable rewards |
| B-9 | Fleet Management | Corporate fleet accounts, multi-vehicle management, billing |
| B-10 | Insurance Assistance | Claim filing, partner insurance companies, document collection |
| B-11 | Roadside Membership | Annual roadside assistance membership (standalone product) |
| B-12 | Service Packages | Bundled services (e.g., "Oil + Filter + Inspection" at fixed price) |

### 8.4 Startup Infrastructure Modules

| # | Module | Description |
|---|--------|-------------|
| S-1 | Audit Logs | Immutable log of all system actions for compliance and debugging |
| S-2 | Feature Flags | Toggle features on/off without deployment, phased rollouts |
| S-3 | CMS | Manage website content (pages, blogs, FAQs) without engineering |
| S-4 | Feedback & Crash Reporting | In-app feedback, automatic crash reporting (Sentry) |
| S-5 | User Behavior Analytics | Track user actions, funnels, retention, conversion |
| S-6 | Growth Dashboard | Real-time startup KPIs: acquisition cost, lifetime value, retention, activation rate |

---

## 9. Reusable UI Components

| # | Component | Usage |
|---|-----------|-------|
| 1 | Primary Button | Full-width, icon + text, loading state, disabled state |
| 2 | Secondary Button | Outlined, text-only variant |
| 3 | Ghost Button | Text-only, no border |
| 4 | Icon Button | Circular, variant for SOS (red, pulsing) |
| 5 | Service Card | Icon + title + description + arrow; grid layout |
| 6 | Mechanic Card | Photo, name, rating, distance, ETA, price |
| 7 | Vehicle Card | Photo, nickname, make/model, plate, default badge |
| 8 | Booking Card | Service type, status chip, ETA, mechanic name, tap to expand |
| 9 | Order Card | Order ID, date, service, status, amount |
| 10 | Status Chip | Colored chip: Pending (yellow), Active (blue), Completed (green), Cancelled (red) |
| 11 | Bottom Navigation Bar | 4-5 tabs with icons + labels |
| 12 | App Bar | Title, back button, actions (bell, menu) |
| 13 | Text Input | Label, hint, error, icon prefix, password toggle |
| 14 | Search Bar | Debounced input, clear button, recent searches |
| 15 | Bottom Sheet | Drag handle, scrollable content, CTA button |
| 16 | Dialog | Alert, confirmation, input dialogs |
| 17 | Loading Widget | Shimmer, spinner, skeleton screen |
| 18 | Error Widget | Icon, message, retry button |
| 19 | Empty State | Illustration, message, CTA button |
| 20 | Rating Display | Star row, read-only and interactive modes |
| 21 | Map Widget | Google Maps / OSM with markers, polylines, info windows |
| 22 | Timeline Widget | Vertical steps with status indicators |
| 23 | Image Picker | Camera/gallery selection, crop, preview |
| 24 | OTP Input | 6-digit segmented input, auto-focus, paste |
| 25 | Chip Group | Filter chips, toggle chips, choice chips |

---

## 10. Design System Proposal

### 10.1 Brand Identity

| Element | Suggestion |
|---------|------------|
| Brand Name | Mecha Connect |
| Brand Personality | Trustworthy, fast, modern, helpful |
| Tagline | "Your Road, Our Responsibility" |

### 10.2 Color Palette

| Token | Role | Hex (Suggested) |
|-------|------|-----------------|
| Primary | Brand, CTAs | #1A73E8 (Trustworthy Blue) |
| Primary Container | Selected states | #D2E3FC |
| On Primary | Text on primary | #FFFFFF |
| Secondary | Accent actions | #34A853 (Go Green — for success/complete) |
| Tertiary | SOS/Emergency | #EA4335 (Alert Red) |
| Surface | Card backgrounds | #FFFFFF / #1E1E1E (dark) |
| Background | Page bg | #F8F9FA / #121212 (dark) |
| Error | Validation | #DC3545 |
| Warning | Pending states | #FFC107 |
| Success | Completed | #28A745 |

### 10.3 Typography

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display Large | 57 | Bold | Landing page hero |
| Display Medium | 45 | Bold | Splash title |
| Headline Large | 32 | Bold | Screen titles |
| Headline Medium | 28 | SemiBold | Section headers |
| Headline Small | 24 | SemiBold | Card titles |
| Title Large | 22 | Medium | App bar titles |
| Title Medium | 16 | Medium | Subheadings |
| Title Small | 14 | Medium | Card subtitles |
| Body Large | 16 | Regular | Body text |
| Body Medium | 14 | Regular | Secondary text |
| Body Small | 12 | Regular | Captions, metadata |
| Label Large | 14 | Medium | Button text, tabs |
| Label Medium | 12 | Medium | Chip text |
| Label Small | 11 | Medium | Badge text |

### 10.4 Spacing Scale

| Token | Value |
|-------|-------|
| space-0 | 0 |
| space-1 | 4 |
| space-2 | 8 |
| space-3 | 12 |
| space-4 | 16 |
| space-5 | 20 |
| space-6 | 24 |
| space-8 | 32 |
| space-10 | 40 |
| space-12 | 48 |
| space-16 | 64 |

### 10.5 Elevation

| Level | Value | Usage |
|-------|-------|-------|
| 0 | None | Surface content |
| 1 | 1dp | Cards resting |
| 2 | 3dp | FAB, raised buttons |
| 3 | 6dp | Bottom sheet, nav drawer |
| 4 | 8dp | Dialog, bottom nav bar |
| 5 | 12dp | Snackbar, floating elements |

### 10.6 Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| radius-none | 0 | Full-bleed images |
| radius-sm | 4 | Input fields |
| radius-md | 8 | Cards, dialogs |
| radius-lg | 12 | Bottom sheets |
| radius-xl | 16 | Buttons |
| radius-full | 999 | Avatars, pills |

### 10.7 Icon Style
- Material Symbols (outlined variant as default)
- 24dp standard, 20dp for dense layouts
- Custom brand icon for app icon and logo mark
- Animated icons for loading states and transitions

### 10.8 Animation Style

| Type | Duration | Curve |
|------|----------|-------|
| Page transitions | 300ms | EaseInOut |
| Button press | 100ms | FastOutSlowIn |
| Card expansion | 250ms | Standard |
| Fade in/out | 200ms | Linear |
| Shimmer | 1.5s loop | EaseInOut |
| Map marker bounce | 500ms | Bounce |

### 10.9 Material 3 Compliance
- Follow Material 3 color scheme with custom brand colors mapped to M3 roles
- Use M3 navigation components: NavigationBar (bottom), NavigationDrawer (admin sidebar)
- M3 card, dialog, bottom sheet, and chip components
- M3 typography scale
- M3 motion system
- Dynamic color support (Android 12+) as opt-in feature

---

## 11. Customer Journey (Full Flow)

### Step-by-step: First-time user completing a service request

1. **Splash Screen** — Brand animation, check auth token → no token → navigate to onboarding
2. **Onboarding** — 3 pages: "24/7 Roadside Assistance", "Track in Real Time", "Pay Securely" → tap "Get Started"
3. **Role Selection** — Select "Customer"
4. **Registration** — Enter name, phone, email, password → tap "Register"
5. **OTP Verification** — 6-digit SMS code arrives → auto-detect → verified
6. **Profile Setup** — Add photo, address → tap "Done"
7. **Customer Home** — Map loads with nearby mechanics, quick action grid (SOS, Fuel, Tyre, Towing, Battery)
8. **Tap "Towing"** → Service Detail screen for Towing
9. **Booking — Location** — Map shows current location, drag pin to breakdown spot, address auto-fills → "Confirm Location"
10. **Booking — Vehicle** — No vehicles saved → "Add Vehicle" → Fill make/model/year/plate → Save
11. **Booking — Details** — Describe issue "Car won't start", add photo → "Continue"
12. **Booking — Mechanic Selection** — Shows 3 nearby mechanics sorted by distance → tap mechanic → "Select"
13. **Booking — Price Estimate** — Base fee $15 + distance $5 = $20 → "Proceed to Payment"
14. **Booking — Payment** — Select Wallet (balance $50) → "Pay $20"
15. **Confirmation** — "Mechanic assigned! ETA: 8 min" → Mechanic card: John, ★4.8, Toyota truck → "Track"
16. **Live Tracking** — See mechanic avatar moving on map, ETA counting down → "Call Mechanic" button
17. **Service in Progress** — Status updates: Arrived → Diagnosing → Repairing → Completed
18. **Service Complete** — Mechanic marks done → Order complete notification
19. **Invoice** — Itemized bill, $20 charged → "Download"
20. **Rating** — 5 stars, "Fast and professional!" → optional tip $2 → Submit
21. **Back to Home** — Active booking card replaced with recent orders

### Key touchpoints:
- Push notification at every status change
- SMS fallback if app in background
- Cancel option available until mechanic arrives
- In-app chat during active service

---

## 12. Mechanic Journey (Full Flow)

### Step-by-step: Mechanic completing a job

1. **Splash** — Auto-login → redirect to Dashboard
2. **Dashboard** — Toggle "Online" → green indicator, job alerts enabled
3. **Job Alert** — Full-screen overlay: "Towing - 2.3 km away" → Customer: Priya, Vehicle: Honda City, Issue: "Car won't start"
4. **Review Job Details** — Customer contact, vehicle info, issue photos, location on map
5. **Accept** → "Job accepted! Navigate to customer"
6. **Navigation** — Integrated map with turn-by-turn, distance: 2.3 km, ETA: 6 min → "Start Navigation"
7. **Arrived** — Tap "I've arrived" → customer notified via push
8. **Active Job** — Timer starts → "Diagnosing" → tap "Next Step" → "Repairing" → tap "Next"
9. **Service Completion** — Enter parts used: "Battery cable $5" → Add charge: "Service $20" → Get customer signature → "Complete"
10. **Payment** — Payment processed → earnings updated → "Back to Dashboard"
11. **Dashboard** — Earnings today: +$25, jobs completed: 1, toggle back Online

### Notes:
- Mechanic can reject job (reason optional)
- 30-second timer on job alert before auto-decline
- Silenced if offline
- Earnings auto-withdraw daily threshold config

---

## 13. Admin Journey (Full Flow)

### Step-by-step: Admin approving a mechanic

1. **Admin Login** — Email + password + 2FA code → Dashboard
2. **Dashboard** — Sees: 12 active jobs, 1,234 users, 56 mechanics (3 pending), $4,560 revenue today
3. **Click Pending Approvals** → Navigate to Mechanics list filtered by "Pending"
4. **Select Mechanic** → Shows full profile, uploaded documents (ID, license, certificate, background check)
5. **Document Review** — Verify each document, check completeness
6. **Decision** — Approve (with notes: "Welcome aboard!") or Reject (required reason: "Certification expired")
7. **Approved** → Mechanic receives push notification + welcome email → Status changes to Active

### Step-by-step: Admin managing an order issue

1. **Dashboard** → Sees flagged order in activity feed → clicks
2. **Order Detail** — Full view: customer complaint "Mechanic didn't show"
3. **Check Timeline** — Mechanic accepted but never marked arrived
4. **Action** — Reassign mechanic or cancel + refund
5. **Refund** — Process refund via system → customer notified
6. **Mechanic Penalty** — Warning or suspension based on history

### Step-by-step: Admin viewing analytics

1. **Analytics Tab** → Overview charts: revenue (30d, 6m, 1y)
2. **Filter by service type** → Compare Towing vs Fuel vs Battery
3. **Filter by region** → Heat map showing demand density
4. **Export** → CSV/PDF report generated
5. **Schedule** → Set recurring weekly report email

---

## 14. Module Architecture

### 14.1 Layer Architecture (True Monorepo)

```
mecha_connect/
├── apps/
│   ├── customer_app/             # Customer Flutter app
│   ├── mechanic_app/             # Mechanic Flutter app
│   ├── admin_dashboard/          # Admin Next.js dashboard
│   └── landing_site/             # Next.js landing website
├── backend/
│   ├── api/                      # FastAPI — REST API gateway
│   │   ├── routes/               # Route definitions per module
│   │   ├── middleware/           # Auth, rate limiting, logging
│   │   └── dependencies/        # DI, DB sessions, config
│   ├── ai/                       # Python AI services
│   │   ├── vehicle_diagnosis/    # ML model inference
│   │   ├── mechanic_recommendation/
│   │   ├── maintenance_prediction/
│   │   ├── repair_estimation/
│   │   ├── smart_search/         # NLP + vector search
│   │   ├── customer_support/     # RAG chatbot
│   │   └── knowledge_engine/     # Document retrieval
│   ├── services/
│   │   ├── auth/                 # JWT + OTP + OAuth2
│   │   ├── users/                # User CRUD
│   │   ├── bookings/             # Booking pipeline
│   │   ├── payments/             # Stripe/Razorpay integration
│   │   ├── wallet/               # Balance + transactions
│   │   ├── mechanics/            # Mechanic management
│   │   ├── notifications/        # Push + SMS + email
│   │   ├── analytics/            # Aggregation + reporting
│   │   ├── inventory/            # Parts + stock management
│   │   ├── marketplace/          # Spare parts marketplace
│   │   ├── subscriptions/        # Recurring billing
│   │   ├── fleet/                # Fleet account management
│   │   └── support/              # Ticket system
│   └── shared/
│       ├── database/             # Alembic migrations, seeds
│       ├── models/               # SQLAlchemy / Pydantic models
│       └── messaging/            # Redis pub/sub, Celery tasks
├── packages/
│   ├── design_system/            # Shared Flutter UI components, tokens, theme
│   ├── shared/                   # Shared Dart models, enums, constants
│   ├── api_client/               # Generated OpenAPI client
│   ├── ui/                       # Reusable Flutter widgets
│   └── utils/                    # Dart extensions, helpers
├── docs/                         # All documentation
├── assets/                       # Shared design assets, icons, illustrations
├── infrastructure/               # Docker, k8s, CI/CD, Terraform
└── scripts/                      # Dev setup, seed, deploy automation
```

### 14.2 Flutter App Architecture (per app)

```
lib/
├── main.dart
├── app.dart                    # MaterialApp, router, theme
├── core/
│   ├── config/                 # Environment config, constants
│   ├── theme/                  # ThemeData, colors, styles
│   ├── router/                 # GoRouter config
│   ├── di/                     # Dependency injection
│   ├── network/                # HTTP client, interceptors
│   ├── errors/                 # Error handling, failure types
│   └── utils/                  # Extensions, helpers
├── data/
│   ├── models/                 # DTOs, JSON serialization
│   ├── repositories/           # Repository implementations
│   ├── datasources/            # Remote (API) and Local (SQLite)
│   └── providers/              # State management stores
├── domain/
│   ├── entities/               # Business entities
│   ├── repositories/           # Repository interfaces
│   └── usecases/               # Business logic
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── domain/
│   ├── home/
│   ├── booking/
│   ├── garage/
│   ├── tracking/
│   ├── orders/
│   ├── wallet/
│   ├── profile/
│   └── notifications/
└── shared/
    ├── widgets/                # Reusable widgets
    ├── extensions/             # Extension methods
    └── constants/              # App-wide constants
```

### 14.3 Data Flow Architecture

```
UI Layer (Widgets)
    ↕ Observes
State Management (Riverpod / BLoC)
    ↕ Calls
Domain Layer (Usecases)
    ↕ Interface
Repository Layer
    ↕         ↕
Remote DS (API)    Local DS (SQLite)
    ↓                   ↓
Backend API        Offline Cache
```

---

## 15. Folder Structure Recommendation

### Current: Empty — no structure exists.

### Recommended root structure (true monorepo):

```
mecha_connect/
├── apps/
│   ├── customer_app/
│   ├── mechanic_app/
│   ├── admin_dashboard/
│   └── landing_site/
├── backend/
│   ├── api/
│   │   ├── routes/
│   │   ├── middleware/
│   │   └── dependencies/
│   ├── ai/
│   │   ├── vehicle_diagnosis/
│   │   ├── mechanic_recommendation/
│   │   ├── maintenance_prediction/
│   │   ├── repair_estimation/
│   │   ├── smart_search/
│   │   ├── customer_support/
│   │   └── knowledge_engine/
│   ├── services/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── bookings/
│   │   ├── payments/
│   │   ├── wallet/
│   │   ├── mechanics/
│   │   ├── notifications/
│   │   ├── analytics/
│   │   ├── inventory/
│   │   ├── marketplace/
│   │   ├── subscriptions/
│   │   ├── fleet/
│   │   └── support/
│   └── shared/
│       ├── database/
│       ├── models/
│       └── messaging/
├── packages/
│   ├── design_system/
│   ├── shared/
│   ├── api_client/
│   ├── ui/
│   └── utils/
├── docs/
├── assets/
├── infrastructure/
│   ├── docker/
│   ├── k8s/
│   └── ci_cd/
├── scripts/
│   ├── setup.sh
│   ├── seed.sh
│   └── deploy.sh
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── cd.yml
├── .gitignore
├── README.md
├── CONTRIBUTING.md
├── Makefile                     # Common dev commands
├── pyproject.toml               # Python backend workspace
├── pubspec.yaml                 # Dart/Flutter workspace
├── package.json                 # Web workspace
└── docker-compose.yml
```

### Files to create FIRST:

| File | Purpose |
|------|---------|
| `.gitignore` | Ignore build, deps, env files |
| `README.md` | Project overview, setup instructions |
| `CONTRIBUTING.md` | Contribution guidelines, branch strategy |
| `docker-compose.yml` | Local dev environment with PostgreSQL, Redis, FastAPI |
| `pyproject.toml` | Python workspace (FastAPI + AI services) |
| `Makefile` | One-command dev environment setup |
| `scripts/setup.sh` | Automated dev environment bootstrap |
| `docs/architecture/OVERVIEW.md` | Architecture decision records |
| `docs/api/openapi.yaml` | API contract (start with core endpoints) |

---

## 16. Risk Analysis

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| 1 | Business module scope creep (inventory, marketplace, fleet, subscriptions, etc.) | High | Medium | Phase P0-P2 strictly; business modules start from Sprint 11+ only after core booking flow is solid |
| 2 | Offline scenarios not handled | Medium | Critical | Offline-first from day one; SQLite + sync engine |
| 3 | Poor connectivity in rural areas | High | High | SMS fallback for communications; offline maps |
| 4 | Payment integration complexity | Medium | High | Start with one gateway (Razorpay/Stripe) then expand |
| 5 | Mechanic onboarding friction | High | Medium | Simplified registration, document auto-verify |
| 6 | Real-time tracking latency | Medium | High | WebSocket + polling fallback; optimize location updates |
| 7 | Dual app maintenance cost | Medium | Medium | Max shared code via packages; design system reuse |
| 8 | No user research baseline | High | Medium | Conduct interviews + surveys before Sprint 2 |
| 9 | Admin dashboard feature overload | Medium | Medium | Phase admin features: P0 first, P1-2 in later sprints |
| 10 | Localization complexity | Medium | Low | Use Flutter intl; start with English + 1 regional language |
| 11 | Security & compliance | Medium | High | 2FA for admin, data encryption, GDPR compliance plan |
| 12 | Scalability under load | Low | High | Auto-scaling in k8s; rate limiting; CDN for static assets |
| 13 | AI model quality / accuracy for diagnosis predictions | Medium | High | Start with rule-based + simple ML; iterate with labeled data; human-in-the-loop fallback |
| 14 | Documentation debt — skipping PRD/SRS before coding | High | Medium | Block Sprint 2 for architecture docs; enforce doc review in PR process |
| 15 | Monorepo complexity for a small team | Medium | Medium | Use simple tooling (no Bazel); clear OWNERS files per directory |

---

## 17. Migration Plan

Since the project is greenfield, "migration" refers to the process from planning → implementation.

### Phase 1: Foundation (Sprint 1-2)
- Set up monorepo structure
- Initialize Flutter apps + web projects
- Create `mecha_design_system` package with tokens
- Define OpenAPI specs for core endpoints
- Set up CI/CD pipelines
- Dockerize development environment

### Phase 2: Auth & User Management (Sprint 3-4)
- Implement auth screens (Splash, Onboarding, Login, Register, OTP)
- Backend auth service (JWT, OTP, social login)
- User profile CRUD
- Role-based navigation

### Phase 3: Core Booking Flow (Sprint 5-8)
- Customer home with map + quick actions
- Vehicle garage CRUD
- Full booking pipeline (location → vehicle → mechanic → price → payment)
- Mechanic app: dashboard, job alerts, navigation, active job
- Admin: order management, basic dashboard

### Phase 4: Payments & Wallet (Sprint 9-10)
- Payment gateway integration
- Wallet top-up, transactions, refunds
- Mechanic payout system
- Invoice generation

### Phase 5: Advanced Features (Sprint 11-14)
- SOS / Emergency flow
- Fuel delivery specific flow
- Real-time tracking optimization
- Notifications system (push, SMS, email)
- Ratings & reviews
- Chat system
- AI Services begin: Knowledge Engine (FAQs → RAG), Smart Search

### Phase 6: Admin & Analytics + Business Modules (Sprint 15-18)
- Full admin dashboard (users, mechanics, orders CRUD)
- Analytics charts and reports
- Mechanic approval workflow
- Support ticket system
- Coupons & Referral system
- Loyalty points program
- Service Packages & Memberships
- Subscriptions engine

### Phase 7: AI Deep Integration (Sprint 19-21)
- Vehicle Diagnosis AI (image + symptom analysis)
- Mechanic Recommendation engine
- Maintenance Prediction models
- Repair Estimation tool
- AI Customer Support (chatbot + ticket triage)
- Full RAG pipeline for knowledge engine

### Phase 8: Growth Modules & Website (Sprint 22-24)
- Inventory Management for mechanics
- Spare Parts Marketplace (MVP)
- Vendor Management (basic)
- Fleet Management (corporate accounts)
- Insurance Assistance workflow
- Roadside Membership product
- Landing website with all pages
- Become-a-mechanic flow
- Customer portal web

### Phase 9: Polish & Launch (Sprint 25-26)
- Feature flags mature — phased rollout capability
- CMS for website content
- Growth dashboard (acquisition cost, lifetime value, retention)
- User behavior analytics (funnels, cohorts)
- Feedback & crash reporting (Sentry)
- Audit log finalization for compliance
- Performance optimization
- Accessibility audit (WCAG 2.1 AA)
- Security penetration testing
- Beta testing with 100 users
- App store submission
- Production launch

---

## 18. Development Roadmap

### Sprint Overview (1 sprint = 2 weeks)

```
Sprint 1   │ UX Blueprint (THIS DOCUMENT)
Sprint 2   │ Monorepo setup, design system, CI/CD, doc foundation
Sprint 3   │ Auth screens + backend auth service
Sprint 4   │ Onboarding, profile, role-based nav
Sprint 5   │ Customer home + vehicle garage
Sprint 6   │ Booking pipeline (location → vehicle)
Sprint 7   │ Booking pipeline (mechanic → price → pay)
Sprint 8   │ Mechanic app (dashboard, job alert, nav)
Sprint 9   │ Admin order management + basic dashboard
Sprint 10  │ Payment gateway + wallet
Sprint 11  │ Mechanic payouts + invoicing
Sprint 12  │ SOS flow + fuel delivery flow
Sprint 13  │ Notifications + chat system
Sprint 14  │ Ratings, reviews, Knowledge Engine (RAG) + Smart Search
Sprint 15  │ Coupons, Referral, Loyalty system
Sprint 16  │ Service Packages, Memberships, Subscriptions
Sprint 17  │ Full admin dashboard + analytics + reports
Sprint 18  │ Support tickets + mechanic approval workflow
Sprint 19  │ Vehicle Diagnosis AI
Sprint 20  │ Mechanic Recommendation + Maintenance Prediction AI
Sprint 21  │ Repair Estimation + AI Customer Support
Sprint 22  │ Inventory Management + Spare Parts Marketplace
Sprint 23  │ Fleet Management + Insurance Assistance + Roadside Membership
Sprint 24  │ Landing website, Customer portal, Become-a-Mechanic
Sprint 25  │ Growth dashboard, user behavior analytics, CMS, feature flags
Sprint 26  │ Polish, security audit, beta testing, launch
```

**Total estimated timeline: ~52 weeks (12 months)**

### P0 Features (MVP — Sprint 3-10) — Core Platform:
- Auth (login, register, OTP)
- Customer home + quick actions
- Vehicle garage
- Full booking flow (all services)
- Mechanic app (dashboard, alerts, navigation, job completion)
- Payment + wallet
- Admin order management
- Basic SOS

### P1 Features (Sprint 11-18) — Retention & Growth:
- Mechanic payouts
- Invoicing
- Notifications + chat
- Ratings & reviews
- Coupons, Referral, Loyalty
- Service Packages, Memberships, Subscriptions
- Full admin dashboard
- Analytics + reports
- Support tickets + mechanic approval
- AI Knowledge Engine + Smart Search

### P2 Features (Sprint 19-24) — AI & Business Modules:
- Vehicle Diagnosis AI
- Mechanic Recommendation AI
- Maintenance Prediction AI
- Repair Estimation AI
- AI Customer Support
- Inventory Management
- Spare Parts Marketplace
- Fleet Management
- Insurance Assistance
- Roadside Membership
- Landing website + Customer portal

### P3 Features (Sprint 25-26) — Startup Infrastructure:
- Growth dashboard (acquisition cost, lifetime value, retention)
- User behavior analytics
- CMS for website content
- Feature flags maturity
- Audit log finalization
- Feedback & crash reporting

---

## 19. Complete Documentation Roadmap

This UX Blueprint is Sprint 1. To build a real startup-grade platform, we need the following documentation set. Each document builds on the previous.

### 19.1 Document Hierarchy

```
01_VISION.md                  — Company vision, mission, market positioning, product philosophy
02_PRODUCT_REQUIREMENTS.md    — PRD: feature specs, user stories, acceptance criteria
03_UX_BLUEPRINT.md            ← CURRENT DOCUMENT: screens, flows, design system, journey maps
04_SYSTEM_ARCHITECTURE.md     — High-level architecture, service boundaries, data flow diagrams
05_DATABASE_DESIGN.md         — ER diagrams, schema definitions, indexing strategy, migration plan
06_API_DESIGN.md              — OpenAPI spec, endpoint definitions, request/response schemas
07_FLUTTER_ARCHITECTURE.md    — Widget tree, state management pattern, routing, code generation
08_BACKEND_ARCHITECTURE.md    — FastAPI project structure, middleware, dependency injection, testing
09_AI_ARCHITECTURE.md         — ML pipeline, model training, RAG setup, embedding strategy
10_DEPLOYMENT_GUIDE.md        — Docker, k8s, CI/CD pipelines, environment configuration
11_TESTING_STRATEGY.md        — Unit, integration, E2E, load testing, QA processes
12_LAUNCH_CHECKLIST.md        — App store prep, security audit, beta program, go/no-go criteria
```

### 19.2 Document Ownership & Timeline

| # | Document | Owner | Target Sprint | Prerequisites |
|---|----------|-------|---------------|---------------|
| 1 | Vision | Founder/CEO | Sprint 1 | None |
| 2 | Product Requirements | PM | Sprint 1-2 | Vision doc |
| 3 | UX Blueprint | Product Designer | Sprint 1 | PRD |
| 4 | System Architecture | Tech Lead | Sprint 2 | UX Blueprint |
| 5 | Database Design | Backend Lead | Sprint 2-3 | System Architecture |
| 6 | API Design | Backend Lead | Sprint 3 | Database Design |
| 7 | Flutter Architecture | Flutter Lead | Sprint 3 | UX Blueprint + API Design |
| 8 | Backend Architecture | Backend Lead | Sprint 3 | System Architecture |
| 9 | AI Architecture | AI Lead | Sprint 4 | Backend Architecture |
| 10 | Deployment Guide | DevOps | Sprint 4 | System Architecture |
| 11 | Testing Strategy | QA Lead | Sprint 4 | All architecture docs |
| 12 | Launch Checklist | PM + Leads | Sprint 18 | All docs |

### 19.3 What Each Document Contains

**01_VISION.md**
- Problem statement, target market, competitive landscape
- North Star metrics, success criteria
- Brand positioning, tone, voice

**02_PRODUCT_REQUIREMENTS.md**
- Epic-level feature breakdown
- User stories with acceptance criteria (Gherkin format)
- Priority matrix (MoSCoW: Must/Should/Could/Won't)
- Non-functional requirements (performance, security, scalability)
- Regulatory requirements (GDPR, data localization, if applicable)

**03_UX_BLUEPRINT.md** (this document)
- Screen inventory, navigation flows, design system
- User personas, journeys, wireframe references
- Reusable components, accessibility standards

**04_SYSTEM_ARCHITECTURE.md**
- C4 diagrams (Context, Container, Component, Code)
- Service boundaries and inter-service communication
- Data flow diagrams for critical paths (booking, payment, SOS)
- Security architecture (auth flow, encryption, API gateway)
- Scaling strategy and bottleneck analysis

**05_DATABASE_DESIGN.md**
- Full ER diagram with all entities and relationships
- Column-level schema definitions, types, constraints
- Index strategy (B-tree, GIN, vector indexes for pgvector)
- Migration strategy (Alembic), seed data plan
- Backup and disaster recovery plan

**06_API_DESIGN.md**
- OpenAPI 3.1 specification (YAML)
- Endpoint list with methods, paths, request/response schemas
- Authentication and authorization per endpoint
- Rate limiting, pagination, error response format
- WebSocket event definitions

**07_FLUTTER_ARCHITECTURE.md**
- Folder structure, code organization
- State management pattern (Riverpod providers)
- Navigation / routing (GoRouter)
- Code generation (freezed, json_serializable, retrofit)
- Theme and design system integration
- Offline-first strategy (SQLite, sync engine)

**08_BACKEND_ARCHITECTURE.md**
- FastAPI project structure, middleware chain
- SQLAlchemy models and repository pattern
- Celery task definitions (notifications, emails, cleanup)
- Testing strategy (pytest, fixtures, mocks)
- Logging, error handling, monitoring setup

**09_AI_ARCHITECTURE.md**
- ML model training pipeline (data collection, labeling, training, evaluation)
- RAG architecture (document ingestion, chunking, embedding, retrieval)
- Model serving strategy (ONNX, Triton, or FastAPI endpoints)
- A/B testing framework for model versions
- Monitoring (drift detection, accuracy tracking)

**10_DEPLOYMENT_GUIDE.md**
- Docker Compose for local development
- Kubernetes manifests for staging/production
- GitHub Actions workflows (lint → test → build → deploy)
- Environment variable configuration per environment
- Secrets management (Vault / GitHub Secrets)

**11_TESTING_STRATEGY.md**
- Unit testing expectations (coverage targets)
- Integration testing (API tests with test DB)
- E2E testing (Flutter integration tests, Playwright for web)
- Load testing (Locust / k6 for critical endpoints)
- QA process, bug reporting template, regression strategy

**12_LAUNCH_CHECKLIST.md**
- App Store / Play Store submission requirements
- Security penetration testing results
- Beta program plan (100 users, feedback collection)
- Performance benchmarks (P95 latency, crash rate targets)
- Go/no-go criteria
- Post-launch monitoring plan

### 19.4 Templates & Consistency

All documents follow a standard template:
- **Header:** Title, author, date, version, status (Draft/Review/Approved)
- **Change log:** Version history with dates and changes
- **Table of contents**
- **Body:** Structured with numbered sections
- **References:** Links to related documents
- **Decision log:** ADRs (Architecture Decision Records) embedded inline

---

## Appendix A: Screen Mapping Summary

| Category | Count | Priorities |
|----------|-------|------------|
| Authentication | 8 | P0: 5, P1: 3 |
| Customer App | 26 | P0: 20, P1: 4, P2: 2 |
| Mechanic App | 12 | P0: 7, P1: 3, P2: 2 |
| Admin Dashboard | 17 | P0: 9, P1: 5, P2: 3 |
| Website | 11 | P0: 4, P1: 4, P2: 2, P3: 1 |
| Shared/Overlay | 7 | P0: 4, P1: 3 |
| **Total** | **81** | **P0: 49, P1: 22, P2: 9, P3: 1** |

---

## Appendix B: Technology Stack Recommendations (Python-First)

| Layer | Technology | Notes |
|-------|-----------|-------|
| Mobile Apps | Flutter 3.x | Single codebase for iOS + Android |
| Web Apps | Next.js 14+ | Admin dashboard + landing site + portal |
| State Management | Riverpod 2.x | Customer + Mechanic apps |
| Navigation | GoRouter | Declarative, deep linking support |
| Maps | Google Maps Flutter | With OSM fallback for offline |
| Backend API | FastAPI (Python) | Async, auto OpenAPI docs, Pydantic validation |
| AI / ML | Python (PyTorch, transformers, LangChain, RAG) | Unified Python ecosystem with backend |
| ORM | SQLAlchemy 2.0 + Alembic | Async, migrations |
| Database | PostgreSQL + Redis | Primary + caching + pub/sub |
| Background Tasks | Celery + Redis | Async job queues |
| Real-time | WebSockets (FastAPI native) + Socket.io | Tracking, chat, notifications |
| Payments | Stripe / Razorpay | Region-dependent |
| Auth | JWT + OTP + OAuth2 (FastAPI middleware) | Social login optional |
| Search | PostgreSQL full-text + pgvector (for AI embeddings) | Unified DB approach |
| CI/CD | GitHub Actions | Lint, test, build, deploy |
| Container | Docker + Kubernetes | Scalable deployment |
| Monitoring | Sentry + DataDog / Prometheus | Error tracking + APM |

**Rationale:** Python everywhere (FastAPI backend + AI/ML services) eliminates language switching between backend logic and AI features. Flutter for mobile ensures fast iteration. PostgreSQL + pgvector handles both relational data and vector embeddings, reducing infrastructure complexity.

---

*End of Sprint 1 UX Blueprint Document*
