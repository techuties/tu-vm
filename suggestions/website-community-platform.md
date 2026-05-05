# Website Suggestion: Community Suggestions Platform

## Summary

Build a community-driven suggestion system directly into the existing website stack so contributors can propose improvements, vote on priorities, and track implementation status without leaving the platform.

This should **extend current components** (`nginx/html/index.html` + `helper/uploader.py`) rather than introduce a new web framework immediately.

## Problem Statement

Current dashboard capabilities are operational (status, control, announcements), but community collaboration is still ad hoc. There is no structured workflow for:

- submitting suggestions,
- detecting duplicates,
- discussing priority,
- showing lifecycle state from idea to delivery.

## Proposed Framework (Reuse-First)

### 1) Data Model (MVP)

Add a simple JSON-backed store first, then migrate to Postgres only if volume requires it.

`suggestion` fields:

- `id` (uuid)
- `title`
- `problem`
- `proposal`
- `category` (security, UX, automation, docs, reliability, performance)
- `impact_score` (1-5)
- `effort_score` (1-5)
- `risk_score` (1-5)
- `status` (`proposed`, `accepted`, `implemented`, `rejected`)
- `author`
- `created_at`
- `updated_at`
- `duplicate_of` (nullable)
- `notes`

### 2) API Extensions (Helper Service)

Extend `helper/uploader.py` with endpoints:

- `GET /suggestions`  
  List with query filters (`status`, `category`, search text).
- `POST /suggestions`  
  Create new suggestion with required validation.
- `GET /suggestions/<id>`  
  Fetch detail.
- `POST /suggestions/<id>/vote`  
  Upvote/downvote (basic token/IP throttling in MVP).
- `POST /suggestions/<id>/status`  
  Maintainer-only transition with audit note.
- `GET /suggestions/stats`  
  Counts by category/status and top-voted items.

### 3) Website UX (Landing Page Section)

Add a “Community Suggestions” module in `nginx/html/index.html`:

- **New Suggestion form** (title/problem/proposal/category).
- **Suggestion list** with filters:
  - status chips,
  - category chips,
  - sort by votes/updated.
- **Detail drawer/modal**:
  - lifecycle status,
  - rationale,
  - linked duplicate if applicable.
- **Top Priorities panel** driven by `/suggestions/stats`.

### 4) Governance Flow

Define a simple moderation policy:

1. New submission lands in `proposed`.
2. Maintainer triage sets:
   - duplicate link, or
   - accepts with prioritization note.
3. Accepted work transitions to `implemented` when merged.
4. Rejected items require explicit reason to preserve transparency.

## Why This Avoids Re-inventing the Wheel

- Reuses **existing helper API** pattern and auth model.
- Reuses **existing dashboard UI style** and notification behaviors.
- Reuses **existing operational concepts** (status chips, announcements).
- Delays heavy framework migration until there is clear scaling need.

## Technical Risks and Mitigations

1. **JSON store concurrency risk**  
   Mitigation: atomic writes + file lock; move to Postgres when contention appears.
2. **Abuse/spam submissions**  
   Mitigation: token-gated submit mode or basic rate limiting by IP.
3. **Status drift from code reality**  
   Mitigation: require maintainer update note with PR/commit reference in status transitions.

## Success Criteria

- Contributors can submit suggestions from the website in under 2 minutes.
- Duplicate suggestions are visibly linked to canonical items.
- Maintainers can change status with traceable reasoning.
- Community can see top priorities and what was recently implemented.
- No new infrastructure service is required for MVP.
