# Documentation Audit — Phase 6 — Cross-Link Audit

> Pre-Sprint 2 Documentation Architecture Audit & Cleanup Sprint
> Date: 2026-08-05
> Method: automated scan of all 77 markdown links (77 files) + manual review

---

## 1. Broken Links

**Result: 0 broken markdown links.** Every relative link resolves to an
existing file. The link health of the tree is good.

## 2. Active Documents Pointing into `archive/` (4)

These are **valid** links today, but they defeat the archive boundary — active
docs should reference the current canonical source, not an archived one.

| Active doc | Links to archive | Should point to |
|---|---|---|
| `01_product/RISK_ANALYSIS.md` §5 | `archive/THIRD_PARTY_SERVICES.md` | `07_rc1_certification/LICENSE_GUIDE.md` + Handbook ch9 |
| `01_product/ROADMAP.md` Related Docs | `archive/PROJECT_ARCHITECTURE.md` | `MASTER_HANDBOOK.md` ch17 (once moved) |
| `03_development/CONTRIBUTING.md` Related Docs | `archive/PROJECT_ARCHITECTURE.md` | `MASTER_HANDBOOK.md` ch8/ch10 |
| `03_development/DEPLOYMENT.md` Related Docs | `archive/SYSTEM_ARCHITECTURE.md` | `MASTER_HANDBOOK.md` ch8 |

## 3. Stale References (plain text / non-link)

These do not break the link checker but will break or mislead after a reorg,
or are already wrong:

| Location | Issue | Fix |
|---|---|---|
| `docs/README.md` | References `design_reference/` folder — **does not exist** | Remove the line |
| `docs/README.md` | Says "27 active" era counts; folder tree lists removed folders | Regenerate tree from reality |
| Root `README.md` | Corrupted encoding (mojibake), references `02_architecture/04_sprints/06_reference` folders that no longer exist; stale versions (Flutter 3.19.0, FastAPI 0.110.0 vs current 3.29.2) | **Full rewrite** |
| `docs/archive/PROJECT_ARCHITECTURE.md` | Text mentions `docs/04_sprints/SPRINT_1_*.md` (folders removed) | Historical — leave as-is |
| `docs/archive/SPRINT_D5_HYGIENE_REPORT.md` / `_AUDIT.md` | Same removed-folder text refs | Historical — leave as-is |
| `PROJECT_STATUS_REPORT.md` §6 | Lists `docs/05_reports/SPRINT_1_9B_FINAL_REVIEW_REPORT.md` as plain text (not a link); path will change when report is archived | Convert to relative link after archive |
| `PROJECT_STATUS_REPORT.md` §3 / `PROJECT_STATUS.md` | Sprint tables duplicate Handbook ch17 | Replace with link to ch17 |
| `CHANGELOG.md` | Mentions `docs/05_reports/SPRINT_D5_HYGIENE_REPORT.md` (archived) and `docs/07_rc1_certification/...` paths | Historical log entries — acceptable; only current-path mentions updated |

## 4. Circular References

**None found** in active docs. Archive docs reference each other
(PROJECT_ARCHITECTURE ↔ SYSTEM_ARCHITECTURE ↔ API_SPEC ↔ DATABASE_SCHEMA
cluster) — acceptable within the archive, no action.

## 5. Orphaned Active Document

| File | Referenced from | Action |
|---|---|---|
| `05_reports/SPRINT_1_9B_FINAL_REVIEW_REPORT.md` | `PROJECT_STATUS_REPORT.md` (plain text only, not a link) | Add link or archive with path update |

All 43 archive files that are never referenced are fine — the archive is a
history shelf, not a dependency graph.

## 6. Repair List (consolidated)

| # | Repair | Files |
|---|---|---|
| 1 | Repoint 4 active→archive links to canonical docs | RISK_ANALYSIS, ROADMAP, CONTRIBUTING, DEPLOYMENT |
| 2 | Remove `design_reference/` mention | docs/README.md |
| 3 | Rewrite root `README.md` (mojibake + stale structure/versions) | README.md |
| 4 | Merge index into docs README | PROJECT_DOCUMENTATION_INDEX.md → README.md |
| 5 | Update all `docs/...` paths after reorg (convert to relative markdown links) | ~30 files (mechanical) |
| 6 | Handbook ch9/ch17 cross-link adoption | PRODUCT_STATUS, PROJECT_STATUS_REPORT, FEATURE_SPECIFICATIONS, ROADMAP, RISK_ANALYSIS |

## 7. Post-Migration Verification Command

Re-run the link audit script after migration — target: **0 broken, 0
active→archive links**:

```powershell
python "C:\Users\venka\AppData\Local\Temp\opencode\link_audit.py"
```
