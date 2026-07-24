# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on the project website/docs surface.

## Goals for website pages

- Make it obvious how to submit high-quality suggestions.
- Show transparent status and decision rationale.
- Help contributors avoid duplicates before submitting.
- Keep maintainers from manually repeating the same guidance.

## Recommended page set

Stage 1 sources are authored under [`website/`](./website/) so the community website has concrete markdown now. After static-framework adoption, map that folder into `docs/community/` (or the configured content root) without keeping two editable copies.

### 1) `community/suggestions/index.md` → [`website/index.md`](./website/index.md)

Purpose:

- Landing page for all community suggestions content.
- Explains lifecycle and links to active suggestion board.

Suggested sections:

- Why suggestions matter
- How suggestions are evaluated
- Quick links (submit, status board, decisions, implemented ideas)

### 2) `community/suggestions/how-to-submit.md` → [`website/how-to-submit.md`](./website/how-to-submit.md)

Purpose:

- Contributor guide for writing high-signal suggestions.

Suggested sections:

- Before you submit (dedupe checks)
- Required template fields
- Example strong suggestion
- Example extension (instead of duplicate)

### 3) `community/suggestions/status-board.md` → [`website/status-board.md`](./website/status-board.md)

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

Add this page once the first triage cycle under the Stage 1 board completes (do not invent a second tracker).

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.

Suggested sections:

- Implemented suggestion summary
- What changed in product/operations
- Validation evidence
- Link to release/changelog entry

### 6) Tools pages (Stage 1 detailed)

- [`website/day-to-day-community-tools.md`](./website/day-to-day-community-tools.md) — frameworks and daily commands
- [`website/mcp-tools-catalog.md`](./website/mcp-tools-catalog.md) — community MCP contribution contract (distinct constructional focus)

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

## Rollout recommendation

1. Stage 1 drafts now exist under [`website/`](./website/index.md) (`index`, `how-to-submit`, `status-board`, day-to-day tools, MCP catalog).
2. Link the hub from CONTRIBUTING / landing community strip when ready for wider visibility.
3. Add `decisions.md` once first triage cycle completes.
4. Add `implemented.md` when first suggestion ships under this framework.
5. On docs-framework adoption, move or mount `website/` as the community content root once.
