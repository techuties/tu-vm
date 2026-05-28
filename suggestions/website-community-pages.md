# Website Community Pages and Markdown Publishing System

This is the canonical suggestion for turning the existing `/suggestions/`
archive into website-ready Markdown without building a custom community
application first.

## Goals for website pages

- Make it obvious how to submit high-quality suggestions.
- Show transparent status, ownership, and decision rationale.
- Help contributors find historical suggestions before opening duplicates.
- Keep maintainers from manually repeating the same guidance.
- Reuse mature static-site and GitHub workflows before introducing custom code.

## Historical baseline to reuse

The current repository already contains many related suggestion files. Treat them
as source material, then publish a smaller curated path on the website:

- [`website-historical-baseline.md`](./website-historical-baseline.md) for repeated historical themes.
- [`community-system-framework.md`](./community-system-framework.md) for lifecycle and governance.
- [`website-and-docs-framework.md`](./website-and-docs-framework.md) for the website stack and navigation model.
- [`day-to-day-tooling.md`](./day-to-day-tooling.md) for maintainer and contributor automation.
- [`implementation-backlog.md`](./implementation-backlog.md) for shipped, superseded, and next-priority work.

Every new website page should link back to this archive instead of rewriting the
same context in isolation.

## Recommended website page set

Place community pages under a single website/docs subtree such as
`community/suggestions/`. The physical location can be adapted to Docusaurus,
MkDocs Material, Astro Starlight, or another static-site framework.

### 1) `community/suggestions/index.md`

Purpose:

- Landing page for all community suggestion content.
- Explains the lifecycle and links to active entry points.
- Sets the expectation that contributors check historical suggestions first.

Suggested sections:

- Why suggestions matter.
- How suggestions are evaluated.
- Current lifecycle statuses.
- Quick links: submit, status board, decisions, implemented ideas, archive.
- Maintainer contact and escalation path for sensitive reports.

Acceptance criteria:

- New contributors can find the submit path and status board in one click.
- The page links to GitHub Issues or Discussions rather than a separate custom
  intake form unless the project later needs one.
- The page links to the historical archive and backlog.

### 2) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.
- Converts "good idea" energy into proposals maintainers can evaluate quickly.

Suggested sections:

- Before you submit: search existing Issues, Discussions, and `/suggestions/`.
- Required fields: problem, users affected, existing alternatives, proposed
  approach, impact, risks, rollout, rollback, and success criteria.
- How to extend an existing suggestion instead of creating a duplicate.
- Example strong suggestion with concise scope and validation notes.
- Example weak suggestion showing what information is missing.

Acceptance criteria:

- The guide maps directly to the GitHub **Idea / suggestion** template.
- Contributors can copy the structure into an issue without reformatting.
- Duplicate proposals have a clear "related suggestion" linking pattern.

### 3) `community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of the suggestion pipeline.
- Gives contributors confidence that proposals are seen and moving.

Suggested sections:

- Table grouped by status: `new`, `triaged`, `accepted`, `in-progress`,
  `shipped`, `deferred`, `rejected`, and `merged-with-existing`.
- Columns: ID, title, theme, owner, last update, next action, related links.
- Last-generated timestamp and data source.
- Explanation of what each status means.

Acceptance criteria:

- Each row links to either the original GitHub issue, a decision entry, a
  changelog/release entry, or a historical suggestion file.
- Stale rows show the next required action rather than silently aging.
- The board can be generated from Markdown front matter or GitHub labels.

### 4) `community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted, rejected, merged, and deferred
  suggestions.
- Reduces repeated debate by preserving tradeoffs and context.

Suggested sections:

- Decision entry format.
- Accepted with tradeoffs.
- Merged with existing suggestion.
- Deferred with re-open conditions.
- Rejected with alternatives.

Acceptance criteria:

- Every accepted or rejected suggestion has a short rationale.
- Deferred decisions include explicit revisit conditions.
- Rejected decisions offer an alternative path when possible.

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.
- Closes the loop between community input and delivered platform value.

Suggested sections:

- Implemented suggestion summary.
- What changed in product, docs, operations, or automation.
- Validation evidence.
- Link to PR, commit, release, or changelog entry.

Acceptance criteria:

- Each implemented item references a shipped artifact.
- The page is short enough for users to scan, with deep detail linked elsewhere.
- Release notes and changelog entries can reference suggestion IDs.

### 6) `community/suggestions/archive.md`

Purpose:

- Curated entry point into historical and superseded suggestions.
- Makes "do not reinvent the wheel" enforceable for contributors and reviewers.

Suggested sections:

- Historical themes already explored.
- Superseded suggestions and their replacements.
- Duplicate clusters with canonical file links.
- How to revive an archived idea with new evidence.

Acceptance criteria:

- Archive entries point to canonical files in `/suggestions/`.
- Superseded items explain what replaced them.
- Revived suggestions must reference what changed since the prior decision.

### 7) `community/suggestions/tooling.md`

Purpose:

- Documents day-to-day tools for contributors and maintainers.
- Keeps operational guidance near the suggestion workflow.

Suggested sections:

- Local checks before submitting docs or config changes.
- Optional pre-commit setup.
- Release note helper usage.
- Link checker and Markdown quality checks.
- Maintainer scripts for generating status summaries.

Acceptance criteria:

- The page reuses existing repository commands instead of inventing new wrappers.
- Each command has expected output or success criteria.
- Tooling that depends on Docker or configured `.env` says so clearly.

## Markdown front matter schema

Use front matter so the static-site framework can generate indexes without a
database.

For website guide pages:

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
section: community
owner: maintainers
last_updated: YYYY-MM-DD
status: active
```

For individual suggestion pages or generated entries:

```yaml
id: SUG-YYYY-NNN
title: Short suggestion title
status: triaged
theme: operations
impact: high
effort: medium
owner: maintainer-or-team
source: https://github.com/techuties/tu-vm/issues/123
related:
  - ../../suggestions/website-historical-baseline.md
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
```

Recommended status values:

- `new`
- `triaged`
- `accepted`
- `in-progress`
- `shipped`
- `deferred`
- `rejected`
- `merged-with-existing`
- `archived`

## Duplicate-avoidance workflow

1. Search GitHub Issues and Discussions for the proposed topic.
2. Search `/suggestions/` for matching themes and keywords.
3. If a close match exists, add context to that thread or create an extension
   proposal that links to the canonical suggestion.
4. If the idea is new, create a suggestion with the required fields and at least
   one "existing alternatives reviewed" note.
5. During triage, maintainers add one of:
   - `accepted`
   - `needs-info`
   - `merged-with-existing`
   - `deferred`
   - `rejected`

This keeps the community process additive instead of repetitive.

## Publishing and automation recommendations

### Static-site framework

Prefer a mature Markdown-first framework:

- Docusaurus for versioned docs, plugin ecosystem, and large-community patterns.
- MkDocs Material for lightweight Python-based docs and simple navigation.
- Astro Starlight for fast content sites with strong defaults and component
  flexibility.

Selection criteria:

- Markdown/MDX support.
- Front matter parsing.
- Generated navigation and tag indexes.
- Local preview command.
- Search plugin support.
- Accessibility-friendly defaults.

### Generated indexes

Add a small script later if manual curation becomes noisy. The script should:

- Read suggestion front matter.
- Group entries by status and theme.
- Emit a JSON file or Markdown table for the website.
- Warn on duplicate IDs, missing owners, missing source links, or stale entries.

### CI quality gates

Start with non-blocking checks, then enforce once the rules are stable:

- Markdown formatting.
- Broken links.
- Required front matter fields.
- Duplicate suggestion IDs.
- Heading hierarchy.
- Accessibility smoke checks for generated pages.

## Day-to-day maintainer workflow

1. Review new suggestion issues or Markdown changes.
2. Search historical suggestions and link related files.
3. Apply status, theme, and owner labels.
4. Update status-board data or front matter.
5. Record decisions when scope changes materially.
6. Link shipped work to changelog, release notes, and `implemented.md`.

## Accessibility and readability baseline

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and mobile-readable.
- Ensure link text is descriptive.
- Use explicit dates and statuses.
- Keep heading levels sequential.
- Add alt text for images or diagrams.
- Avoid relying on color alone for status.

## Rollout recommendation

1. Publish `index.md`, `how-to-submit.md`, and `status-board.md`.
2. Add `decisions.md` and `archive.md` once triage creates enough entries.
3. Add `implemented.md` when shipped work can be linked to suggestions.
4. Add generated indexes only after the manual structure proves stable.
