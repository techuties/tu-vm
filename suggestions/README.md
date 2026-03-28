# Suggestions Directory

This folder stores community-facing website suggestions and their status so we can build on previous work instead of duplicating it.

## Goals

- Keep a **single source of truth** for suggestion ideas and outcomes.
- Reuse existing stack components first (Nginx landing page + `helper/uploader.py` API + current dashboard patterns).
- Make implementation decisions auditable for maintainers and contributors.

## Files

- `historical-suggestions.md`  
  Baseline of already implemented ideas, partially implemented items, and open opportunities.
- `website-community-platform.md`  
  Framework proposal for a community-driven suggestions system integrated with current services.
- `website-day-to-day-tools.md`  
  Practical tooling suggestions to make contributor and maintainer workflows easier.
- `website-build-phases.md`  
  Incremental delivery plan with clear scope and acceptance criteria.

## Contribution Rules for New Suggestions

1. Check `historical-suggestions.md` before proposing a new item.
2. Mark each new proposal with:
   - Problem statement
   - Reuse strategy (what already exists and can be extended)
   - Scope (MVP vs future)
   - Risks
   - Success criteria
3. Prefer extension over replacement:
   - Extend `helper/uploader.py` endpoints when possible.
   - Keep static-first UI patterns in `nginx/html/index.html` unless dynamic rendering is required.
4. Track status transitions: `proposed -> accepted -> implemented` (or `rejected` with reason).
