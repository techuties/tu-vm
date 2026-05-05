# Community Framework Suggestions

This document defines a practical, community-based framework for collecting, reviewing, and implementing suggestions in a consistent way.

The system is designed for a small operations-focused platform where maintainability and security are as important as feature velocity.

## 1) Community framework goals

1. Make it easy for users to submit useful suggestions.
2. Prevent duplicate proposals and repetitive work.
3. Ensure decisions are transparent (accepted, rejected, deferred).
4. Keep implementation aligned with platform constraints (local-first, secure-by-default, lightweight).

## 2) Suggestion lifecycle

Use a clear lifecycle so contributors know proposal status at all times.

### Proposed states

- `new` - submitted and awaiting triage
- `needs-context` - missing problem statement, scope, or acceptance criteria
- `planned` - accepted for upcoming implementation
- `in-progress` - currently being implemented
- `implemented` - merged and released
- `declined` - not aligned with strategy or constraints
- `archived` - stale or superseded proposal

## 3) Suggestion quality standard

Require suggestions to include the same minimum structure.

### Required fields

1. **Problem**: What is currently hard or broken?
2. **Proposed change**: What should be added/changed?
3. **Expected outcome**: Measurable impact on users/operators.
4. **Scope**: Which services/components are affected?
5. **Risks**: Security, performance, operational complexity.
6. **Validation**: How to verify success after implementation.

This template reduces low-signal ideas and shortens implementation handoff.

## 4) Governance model (lightweight)

Use a simple role split that fits community-driven maintenance.

### Roles

- **Contributors**: submit and refine suggestions.
- **Maintainers**: triage, prioritize, and decide on acceptance.
- **Reviewers**: validate technical feasibility/security implications.

### Decision policy

- Small changes: maintainer + one reviewer.
- Cross-cutting/security-sensitive changes: maintainer + two reviewers.
- Major architectural changes: require RFC-style proposal and migration plan.

## 5) Prioritization framework

Score suggestions using four dimensions (1-5 each):

1. User impact
2. Operational simplicity
3. Security/compliance impact
4. Implementation effort (inverse score)

Sort by total score and apply strategic overrides only with written rationale.

## 6) Anti-duplication process

To avoid reinventing the wheel:

1. Search open + archived suggestions before accepting a new one.
2. Link duplicate suggestions to a canonical proposal.
3. Merge overlapping suggestions into one tracked item.
4. Preserve original authorship references.

## 7) RFC trigger criteria

Require RFC-level detail when a suggestion:

- touches security/auth/access control behavior,
- changes storage/network topology,
- introduces new always-on services,
- or adds external dependencies with operational cost.

### RFC minimum sections

- Context and problem statement
- Alternatives considered
- Proposed design
- Rollout and rollback strategy
- Migration and compatibility notes
- Test/validation strategy

## 8) Community communication loop

Every accepted suggestion should produce user-visible updates:

1. Added to planned backlog.
2. Mentioned when implementation starts.
3. Marked implemented with release reference.
4. Reflected in changelog/documentation.

This closes the loop and keeps contributors engaged.

## 9) Suggested KPIs

Track a small set of useful metrics:

- Median triage time
- Acceptance rate
- Duplicate rate
- Time from accepted -> implemented
- Regression rate for implemented suggestions

Keep metrics lightweight and review monthly.

## 10) First implementation steps

1. Add a suggestion template to the contribution path.
2. Create labels matching lifecycle states.
3. Publish decision rules and prioritization rubric.
4. Start with weekly triage and small visible wins.
