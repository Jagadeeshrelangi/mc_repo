# UI/UX — Mecha Connect

> Experience principles and user journeys at RC1. Token-level guidance lives in
> `Design_System.md`; detailed step-by-step flows live in `workflows/`.

## 1. Experience Principles

1. **Trust through transparency** — verified mechanics, honest ratings, and
   itemized pricing (fuel price breakdown: fuel + delivery + platform fee +
   taxes) on every booking.
2. **Speed to help** — SOS/breakdown access is one card away from the Services
   tab; live tracking with ETA at every step.
3. **Safety first** — GPS denial is handled with a state machine and manual
   address fallback; reduced-motion accessibility setting disables the hero
   carousel autoplay.
4. **No dead ends** — every async call has loading, empty, and error/retry
   states (mock repositories inject failures so these paths are real).
5. **Consistent mental model** — a unified Orders tab and profile order history
   read the same feed; vehicles/addresses always sort default-first.

## 2. Information Architecture

5-tab `IndexedStack` shell (all tabs stay mounted and stateful):

| Tab | Destination | Purpose |
|---|---|---|
| Home | HomeDashboard | Quick services, nearby, offers, activity |
| Services | ServiceSelectionScreen | Entry to Marketplace, Mechanic, Fuel, SOS |
| Orders | OrdersScreen | Unified order feed (Parts/Mechanic/Fuel/AI) |
| AI | AiHomeScreen | Chat, diagnosis, history |
| Profile | ProfileScreen | Account, wallet, rewards, vehicles, settings |

Only named route is `/` (Splash); everything else is imperative
`Navigator.push`.

## 3. Key User Journeys

- **Mechanic booking:** VehicleForm → nearby mechanics → details → select
  service → summary → confirm → live tracking → complete → rate.
- **Fuel delivery:** fuel type → saved vehicle → station near me → price
  estimate → payment → confirm → track → receipt/invoice.
- **Marketplace checkout:** browse catalog → product detail → cart →
  checkout → order success → appears in Orders tab.
- **AI diagnosis:** describe problem → structured diagnosis (confidence, cost,
  severity) → recommended action → deep-link into mechanic/fuel/marketplace.
- **Auth:** first launch → onboarding → login/signup → shell; logout returns to
  login.

## 4. Visual Language (summary)

Brand orange `#F15A22` on neutral slate greys; premium (non-inverted) dark mode
palette; Space Grotesk for display/headings; 4px spacing scale; pill buttons;
rounded cards (`radiusMd`–`radiusLg`). Full tokens: `Design_System.md`.

## 5. Accessibility

- `Semantics` exposed on steppers, search bar, and SOS card (added 1.9b).
- Dark-mode text contrast verified (e.g. empty star uses `white38` in dark).
- Accepted RC1 limits: white on `brandOrange` ≈ 3.37:1 below WCAG AA for body
  text — brand-mandated, revisit at Sprint 2 design sign-off.

## 6. Flow References

`workflows/`: auth_session_flow, mechanic_booking_flow, fuel_delivery_flow,
marketplace_checkout_flow, ai_diagnosis_flow, orders_tab_flow,
profile_vehicle_management_flow.
