# Community Suggestions Framework

This folder is the central place for constructional, community-driven suggestions for the TechUties VM project.

## Goals

- Keep historical suggestions in one location.
- Avoid re-proposing ideas that are already documented or implemented.
- Propose practical website and tooling improvements that reduce day-to-day maintainer effort.
- Prioritize community contribution pathways and transparent governance.

## How to use this folder

1. Start with `historical-suggestions.md` to review prior proposals and implementation status.
2. Read the targeted proposal docs:
   - `website-framework-suggestions.md`
   - `community-system-suggestions.md`
   - `maintainer-tools-suggestions.md`
3. When implementing a suggestion:
   - Update its status in the relevant file.
   - Add a short note in `historical-suggestions.md` with date and commit reference.
4. Do not remove old suggestions; mark them as superseded when replaced.

## Status labels

- `proposed`: documented but not yet started
- `in-progress`: active implementation
- `implemented`: merged in codebase
- `deferred`: useful but intentionally postponed
- `superseded`: replaced by a newer suggestion

## Scope assumptions for this repository

Current website surface appears to be:
- `nginx/html/index.html` (single-page service hub dashboard)
- `helper/uploader.py` (status/control/announcement API layer)

Suggestions below are designed to work incrementally with this architecture.
