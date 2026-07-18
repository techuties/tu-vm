# Website Community Pages (Markdown Suggestions)

This page defines the reusable Markdown publishing model for a community-facing suggestions section. It complements GitHub Issues; it does not introduce another submission, voting, comment, or authentication system.

## Source-of-truth model

| Information | Canonical source | Website treatment |
|---|---|---|
| Proposal and discussion | GitHub Issue created from the existing suggestion form | Link to the issue; summarize only accepted scope and status. |
| Implementation | Linked pull request(s) | Show implementation links and verification evidence. |
| Release outcome | GitHub Release / `CHANGELOG.md` | Show the shipped version and operator-visible outcome. |
| Security report | `SECURITY.md` and private advisory | Link only to private reporting guidance; never mirror report details. |
| Historical architecture idea | Existing file in `suggestions/` | Link or consolidate into a canonical page before creating another file. |

Website pages are curated, reviewable views. GitHub labels and linked artifacts remain the live workflow.

## Recommended page set

### 1) `community/suggestions/index.md`

- Explain the lifecycle and reuse rule.
- Link to the existing GitHub suggestion form.
- Show generated counts by status and theme.
- List recently updated, accepted, and good-first-contribution items.
- Include a clear security-reporting warning beside the submit link.

### 2) `community/suggestions/how-to-submit.md`

- Search open/closed issues and canonical suggestion pages first.
- State the user problem and current behavior.
- Identify existing components or frameworks that can be reused.
- Define constraints, security impact, rollout/rollback, and acceptance criteria.
- Show one strong example and one duplicate that should be added to an existing issue.

### 3) `community/suggestions/status-board.md`

- Generate a read-only table from curated metadata.
- Filter by lifecycle state, theme, and contribution readiness.
- Show last verified date and canonical issue for every row.
- Never infer `accepted` or `shipped` from free text; require explicit reviewed metadata.

### 4) `community/suggestions/decisions.md`

- Record decision, rationale, alternatives, constraints, and decision date.
- For deferred work, state the measurable reopen condition.
- For superseded work, link the replacement.
- Keep sensitive security reasoning in private channels and publish only safe conclusions.

### 5) `community/suggestions/implemented.md`

- Summarize the operator-visible outcome rather than repeating release notes.
- Link the originating issue, implementation PR, validation evidence, and release.
- Include follow-up metrics or rollback notes when relevant.

### 6) `community/integrations/index.md`

- List reviewed extensions and MCP integrations using the contract in [`extensions-and-integration-framework.md`](./extensions-and-integration-framework.md).
- Show owner, compatibility range, capabilities, network access, security review, and support status.
- Mark community-maintained integrations distinctly from core-supported services.

## Metadata contract

Use page metadata for all website pages:

```yaml
---
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
page_status: maintained
last_verified: 2026-07-18
owner: maintainer-or-team
source: suggestions
---
```

Use lifecycle metadata only for a curated suggestion page:

```yaml
---
id: SUG-YYYY-NNN
title: Short outcome-oriented title
summary: One sentence describing the user value
status: proposed
theme: operations
impact: high
issue_url: https://github.com/techuties/tu-vm/issues/NNN
decision_url: null
implementation_urls: []
shipped_in: null
owner: unassigned
last_verified: 2026-07-18
related:
  - SUG-YYYY-NNN
---
```

Required lifecycle values:

- `proposed` — submitted, not approved.
- `triaged` — scope and duplicate check complete.
- `discussing` — alternatives or constraints are under review.
- `accepted` — approved with explicit acceptance criteria.
- `in-progress` — implementation is linked and active.
- `implemented` — merged and validated, not necessarily released.
- `shipped` — included in a named release.
- `deferred` — paused with a stated reopen condition.
- `rejected` — closed with rationale.
- `superseded` — replaced by a linked canonical proposal.

`page_status` describes document maintenance (`maintained`, `historical`, or `superseded`) and must not be confused with proposal `status`.

## Curated suggestion body template

```markdown
# Outcome-oriented title

## Problem
Describe the observable user or maintainer pain.

## Current state
Link repository evidence and existing behavior.

## Reuse assessment
List existing TU-VM components and mature external frameworks considered.

## Proposed outcome
Define behavior and boundaries without prescribing unnecessary implementation.

## Security and operational impact
Cover network exposure, data, secrets, resources, compatibility, and maintenance.

## Delivery and rollback
Split work into independently reviewable changes and state how each can be disabled.

## Acceptance criteria
List testable outcomes.

## Decision and evidence
Link issue discussion, decision, PRs, validation, and release.
```

## Publishing workflow

1. A contributor submits the existing GitHub issue form after searching for duplicates.
2. Triage links related issues and the nearest canonical suggestion page.
3. Maintainers apply lifecycle labels in GitHub.
4. Once scope is accepted, a PR updates or adds one curated website page with the issue URL.
5. CI validates metadata, lifecycle values, local links, and duplicate IDs.
6. A generator builds navigation/status pages from metadata; generated files must be reproducible.
7. Implementation PRs link the issue and update evidence fields.
8. Release automation marks the shipped version or opens a small docs follow-up.

Draft discussion should not create a new Markdown page for every issue. Curate pages for accepted work, durable decisions, high-value historical context, or themes that consolidate several duplicate issues.

## De-duplication workflow

Before accepting a website page:

1. Normalize the problem into key terms and affected components.
2. Search filenames, titles, headings, `related` IDs, and open/closed GitHub issues.
3. Add a new angle to the canonical page when the desired outcome is the same.
4. Use `superseded` when an old approach is replaced, preserving its rationale.
5. Allow a separate proposal only when its acceptance criteria and deployment boundary can be evaluated independently.

An optional similarity report may suggest related pages, but it must never auto-close an issue or make a governance decision.

## Validation tooling

A single repository command should support local and CI use:

```bash
./scripts/suggestions-lint.sh
```

The proposed validator should:

- parse frontmatter safely,
- reject duplicate IDs and invalid status values,
- verify required fields by page type,
- verify relative links and referenced local paths,
- require an issue for `accepted` and later states,
- require implementation evidence for `implemented`,
- require a release identifier for `shipped`,
- detect stale `last_verified` values as a warning,
- produce likely duplicate hints without blocking on low-confidence matches,
- offer machine-readable output for a future static-site generator.

Start the metadata checks in warning mode on historical files. Enforce them only for canonical pages and changed files until the archive is normalized.

## Accessibility and privacy

- Pair status color with visible text.
- Ensure generated filters and navigation work by keyboard.
- Provide a text summary for charts; avoid making contributor ranking a gamified leaderboard.
- Publish aggregate workflow metrics only. Do not expose contributor email addresses, local operator data, or private security activity.
- Keep tables usable on small screens and preserve headings when rendered as cards.

## Implementation stages

1. Declare the canonical pages and lifecycle; link the existing issue form.
2. Add metadata validation for canonical/changed pages.
3. Generate the status board and navigation.
4. Publish through the selected static framework only after the adoption gate is met.
5. Add aggregate metrics or integration catalog views after their sources are reliable.

## Acceptance criteria

- Contributors have one obvious submission path and one canonical status source.
- Every accepted or later website entry links to a GitHub issue.
- Every shipped entry links to implementation and release evidence.
- Duplicate IDs, invalid states, and broken local links fail before publication.
- The generated website contains no write API, privileged helper endpoint, or private operator data.
- Historical documents remain discoverable without appearing as active competing proposals.
