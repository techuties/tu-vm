# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on the project website/docs surface.

## Goals for website pages

- Make it obvious how to submit high-quality suggestions.
- Show transparent status and decision rationale.
- Help contributors avoid duplicates before submitting.
- Keep maintainers from manually repeating the same guidance.

## Recommended page set

### 1) `community/suggestions/index.md`

Purpose:

- Landing page for all community suggestions content.
- Explains lifecycle and links to active suggestion board.

Suggested sections:

- Why suggestions matter
- How suggestions are evaluated
- Quick links (submit, status board, decisions, implemented ideas)

### 2) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.

Suggested sections:

- Before you submit (dedupe checks)
- Required template fields
- Example strong suggestion
- Example extension (instead of duplicate)

### 3) `community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of suggestion pipeline.

Suggested sections:

- Table by status (new, triaged, accepted, in-progress, shipped)
- Last-updated timestamp
- Links to decision records

### 4) `community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted/rejected/deferred items.

Suggested sections:

- Decision entry format
- Accepted with tradeoffs
- Deferred with re-open conditions
- Rejected with alternatives

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.

Suggested sections:

- Implemented suggestion summary
- What changed in product/operations
- Validation evidence
- Link to release/changelog entry

## Suggested metadata format (front matter)

Use a consistent metadata block in each website markdown page:

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
last_updated: YYYY-MM-DD
owner: maintainer-or-team
```

For individual suggestion entries (if represented as markdown pages):

```yaml
id: SUG-YYYY-NNN
status: triaged
theme: operations
impact: high
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
```

## Information architecture guidance

- Keep suggestion pages in a single docs subtree for discoverability.
- Ensure every status-board row links to a decision entry or rationale.
- Keep "implemented" entries short and link to technical details elsewhere.
- Add a visible note: "Check historical suggestions before submitting."

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column count.
- Ensure link text is descriptive (avoid generic "click here").
- Use explicit dates and statuses to avoid ambiguity.

## Publishable website directory

Curated, read-only pages live under [`website/`](./website/index.md) for a future static docs mount:

| Stage | Focus | Representative pages |
|---|---|---|
| 1 (open PR) | Intake and daily tools | `how-to-submit`, `status-board`, `day-to-day-community-tools`, `mcp-tools-catalog` |
| 2 (open PR) | Living ops artifacts | `hardware-compatibility-matrix`, `persona-entry-paths`, `operator-service-profiles` |
| 3 (open PR) | Lifecycle + constructional contracts | `decision-log`, `implemented-showcase`, `docs-framework-adoption`, `community-quality-gates`, `extension-pilot-contract`, `hardware-class-intake` |
| 4 (this branch) | Implementation contracts | `mcp-catalog-ci-contract`, `operator-profile-cli`, `extension-pilot-scaffold`, `supply-chain-community-gates`, `dashboard-modularization-smoke`, `stage-merge-playbook` |

Use [`website/stage-merge-playbook.md`](./website/stage-merge-playbook.md) when reconciling Stage hubs so only one editable `website/index.md` remains.

## Rollout recommendation

1. Publish Stage 1 `index.md`, `how-to-submit.md`, and `status-board.md` first.
2. Add decision log / implemented showcase (Stage 3) once triage produces outcomes.
3. Land Stage 4 implementation contracts before coding MCP CI, profile CLI, or extension scaffolds.
4. Merge Stage 1–4 with the stage-merge playbook; then mount to `docs/community/` after docs-framework gates pass.
