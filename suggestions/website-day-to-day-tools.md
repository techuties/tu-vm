# Website Suggestion: Day-to-Day Community and Maintainer Tools

## Summary

Introduce practical website tools that reduce friction for both contributors and maintainers, while reusing existing VM services and dashboard patterns.

These suggestions are intentionally implementation-focused and compatible with the current stack.

## Tooling Suggestions

### 1) Suggestion Templates in UI

Add selectable templates in the suggestion form:

- Bug risk prevention
- UX quality improvement
- Automation/ops enhancement
- Documentation gap
- Security hardening

Each template pre-fills a structure:

- Current pain
- Desired behavior
- Proposed approach
- Impact and risk

**Benefit:** Higher quality submissions and faster triage.

### 2) Duplicate Detection Assistant (Lightweight)

Before creating a new suggestion:

- Run client-side similarity check against existing titles/problems.
- Show likely duplicates with quick links.

MVP can use simple normalized keyword overlap and token matching.

**Benefit:** Avoids fragmented discussions and duplicate work.

### 3) Suggestion Health Dashboard

Add a compact metrics panel:

- Open suggestions by category
- Median age of `proposed` items
- Accepted-to-implemented conversion count
- Recently implemented suggestions

Use existing status panel patterns and expose data via `/suggestions/stats`.

**Benefit:** Transparent progress tracking for community trust.

### 4) Maintainer Triage Workbench

Add a protected triage section with bulk actions:

- mark duplicate
- assign category
- set priority band (high/medium/low)
- move status with reason

Track all changes in a simple audit trail.

**Benefit:** Reduces triage overhead and keeps decisions consistent.

### 5) “How to Contribute Better” Contextual Hints

When users open the suggestion form, display short hints:

- Check historical suggestions first
- Include measurable impact
- Mention affected service(s)
- Suggest MVP scope first

**Benefit:** Better proposal quality without extra docs navigation.

### 6) Implementation Linkage

Allow maintainers to attach:

- commit SHA
- release/changelog version
- related script or endpoint

when marking a suggestion as `implemented`.

**Benefit:** Closes the loop and makes outcomes verifiable.

## Suggested Endpoint Additions

- `POST /suggestions/check-duplicates`
- `POST /suggestions/<id>/link-implementation`
- `GET /suggestions/audit`

All endpoints should follow existing token authorization patterns for protected operations.

## Reuse Strategy

- Keep UI in existing `nginx/html/index.html` style and component conventions.
- Extend `helper/uploader.py` for API logic.
- Reuse current notification and announcements behavior for feedback to users.

## Risks

1. Feature creep in landing page  
   Mitigation: implement as collapsible module and keep MVP focused.
2. Too many moderation actions in one view  
   Mitigation: phase in bulk actions after single-item flow stabilizes.
3. Data quality inconsistency  
   Mitigation: enforce schema validation at API layer.

## Success Criteria

- Duplicate suggestion creation rate drops over time.
- Triage completion time decreases for maintainers.
- Community sees clear mapping from accepted ideas to implemented outcomes.
