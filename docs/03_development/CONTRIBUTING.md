# Mecha Connect — Contributing Guide

**Version:** 1.1.0  
**Status:** Active  
**Last Updated:** 2026-07-29  
**Owner:** Engineering Team  

---

## Table of Contents

1. [Development Setup](#development-setup)
2. [Code Standards](#code-standards)
3. [Sprint Workflow](#sprint-workflow)
4. [Git Guidelines](#git-guidelines)
5. [Quality Checklist](#quality-checklist-pre-commit)
6. [Architecture Overview](#architecture-overview)
7. [Related Documents](#related-documents)

---

## Development Setup

### Prerequisites
- Flutter SDK ^3.7.2
- Dart SDK ^3.7.2
- Python 3.10+ (for FastAPI backend)
- Git

### Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd mecha_connect

# Install Flutter dependencies
flutter pub get

# Verify setup
dart analyze
flutter build web

# Start FastAPI backend (optional, for AI chat)
cd backend
uvicorn main:app --reload --port 8000
```

---

## Code Standards

### Flutter/Dart
- Use `const` constructors where possible
- Follow Material 3 design guidelines
- Use theme-aware colors via `context.textPrimary`, `context.cardBg`, etc.
- Use `AppSpacing` constants for all spacing values
- Use `AppResponsive` for responsive scaling
- Never hardcode padding/margins — use the spacing system

### Naming Conventions
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Widgets:** `_buildMethodName` for private builders
- **Variables:** `camelCase`
- **Constants:** `camelCase` with `const` keyword

### File Organization
```
lib/<module>/
├── screens/     # Full-screen widgets
├── widgets/     # Reusable widgets for that module
└── mock_data.dart  # Mock data (until backend)
```

---

## Sprint Workflow

1. Read the sprint requirements
2. Plan implementation (read existing code first)
3. Implement changes
4. Run `dart analyze` — must pass with 0 errors
5. Run `flutter build web` — must succeed
6. Verify runtime (no overflows, dead buttons, unreachable screens)
7. Generate sprint report in `docs/05_reports/` (archive superseded reports to `docs/archive/`)
8. Update `docs/07_rc1_certification/` (canonical RC1 docs), `docs/03_development/CHANGELOG.md`, `docs/01_product/PROJECT_STATUS.md`
9. Mark sprint as LOCKED

---

## Git Guidelines

### Branch Naming
```
feature/<module-name>
fix/<short-description>
refactor/<module-name>
docs/<what-changed>
```

### Commit Format
```
feat(module): description
fix(module): description
refactor(module): description
docs: description
```

### Examples
```
feat(mechanic): add booking confirmation screen
fix(profile): fix overflow in bio section
refactor(theme): extract color constants
docs: update sprint 1.6.4 report
```

---

## Quality Checklist (Pre-Commit)

- [ ] `dart analyze` — 0 errors, 0 warnings
- [ ] `flutter build web` — succeeds
- [ ] No RenderFlex overflow messages
- [ ] All buttons have `onPressed` callbacks
- [ ] No unreachable screens in navigation
- [ ] Responsive on mobile/tablet/desktop
- [ ] Dark mode compatible
- [ ] Const constructors where possible
- [ ] No duplicate widgets or code
- [ ] All imports are used (no dangling imports)
- [ ] Sprint report generated
- [ ] Architecture docs updated

---

## Architecture Overview

See `PROJECT_ARCHITECTURE.md` for the complete blueprint.

Key principles:
- **Feature-first** folder structure
- **Single source of truth** for design tokens
- **One MechanicCard** for all mechanic list views
- **Reusable shared widgets** in `lib/widgets/`
- **Mock data** until Sprint 2 (backend)

---

## Related Documents
- [PROJECT_ARCHITECTURE.md](../archive/PROJECT_ARCHITECTURE.md) (master blueprint)

- [UI_DESIGN_SYSTEM.md](../07_rc1_certification/UI_DESIGN_SYSTEM.md) (theme tokens)
- [TEST_PLAN.md](TEST_PLAN.md) (testing guidelines)
- [DEPLOYMENT.md](DEPLOYMENT.md) (build commands)
- [CHANGELOG.md](CHANGELOG.md) (version history)

