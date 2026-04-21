# Suggestion 02: Community Contribution System (Suggestions as a First-Class Workflow)

## Goal

Turn "good ideas from users/contributors" into a predictable system that:

- captures proposals consistently,
- avoids duplicate work,
- allows transparent decision-making, and
- keeps implementation tied to real repository changes.

## Problem to solve

Without a clear suggestion lifecycle, projects often see:

- repeated ideas in different channels,
- high-quality suggestions getting lost,
- unclear ownership of proposal follow-through,
- friction for newcomers who want to contribute.

## Recommendation

Introduce a lightweight **Suggestion Lifecycle Framework**.

## Suggested lifecycle states

1. **Draft**
   - Initial proposal submitted.
   - Must include problem statement and expected user impact.
2. **Triaged**
   - Maintainers assign scope label (`docs`, `ops`, `ui`, `security`, `automation`).
   - Duplicate check completed.
3. **Accepted for Trial**
   - Proposal is approved for small-scale implementation or experiment.
4. **Implemented**
   - Changes merged to repository.
   - Links to commit(s), changed files, and rollout notes.
5. **Archived / Rejected**
   - Stored with clear rationale to prevent repeating discussion.

## File structure suggestion

Use this same `suggestions/` folder as the canonical source.

Recommended naming:

`NN-short-topic.md` (example: `05-dashboard-plugin-architecture.md`)

Each suggestion should include:

- problem
- proposed solution
- alternatives considered
- implementation steps
- risks
- success criteria
- current status

## Community operating model

### Roles

- **Contributors**: submit and refine suggestions.
- **Maintainers**: triage, de-duplicate, decide trial acceptance.
- **Implementers**: execute accepted suggestions with traceable commits.

### Decision cadence

- Regular review pass (for example weekly or bi-weekly) over new drafts.
- Small "accepted for trial" batch each cycle to limit operational risk.

### Governance guardrails

- No silent rejection: every rejected suggestion includes reason.
- No stale limbo: suggestions older than a threshold must be updated, accepted, or archived.
- No reinvention: each new suggestion links to related existing suggestions/files.

## Template for future suggestions (copy/paste)

```md
# Suggestion NN: <Title>

## Summary
## Problem
## Proposed Solution
## Alternatives Considered
## Implementation Steps
## Risks and Mitigations
## Success Criteria
## Status
## Related Suggestions / Files
```

## Practical integrations for this repository

1. Link `suggestions/README.md` from the root `README.md`.
2. Add a "Suggestion Checklist" section to PR process (or contribution notes).
3. Use labels (or equivalent metadata) to map suggestions to implementation commits.
4. Keep accepted suggestions updated with final outcomes and operational notes.

## Expected benefits

- Better contributor onboarding and retention.
- Fewer duplicate conversations.
- Faster prioritization of high-value work.
- Clear institutional memory for why changes were made.
