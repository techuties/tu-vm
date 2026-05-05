# Community Suggestions Framework

This framework is designed to help TU-VM accept, evaluate, and implement suggestions from contributors without creating process overhead.

## 1) Objectives

- Prevent duplicate work and repeated suggestion cycles.
- Make acceptance/rejection decisions transparent and auditable.
- Prioritize suggestions that improve reliability, security, and day-to-day contributor experience.
- Ensure each accepted suggestion has an owner, scope, and measurable outcome.

## 2) Suggestion Lifecycle

### Stage A: Intake

Required fields for every new suggestion:

- Problem statement (what hurts today)
- Proposed improvement (what should change)
- User impact (who benefits)
- Ops impact (runtime, maintenance, security)
- Expected validation method (how success is measured)

### Stage B: Deduplication

Maintainer checks:

1. `suggestions/historical-suggestions.md`
2. `CHANGELOG.md` (implemented/planned equivalents)
3. Existing scripts or docs that already solve the need

Decision:

- Duplicate -> close as duplicate with link.
- Partial overlap -> convert to extension proposal.
- Net-new -> move to triage.

### Stage C: Triage and Scoring

Use a weighted score (1-5 each):

- Community value (weight 3)
- Reliability gain (weight 3)
- Security/safety gain (weight 3)
- Implementation complexity (inverse, weight 2)
- Ongoing maintenance cost (inverse, weight 2)

Interpretation:

- High score: queue for next implementation cycle
- Medium score: keep in active backlog with prerequisite notes
- Low score: archive with rationale

### Stage D: Decision

Each suggestion gets a status:

- Accepted
- Accepted with changes
- Deferred
- Rejected

Every non-accepted decision must include rationale and a re-open condition.

### Stage E: Implementation

For accepted suggestions:

- Define minimal first slice
- Link to affected files/services
- Define verification commands
- Add changelog entry reference once shipped

### Stage F: Closure

A suggestion is closed only when:

- Change is merged
- Validation evidence is recorded
- Changelog notes the outcome
- Suggestion is moved to "implemented" state in website/community surface

## 3) Governance Roles (lightweight)

- Community submitter: proposes issue/opportunity
- Triage maintainer: runs dedupe and scoring
- Implementation owner: ships change and validates
- Reviewer: confirms acceptance criteria and regression risk

One person can hold multiple roles for small changes, but all roles must be represented.

## 4) Acceptance Criteria Template

Use this checklist for implementation-ready suggestions:

- [ ] Problem is observable and reproducible
- [ ] Proposal is scoped to one logical outcome
- [ ] Backward compatibility impact is documented
- [ ] Security implications reviewed
- [ ] Operational runbook impact documented
- [ ] Validation method is explicit and repeatable
- [ ] Rollback path exists

## 5) Cadence and Hygiene

- Run a recurring suggestion triage sweep (cron/weekly cadence in operations workflow).
- Keep backlog compact by enforcing explicit status changes.
- Archive stale deferred items that have no champion or obsolete context.
- Convert recurring "support pain points" into standard tooling proposals.

## 6) Suggested Metrics

- Suggestion lead time (intake -> decision)
- Acceptance rate
- Median time from accepted -> shipped
- Duplicate suggestion rate
- Post-release regression rate for suggestion-driven changes

These metrics show if the framework is helping or creating friction.
