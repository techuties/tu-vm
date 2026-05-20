# Community System Framework

## Objective

Build a repeatable community process that turns suggestions into high-quality outcomes without bottlenecks, ambiguity, or duplicate effort.

## Core model

Use a lightweight lifecycle inspired by established open-source governance (Rust RFCs, Kubernetes enhancement proposals, and docs-driven engineering):

1. **Idea**: short proposal from any contributor
2. **Discovery**: quick check for overlap with existing or historical suggestions
3. **Draft**: structured proposal with impact, scope, and alternatives
4. **Review**: async feedback from maintainers and community
5. **Decision**: accept, accept-with-changes, defer, or reject
6. **Implementation**: linked issues/PRs with milestones
7. **Retrospective**: outcome review and lessons learned

## Historical suggestion check

Before accepting a new suggestion, reviewers should check existing records in this order:

1. [`historical-suggestions.md`](./historical-suggestions.md)
2. [`website-historical-baseline.md`](./website-historical-baseline.md)
3. [`implementation-backlog.md`](./implementation-backlog.md)
4. Open GitHub Issues with the `suggestion` label
5. `CHANGELOG.md` and release notes for already-shipped equivalents

Decision outcomes from that check:

- **Duplicate**: close or archive with a link to the canonical suggestion.
- **Partial overlap**: update the existing suggestion with a new requirement or constraint.
- **New direction**: move forward as a separate proposal with alternatives documented.

## Recommended structure for each suggestion

Every suggestion should answer:

- Problem statement: what pain exists today?
- Existing solutions scan: what can we reuse?
- Proposed solution: what exactly changes?
- Trade-offs: what do we gain/lose?
- Rollout and rollback: how to deploy safely?
- Ownership: who drives and who reviews?
- Success metrics: how do we measure value?

## Governance roles

### Maintainers
- Final decision makers for acceptance and scope boundaries
- Ensure security, reliability, and architecture consistency

### Community reviewers
- Provide domain feedback and implementation alternatives
- Validate usability and onboarding impact

### Proposal champions
- Author and iterate the suggestion
- Coordinate implementation and status updates

## Decision framework

Use a simple scorecard to reduce subjective decisions:

- Community impact (1-5)
- Implementation effort (1-5, lower is better)
- Operational risk (1-5, lower is better)
- Time-to-value (1-5)
- Reuse of existing tools/frameworks (1-5)

Accepted proposals should have high impact and reuse score with manageable risk.

## Community workflows to implement

### 1) Suggestion intake workflow
- Trigger: new suggestion markdown file or issue label
- Actions:
  - Validate required fields
  - Detect likely duplicates using keyword matching
  - Auto-tag by domain (docs, automation, infra, UX, security)
  - Link the suggestion to any matching historical page

Suggested required fields:

- Summary
- Current pain point
- Existing alternatives reviewed
- Proposed change
- Affected surfaces (`tu-vm.sh`, helper API, nginx, docs, Compose, workflows)
- Security/privacy impact
- Validation command or review method

### 2) Review workflow
- Trigger: suggestion status set to `review`
- Actions:
  - Assign maintainers and reviewers
  - Post review checklist
  - Set reminder if no activity after a defined window
  - Confirm whether the proposal can be solved by documented configuration or existing tooling

### 3) Implementation tracking workflow
- Trigger: proposal accepted
- Actions:
  - Create linked implementation tasks
  - Publish progress status on dashboard/docs
  - Close loop with retrospective template

### 4) Community visibility workflow
- Trigger: suggestion status changes or implementation ships
- Actions:
  - Update the suggestion markdown status and decision notes
  - Add release/changelog reference
  - Surface accepted or implemented items in the website suggestions index
  - Include community credit when appropriate

## Metrics

Track these to keep the process healthy:

- Suggestion-to-decision cycle time
- Decision-to-implementation cycle time
- Acceptance ratio
- Duplicate suggestion rate
- Active contributor count (30/90 days)
- Reopened proposals (quality signal)
- Percentage of accepted suggestions with validation evidence
- Percentage of implemented suggestions linked from release notes

## Risk controls

- No accepted proposal without rollback notes
- No production-impacting change without test/validation path
- Security review required for network, auth, data, or secret changes
- Archive stale proposals after review window with clear reason
- Prefer opt-in automation for operations changes until real usage validates defaults
- Do not add custom storage or service dependencies for community workflows while GitHub-native tools are sufficient

## First implementation slice

1. Standardize a proposal template and status taxonomy (`idea`, `draft`, `review`, `accepted`, `deferred`, `rejected`, `implemented`).
2. Define owner rotation for suggestion triage.
3. Add duplicate-check guidance that references the historical suggestion pages.
4. Publish a recurring community update summarizing accepted/rejected suggestions and rationale.
5. Add automation only for repetitive checks: required fields, stale review reminders, and link validation.
