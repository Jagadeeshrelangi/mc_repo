# Version Matrix — Mecha Connect

> Phase 7 · Frozen facts about versions, environment, and tooling.

## App & Environment
| Item | Value |
|---|---|
| App version (RC1) | `1.0.0+1` (pubspec.yaml) |
| Flutter | 3.29.2 |
| Dart | ^3.7.2 |
| Repo | `github.com/Jagadeeshrelangi/mc_repo`, branch `main` |
| Backend | FastAPI scaffold (non-venv), version string 1.0.0 |
| Python | 3.13 (`C:\Python313\python.exe`) |
| Package manager (client) | pub |

## Dependency Versions (client)
provider 6.1.5 · google_nav_bar 5.0.7 · device_preview 1.2.0 · shared_preferences 2.5.3 ·
flutter_dotenv 5.2.1 · latlong2 0.9.1 · geolocator 13.0.4 · permission_handler 11.4.0 ·
flutter_map 7.0.2 · http 1.6.0 · flutter_lints 5.0.0.

## Release History (head)
| Version | Date | Sprint |
|---|---|---|
| 1.0.0+1 | 2026-08-05 | RC1 Release |
| 1.9.2 | 2026-08-05 | 1.9b Final Review |
| 1.9.1 | 2026-08-05 | 1.9b Close |
| 1.9.0 | 2026-08-02 | 1.9B RC1 certification |
| 1.2.0 | 2026-07-30 | 1.7A Fuel delivery |
| … | … | 0.0.1 Init (2026-07-20) |

Release tag `v1.0.0-rc1` = documented manual step (RC1_CHECKLIST.md), **not yet created**.

## Verification Baseline (frozen)
- `flutter analyze` → 0 issues
- `flutter test` → 162/162 (AI 25 · Fuel 37 · Marketplace 43 · Profile 30 · Mechanic 10 · Vehicle location 8 · Home 3 · Integration 2 · Widget 4)
- `flutter build web` → passes

## Versioning Policy
dev-`{hash}` · alpha-`{build}` · beta-`{build}` · rc-`{build}` · production `{major}.{minor}.{patch}`.
