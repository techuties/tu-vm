# Suggestion 04: Implementation Roadmap (Community + Framework + Tooling)

## Purpose

Provide a practical rollout path for the suggestions in this folder so TU-VM gains value early and avoids big-bang migrations.

## Scope

This roadmap combines:

- website framework adoption,
- community suggestion lifecycle, and
- maintainer/contributor tooling improvements.

## Phase 0: Foundation (start here)

### Deliverables

1. Keep this `suggestions/` folder as the source of proposal history.
2. Add a short section in `README.md` that points to `suggestions/README.md`.
3. Define proposal status tags in docs:
   - `draft`
   - `trial`
   - `accepted`
   - `deprecated`

### Outcome

The project has an explicit place for structured improvement ideas and can track evolution without losing context.

## Phase 1: Docs framework adoption

### Deliverables

1. Scaffold docs framework (recommended: VitePress) under `docs/`.
2. Migrate high-value docs first:
   - `QUICK_REFERENCE.md`
   - selected operational parts of `README.md`
3. Add navigation for:
   - Getting Started
   - Operations
   - Architecture
   - Workflows
   - Suggestions

### Outcome

Contributors get a clear documentation home that scales better than standalone root markdown files.

## Phase 2: Community workflow

### Deliverables

1. Create issue templates for:
   - feature proposal,
   - ops/tooling improvement,
   - docs improvement.
2. Add PR checklist items:
   - docs impact reviewed,
   - rollback/operational risk evaluated.
3. Add a lightweight triage routine:
   - proposals grouped by status and priority.

### Outcome

Community ideas become actionable and consistent, reducing duplicated or stalled efforts.

## Phase 3: Tooling for maintainers and contributors

### Deliverables

1. Add markdown linting/formatting checks for docs and suggestions.
2. Add helper script for proposal index generation (optional).
3. Add "changed docs preview" guidance for reviewers.
4. Add changelog automation for suggestion status changes (optional but useful).

### Outcome

Day-to-day work becomes easier, with less manual bookkeeping and more predictable contribution quality.

## Phase 4: Community visibility and growth

### Deliverables

1. Public "Contributing to TU-VM" page in docs.
2. "Good first suggestion" labels and beginner-friendly starter proposals.
3. Quarterly cleanup of stale drafts and status updates.

### Outcome

The repository moves from maintainer-only operations toward a healthier community contribution model.

## Definition of success

Use measurable outcomes:

1. Suggestion-to-implementation cycle is visible and documented.
2. Repeat/duplicate proposals decrease over time.
3. More external contributors can submit useful docs/proposals on first attempt.
4. Maintainer review effort drops due to clearer templates and checklists.

## Rollout guardrails

1. No disruption to current service operations (`tu-vm.sh`, compose, dashboard).
2. Keep docs content markdown-first to prevent future migration pain.
3. Prefer incremental PRs over broad refactors.
4. Keep governance lightweight; optimize for action, not bureaucracy.
