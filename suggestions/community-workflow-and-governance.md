# Community Workflow and Governance

## 1) Workflow lifecycle

Use a clear state machine so contributors understand where ideas stand:

1. `proposed` - submitted with complete template
2. `triaged` - validated for scope and duplicate checks
3. `accepted` - approved for implementation
4. `in-progress` - actively being built
5. `completed` - delivered and documented
6. `rejected` - closed with explicit rationale

## 2) Triage checklist (avoid duplicates)

Before accepting a suggestion:

- Check existing `suggestions/` files for overlap.
- Check `CHANGELOG.md` for already delivered features.
- Check `README.md` architecture for compatibility.
- Confirm operational impact on Tier 1/Tier 2 model.
- Confirm security fit (tokens, rate limits, auditability).

If duplicate:

- Link to the canonical suggestion.
- Merge useful details into canonical proposal.
- Mark duplicate suggestion as rejected with reason "duplicate-canonicalized".

## 3) Governance roles

- **Community contributor**
  - Submits suggestion via template.
  - Provides expected outcome and success metric.
- **Triage maintainer**
  - Validates structure and duplicate status.
  - Assigns category, effort, and priority.
- **Technical owner**
  - Confirms implementation approach and rollback plan.
  - Owns status updates during delivery.
- **Release reviewer**
  - Confirms acceptance criteria and changelog entry.

For small teams, one person may hold multiple roles, but each decision point should still be explicit in the suggestion metadata.

## 4) Decision rubric (scoring model)

Score each suggestion across five dimensions:

1. User value
2. Architectural fit
3. Operational simplicity
4. Security/compliance impact
5. Maintenance burden

Suggested scoring:

- 1-2: weak
- 3: neutral
- 4-5: strong

Set default acceptance threshold (for example, mean score >= 3.5 with no "1" in security).

## 5) Community voting model

Voting should inform priority, not replace technical review.

- Keep vote records immutable (append-only events).
- Weight can be simple (1 user = 1 vote) at first.
- Prevent rapid vote abuse with per-IP or per-token rate limits.

Recommended derived fields in suggestion metadata:

- `vote_score = up - down`
- `engagement = up + down + comments_count`

## 6) Transparency conventions

Each suggestion detail page should show:

- Current status
- Last decision and date
- Decision rationale (1-3 bullets)
- Blocking dependencies
- Owner

This keeps expectations realistic and reduces repeated requests for status.

## 7) Required acceptance gates

A suggestion can move to `accepted` only when it has:

- explicit success metric,
- rollback plan,
- impacted component list,
- security consideration,
- test or validation plan.

## 8) Completion criteria

A suggestion moves to `completed` only when:

- code/docs shipped,
- validation evidence captured,
- changelog updated,
- status in suggestion file updated.

## 9) Minimum template for new suggestions

Use this section structure in each suggestion markdown file:

1. Context
2. Problem
3. Proposal
4. Reuse of existing TU-VM components
5. Risks + rollback
6. Acceptance criteria
7. KPI / measurable impact
8. Ownership
