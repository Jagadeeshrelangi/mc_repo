#!/usr/bin/env python3
"""
Generate Claude Bundle for Mecha Connect.

This script creates a self-contained bundle for Claude handbook generation.
It copies required files from documentation_build/ to a temporary directory
and packages them for easy distribution.

Usage:
    python tools/generate_bundle.py [output_dir]

If output_dir is not specified, creates bundle in dist/claude_bundle/
"""

import os
import sys
import shutil
from pathlib import Path


def main():
    # Determine output directory
    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = Path(__file__).parent.parent / "dist" / "claude_bundle"
    
    # Clean and create output directory
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Define source and destination mappings
    bundle_mappings = {
        # Core files
        "00_core/PROJECT_CONTEXT.md": "PROJECT_CONTEXT.md",
        "00_core/AI_PROJECT_MEMORY.md": "AI_PROJECT_MEMORY.md",
        "00_core/PROJECT_TIMELINE.md": "PROJECT_TIMELINE.md",
        "00_core/PROJECT_OPERATING_MANUAL.md": "PROJECT_OPERATING_MANUAL.md",
        
        # Knowledge base
        "01_knowledge/MASTER_PROJECT_KNOWLEDGE_BASE.md": "MASTER_PROJECT_KNOWLEDGE_BASE.md",
        "01_knowledge/KNOWLEDGE_GRAPH.md": "KNOWLEDGE_GRAPH.md",
        
        # Exports
        "09_exports/MASTER_PROJECT_DATA.json": "MASTER_PROJECT_DATA.json",
        "09_exports/knowledge_graph.json": "knowledge_graph.json",
        
        # Supporting folders
        "02_architecture/diagrams": "diagrams",
        "02_architecture/glossary.md": "glossary.md",
        "02_architecture/version_matrix.md": "version_matrix.md",
        "03_database": "database",
        "04_api": "api",
        "05_navigation": "navigation",
        "06_workflows": "workflows",
        "07_modules": "modules",
        "08_assets": "assets",
    }
    
    # Copy files and folders
    for src, dst in bundle_mappings.items():
        src_path = Path(__file__).parent.parent / src
        dst_path = output_dir / dst
        
        if not src_path.exists():
            print(f"Warning: {src_path} not found, skipping")
            continue
        
        if src_path.is_dir():
            shutil.copytree(src_path, dst_path)
            print(f"Copied directory: {src} -> {dst}")
        else:
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)
            print(f"Copied file: {src} -> {dst}")
    
    # Create README_FOR_CLAUDE.md
    readme_content = """# README FOR CLAUDE — Mecha Connect Bundle

> This bundle is self-contained. Everything Claude needs to produce the final
> Mecha Connect handbook in ONE session is here. Do not modify anything outside
> this folder.

## What to do in order

1. **Read `PROJECT_CONTEXT.md` first** — project identity and vision.
2. **Read `KNOWLEDGE_GRAPH.md` second** — structured relationship map.
3. **Read `MASTER_PROJECT_KNOWLEDGE_BASE.md` third** — complete technical knowledge.
4. **Load `MASTER_PROJECT_DATA.json`** — machine-readable facts.
5. **Read `AI_PROJECT_MEMORY.md`** — living engineering memory.
6. **Read `CLAUDE_PROMPT.md`** — generation contract (if generating handbook).

## Ground rules
- Everything is traceable to the official `documentation_build/` tree; do NOT invent architecture,
  APIs, workflows, or seed data.
- Certification wording: use **"Frontend Lock Candidate"** — never "RC1 Certified".
- If a figure/screenshot is missing, keep the placeholder reference (FIG-N) and
  mark it PENDING in the handbook.
- Engineering audit (Phase 0) is APPROVED — see `archive/engineering_review/AUDIT_SUMMARY.md`.
"""
    
    with open(output_dir / "README_FOR_CLAUDE.md", "w") as f:
        f.write(readme_content)
    print("Created: README_FOR_CLAUDE.md")
    
    # Create CLAUDE_PROMPT.md (minimal version)
    prompt_content = """# CLAUDE_PROMPT — Mecha Connect Handbook Generation

## Objective

Generate a world-class engineering handbook for Mecha Connect.

## Structure

21 chapters covering:
1. Introduction
2. Business Model
3. Product Requirements
4. Architecture
5. Database
6. API
7. Navigation
8. Design System
9. Testing
10. AI Module
11. Mechanic Module
12. Fuel Delivery Module
13. Marketplace Module
14. Profile Module
15. Home Module
16. Orders Module
17. Deployment
18. Security
19. Performance
20. Future Roadmap
21. Conclusion

## Rules

- Use canonical documents as sources
- Embed figures from diagrams/
- Mark missing screenshots as PENDING
- Follow the structure defined in this bundle
- Verify all claims against MASTER_PROJECT_DATA.json
"""
    
    with open(output_dir / "CLAUDE_PROMPT.md", "w") as f:
        f.write(prompt_content)
    print("Created: CLAUDE_PROMPT.md")
    
    print(f"\n✅ Bundle generated successfully at: {output_dir}")
    print(f"   Total files: {len(list(output_dir.rglob('*')))}")


if __name__ == "__main__":
    main()