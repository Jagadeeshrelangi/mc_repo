# Screenshot Manifest — Mecha Connect

> Phase 6 · Capture plan for the handbook. No screenshots captured yet at RC1
> (no golden/screenshot tests). Placeholders describe each required capture.

## Conventions
- Device: 390×844 logical px (mobile reference), light + dark where noted.
- Format: PNG, `@{2,3}x` for device-pixel-density variants.
- Naming: `{module}-{screen}-{variant}.png` e.g. `marketplace-productdetail-light.png`.
- Every screenshot maps to a Handbook chapter for figure placement (see `08_assets/figures/`).

## Shell & Entry
| Screen | File | Notes |
|---|---|---|
| Splash | `shell-splash.png` | warm gradient + logo, breathing glow |
| Onboarding | `shell-onboarding-p1..p3.png` | 3 pages + Get Started |
| Home dashboard | `home-dashboard-light.png` / `-dark.png` | quick services, offers, activities |
| Services tab | `home-services.png` | service cards + drawer |
| Orders tab | `orders-tab.png` | category filters All/Parts/Mechanic/Fuel/AI |
| Bottom nav | `shell-bottomnav.png` | GNav 5 tabs, active accent |

## Auth
| Screen | File |
|---|---|
| Login | `auth-login.png` |
| Sign Up | `auth-signup.png` |
| Forgot password | `auth-forgot.png` |

## AI (tab 3)
| Screen | File |
|---|---|
| AI home | `ai-home.png` |
| Chat | `ai-chat.png` |
| Guided diagnosis | `ai-diagnosis.png` |
| History | `ai-history.png` |
| Conversation detail | `ai-conversation.png` |

## Marketplace (Services tab)
| Screen | File |
|---|---|
| Marketplace home | `marketplace-home.png` |
| Category | `marketplace-category.png` |
| Product detail | `marketplace-productdetail-light.png` / `-dark.png` |
| Search | `marketplace-search.png` |
| Cart | `marketplace-cart.png` |
| Wishlist | `marketplace-wishlist.png` |
| Checkout | `marketplace-checkout.png` |
| Order success | `marketplace-ordersuccess.png` |

## Mechanic (Services tab)
| Screen | File |
|---|---|
| Mechanic home | `mechanic-home.png` |
| Nearby mechanics | `mechanic-nearby.png` |
| Mechanic details | `mechanic-details.png` |
| Select service | `mechanic-selectservice.png` |
| Vehicle form (diagnosis) | `mechanic-vehicleform.png` |
| Booking summary | `mechanic-summary.png` |
| Booking confirmation | `mechanic-confirmation.png` |
| Live tracking | `mechanic-livetracking.png` |
| Job completed | `mechanic-completed.png` |
| Rating & review | `mechanic-rating.png` |
| Booking history | `mechanic-history.png` |

## Fuel Delivery (Services tab)
| Screen | File |
|---|---|
| Fuel home | `fuel-home.png` |
| Fuel booking | `fuel-booking.png` |
| Payment | `fuel-payment.png` |
| Order confirmation | `fuel-confirmation.png` |
| Live tracking | `fuel-livetracking.png` |
| Order complete | `fuel-complete.png` |
| Receipt / invoice | `fuel-receipt.png` |
| Order history | `fuel-history.png` |

## Profile (tab 4)
| Screen | File |
|---|---|
| Profile | `profile-home.png` |
| Edit profile | `profile-edit.png` |
| My vehicles | `profile-vehicles.png` |
| Vehicle detail | `profile-vehicledetail.png` |
| Saved addresses | `profile-addresses.png` |
| Wallet | `profile-wallet.png` |
| Rewards | `profile-rewards.png` |
| Order history | `profile-orders.png` |
| Notification settings | `profile-notifications.png` |
| Privacy & security | `profile-privacy.png` |
| Support | `profile-support.png` |
| About | `profile-about.png` |

## Capture instructions
1. Run `flutter run -d chrome --dart-define=ENABLE_DEVICE_PREVIEW=false` (or emulator) on the 390×844 viewport.
2. Navigate to each screen via the flows in `05_navigation/route_maps.md`.
3. Capture light mode; capture dark variant for Home dashboard, Product detail, and any
   screen with dark-token risk (see `UI_DESIGN_SYSTEM.md` §6).
4. Keep 16:9-free, rounded-corner-free device frame for figure reuse.
