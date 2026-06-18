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

The lifecycle should run on tools the project already has: GitHub Issues for intake, pull requests for implementation, `suggestions/` for historical planning, `CONTRIBUTING.md` for labels and review expectations, Release Drafter plus `CHANGELOG.md` for shipped outcomes, and the website/docs layer for public navigation.

## Recommended structure for each suggestion

Every suggestion should answer:

- Problem statement: what pain exists today?
- Existing solutions scan: what can we reuse from mature frameworks, GitHub features, existing TU-VM scripts, or prior suggestions?
- Proposed solution: what exactly changes?
- Trade-offs: what do we gain/lose?
- Rollout and rollback: how to deploy safely?
- Ownership: who drives and who reviews?
- Success metrics: how do we measure value?

Suggested "reuse scan" checklist:

- Does [`tu-vm.sh`](../tu-vm.sh) already expose the operational action?
- Does [`scripts/`](../scripts/) already provide validation or release support?
- Does [`docs/playbooks/`](../docs/playbooks/README.md) already explain the workflow?
- Is this already covered by a GitHub template, label, workflow, or release process?
- Is there a historical suggestion that should be extended instead of duplicated?

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
  - Link the closest historical suggestion files, even when the result is "no close match"

### 2) Review workflow
- Trigger: suggestion status set to `review`
- Actions:
  - Assign maintainers and reviewers
  - Post review checklist
  - Set reminder if no activity after a defined window
  - Confirm operational, security, and docs impacts before acceptance

### 3) Implementation tracking workflow
- Trigger: proposal accepted
- Actions:
  - Create linked implementation tasks
  - Publish progress status on dashboard/docs
  - Close loop with retrospective template
  - Require changelog/release evidence before moving to `implemented`

### 4) Website publishing workflow
- Trigger: suggestion status changes or frontmatter updates
- Actions:
  - Regenerate status indexes
  - Update "recently changed" and "needs reviewer" lists
  - Validate internal links to issues, PRs, historical suggestions, and changelog entries
  - Emit a small JSON summary that the landing dashboard can optionally consume

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

1. Add a proposal template and status taxonomy (`idea`, `draft`, `review`, `accepted`, `deferred`, `rejected`, `implemented`).
2. Define owner rotation for weekly triage.
3. Automate duplicate checks and stale-review reminders.
4. Publish monthly community update summarizing accepted/rejected suggestions and rationale.
5. Publish the Markdown-first website page set described in [`website-community-pages.md`](./website-community-pages.md).
