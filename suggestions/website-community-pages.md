# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on the project website/docs surface.

They are intentionally designed to work as plain markdown first. A static site framework can render them later without changing the contribution model.

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
- Links to canonical historical files in `suggestions/`
- Current status counts generated from metadata

### 2) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.

Suggested sections:

- Before you submit (dedupe checks)
- Required template fields
- Example strong suggestion
- Example extension (instead of duplicate)
- Security and privacy considerations for private-AI operators

Contributor checklist:

1. Search existing `suggestions/` pages.
2. Link related historical suggestions.
3. State the operator or contributor problem.
4. Name the framework, project feature, or existing workflow being reused.
5. Include acceptance criteria and rollback notes when behavior changes.

### 3) `community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of suggestion pipeline.

Suggested sections:

- Table by status (new, triaged, accepted, in-progress, shipped)
- Last-updated timestamp
- Links to decision records
- Owner or next-review field for each accepted item
- Related changelog or release link for shipped items

### 4) `community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted/rejected/deferred items.

Suggested sections:

- Decision entry format
- Accepted with tradeoffs
- Deferred with re-open conditions
- Rejected with alternatives
- Superseded by another suggestion with canonical replacement link

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.

Suggested sections:

- Implemented suggestion summary
- What changed in product/operations
- Validation evidence
- Link to release/changelog entry

### 6) `community/suggestions/template.md`

Purpose:

- Starter page for new website-ready suggestion markdown.
- Keeps submissions consistent and easier to validate.

Suggested sections:

- Frontmatter example
- Problem
- Historical references
- Recommended approach
- Community workflow impact
- Risks and guardrails
- Acceptance criteria
- Decision log

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
source:
  - suggestions/historical-suggestions.md
related:
  - suggestions/website-markdown-publishing-system.md
```

See [Website Markdown Publishing System](./website-markdown-publishing-system.md) for the complete schema.

## Information architecture guidance

- Keep suggestion pages in a single docs subtree for discoverability.
- Ensure every status-board row links to a decision entry or rationale.
- Keep "implemented" entries short and link to technical details elsewhere.
- Add a visible note: "Check historical suggestions before submitting."
- Make the canonical suggestion index the default landing page, not a chronological archive.
- Use tags for theme, subsystem, and contributor type so newcomers can filter quickly.

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column count.
- Ensure link text is descriptive (avoid generic "click here").
- Use explicit dates and statuses to avoid ambiguity.

## Rollout recommendation

1. Publish `index.md`, `how-to-submit.md`, `status-board.md`, and `template.md` first.
2. Add `decisions.md` when maintainers start recording accepted, deferred, rejected, and superseded outcomes.
3. Add `implemented.md` when release notes can link shipped work back to suggestion IDs.
4. Generate indexes from frontmatter once the schema is in use.

## Acceptance criteria

- Contributors can identify the right page for submission, status, decisions, and shipped work.
- Every public suggestion page links back to historical context or explicitly says no prior match was found.
- The website can render the pages without custom backend state.
- Maintainers can update statuses by editing markdown metadata in a normal pull request.
