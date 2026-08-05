# Mecha Connect — Documentation

**Version:** 1.9.2 (RC1 · Frontend Lock Candidate) | **Last Updated:** 2026-08-05

---

## Project Overview

Mecha Connect is a Flutter application that brings every vehicle service into
one app: a parts marketplace, mechanic booking with live tracking, fuel
delivery with invoicing, an AI assistant with guided diagnosis, and a profile
with wallet & rewards.

- **Frontend:** Flutter 3.29.2 (Provider state management)
- **Data layer (RC1):** in-memory mock repositories with simulated latency
  and failure injection (`docs/07_rc1_certification/API_CONTRACT.md`)
- **Next milestone:** Sprint 2 backend integration (FastAPI + PostgreSQL)
  implementing the frozen `API_CONTRACT.md` + `DATABASE_BLUEPRINT.md`

**Status:** Frontend Lock Candidate — `flutter analyze` clean, **162/162 tests
passing**.
See [Frontend Certification](#frontend-certification).

---

## Folder Structure

```
docs/
│
├── README.md                           ← You are here
├── PROJECT_DOCUMENTATION_INDEX.md      ← Master navigation index
│
├── 01_product/                         ← Vision, requirements, business
├── 03_development/                     ← Installation, deployment, testing, changelog
├── 05_reports/                         ← Active sprint & QA reports
├── 07_rc1_certification/               ← Canonical frontend documentation
│
├── archive/                            ← Superseded / historical documents
├── source/                             ← All non-Markdown assets
└── design_reference/                   ← Design reference material
```

---

## Documentation Guide

| Folder | Contents | Status |
|---|---|---|
| `01_product/` | Business model, requirements, feature specs, roadmap, risk | Living docs |
| `03_development/` | Install, contribute, deploy, test plan, changelog | Living docs |
| `05_reports/` | Active sprint/QA reports | Read-only snapshots |
| `07_rc1_certification/` | **Canonical frontend documentation (frozen)** | Frozen |
| `archive/` | Superseded docs & historical sprint notes | Historical |
| `source/` | PRD PDFs, decks, images, videos, HTML | Assets |

---

## Reading Order

New developer or evaluator — read in this order:

1. **[PROJECT_DOCUMENTATION_INDEX.md](PROJECT_DOCUMENTATION_INDEX.md)** — master navigation
2. **[07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md](07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md)** — master engineering handbook
3. **[07_rc1_certification/FRONTEND_LOCK_REPORT.md](07_rc1_certification/FRONTEND_LOCK_REPORT.md)** — what is frozen and why
4. **[07_rc1_certification/FRONTEND_ARCHITECTURE.md](07_rc1_certification/FRONTEND_ARCHITECTURE.md)** — how the app is built
5. **[07_rc1_certification/NAVIGATION_MAP.md](07_rc1_certification/NAVIGATION_MAP.md)** — how the user moves through the app
6. **[07_rc1_certification/UI_DESIGN_SYSTEM.md](07_rc1_certification/UI_DESIGN_SYSTEM.md)** — visual language & tokens
7. **[07_rc1_certification/API_CONTRACT.md](07_rc1_certification/API_CONTRACT.md)** — the contract Sprint 2 must implement
8. **[07_rc1_certification/DATABASE_BLUEPRINT.md](07_rc1_certification/DATABASE_BLUEPRINT.md)** — target database schema
9. **[07_rc1_certification/QA_CERTIFICATION_REPORT.md](07_rc1_certification/QA_CERTIFICATION_REPORT.md)** — test evidence (162/162)
10. **[03_development/INSTALLATION.md](03_development/INSTALLATION.md)** — run it locally

---

## Frontend Certification

Canonical, frozen documentation for the Frontend Lock Candidate frontend:

| Document | Description |
|---|---|
| [MECHA_CONNECT_MASTER_HANDBOOK.md](07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md) | **Official Master Handbook (v1.0.0, 21 chapters)** |
| [MECHA_CONNECT_MASTER_HANDBOOK.pdf](07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.pdf) | Handbook PDF (submission-ready) |
| [MECHA_CONNECT_MASTER_HANDBOOK.docx](07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.docx) | Handbook DOCX (Word, editable) |
| [FRONTEND_LOCK_REPORT.md](07_rc1_certification/FRONTEND_LOCK_REPORT.md) | Freeze list, governance, change log |
| [FRONTEND_ARCHITECTURE.md](07_rc1_certification/FRONTEND_ARCHITECTURE.md) | Provider graph, module tree, integration seams |
| [UI_DESIGN_SYSTEM.md](07_rc1_certification/UI_DESIGN_SYSTEM.md) | Frozen design tokens & patterns |
| [NAVIGATION_MAP.md](07_rc1_certification/NAVIGATION_MAP.md) | 5-tab shell + all flow maps |
| [API_CONTRACT.md](07_rc1_certification/API_CONTRACT.md) | Frozen mock API contract (Sprint 2 spec) |
| [DATABASE_BLUEPRINT.md](07_rc1_certification/DATABASE_BLUEPRINT.md) | PostgreSQL schema blueprint |
| [QA_CERTIFICATION_REPORT.md](07_rc1_certification/QA_CERTIFICATION_REPORT.md) | Certification evidence (162/162) |
| [PROJECT_STATUS_REPORT.md](07_rc1_certification/PROJECT_STATUS_REPORT.md) | RC1 status, next steps, risks |
| [RC1_RELEASE_REPORT.md](07_rc1_certification/RC1_RELEASE_REPORT.md) | Full RC1 release report |
| [RELEASE_NOTES_RC1.md](07_rc1_certification/RELEASE_NOTES_RC1.md) | RC1 release notes |
| [RC1_CHECKLIST.md](07_rc1_certification/RC1_CHECKLIST.md) | Release gates + tag/push commands |
| [VERSION_HISTORY.md](07_rc1_certification/VERSION_HISTORY.md) | Release-level version summary |
| [LICENSE_GUIDE.md](07_rc1_certification/LICENSE_GUIDE.md) | Project + dependency licensing |
| [COPYRIGHT_NOTICE.md](07_rc1_certification/COPYRIGHT_NOTICE.md) | Copyright & confidentiality notice |

---

## Development Workflow

1. Feature work happens in modules under `lib/features/`.
2. Every change is verified with `flutter analyze` (0 issues) and
   `flutter test` (162/162).
3. Repositories are the only data source — the UI never calls the network
   directly (see `FRONTEND_ARCHITECTURE.md`).
4. Sprint reports go to `05_reports/` (active) or `archive/` (superseded).
5. Changelog: append to `03_development/CHANGELOG.md` (see
   [CONTRIBUTING.md](03_development/CONTRIBUTING.md)).

---

## Backend Preparation (Sprint 2)

Sprint 2 replaces the mock repository internals with a real backend. The
frontend is contract-frozen, so no UI changes are required:

| Requirement | Reference |
|---|---|
| API surface | `07_rc1_certification/API_CONTRACT.md` |
| Database schema | `07_rc1_certification/DATABASE_BLUEPRINT.md` |
| ID schemes, latency, failure conventions | `API_CONTRACT.md` §1 |
| Repository seams | `FRONTEND_ARCHITECTURE.md` §8 |

---

## Archive

Historical and superseded documents are preserved in `archive/`:

- Legacy architecture (AI_ARCHITECTURE, DATABASE_SCHEMA, DESIGN_SYSTEM,
  PROJECT_ARCHITECTURE, SYSTEM_ARCHITECTURE)
- Legacy API draft (`API_SPEC`)
- Sprint reports 1.1–1.7 and legacy QA/hygiene reports
- Historical engineering sprint notes (sprint-1.3 … sprint-1.8.3)

See [PROJECT_DOCUMENTATION_INDEX.md](PROJECT_DOCUMENTATION_INDEX.md) → Archive.

---

## References

- Source assets (PRD PDFs, decks, images, videos): `source/`
- Full navigation: [PROJECT_DOCUMENTATION_INDEX.md](PROJECT_DOCUMENTATION_INDEX.md)
- Root repository README: [`../README.md`](../README.md)

---

## Conventions

- Markdown folders contain **Markdown only**; all assets live in `source/`.
- Cross-references use relative paths from the file's own folder.
- Reports are read-only snapshots; all other docs are living documents.
- Canonical frontend docs are frozen — changes require sprint sign-off.
