# UI Design System — Mecha Connect RC1

> Sprint 1.9b · Frozen design tokens · Source of truth: `lib/theme/`

All tokens below are frozen for RC1. No color/typography/spacing changes
without sprint sign-off (see `FRONTEND_LOCK_REPORT.md`).

## 1. Brand Colors (`lib/theme/app_colors.dart`)

### Brand / Logo
| Token | Hex |
|---|---|
| `brandOrange` | `#F15A22` |
| `brandOrangeLight` | `#FF7A4D` |
| `brandOrangeDark` | `#D44A15` |
| `brandOrangeSoft` | `#FFF3ED` |
| `brandBlue` | `#4285F4` |
| `brandBlueLight` | `#6BA3FF` |
| `brandBlueDark` | `#1565C0` |
| `brandBlueSoft` | `#EEF2FF` |

### Neutral Greys (Light)
`white #FFFFFF`, `grey50 #F8FAFC`, `grey100 #F1F5F9`, `grey200 #E2E8F0`,
`grey300 #CBD5E1`, `grey400 #94A3B8`, `grey500 #64748B`, `grey600 #475569`,
`grey700 #334155`, `grey800 #1E293B`, `grey900 #0F172A`.

### Dark Mode Palette (premium, not inversion)
| Token | Hex |
|---|---|
| `darkBg` | `#0E1117` |
| `darkCard` | `#1A1D24` |
| `darkSurface` | `#232833` |
| `darkBorder` | `#313846` |
| `darkBorderLight` | `#2A2F3A` |
| `darkPrimary` | `#FF6A2A` |
| `darkText` | `#FFFFFF` |
| `darkTextSecondary` | `#B7BDC8` |
| `darkTextTertiary` | `#6B7280` |

### Semantic
| Token | Hex | Pair (light/dark) |
|---|---|---|
| `success` / `successLight` / `successDark` | `#10B981` / `#D1FAE5` / `#065F46` |
| `error` / `errorLight` / `errorDark` | `#EF4444` / `#FEE2E2` / `#7F1D1D` |
| `warning` / `warningLight` / `warningDark` | `#F59E0B` / `#FEF3C7` / `#78350F` |
| `info` / `infoLight` / `infoDark` | `#3B82F6` / `#DBEAFE` / `#1E3A5F` |

### Text
`textPrimary #0F172A`, `textSecondary #475569`, `textTertiary #94A3B8`,
`textOnPrimary #FFFFFF`, `textOnError #FFFFFF`.

### Surfaces / Borders
`surfaceLight #F8FAFC`, `surfaceDark #0E1117`, `cardLight #FFFFFF`,
`cardDark #1A1D24`, `borderLight #E2E8F0`, `borderDark #313846`.

### Glass
`glassWhite 0x0DFFFFFF`, `glassWhiteMed 0x1AFFFFFF`, `glassWhiteStrong 0x33FFFFFF`,
`glassDark 0x0D000000`, `glassDarkMed 0x1A000000`.

### Gradient Stops
`gradientStart #F15A22`, `gradientMid #E8451A`, `gradientEnd #D44A15`.

### Legacy aliases (kept)
`primaryBlue = brandBlue`, `accentOrange = brandOrange`, `backgroundWhite`,
`backgroundLightGrey`, `backgroundInputFill`, `borderGrey`, `iconDefault`,
`iconActive`, `successGreen`, `errorRed`.

## 2. Spacing (`lib/theme/app_spacing.dart`)

Scale (4px base): `xxs 2` · `xs 4` · `sm 8` · `md 12` · `base 16` · `lg 20` ·
`xl 24` · `xxl 32` · `xxxl 40` · `xxxxl 48` · `hero 64`.

Common `EdgeInsets`: `pageH` (h:16), `pageAll` (16), `cardH` (h:16 v:12),
`cardAll` (16), `buttonH` (h:24).

### Corner Radius
`radiusXs 6` · `radiusSm 10` · `radiusMd 14` · `radiusLg 18` · `radiusXl 22` ·
`radiusXxl 28` · `radiusFull 999`. Mirrored `BorderRadius` helpers `brXs`…`brFull`.

## 3. Elevation & Shadows (`AppElevation`)

Levels: `none 0` · `low 1` · `medium 2` · `high 3` · `higher 4` · `highest 5`.

- Light shadows: `shadowLow` (4/1), `shadowMedium` (12/3), `shadowHigh` (20/6),
  `shadowHigher` (32/10), `shadowHighest` (48/16) — black with low alpha.
- Brand glow: `shadowBrand` (orange 25% @ 20/6), `shadowBrandLight` (orange 12% @ 12/3).
- Dark shadows: `shadowDarkLow/Medium/High` (black 10–20% alpha).

## 4. Typography

- Display/headings favor the **Space Grotesk** family (e.g. dashboard greeting
  `fontFamily: 'Space Grotesk', w700`); body uses the platform default stack.
- Scale is responsive: see `AppResponsive.scaleFont` below (clamped 0.88–1.2).
- Sizes follow a 12/13/14/16/20/28/32-ish hierarchy with weights
  w500/w600/w700 depending on emphasis; see `theme/app_theme.dart` text styles.

## 5. Responsive System (`lib/theme/app_responsive.dart`)

| Constant | Value |
|---|---|
| Breakpoint `mobile` | 600 |
| Breakpoint `tablet` | 1024 |
| `getDeviceType` | width < 600 → mobile; < 1024 → tablet; else desktop |

Scalers (clamped to a 390px design width):
- `scale(base)` clamp `0.85–1.3`
- `scaleFont(base)` clamp `0.88–1.2`
- `scaleIcon(base)` clamp `0.9–1.15`
- `scaleWidth / scaleHeight` percent-based

Helpers:
- `responsive<T>(context, mobile, tablet, desktop)` — desktop falls back to
  tablet then mobile; tablet falls back to mobile.
- `gridColumns(context)` → mobile 2 / tablet 3 / desktop 4.
- `horizontalPadding(context)` → mobile 16 / tablet 24 / desktop 32.
- `ConstrainedContent` — centers child and caps width at
  `contentMaxWidth` (480 on tablet/desktop).

## 6. Theme Mode

- `ThemeProvider` (`lib/theme/theme_provider.dart`): `ThemeMode.system` default;
  persists index to SharedPreferences key `theme_mode`; labels
  "Follow System / Light / Dark".
- `AppTheme.light` and `AppTheme.dark` wired into `MaterialApp`
  (`theme` / `darkTheme` / `themeMode`).
- Screens read theme through `Theme.of(context).brightness` and the
  `app_theme_helpers.dart` context getters (`cardBg`, `border`, `accent`,
  `textTertiary`, …), so components adapt automatically.

## 7. UI Pattern Inventory (frozen)

- **Loading / Empty / Error:** dedicated state widgets per module; loaders
  feature the brand repeating-animation pattern (files under
  `lib/features/*/widgets/` and `lib/widgets/`); error states offer retry and
  surface the repository's simulated error messages.
- **Cards:** rounded (`radiusMd`–`radiusLg`), soft shadows, sectioned content;
  standard card padding `cardH`/`cardAll`.
- **Bottom nav:** `GNav` with `activeColor = accent`, `tabBackgroundColor =
  accent @ 8%`, `tabBorderRadius 12`, icon size 22, text w600 @ 12.
- **Buttons:** pill-shaped (`radiusFull`), brand gradient/orange primary,
  tonal secondary; see theme button styles.
- **Forms:** rounded input fills using `backgroundInputFill` (`grey50`),
  bordered with `borderGrey`.
- **A11y:** interactive controls expose `Semantics` (added for steppers, search
  bar, SOS card in 1.9b); text contrast verified in dark mode (e.g. empty star
  now `white38` in dark).
