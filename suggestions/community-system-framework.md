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

## Reuse-first operating rule

Before creating a new process or tool, check whether an existing community pattern already covers the need:

- **GitHub Issues and labels** for intake, ownership, status, and duplicate closure.
- **Pull request templates** for validation, security review, and release-note discipline.
- **Markdown proposal pages** for durable context and website publishing.
- **Release Drafter / changelog practices** for tying implemented suggestions to releases.
- **Static-site framework plugins** for search, sidebars, versioning, redirects, and link checks.
- **Small repository scripts** for duplicate reports and required-section validation.

Only introduce a custom service when the markdown + GitHub + static-site path cannot provide the required workflow safely.

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
  - Link to the closest historical suggestion before review starts

### 2) Review workflow
- Trigger: suggestion status set to `review`
- Actions:
  - Assign maintainers and reviewers
  - Post review checklist
  - Set reminder if no activity after a defined window
  - Require explicit rationale for accepted-with-changes, deferred, and rejected outcomes

### 3) Implementation tracking workflow
- Trigger: proposal accepted
- Actions:
  - Create linked implementation tasks
  - Publish progress status on dashboard/docs
  - Close loop with retrospective template

### 4) Community visibility workflow
- Trigger: suggestion status or implementation link changes
- Actions:
  - Rebuild generated suggestion indexes
  - Update roadmap status links
  - Include shipped suggestions in release notes
  - Keep dashboard/community stats public-safe and free of operational secrets

## Metrics

Track these to keep the process healthy:

- Suggestion-to-decision cycle time
- Decision-to-implementation cycle time
- Acceptance ratio
- Duplicate suggestion rate
- Active contributor count over agreed reporting windows
- Reopened proposals (quality signal)

## Risk controls

- No accepted proposal without rollback notes
- No production-impacting change without test/validation path
- Security review required for network, auth, data, or secret changes
- Archive stale proposals after review window with clear reason

## First implementation actions

1. Add or confirm a proposal template and status taxonomy (`idea`, `draft`, `review`, `accepted`, `deferred`, `rejected`, `implemented`).
2. Define a maintainer ownership model for suggestion triage.
3. Automate duplicate checks and stale-review reminders.
4. Publish a recurring community update summarizing accepted/rejected suggestions and rationale.
5. Add generated website indexes once the markdown frontmatter contract is stable.
