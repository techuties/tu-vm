# Community System Framework

## Objective

Build a repeatable community process that turns suggestions into high-quality outcomes without bottlenecks, ambiguity, or duplicate effort.

## Core model

Use a lightweight lifecycle inspired by established open-source governance (Rust RFCs, Kubernetes enhancement proposals, and docs-driven engineering):

1. **Proposed**: a contributor opens the existing GitHub suggestion form.
2. **Triaged**: maintainers check scope, duplicates, security routing, and ownership.
3. **Discussing**: alternatives and constraints receive asynchronous review.
4. **Accepted**, **deferred**, or **rejected**: the decision and rationale are recorded.
5. **In progress**: linked implementation work is active.
6. **Implemented**: code/docs are merged and validation evidence is linked.
7. **Shipped**: a named release contains the outcome.
8. **Superseded**: a proposal is replaced by a linked canonical proposal.

The machine-readable lifecycle values and exact evidence requirements are defined in [`website-community-pages.md`](./website-community-pages.md). That page is the status vocabulary source of truth.

GitHub is the workflow source of truth. All suggestion issues use the `suggestion` label; existing `triage` and `needs-info` labels support intake. If volume justifies stricter reporting, use one GitHub Project status field or a documented `status:*` label set that maps exactly to the canonical lifecycle. Do not encode the same state differently in labels, Project fields, and Markdown.

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
- Trigger: a new issue created from `.github/ISSUE_TEMPLATE/suggestion.yml`
- Actions:
  - Apply `suggestion` and `triage`
  - Check open/closed issues and canonical pages for likely duplicates
  - Route security-sensitive content to the private process in `SECURITY.md`
  - Suggest domain labels (docs, automation, infra, UX, security) with human confirmation

### 2) Review workflow
- Trigger: triage confirms the issue is in scope and not a duplicate
- Actions:
  - Assign maintainers and reviewers
  - Post the reuse, risk, rollout, and acceptance checklist
  - Set reminder if no activity after a defined window
  - Record an accepted/deferred/rejected rationale in the canonical issue

### 3) Implementation tracking workflow
- Trigger: proposal accepted
- Actions:
  - Create linked implementation tasks
  - Link pull requests with `Fixes #…`, `Closes #…`, or `Refs #…`
  - Curate a website Markdown page only for durable accepted work or consolidated themes
  - Link validation evidence and the shipped release before closing the loop

## Metrics

Track these to keep the process healthy:

- Suggestion-to-decision cycle time
- Decision-to-implementation cycle time
- Acceptance ratio
- Duplicate suggestion rate
- Active contributor count (30/90 days)
- Reopened proposals (quality signal)

## Risk controls

- No accepted proposal without rollback notes
- No production-impacting change without test/validation path
- Security review required for network, auth, data, or secret changes
- Archive stale proposals after review window with clear reason

## First implementation actions

1. Keep the existing GitHub issue form as the sole intake path.
2. Publish the canonical lifecycle and optional GitHub field/label mapping.
3. Define owner rotation for regular triage.
4. Add advisory duplicate hints and stale-review reminders only after ownership is clear.
5. Generate a read-only website status view from reviewed metadata.
