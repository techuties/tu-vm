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

The lifecycle should be visible on the website through markdown frontmatter,
generated indexes, and links back to GitHub Issues/PRs. GitHub remains the
system of record for discussion; the website is the readable community layer.

## Recommended structure for each suggestion

Every suggestion should answer:

- Problem statement: what pain exists today?
- Existing solutions scan: what can we reuse?
- Proposed solution: what exactly changes?
- Trade-offs: what do we gain/lose?
- Rollout and rollback: how to deploy safely?
- Ownership: who drives and who reviews?
- Success metrics: how do we measure value?
- Historical overlap: what existing suggestion, issue, or framework is reused?
- Website impact: what docs, navigation, or status page changes are needed?

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
- Community maintainability (1-5)

Accepted proposals should have high impact and reuse score with manageable risk.

## Status taxonomy

Use one vocabulary across GitHub labels, markdown frontmatter, and the website:

| Status | Meaning | Exit condition |
|--------|---------|----------------|
| `draft` | Author is shaping the idea | Required fields complete |
| `triage` | Maintainers check scope, duplicates, and safety | Owner/theme assigned |
| `review` | Community and domain owners evaluate trade-offs | Decision recorded |
| `accepted` | Proposal approved | Implementation issue/PR linked |
| `in-progress` | Work is actively underway | Validation evidence available |
| `shipped` | Released, documented, or operationalized | Release/changelog linked |
| `deferred` | Valid but blocked or lower priority | Reopen condition documented |
| `rejected` | Not planned | Rationale and alternative documented |
| `superseded` | Folded into a better canonical suggestion | Canonical target linked |

## Community workflows to implement

### 1) Suggestion intake workflow
- Trigger: new suggestion markdown file or issue label
- Actions:
  - Validate required fields
  - Detect likely duplicates using keyword matching
  - Auto-tag by domain (docs, automation, infra, UX, security)
  - Add or update website frontmatter when the proposal becomes durable
  - Link the proposal to any historical suggestion it extends

### 2) Review workflow
- Trigger: suggestion status set to `review`
- Actions:
  - Assign maintainers and reviewers
  - Post review checklist
  - Set reminder if no activity after a defined window
  - Record accepted trade-offs directly in a decision log entry

### 3) Implementation tracking workflow
- Trigger: proposal accepted
- Actions:
  - Create linked implementation tasks
  - Publish progress status on dashboard/docs
  - Close loop with retrospective template
  - Update `implemented` or `archive` website pages when the proposal ships,
    is deferred, rejected, or superseded

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
- No new website suggestion page when an existing canonical page can be updated
- No external community tool unless it has an owner, fallback path, and clear
  value beyond GitHub-native workflow

## Community website outputs

The framework should produce these user-facing artifacts:

- suggestion landing page that explains lifecycle and expectations
- how-to-submit guide with duplicate checks and examples
- status board grouped by lifecycle state
- decision log with accepted, deferred, rejected, and superseded entries
- implemented page that links shipped ideas to release evidence
- archive page that keeps historical context discoverable without crowding the
  active backlog

## First implementation actions

1. Add a proposal template and status taxonomy (`draft`, `triage`, `review`,
   `accepted`, `in-progress`, `shipped`, `deferred`, `rejected`,
   `superseded`).
2. Define owner rotation for weekly triage.
3. Automate duplicate checks and stale-review reminders.
4. Publish monthly community update summarizing accepted/rejected suggestions and rationale.
5. Define a future field mapping across the current Issue template (summary,
   acceptance/constraints, duplicate check), durable website frontmatter, and
   PR verification. Keep detailed lifecycle, owner, risk, and rollout fields in
   website markdown unless the Issue template is deliberately expanded.
6. Publish a dedupe pass that marks older overlapping suggestions as
   `superseded` by canonical pages.
