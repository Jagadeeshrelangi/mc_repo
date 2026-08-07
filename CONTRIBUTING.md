# Contributing to Mecha Connect

Thanks for your interest in contributing. This repository is a
[monorepo](#repository-structure) with a Flutter frontend and a FastAPI
backend.

> **Note:** Mecha Connect is proprietary and distributed under **All Rights
> Reserved** (see [LICENSE](LICENSE)). Internal business documentation is not
> version-controlled. By contributing you agree to the project's license terms.

## Repository Structure

- `frontend/` — Flutter application
- `backend/` — FastAPI service
- `docs/` — repository documentation
- `scripts/` — tooling

## How to Contribute

1. **Find or open an issue** and agree on the approach.
2. **Fork / branch** from `main`.
3. Follow the engineering standards in
   [docs/common/CODING_STANDARDS.md](docs/common/CODING_STANDARDS.md).
4. Keep changes scoped to one component (frontend or backend).
5. **Do not commit** secrets, `.env` files, API keys, or internal documents.
6. Open a PR; CI runs frontend analysis/tests and backend checks.

## Commit Guidelines

Use the git workflow and conventions in
[CONTRIBUTING (detailed)](docs/common/CONTRIBUTING.md). Keep commits focused
and write clear messages.

## Code of Conduct

Be respectful and constructive. Harassment or abuse is not tolerated.

## Questions

See [docs/README.md](docs/README.md) and the
[FAQ](docs/common/FAQ.md). For anything else, open an issue.