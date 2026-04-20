# Implementation Backlog for Community-Based Website Suggestions

This backlog translates suggestions into implementation-ready work items with clear acceptance criteria.

## Priority model

- **P0**: High impact, low complexity, immediate quality gain
- **P1**: Core community workflows
- **P2**: Scale and polish

---

## P0-1: Establish Suggestions Data Model

### Scope
Define a canonical schema for community suggestions:

- `id`
- `title`
- `problem`
- `proposal`
- `category`
- `status`
- `votes`
- `created_at`
- `updated_at`
- `owner`
- `release_link` (optional)

### Acceptance criteria
- Schema is documented and used consistently by API and UI.
- Status values are enum-constrained (`new`, `triaged`, `planned`, `in-progress`, `released`, `declined`).
- Invalid payloads are rejected with clear error messages.

---

## P0-2: Add Community Suggestions API (helper service)

### Scope
Introduce minimal endpoints:

- `GET /suggestions`
- `POST /suggestions`
- `POST /suggestions/:id/vote`
- `PATCH /suggestions/:id/status` (admin-maintainer scope)

### Acceptance criteria
- API responses follow the schema.
- Requests are authenticated/authorized in alignment with existing control strategy.
- API has basic integration tests (or at minimum request/response validation tests).

---

## P0-3: Add Website Suggestions Section

### Scope
Add a "Community Suggestions" panel in the dashboard with:

- Submission form
- List with filters (status/category)
- Vote action
- Status badges

### Acceptance criteria
- Users can submit and see new suggestions immediately.
- Duplicate submissions are discouraged (basic similarity check or title conflict warning).
- Keyboard-accessible controls and ARIA labels are present.

---

## P1-1: Changelog Linkage ("Implemented from Community")

### Scope
Link released suggestions to changelog entries and display this relation in the website.

### Acceptance criteria
- A released suggestion can store and display a changelog reference.
- Dashboard card shows at least the latest 3 changelog highlights.
- Users can navigate from suggestion -> changelog item.

---

## P1-2: Runbook/Playbook Quick Actions

### Scope
Create curated operational playbooks rendered in the website:

- Safe update
- Service failure recovery
- RAG troubleshooting
- MCP/LangGraph smoke check

### Acceptance criteria
- Each playbook has command snippets and expected outcomes.
- Playbooks are searchable by keyword.
- Playbook content is version-aware (at least indicates applicable version range).

---

## P1-3: Contributor Workflow Standardization

### Scope
Standardize contribution channels around suggestions:

- Suggestion issue template
- Bug template for website/dashboard
- PR checklist with accessibility + rollback items

### Acceptance criteria
- Templates are active and referenced in contribution docs.
- New PRs consistently include checklist completion.
- Review friction (missing context) decreases qualitatively.

---

## P2-1: Frontend modularization

### Scope
Refactor monolithic `nginx/html/index.html` into maintainable assets:

- `assets/js/*`
- `assets/css/*`
- optional component abstraction

### Acceptance criteria
- Existing UX is behaviorally equivalent after refactor.
- Linting is active for extracted JS/CSS.
- Build/deploy path remains compatible with current Docker/Nginx setup.

---

## P2-2: Automated browser smoke tests

### Scope
Add Playwright checks for core flows.

### Acceptance criteria
- CI executes smoke tests on key website interactions.
- Failing tests block regressions on critical flows.
- Test docs describe local run procedure for community contributors.

---

## P2-3: Feature-flagged rollout strategy

### Scope
Roll out major community features (voting/status boards) behind feature flags.

### Acceptance criteria
- Flags can be toggled via config/env without code edits.
- Rollback path documented and tested.
- Observability includes feature-usage metrics.

---

## Suggested implementation order

1. P0-1, P0-2, P0-3
2. P1-1, P1-2
3. P2-1, P2-2
4. P1-3 and P2-3 in parallel where possible

This ordering minimizes risk while delivering immediate community value.
