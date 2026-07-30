# Changelog

**Version:** 1.2.0  
**Last Updated:** 2026-07-30  

All notable changes to Mecha Connect will be documented in this file.

---

## [1.2.0] — 2026-07-30 — Sprint 1.7A

### Added
- Fuel Delivery feature foundation (`lib/features/fuel_delivery/`)
  - Models: FuelType, Vehicle, FuelOrder, FuelPartner, DeliveryLocation, PriceEstimate, TrackingInfo, OrderStatus, Invoice
  - Repository: FuelRepository with mock data, price calculation, partner assignment, order history, invoice generation
  - Services: FuelService, PricingService, LocationService, MockTrackingService
  - Providers: FuelProvider (state machine: initial/loading/ready/error/noLocation/noInternet/empty), OrderProvider, TrackingProvider
  - Screens: FuelHomeScreen with banner, fuel type card grid, quantity selector, price breakdown, partner cards
  - Widgets: FuelTypeCard, QuantitySelector, PriceBreakdown, FuelActionButton, FuelEmptyState, FuelErrorState, RecentOrderCard
  - Constants and utils (location math, preset quantities)
- "Set Manually" fallback button in `petrol_page.dart` when GPS unavailable

### Changed
- `petrol_page.dart` `_getCurrentLocation()`: added 10s `LocationSettings.timeLimit` + 12s `Future.timeout` to prevent indefinite GPS hang
- `petrol_page.dart` unavailable state: added "Set Manually" action button with default Bengaluru coordinates

### Fixed
- Blank Fuel Delivery screen on devices without GPS — now gracefully fails to unavailable state within 12 seconds

---

## [1.1.0] — 2026-07-29 — Sprint D5.1

### Added
- Repository hygiene report (`docs/05_reports/SPRINT_D5_HYGIENE_REPORT.md`)
- Widget smoke test (`test/widget_test.dart`)
- `venv/` to `.gitignore`

### Removed
- `reports/` folder (28 superseded files)
- 5 unused assets: `fuelbg.jpg`, `logo.jpg`, `mech.jpg`, `petrol.jpg`, `tr.jpg` (~3 MB)
- Empty `docs/07_templates/` folder
- Root-level `ui_blueprint.html` (moved to `docs/source/`)

### Changed
- `lib/Starting_screen/` → `lib/starting_screen/`, `Login.dart` → `login.dart`
- `lib/home/mock_data.dart` → `lib/home/home_data.dart`
- `README.md` folder structure diagram updated (removed legacy paths, added new directories)
- `docs/README.md` stats updated for current document count
- All affected imports updated across the codebase
- 9 oversized PNGs compressed (saved ~1.73 MB)

### Fixed
- `.vscode/settings.json` path (absolute → relative)
- README.md broken absolute paths → relative paths
- PROJECT_ARCHITECTURE.md sprint table → relative doc links

---

## [1.0.0] — 2026-07-29 — Sprint D1

### Added
- Documentation Audit Report (`AUDIT_REPORT.md`) with per-doc scoring
- 7 new blueprint documents:
  - `PRODUCT_REQUIREMENTS_DOCUMENT.md` (vision, personas, market analysis)
  - `BUSINESS_MODEL.md` (revenue, unit economics, growth)
  - `SYSTEM_ARCHITECTURE.md` (Mermaid diagrams: component, sequence, navigation)
  - `DEPLOYMENT.md` (build, CI/CD, release checklist)
  - `TEST_PLAN.md` (test strategy, coverage targets)
  - `FEATURE_SPECIFICATIONS.md` (per-feature spec with states)
  - `RISK_ANALYSIS.md` (risk register, tech debt, mitigations)
  - `THIRD_PARTY_SERVICES.md` (service inventory, API keys, rate limits)
- Mermaid diagrams to: AI_ARCHITECTURE.md, SYSTEM_ARCHITECTURE.md, DATABASE_SCHEMA.md, DEPLOYMENT.md, RISK_ANALYSIS.md, TEST_PLAN.md, THIRD_PARTY_SERVICES.md
- Document header standard: version, status, last_updated, owner, ToC, Related Docs on all docs
- Cross-reference synchronization across all 22 documents

### Changed
- PROJECT_ARCHITECTURE.md: version 1.0.0 → 1.1.0, consolidated sub-sprints (1.6.1–1.6.4 → Sprint 1.6)
- ROADMAP.md: consolidated sub-sprint rows, added Sprint D1 entry
- PROJECT_STATUS.md: added version header, related docs
- DESIGN_SYSTEM.md: added ToC, related docs, version header
- DATABASE_SCHEMA.md: added index strategy, migration plan diagram, related docs
- API_SPEC.md: added auth/pagination documentation, related docs
- AI_ARCHITECTURE.md: Mermaid dataflow diagram, model registry with accuracy metrics, related docs
- CONTRIBUTING.md: fixed path references (`docs/` → `docs/blueprint/`), added ToC, related docs

---

## [0.6.0] — 2026-07-29 — Sprint 1.6.4

### Added
- MechanicCard compact variant for Featured section (no action buttons, smaller photo)
- Skeleton loaders for Featured and Nearby mechanic sections
- Camera/Gallery placeholder actions in VehicleFormPage
- Horizontal scrollable brand selector with 14 brands
- Search hint "Search mechanics, services..."

### Changed
- MechanicCard: all Expanded → Flexible with TextOverflow.ellipsis (no overflow)
- MechanicCard: Call button touch target increased to 48×36px
- Featured mechanics: card width adapts to screen size
- Brand selector: Wrap → SingleChildScrollView + Row
- Search placeholder updated

### Fixed
- All RenderFlex overflow issues in mechanic cards
- Duplicate RatingBadge class definition
- `num` → `double` type mismatch in card width calculation

---

## [0.5.0+] — 2026-07-29 — Sprint 1.6.3

### Added
- "Service Completed" button on LiveTrackingScreen → navigates to JobCompletedScreen

### Removed
- `lib/screens/mechanic_map_screen.dart` (unreachable, superseded by MechanicHomeScreen)
- `lib/widgets/mechanic_card.dart` (duplicate of `lib/mechanic/widgets/mechanic_card.dart`)
- `lib/widgets/status_chip.dart` (dead code)

### Changed
- VehicleFormPage navigation → MechanicHomeScreen (already in place)

---

## [0.5.0] — 2026-07-28 — Sprint 1.6.2

### Added
- Responsive layout system (`ConstrainedContent`, `AppResponsive`)
- Tablet/desktop support with max-width 480px content centering
- ConstrainedContent wrapper on all mechanic screens

---

## [0.4.0+] — 2026-07-28 — Sprint 1.6.1

### Fixed
- Overflow in extended_price row (OrderScreen)
- Bottom nav overflow on small devices (use Flexible)
- Chat timestamp overflow
- Profile screen overflow (use ConstrainedContent)
- Back button in auth screens
- Theme color inconsistencies (hintStyle, cursorColor)
- Keyboard dismissal on login
- DrawerScreen crash (missing import)

### Changed
- Button sizing to prevent overflow
- Improved profile screen layout

---

## [0.4.0] — 2026-07-28 — Sprint 1.6

### Added
- Mechanic Booking Module (complete flow)
- MechanicHomeScreen with categories, featured, nearby
- MechanicDetailsScreen with skills, services, charges
- SelectServiceScreen with service selection
- BookingSummaryScreen with address and cost breakdown
- BookingConfirmationScreen with booking details
- LiveTrackingScreen with map and status
- JobCompletedScreen with summary
- RatingReviewScreen with star rating
- MechanicInfo model with mock data
- MechanicCard, ServiceChip, PrimaryActionButton widgets
- ServiceChip with animated selection

---

## [0.3.0] — 2026-07-27 — Sprint 1.5

### Added
- Complete dark mode (system auto-switch)
- Premium splash redesign (pulsing logo, staggered animations)
- Premium home redesign (vehicle health, staggered entrance, dark mode)
- Premium login (logo asset, dark mode inputs)
- Premium onboarding (glow effects, dark backgrounds)
- Premium drawer (dark mode, rounded icons)
- Improved typography hierarchy (hero sizes)
- New dark palette (#0E1117, #1A1D24, #FF6A2A)
- Brand shadows (orange glow)
- Larger touch targets (52dp)
- Removed legacy AppColors from main.dart

---

## [0.2.0] — 2026-07-26 — Sprint 1.4

### Added
- Material 3 theme (light + dark)
- Reusable widget library (14 components)
- Home Dashboard with emergency, vehicle health, services grid
- Bottom Navigation (Home, Orders, Chat, Profile)
- Profile screen with user info and settings
- AI Chat interface with message bubbles

### Changed
- Upgraded Splash UI (gradient, frosted glass, staggered animations)
- Upgraded Onboarding UI (Material icons, pill indicators, brand colors)
- Upgraded Login UI (brand header, theme inputs, keyboard submit, sign up link)

---

## [0.1.0] — 2026-07-25 — Sprint 1.1–1.3

### Added
- Initial project setup
- Splash screen with logo animation
- Onboarding flow (3 slides)
- Authentication (Login, Register, Forgot Password)
- Basic navigation structure

---

## [0.0.1] — 2026-07-20

### Added
- Flutter project initialization
- Basic folder structure
- pubspec.yaml configuration
