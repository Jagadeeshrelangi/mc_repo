# Mecha Connect — RC1 Checklist

**Release:** RC1 · Frontend Lock Candidate
**Date:** 2026-08-05 · Flutter 3.29.2

Use this checklist to verify the RC1 release is complete and safe to certify
and hand to Sprint 2. Every gate below is currently **PASS** at the time of
writing.

## A. Verification Gates

- [x] `flutter analyze` → **No issues found!** (0 errors, 0 warnings)
- [x] `flutter test` → **162 / 162 passing**
- [x] No RenderFlex overflow at 320/360/390/412/600/768dp, light + dark
- [x] No dead code / orphan files (29 legacy files removed at freeze)
- [x] No dev flags or runtime-trace wiring in `main.dart`
- [x] No real HTTP in mock paths (audit-verified)
- [x] Interactive controls have semantics/tooltips and ≥44dp targets
- [x] Controllers and timers disposed (no leaks after route pops)

## B. Freeze & Certification

- [x] Frontend freeze signed in `FRONTEND_LOCK_REPORT.md`
- [x] `QA_CERTIFICATION_REPORT.md` records PASS evidence
- [x] `PROJECT_STATUS_REPORT.md` reflects candidate status
- [x] All active docs use "Frontend Lock Candidate" wording (no "RC1
      Certified")
- [x] Master Handbook regenerated as the official 21-chapter book
- [x] Release docs generated: release notes, checklist, version history,
      license guide, copyright notice, release report

## C. Documentation Consistency

- [x] 162/162 test count consistent across QA report, lock report, handbook
- [x] Test file paths match the repository (`test/*_module_test.dart`)
- [x] Version/date consistent: 2026-08-05, v1.0.0, Flutter 3.29.2
- [x] No TODO / FIXME / draft markers in active canonical docs
- [x] Changelog has a release entry

## D. Repository Hygiene

- [x] `git status` clean of untracked junk / debug files
- [x] Commits follow Conventional Commits on `main`
- [x] No secrets or `.env` staged
- [x] PDF and DOCX of the handbook generated from the markdown source

## E. Release Commands (manual — do not auto-run)

```bash
git add .
git commit -m "docs: finalize RC1 frontend release documentation"
git push origin main
git tag -a v1.0.0-rc1 -m "Mecha Connect Frontend RC1"
git push origin v1.0.0-rc1
```

## F. Post-Release (Sprint 2 Entry)

- [ ] Backend team implements `API_CONTRACT.md` behind the repository seams
- [ ] Re-run the 162-test suite after every backend contract change
- [ ] Re-run the four-part frontend audit before final 1.0.0 production release
