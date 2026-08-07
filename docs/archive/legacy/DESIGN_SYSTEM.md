# Mecha Connect — Design System

**Version:** 1.1.0  
**Status:** Active  
**Last Updated:** 2026-07-29  
**Owner:** Design Team  

---

## Table of Contents

1. [Brand Identity](#brand-identity)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Spacing](#spacing)
5. [Corner Radius](#corner-radius)
6. [Elevation](#elevation)
7. [Component Library](#component-library)
8. [Related Documents](#related-documents)

---

## Brand Identity

**Tesla × Uber × Google Maps × Apple**

| Attribute | Direction |
|-----------|-----------|
| Automotive | Mechanical precision, reliability |
| AI-Powered | Intelligence, speed |
| Premium Startup | Clean, confident, modern |
| Emergency | Trust under pressure, fast response |
| Indian Market | ₹ pricing, local context |

### Brand Pillars
1. **Speed** — Emergency assistance in seconds
2. **Trust** — Verified mechanics, transparent pricing
3. **Intelligence** — AI diagnosis, smart matching
4. **Simplicity** — Complex problems, simple solutions

---

## Color System

### Source of Truth (from Logo)

```
Logo Orange:    #F15A22  (primary brand, CTA, accents)
Logo Dark:      #1A1A2E  (near-black, text, backgrounds)
Logo White:     #FFFFFF  (clean space, contrast)
```

### Brand Palette

| Token | Color | Hex |
|-------|-------|-----|
| brand-orange | Primary | `#F15A22` |
| brand-orange-light | Hover | `#FF7A4D` |
| brand-orange-dark | Pressed | `#D44A15` |
| brand-orange-soft | Background | `#FFF3ED` |
| brand-blue | Accent | `#4285F4` |
| brand-blue-light | Hover | `#6BA3FF` |
| brand-blue-dark | Pressed | `#1565C0` |
| brand-blue-soft | Background | `#EEF2FF` |

### Neutrals

| Grey | Hex |
|------|-----|
| 50 | `#F8FAFC` |
| 100 | `#F1F5F9` |
| 200 | `#E2E8F0` |
| 300 | `#CBD5E1` |
| 400 | `#94A3B8` |
| 500 | `#64748B` |
| 600 | `#475569` |
| 700 | `#334155` |
| 800 | `#1E293B` |
| 900 | `#0F172A` |

### Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| success | `#10B981` | Confirmed, completed |
| success-light | `#D1FAE5` | Success backgrounds |
| error | `#EF4444` | Destructive actions |
| error-light | `#FEE2E2` | Error backgrounds |
| warning | `#F59E0B` | Alerts |
| warning-light | `#FEF3C7` | Warning backgrounds |
| info | `#3B82F6` | Informational |
| info-light | `#DBEAFE` | Info backgrounds |

### Dark Mode Palette

| Token | Hex |
|-------|-----|
| bg-primary | `#0E1117` |
| card | `#1A1D24` |
| surface | `#232833` |
| border | `#313846` |
| border-light | `#2A2F3A` |
| text-primary | `#FFFFFF` |
| text-secondary | `#B7BDC8` |
| text-tertiary | `#6B7280` |
| accent (orange) | `#FF6A2A` |

---

## Typography

### Font Stack

| Priority | Font | Usage |
|----------|------|-------|
| Display | Space Grotesk | Headings, hero text, stats, brand moments |
| Body | Inter | Body text, labels, inputs, descriptions |

### Type Scale

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| hero-lg | 40px | 700 | Hero headings |
| hero-md | 36px | 700 | Primary hero text |
| hero-sm | 32px | 700 | Secondary hero text |
| display-lg | 28px | 700 | Screen titles |
| display-md | 24px | 700 | Section headers |
| display-sm | 20px | 600 | Sub-section headers |
| headline-lg | 18px | 700 | Card titles |
| headline-md | 16px | 600 | Sub-headings |
| headline-sm | 15px | 600 | List item titles |
| title-lg | 16px | 600 | Item titles |
| title-md | 14px | 600 | List item labels |
| title-sm | 13px | 600 | Chip labels |
| body-lg | 15px | 400 | Primary body text |
| body-md | 14px | 400 | Default body text |
| body-sm | 13px | 400 | Descriptions |
| label-lg | 14px | 600 | Button text, chip labels |
| label-md | 12px | 600 | Section labels, captions |
| label-sm | 11px | 500 | Badges, timestamps |
| caption | 10px | 500 | Fine print, helper text |
| overline | 10px | 600 | Overline text (letter-spacing 1.2) |

---

## Spacing

Base unit: **4px**. All spacing must be a multiple of 4.

| Token | Value |
|-------|-------|
| xxs | 2px |
| xs | 4px |
| sm | 8px |
| md | 12px |
| base | 16px |
| lg | 20px |
| xl | 24px |
| xxl | 32px |
| xxxl | 40px |
| xxxxl | 48px |
| hero | 64px |

---

## Corner Radius

| Token | Value |
|-------|-------|
| xs | 6px |
| sm | 10px |
| md | 14px |
| lg | 18px |
| xl | 22px |
| xxl | 28px |
| full | 999px |

---

## Elevation

Soft shadows with orange glow on brand elements.

| Level | Blur | Offset | Color |
|-------|------|--------|-------|
| low | 4px | 0,1 | 8% black |
| medium | 12px | 0,3 | 12% black |
| high | 20px | 0,6 | 18% black |
| brand | 20px | 0,6 | Orange 25% |

---

## Component Library

45+ reusable components in `lib/widgets/`:
- `app_avatar.dart` — User avatar with fallback
- `app_badge.dart` — Notification count badge
- `app_bottom_sheet.dart` — Modal bottom sheet
- `app_button.dart` — Primary/secondary/outline buttons
- `app_card.dart` — Elevated card container
- `app_chip.dart` — Selectable chip
- `app_dialog.dart` — Alert/confirm dialogs
- `app_empty_state.dart` — Empty state placeholder
- `app_error_state.dart` — Error state with retry
- `app_input.dart` — Themed text field
- `app_loading.dart` — Loading spinner + shimmer
- And 35+ more

For full reference see: `02_architecture/DESIGN_SYSTEM.md`

---

## Related Documents

- [FEATURE_SPECIFICATIONS.md](../01_product/FEATURE_SPECIFICATIONS.md) (component usage per feature)
- [PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md) (design system section)
- [CONTRIBUTING.md](../03_development/CONTRIBUTING.md) (code standards for theme usage)

