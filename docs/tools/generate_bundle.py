#!/usr/bin/env python3
"""
Generate public documentation bundle for Mecha Connect.

Creates a self-contained bundle from the PUBLIC documentation tree
(docs/common, docs/frontend, docs/backend, docs/handbook). Confidential
content under docs/internal/ is never included, and root security secrets are
excluded by the .gitignore rules.

Usage:
    python docs/tools/generate_bundle.py [output_dir]

If output_dir is not specified, creates bundle in docs/dist/claude_bundle/
"""

import os
import sys
import shutil
from pathlib import Path

PUBLIC_SECTIONS = ["common", "frontend", "backend", "handbook"]
EXCLUDED_NAMES = {"__pycache__", ".DS_Store", "Thumbs.db"}


def main():
    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = Path(__file__).parent.parent / "dist" / "claude_bundle"

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    docs_root = Path(__file__).parent.parent

    copied = 0
    for section in PUBLIC_SECTIONS:
        src = docs_root / section
        if not src.exists():
            print(f"Warning: {src} not found, skipping")
            continue
        dst = output_dir / section
        dst.mkdir(parents=True, exist_ok=True)
        for item in src.rglob("*"):
            if item.name in EXCLUDED_NAMES:
                continue
            rel = item.relative_to(src)
            target = dst / rel
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(item, target)
                copied += 1
                print(f"Copied: {section}/{rel}")

    readme_content = """# README — Mecha Connect Public Documentation Bundle

> Self-contained PUBLIC documentation bundle. No internal, business,
> financial, security, competitor, or risk content is included — those live in
> `docs/internal/` and are excluded from this bundle.

## Contents

- `common/` — overview, architecture, public roadmap, development workflow,
  contributing, coding standards, glossary, FAQ, installation, PRD,
  knowledge base, timeline/status.
- `frontend/` — architecture, design system, navigation, feature modules,
  testing, assets, diagrams.
- `backend/` — architecture, API contract, database, authentication, AI,
  deployment, testing, infrastructure.
- `handbook/` — ENGINEERING_HANDBOOK.md (public, 20 chapters) + CHANGELOG.md.

## Rules

- Everything is traceable to the official `docs/` tree; do not invent
  architecture, APIs, workflows, or seed data.
- Do not add confidential material to this bundle. If you find any, remove it
  and record it in `docs/internal/`.
- For a full tree map see `common/CANONICAL_DOCUMENT_MAP.md` when present, or
  `docs/README.md` in the repository.
"""
    (output_dir / "README.md").write_text(readme_content, encoding="utf-8")
    print(f"Created: README.md")
    print(f"\nBundle generated successfully at: {output_dir}")
    print(f"   Total files: {copied}")


if __name__ == "__main__":
    main()
