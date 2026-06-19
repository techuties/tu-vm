# Community System Framework

## Objective

Build a repeatable community process that turns suggestions into high-quality outcomes without bottlenecks, ambiguity, or duplicate effort.

## Recommendation

Use existing, mature collaboration surfaces before building anything custom:

- **GitHub Issues** for intake and triage.
- **GitHub Discussions** for early design conversation when enabled.
- **Markdown proposal pages** in `suggestions/` for durable, website-ready design records.
- **GitHub labels and PR links** for lifecycle tracking.
- **Release notes and `CHANGELOG.md`** for shipped community outcomes.

This gives the project a community-based system while keeping the source of truth in Git and GitHub history.

## Core model

Use a lightweight lifecycle inspired by established open-source governance (Rust RFCs, Kubernetes enhancement proposals, and docs-driven engineering):

1. **Idea**: short proposal from any contributor
2. **Discovery**: quick check for overlap with existing or historical suggestions
3. **Draft**: structured proposal with impact, scope, and alternatives
4. **Review**: async feedback from maintainers and community
5. **Decision**: accept, accept-with-changes, defer, or reject
6. **Implementation**: linked issues/PRs with milestones
7. **Retrospective**: outcome review and lessons learned

## Status taxonomy

Use the same terms in issue labels, Markdown frontmatter, generated website indexes, and release notes:

- `idea`
- `draft`
- `review`
- `accepted`
- `implemented`
- `deferred`
- `rejected`

Avoid introducing separate status names for the website, dashboard, or automation.

## Recommended structure for each suggestion

Every suggestion should answer:

- Problem statement: what pain exists today?
- Existing solutions scan: what can we reuse?
- Proposed solution: what exactly changes?
- Trade-offs: what do we gain/lose?
- Rollout and rollback: how to deploy safely?
- Ownership: who drives and who reviews?
- Success metrics: how do we measure value?
- Related work: which existing issues, suggestion files, changelog entries, or implemented features overlap?

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
  - Link related historical suggestions instead of opening parallel proposals

### 2) Review workflow
- Trigger: suggestion status set to `review`
- Actions:
  - Assign maintainers and reviewers
  - Post review checklist
  - Set reminder if no activity after a defined window
  - Record decision notes for accepted, deferred, or rejected suggestions

### 3) Implementation tracking workflow
- Trigger: proposal accepted
- Actions:
  - Create linked implementation tasks
  - Publish progress status on dashboard/docs
  - Close loop with retrospective template
  - Add release-note or changelog reference once shipped

### 4) Website publishing workflow
- Trigger: canonical suggestion page changes
- Actions:
  - Validate frontmatter and required sections
  - Regenerate status and area indexes
  - Run Markdown link checks
  - Publish static website output without altering runtime control services

## Metrics

Track these to keep the process healthy:

- Suggestion-to-decision cycle time
- Decision-to-implementation cycle time
- Acceptance ratio
- Duplicate suggestion rate
- Active contributor count (30/90 days)
- Reopened proposals (quality signal)
- Accepted suggestions with linked implementation PRs
- Implemented suggestions with release-note or changelog references

## Risk controls

- No accepted proposal without rollback notes
- No production-impacting change without test/validation path
- Security review required for network, auth, data, or secret changes
- Archive stale proposals after review window with clear reason
- No custom tracker until generated Markdown indexes and GitHub labels are demonstrably insufficient

## Initial actions

1. Add proposal frontmatter and status taxonomy to canonical suggestion pages.
2. Define owner rotation for triage and subsystem review.
3. Automate duplicate checks and stale-review reminders.
4. Generate website indexes from Markdown metadata.
5. Publish a recurring community update summarizing accepted/rejected suggestions and rationale.
