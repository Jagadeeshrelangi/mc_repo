# Mecha Connect — License Guide

**Date:** 2026-08-05

## 1. Project License

Mecha Connect is a **proprietary, confidential** project. The source code,
documentation, and design assets are the property of the Mecha Connect project
and may not be reproduced or distributed without explicit authorization.
No open-source license is granted by this document.

## 2. Dependency Licenses

All third-party packages are used under their respective licenses. The project
does not redistribute modified third-party source. Primary licenses in use:

| License | Typical packages |
|---|---|
| BSD-3-Clause | Flutter, provider, shared_preferences, google_nav_bar, device_preview |
| BSD-2-Clause | flutter_lints (inherits BSD-3/BSD-2) |
| MIT | latlong2, geolocator, permission_handler, flutter_map, flutter_dotenv, http |
| Apache-2.0 | dart sdk tooling (where applicable) |

The full authoritative list lives in `pubspec.yaml` / `pubspec.lock`.

## 3. Third-Party Services

- **Google** — Flutter/Dart tooling, Firebase (planned), Gemini API (planned)
- **OpenStreetMap** — map tiles (usage subject to the OSM tile usage policy)

Each service is governed by its own terms; credentials must never be committed.

## 4. Compliance Checklist

- [ ] Never commit API keys or `.env` files (`.env` is git-ignored).
- [ ] Retain third-party license notices for any distributed package.
- [ ] Attribute OpenStreetMap where map tiles are displayed (Sprint 2).
- [ ] Include this notice in any public release: "Mecha Connect © 2026 — all
      rights reserved."

## 5. This Handbook

The `MECHA_CONNECT_MASTER_HANDBOOK.md` and its generated PDF/DOCX are
**Internal / Confidential** (see `COPYRIGHT_NOTICE.md`).
