# Website Roadmap and Acceptance Criteria

## Goal

Translate website and community suggestions into an actionable, low-risk roadmap.

## Guiding principles

- Reuse current architecture (`nginx/html/index.html` + `helper/uploader.py`).
- Improve maintainability without sacrificing reliability.
- Ship in small reversible increments.
- Keep security and operational behavior unchanged by default.

## Phase 1: Documentation and contracts (lowest risk)

### Scope

- Document all helper endpoints consumed by dashboard JS.
- Document expected response schema and status/error semantics.
- Document service-control name mapping in one place.

### Deliverables

- Endpoint contract section in `README.md` (or helper-specific docs section).
- Table mapping dashboard service IDs to helper control IDs.
- Error handling matrix for `/control/*`, `/whitelist/*`, `/status/*`.

### Acceptance criteria

- A new contributor can identify all dashboard API dependencies in one document.
- No behavior changes in runtime services.

## Phase 2: Frontend modularization

### Scope

- Split inline JavaScript in `nginx/html/index.html` into modules.
- Keep existing visual/UI behavior exactly the same.
- Preserve static delivery model (no mandatory heavy frontend framework).

### Deliverables

- `nginx/html/js/app.js` bootstrapping logic.
- `nginx/html/js/services/api.js` for fetch helpers.
- `nginx/html/js/components/` for service cards, notifications, allowlist rendering.

### Acceptance criteria

- Dashboard renders and controls services exactly as before.
- JS code is easier to review and test (smaller files, isolated concerns).

## Phase 3: Reliability and test harness

### Scope

- Add lightweight checks for frontend and helper API regressions.
- Add smoke checks for key dashboard interactions.

### Deliverables

- Basic lint setup for frontend JS.
- Minimal browser smoke test:
  - page loads
  - service status probes run
  - control button request path is correct
- Helper API route smoke test for critical endpoints.

### Acceptance criteria

- Contributor PRs that break core dashboard behavior are detected before merge.
- Existing scripts (`pre-push-check.sh`, daily checks) remain compatible.

## Phase 4: Accessibility and community UX

### Scope

- Improve keyboard accessibility and screen-reader support.
- Improve announcement readability and focus states.
- Add contribution-oriented UI docs for dashboard behavior.

### Deliverables

- ARIA labels and roles for interactive components.
- Keyboard interaction consistency for dropdowns and controls.
- Accessibility check integrated into validation workflow.

### Acceptance criteria

- Core workflows are usable by keyboard only.
- No color-only critical state communication.

## Phase 5: Community operating loop

### Scope

- Adopt the `suggestions/` folder as proposal lifecycle source.
- Ensure implemented suggestions are reflected in changelog and docs.

### Deliverables

- Suggestion file template (status, rationale, rollout notes).
- Lightweight maintainer process for proposal triage and closure.

### Acceptance criteria

- Community can track proposal status without external tools.
- Implemented proposals are discoverable from changelog/repo history.

## Risks and mitigations

### Risk: hidden coupling between dashboard JS and helper responses

Mitigation:

- Explicit endpoint contract and schema checks before refactor.

### Risk: introducing build complexity too early

Mitigation:

- Keep static-first delivery; only add a build step when it reduces maintenance burden measurably.

### Risk: contributor confusion during transition

Mitigation:

- Keep old/new structure documented and make changes incrementally.

## Prioritization summary

1. Contracts and docs
2. JS modularization
3. Reliability tests
4. Accessibility
5. Community lifecycle automation

This order gives the highest practical value with minimal operational disruption.
