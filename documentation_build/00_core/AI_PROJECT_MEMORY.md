# AI PROJECT MEMORY — Mecha Connect

> **Documentation Build v2.1 · AI Knowledge Optimization · 2026-08-05**
> Persistent memory for continuity across AI sessions. Read this file at the
> start of every new AI session to understand the project's current state.

## 1. Project Identity

- **Product:** Mecha Connect — "Uber + Swiggy + AI Assistant" for vehicle services
- **Stage:** RC1 Frontend Lock Candidate (frontend frozen 2026-08-02)
- **Version:** 1.0.0+1 (RC1 release candidate)
- **Stack:** Flutter 3.29.2 / Dart ^3.7.2 (client) · FastAPI + PostgreSQL 15 + Redis (backend, Sprint 2)
- **Repo:** `github.com/Jagadeeshrelangi/mc_repo` (branch `main`)
- **Tests:** 162/162 passing · `flutter analyze` 0 issues

## 2. Current Phase

- **Phase 4 — Documentation Build v2.1 (AI Knowledge Optimization)** — IN PROGRESS
- **Phase 0 — Complete Engineering Audit** — COMPLETE (APPROVED 2026-08-05)
- Next phase after v2.1: Phase 5 (Master Handbook), then Phase 6 (Cleanup), Phase 7 (Git), Phase 8 (Sprint 2)

## 3. What Was Just Completed (v2.1)

| Artifact | Location |
|---|---|
| Regenerated knowledge_graph.json (v2.1 structure) | `09_exports/knowledge_graph.json` |
| Updated MASTER_PROJECT_DATA.json | `09_exports/MASTER_PROJECT_DATA.json` |
| Updated MASTER_PROJECT_KNOWLEDGE_BASE.md | `01_knowledge/MASTER_PROJECT_KNOWLEDGE_BASE.md` |
| GAP_ANALYSIS.md | `archive/engineering_review/` |
| AI_PROJECT_MEMORY.md | `00_core/` (this file) |
| PROJECT_TIMELINE.md | `00_core/` |
| PROJECT_OPERATING_MANUAL.md | `00_core/` |
| Phase 0 Engineering Audit (14 files) | `archive/engineering_review/` |

## 4. Key Decisions Made

1. **Audit approved** — Phase 0 Engineering Audit is the official Sprint 2 baseline.
2. **Handbook is Version 1** — `01_knowledge/MECHA_CONNECT_MASTER_HANDBOOK.md` is canonical; v2.1 only prepares enrichment, does NOT regenerate.
3. **Single documentation tree** — `documentation_build/` is canonical; legacy `docs/` was fully consolidated into it.
4. **No git operations** — Phase 7 blocked until explicit approval.
5. **No backend work** — Sprint 2 blocked until Phase 7 approval.
6. **Entry order for AI:** PROJECT_CONTEXT → KNOWLEDGE_GRAPH → MASTER_PROJECT_KNOWLEDGE_BASE → MASTER_PROJECT_DATA.json → AUDIT_SUMMARY (`archive/engineering_review/AUDIT_SUMMARY.md`).

## 5. Critical Facts to Remember

- Repositories = sole data source; mock realism via latency + `failForFirstCalls` (only in Ai + Profile repos).
- `orderStore`/`ordersList` singletons power the Orders tab + Profile order history.
- `IndexedStack` keeps all 5 tabs alive → offstage widgets remain findable in tests.
- AI module shares ONE `AiRepository` across provider/service/diagnosis.
- Mechanic VehicleForm uses AI DiagnosisService (mock, no HTTP).
- Money = `double` INR (₹); timestamps ISO-8601 on wire payloads.
- Certification wording: "Frontend Lock Candidate", never "RC1 Certified".
- P0 findings: plaintext password, zero backend tests, no Alembic, unverified GEMINI_API_KEY, mock auth bypass, no auth tests.

## 6. What NOT to Do

- Do NOT modify anything outside `documentation_build/` (application code stays frozen).
- Do NOT generate a new handbook.
- Do NOT perform repository cleanup, git operations, or backend work.
- Do NOT invent architecture, APIs, workflows, screen names, seed data, or numbers.
- Do NOT fabricate screenshots.

## 7. Next AI Session — Start Here

1. Read `AI_PROJECT_MEMORY.md` (this file).
2. Read `PROJECT_CONTEXT.md` → `KNOWLEDGE_GRAPH.md` → `MASTER_PROJECT_KNOWLEDGE_BASE.md`.
3. Read `CANONICAL_DOCUMENT_MAP.md` for the single source of truth per topic.
4. Check `archive/engineering_review/AUDIT_SUMMARY.md` for the Sprint 2 baseline.
