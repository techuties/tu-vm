# Website Community Framework Proposal

## 1) Goal

Create a community suggestion system that is visible from the TU-VM website and powered by existing platform components, with minimal new infrastructure.

## 2) Design principles (no wheel re-invention)

1. Reuse current landing page and helper API instead of adding a new web app.
2. Keep suggestions content in Git-tracked markdown (human-readable, reviewable, auditable).
3. Add only thin API/indexing glue for listing, filtering, and voting metadata.
4. Keep write actions guarded the same way as other sensitive operations.

## 3) Proposed website information architecture

Add a new "Community Suggestions" section from the landing page with these pages:

- `/suggestions/` (Index)
  - Search by keyword
  - Filter by status, area, and complexity
  - Sort by newest, most-voted, and recently updated
- `/suggestions/<slug>` (Detail page)
  - Full markdown proposal
  - Status timeline
  - Vote summary
  - "Implementation updates" changelog block
- `/suggestions/submit` (Submission guide + template)
  - Contributor instructions
  - Validation checklist
  - Canonical markdown template

## 4) Content model for each suggestion

Use markdown files with YAML front matter:

```yaml
id: SUG-0001
title: Add quick action profiles to dashboard
status: proposed # proposed | triaged | accepted | in-progress | completed | rejected
category: dashboard
area:
  - helper-api
  - landing-page
author: community
created: 2026-04-16
updated: 2026-04-16
votes:
  up: 0
  down: 0
priority: medium
effort: medium
dependencies:
  - existing service control API
metrics:
  - "time_to_start_common_services_reduced"
```
```

Body sections:

1. Problem statement
2. Proposed approach
3. Why this reuses current architecture
4. Risks and rollback
5. Acceptance criteria
6. Operational impact

## 5) Suggested backend integration (helper API)

Extend `helper/uploader.py` with read-only endpoints first:

- `GET /suggestions/index`
  - Returns parsed metadata for all `suggestions/*.md`
- `GET /suggestions/<id>`
  - Returns metadata + markdown body
- `GET /suggestions/stats`
  - Counts by status/category

Second phase (optional write path):

- `POST /suggestions/vote`
  - Requires control token or scoped community token
  - Appends signed vote events (event-log style) for auditability

## 6) Frontend integration (landing page)

In `nginx/html/index.html`:

1. Add a new section card: "Community Suggestions"
2. Show top 3 suggestions (most voted + newest accepted)
3. Link to full suggestion index
4. Add "Contribute a suggestion" call-to-action with template guidance

Keep styling aligned with existing dark dashboard tokens and badge system (`badge-ok`, `badge-warn`, etc.).

## 7) Security and trust model

- Read endpoints are public (or same visibility as dashboard pages).
- Write endpoints require auth and rate limits (reuse existing control token patterns and nginx rate limiting).
- Keep all accepted changes in Git for transparent history.
- Require "rollback plan" for accepted technical suggestions.

## 8) Accessibility and UX standards for the suggestions UI

- Keyboard-navigable filter controls and links.
- Clear status badges with text labels (not color-only).
- High contrast text against card backgrounds.
- Responsive cards (single column on narrow screens).
- No blocking animations; keep transitions subtle.

## 9) KPI targets

- Suggestion triage SLA: first response on every new suggestion.
- Acceptance ratio visibility (proposed vs accepted vs completed).
- Median time from accepted -> completed.
- Number of unique contributors per month.

## 10) What this unlocks

- Community can propose concrete improvements without platform sprawl.
- Maintainers retain governance through structured status flow.
- Contributors can discover "high-leverage" issues aligned with architecture.
