# PROJECT TIMELINE — Mecha Connect

> **Canonical chronology · corrected 2026-08-06**
> Derived from `00_core/CHANGELOG.md` and the git history of
> `main`. This file supersedes the earlier 12-month narrative (2025-07 →
> 2026-06), which was inconsistent with the changelog, `VERSION_HISTORY.md`,
> and git.

## 1. Timeline

| Date | Version | Sprint | Milestone |
|---|---|---|---|
| 2026-07-20 | 0.0.1 | — | Flutter init, folder structure, pubspec |
| 2026-07-25 | 0.1.0 | Sprint 1.1–1.3 | Splash, onboarding, auth (login/register/forgot) |
| 2026-07-26 | 0.2.0 | Sprint 1.4 | M3 theme, home dashboard, bottom nav, AI chat |
| 2026-07-27 | 0.3.0 | Sprint 1.5 | Dark mode, premium splash/home/login/onboarding/drawer |
| 2026-07-28 | 0.4.0 | Sprint 1.6 | Mechanic booking module (full flow) |
| 2026-07-28 | 0.4.0+ | Sprint 1.6.1 | Overflow fixes, theme consistency, drawer crash fix |
| 2026-07-28 | 0.5.0 | Sprint 1.6.2 | Responsive layout system (`ConstrainedContent`) |
| 2026-07-29 | 0.5.0+ | Sprint 1.6.3 | Service-completed flow; removed dead mechanic screens |
| 2026-07-29 | 0.6.0 | Sprint 1.6.4 | Mechanic card variants, skeleton loaders, brand selector |
| 2026-07-29 | 1.0.0 | Sprint D1 | Documentation audit + 7 blueprint documents + cross-refs |
| 2026-07-29 | 1.1.0 | Sprint D5.1 | Repo hygiene, widget smoke test, `venv/` gitignored |
| 2026-07-30 | 1.2.0 | Sprint 1.7A | Fuel delivery module; **first git commit `0811e62`** |
| 2026-08-02 | 1.9.0 | Sprint 1.9B | RC1 certification docs (8), `OrderStore`, P0 fixes, 159/159 |
| 2026-08-05 | 1.9.1 | Sprint 1.9b close | Master handbook, widget tests ×4, a11y/performance fixes |
| 2026-08-05 | 1.9.2 | Sprint 1.9b review | Reduced motion, a11y, design-token unification |
| 2026-08-05 | 1.9.3 | RC1 Release | **Frontend Lock Candidate** — version `1.0.0+1`, 162/162, handbook pdf/docx, release docs |
| 2026-08-05 | — | Phase 0 | Engineering audit (14 reports) APPROVED; docs v2.1/v2.2 + refactor |
| 2026-08-06 | 1.9.3-docs | — | Independent engineering review + pre-Sprint-2 cleanup (this series) |

## 2. Git History

The git record on `main` begins mid-history at the 1.2.0 snapshot
(2026-07-30). Earlier versions (0.0.1–1.1.0) are documented in
`CHANGELOG.md` only.

| Commit | Date | Summary |
|---|---|---|
| `0811e62` | 2026-07-30 | Initial commit — Mecha Connect v2 |
| `d4f3828` | 2026-08-05 | docs: restructure documentation tree + indexes |
| `c98f12e` | 2026-08-05 | feat: feature-first v2 modules + full test suite (285 files) |
| `c313e0b` | 2026-08-05 | feat: Sprint 1.9b Frontend Lock & RC1 Certification |
| `85b856d` | 2026-08-05 | chore: remove archived legacy doc folders |
| `eca001e` | 2026-08-05 | fix: final-review a11y + design-token fixes |
| `0fc4b8d` | 2026-08-05 | docs: cert wording + final-review audit outcome |
| `adaad21` | 2026-08-05 | docs: add Sprint 1.9b final review report |
| `8ed10f6` | 2026-08-05 | docs: bump RC1 reference docs |
| `651ac60` | 2026-08-05 | docs: add RC1 release documents + handbook |
| `84b68f5` | 2026-08-05 | docs: sync status, changelog, doc index for RC1 |

## 3. Key Engineering Decisions

1. **Single-snapshot frontend rewrite** — commit `c98f12e` moved all UI into
   `lib/features/*` (feature-first v2), removing legacy `lib/widgets/*`.
2. **Repository pattern as the backend seam** — all 7 modules expose
   `XxxRepository`; UI never calls HTTP directly.
3. **`IndexedStack` tab persistence** — fixes the stale Orders-tab bug.
4. **Mock realism** via latency + `failForFirstCalls` (Ai + Profile only).
5. **Zero-budget posture** — in-memory rate limiting (no Redis), free-tier
   Gemini, local HuggingFace embeddings, CPU FAISS/XGBoost.
6. **"Frontend Lock Candidate" wording** — enforced repo-wide; no RC1 git tag.

## 4. Upcoming Roadmap

| Phase | Sprint | Target |
|---|---|---|
| Pre-Sprint 2 | — | Engineering cleanup (this series) — repo becomes Sprint 2 baseline |
| Sprint 2 | — | Backend integration (FastAPI, PostgreSQL, JWT, Firebase, Redis, real APIs) |
| Sprint 3 | — | Production polish (optimization, performance, accessibility, security, CI/CD) |
| Sprint 4 | — | Partner app |
| Sprint 5 | — | Admin dashboard |

## 5. Key Dates

- **Frontend frozen:** 2026-08-02 (Frontend Lock Candidate)
- **RC1 release docs:** 2026-08-05 (version `1.0.0+1`; no git tag issued)
- **Engineering audit approved:** 2026-08-05
- **Independent engineering review:** 2026-08-06
