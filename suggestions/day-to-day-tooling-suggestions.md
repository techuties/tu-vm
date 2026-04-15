# Day-to-Day Tooling Suggestions

These suggestions focus on reducing repetitive operational work and improving contributor productivity while fitting TU-VM's existing architecture.

## 1) Suggestion Registry Script

### Proposal

Add a script (for example `scripts/suggestion-registry.sh`) to maintain a machine-readable index of all suggestion states:

- New
- Triaged
- Accepted
- In progress
- Shipped
- Rejected

### Why it helps

- Prevents status drift between docs/changelog/community pages.
- Makes reporting and planning simpler.
- Enables lightweight dashboards later without major refactors.

### Minimal first slice

- Parse markdown metadata blocks from `suggestions/*.md`
- Emit a normalized table/json view
- Validate allowed status values

## 2) Suggestion Linting Gate

### Proposal

Add a pre-push checker to ensure suggestion files have required sections:

- Problem
- Proposal
- Impact
- Validation
- Status

### Why it helps

- Improves suggestion quality at intake.
- Reduces triage rework.
- Standardizes submissions for community contributors.

### Minimal first slice

- Integrate into `scripts/pre-push-check.sh`
- Soft-fail mode first (warnings), then optional strict mode

## 3) Decision Log Automation

### Proposal

Add a helper that can append structured decision entries whenever suggestion status changes to accepted/rejected/deferred.

### Why it helps

- Preserves rationale over time.
- Creates an audit trail that survives maintainer rotation.
- Makes "why this was declined" discoverable.

### Minimal first slice

- Script accepts: suggestion id, new status, rationale
- Appends entry to an existing project log file

## 4) Community Health Snapshot

### Proposal

Add a small script generating a periodic summary of suggestion pipeline health:

- Open suggestions by status
- Average lead time to decision
- Top recurring themes

### Why it helps

- Gives maintainers a quick operational pulse.
- Encourages data-driven prioritization.
- Helps communicate progress to contributors.

### Minimal first slice

- Markdown report generated from local suggestion files
- Optional cron integration with existing ops cadence

## 5) Contributor Starter Pack for Suggestions

### Proposal

Provide template fragments and examples aligned with this framework so first-time contributors can submit high-quality suggestions quickly.

### Why it helps

- Lowers contribution friction.
- Improves consistency and acceptance probability.
- Reduces maintainer feedback loops on missing info.

### Minimal first slice

- Reusable section template in existing docs surface
- One "good suggestion" and one "extension proposal" example

## Prioritization Recommendation

Suggested implementation order:

1. Suggestion linting gate
2. Suggestion registry script
3. Decision log automation
4. Community health snapshot
5. Contributor starter pack

This order delivers the fastest quality and clarity gains with minimal infrastructure change.
