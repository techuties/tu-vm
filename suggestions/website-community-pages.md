# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on the project website/docs surface.

## Goals for website pages

- Make it obvious how to submit high-quality suggestions.
- Show transparent status and decision rationale.
- Help contributors avoid duplicates before submitting.
- Keep maintainers from manually repeating the same guidance.

## Recommended page set

Publishable drafts live under [`website/`](./website/) (mapped later to `docs/community/` after docs-framework adoption). Stage 1/2 sibling pages may land from parallel PRs; Stage 3 fills the lifecycle and construction gaps below.

### 1) `website/index.md`

Purpose:

- Landing page for all community suggestions content.
- Explains lifecycle and links to active suggestion board.

Suggested sections:

- Why suggestions matter
- How suggestions are evaluated
- Quick links (submit, status board, decisions, implemented ideas)

### 2) `website/how-to-submit.md` (Stage 1 sibling)

Purpose:

- Contributor guide for writing high-signal suggestions.

Suggested sections:

- Before you submit (dedupe checks)
- Required template fields
- Example strong suggestion
- Example extension (instead of duplicate)

### 3) `website/status-board.md` (Stage 1 sibling)

Purpose:

- Public, human-readable view of suggestion pipeline.

Suggested sections:

- Table by status (new, triaged, accepted, in-progress, shipped)
- Last-updated timestamp
- Links to decision records

### 4) `website/decision-log.md` (Stage 3)

Purpose:

- Decision log with rationale for accepted/rejected/deferred items.

Draft: [`website/decision-log.md`](./website/decision-log.md).

### 5) `website/implemented-showcase.md` (Stage 3)

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.

Draft: [`website/implemented-showcase.md`](./website/implemented-showcase.md).

### 6) Stage 3 constructional pages

Additional publishable pages for frameworks and day-to-day community operations:

- [`website/docs-framework-adoption.md`](./website/docs-framework-adoption.md) — static docs framework adoption gates (Starlight default)
- [`website/community-quality-gates.md`](./website/community-quality-gates.md) — change-type → evidence matrix
- [`website/extension-pilot-contract.md`](./website/extension-pilot-contract.md) — Compose-backed extension pilot (not a marketplace)
- [`website/hardware-class-intake.md`](./website/hardware-class-intake.md) — optional Issue-form `class_id` tied to the hardware matrix

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

1. Publish Stage 1 pages (`how-to-submit`, `status-board`, day-to-day tools, MCP catalog) when that PR merges.
2. Publish Stage 2 living artifacts (hardware matrix, personas, profiles) when that PR merges.
3. Publish Stage 3 decision log, implemented showcase, docs adoption, quality gates, extension pilot, and hardware-class intake (this folder).
4. Reconcile shared `website/index.md` carefully across Stage 1–3 so one hub remains.
5. After static-framework gates pass, map `suggestions/website/` into the docs content root without two editable copies.
