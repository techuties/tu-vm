# Website Suggestion: Incremental Build Phases for Community Suggestions

## Summary

Deliver the community suggestion framework in small, low-risk increments that fit the current architecture and operational model.

## Phase 1 - Foundation (No New Services)

### Scope

- Create suggestion data schema (JSON-backed).
- Add helper API endpoints:
  - `GET /suggestions`
  - `POST /suggestions`
  - `GET /suggestions/<id>`
- Add website module in `nginx/html/index.html`:
  - suggestion list,
  - create form,
  - basic status filters.

### Acceptance Criteria

- A user can submit and retrieve suggestions from the website.
- Suggestions persist across service restarts.
- UI follows existing dashboard style and remains mobile-friendly.

## Phase 2 - Triage and Governance

### Scope

- Add protected endpoints:
  - `POST /suggestions/<id>/status`
  - `POST /suggestions/<id>/vote`
- Add duplicate marker field (`duplicate_of`) and triage notes.
- Add simple audit entries for status transitions.

### Acceptance Criteria

- Maintainers can triage suggestions with explicit rationale.
- Community can see lifecycle state and vote trends.
- Duplicate suggestions can be linked to canonical items.

## Phase 3 - Day-to-Day Productivity Tools

### Scope

- Add duplicate detection endpoint/UI check:
  - `POST /suggestions/check-duplicates`
- Add suggestion stats endpoint and dashboard cards:
  - `GET /suggestions/stats`
- Add implementation linkage:
  - `POST /suggestions/<id>/link-implementation`

### Acceptance Criteria

- Users are warned about likely duplicates before posting.
- Maintainers can attach commit/release references to implemented suggestions.
- Dashboard clearly shows top priorities and delivered outcomes.

## Phase 4 - Scale Decision Gate

### Trigger Conditions

Consider migration from JSON storage to Postgres if one or more are true:

- frequent concurrent writes,
- large suggestion volume,
- advanced query/filter requirements,
- need for richer moderation or analytics.

### Migration Path

1. Keep API contract stable.
2. Replace storage adapter behind endpoints.
3. Backfill JSON history into Postgres table.
4. Keep read-only archive export for transparency.

## Non-Goals (For Initial Iterations)

- No new frontend framework migration in MVP.
- No external identity provider integration in MVP.
- No heavy workflow tooling before core suggestion lifecycle works.

## Delivery Principles

- Reuse existing helper + Nginx architecture first.
- Add only capabilities that reduce contributor/maintainer friction.
- Keep every phase testable and reversible.
