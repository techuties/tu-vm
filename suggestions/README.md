# Suggestions Framework

This folder contains constructive suggestions for improving the TechUties VM website and community workflow without re-implementing features that already exist.

## Historical suggestions check

Scanned the repository for an existing `/suggestions/` directory and related suggestion files before creating new content.

Result:
- No existing `/suggestions/` folder was found.
- No prior suggestion docs were found in project markdown files.
- Existing implementation patterns were extracted from:
  - `README.md`
  - `CHANGELOG.md`
  - `nginx/html/index.html`
  - `helper/uploader.py`

## Reuse-first principles

To avoid reinventing the wheel, all recommendations in this folder follow these principles:

1. Reuse existing helper API endpoints for status, announcements, and control where possible.
2. Keep the current Nginx + static landing page model for the operations dashboard use case.
3. Build community pages and process docs around the current stack (Open WebUI, n8n, AFFiNE, MCP Gateway, MinIO/Tika pipeline).
4. Prefer incremental migration and measurable acceptance criteria over broad rewrites.

## Files

- `website-foundation-suggestions.md`
- `community-framework-suggestions.md`
- `tooling-and-ops-suggestions.md`
