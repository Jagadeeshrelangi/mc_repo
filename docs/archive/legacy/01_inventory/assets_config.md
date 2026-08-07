# Assets & Configuration Inventory — Mecha Connect

> Phase 1

## 1. Asset Files (`assets/`, 18 files — product/service images)

| Filename | Typical use (category) |
|---|---|
| `battery.png` | Spare-parts/product image (battery) |
| `bike tyre.jpg` | Spare-parts/product image |
| `break pads.png` | Spare-parts/product image (brake pads) |
| `car jack.png` | Tools/product image |
| `chain kit.png` | Spare-parts/product image |
| `clutch lever.png` | Spare-parts/product image |
| `Dashboard Camera.png` | Accessory/product image |
| `engine oil.png` | Consumable/product image |
| `fuel tank cap.png` | Spare-parts/product image |
| `gear knob.png` | Spare-parts/product image |
| `gps tracker.png` | Accessory/product image |
| `helmet lock.png` | Accessory/product image |
| `no_bg.png` | Transparent placeholder (e.g., logo/marketing) |
| `radiator.png` | Spare-parts/product image |
| `side_mirror.png` | Spare-parts/product image |
| `spark plugs.png` | Spare-parts/product image |
| `tool kit.png` | Tools/product image |
| `wipers.png` | Consumable/product image |

> Assets referenced from the marketplace `Product` model for display.
> Detail manifest with dimensions/captioning: Phase 7 `10_assets/asset_manifest.md`.

## 2. Runtime Configuration

| Key | Source | Purpose |
|---|---|---|
| `pubspec.yaml` version `1.0.0+1` | `pubspec.yaml` | Version |
| `.env` (app root, loaded via `flutter_dotenv`) | `lib/main.dart` | Future backend base URL etc. (currently minimal; load failure only logs) |
| `backend/.env` | `backend/` | `GEMINI_API_KEY`, DB/firebase creds for backend scaffold |
| `backend/app/core/config.py` | pydantic-settings | `PROJECT_NAME`, API version, env file path |

> At RC1 the Flutter client performs **no network calls**; `.env` is wiring for Sprint 2.
> Backend startup verifies `GEMINI_API_KEY` presence and logs a masked copy.

## 3. Environment / Build
- Debug-only `DevicePreview` via `enableDevicePreview = kDebugMode`.
- CI baseline: `flutter analyze` clean; `flutter test` 162/162.
- App entry assertions: splash decides onboarding vs session (`starting_screen`).
