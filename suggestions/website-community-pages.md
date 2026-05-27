# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on the project website/docs surface.

The intent is to use plain markdown and front matter first, then let a mature static-site framework such as Docusaurus, Astro Starlight, or MkDocs Material render the content. That keeps contribution simple while still enabling search, sidebars, generated indexes, and link checking.

## Goals for website pages

- Make it obvious how to submit high-quality constructive suggestions.
- Show transparent status and decision rationale.
- Help contributors avoid duplicates before submitting.
- Keep maintainers from manually repeating the same guidance.
- Preserve a public path from idea to accepted work, implementation evidence, and changelog entry.

## Recommended website markdown tree

If a docs website is introduced, keep suggestions in one predictable subtree:

```text
docs/
  community/
    suggestions/
      index.md
      how-to-submit.md
      status-board.md
      decisions.md
      implemented.md
      template.md
```

For this repository, the source-of-truth planning documents can remain in `suggestions/` until a website framework exists. The website files above should link back to this folder as historical context.

## Recommended page set

### 1) `community/suggestions/index.md`

Purpose:

- Landing page for all community suggestions content.
- Explains lifecycle and links to active suggestion board.
- Points readers to historical suggestions before they open a new proposal.

Suggested sections:

- `Why suggestions matter`
  - Explain that the project improves through reproducible operator pain points, contributor proposals, and maintainer decisions.
- `Before proposing something new`
  - Search current Issues, Discussions, `CHANGELOG.md`, and `suggestions/`.
  - Link to the historical baseline and implementation backlog.
- `Lifecycle at a glance`
  - `new -> triaged -> accepted -> in progress -> shipped`
  - `deferred` and `declined` remain visible with rationale.
- `Quick links`
  - Submit an idea
  - View status board
  - Read decisions
  - See implemented suggestions

### 2) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.
- Reduces duplicate proposals by asking for explicit comparison with existing work.

Suggested sections:

- `Dedupe checklist`
  - Search `suggestions/` for the same feature area.
  - Check `implementation-backlog.md` for already-prioritized work.
  - Check Issues and recently merged changelog entries.
- `Required fields`
  - Problem statement
  - Who is affected
  - Current workaround
  - Proposed change
  - Existing project surfaces reused
  - Security/resource impact
  - Validation approach
- `Good suggestion example`
  - Show a short example that extends `tu-vm.sh doctor` or the landing dashboard without inventing a new subsystem.
- `When to extend instead of duplicate`
  - If a suggestion improves an existing roadmap item, comment/link to that item or update the relevant markdown section.

### 3) `community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of the suggestion pipeline.
- Gives contributors confidence that proposals are not disappearing.

Suggested sections:

- `Pipeline summary`
  - Counts by status and last updated date.
- `Active suggestions`
  - Concise table with ID, title, status, theme, owner, and next action.
- `Needs input`
  - Items blocked by missing reproduction detail, security notes, or maintainer decision.
- `Recently changed`
  - Suggestions moved between states since the last update.

Suggested table shape:

```markdown
| ID | Suggestion | Theme | Status | Owner | Next action |
| --- | --- | --- | --- | --- | --- |
| SUG-2026-001 | Docs quality gate | docs | accepted | docs-maintainers | Add CI check |
```

Keep this board generated from front matter once automation exists. Until then, update it manually as part of triage.

### 4) `community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted, declined, deferred, or merged suggestions.
- Prevents the community from reopening the same question without new information.

Suggested sections:

- `Decision format`
  - ID, date, status, decision maker, linked proposal, rationale, tradeoffs, revisit trigger.
- `Accepted with tradeoffs`
  - State what risk was accepted and how it will be monitored.
- `Deferred`
  - State what evidence or dependency is required to reopen.
- `Declined`
  - Provide respectful rationale and recommended alternatives.
- `Merged into existing work`
  - Link duplicate or overlapping ideas to the canonical suggestion.

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.
- Helps contributors see impact and gives maintainers a traceable history.

Suggested sections:

- `Shipped suggestions`
  - Summary, linked issue/PR, release/changelog link, validation evidence.
- `Operator impact`
  - What changed for day-to-day users.
- `Community impact`
  - Which pain point was reduced or which workflow became easier.
- `Follow-up opportunities`
  - Small next steps that should not block marking the original suggestion shipped.

### 6) `community/suggestions/template.md`

Purpose:

- Reusable page template for larger suggestions that need a decision record.
- Keeps proposals comparable across feature areas.

Suggested content:

```markdown
---
id: SUG-YYYY-NNN
title: Short actionable title
status: new
theme: docs|operations|security|automation|community|ux
impact: low|medium|high
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - ../path/to/related-suggestion.md
---

# Short actionable title

## Problem

What user or maintainer problem exists today?

## Current state

What does TU-VM already provide, and what workaround exists?

## Proposal

What should change? Prefer reusing existing surfaces such as `tu-vm.sh`, helper API endpoints, the landing dashboard, GitHub templates, and docs.

## Impact

- User impact:
- Maintainer impact:
- Security impact:
- Resource impact:

## Implementation outline

1. Smallest useful change.
2. Validation or automation.
3. Documentation and changelog updates.

## Rollback or exit path

How can maintainers disable, revert, or decline the idea cleanly?

## Success signals

- Measurable evidence that the suggestion helped.
```

## Suggested metadata format (front matter)

Use a consistent metadata block in each website markdown page:

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
last_updated: YYYY-MM-DD
owner: maintainer-or-team
```

For individual suggestion entries:

```yaml
id: SUG-YYYY-NNN
status: triaged
theme: operations
impact: high
owner: maintainer-or-team
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - ./historical-suggestions.md
```

Required status values should stay small and stable:

- `new`
- `triaged`
- `accepted`
- `in-progress`
- `shipped`
- `merged`
- `deferred`
- `declined`

## Dedupe workflow

1. Search this folder for similar keywords and subsystem names.
2. Check the status board for accepted or in-progress work.
3. If related work exists, add a `related` link and explain the difference.
4. If the proposal is mostly the same, mark it as `merged` and point to the canonical item.
5. If the proposal is new, assign a stable suggestion ID before review.

## Automation opportunities

Start with lightweight checks before building a custom suggestions service:

- Markdown link checking for internal references.
- Front matter validation for required fields.
- Generated status board from suggestion metadata.
- Duplicate-topic hinting based on tags and related links.
- Release note helper support that can list shipped suggestion IDs.

These checks can run in CI and optional local pre-push flows. They should produce actionable errors and avoid blocking contributors on cosmetic preferences.

## Information architecture guidance

- Keep suggestion pages in a single docs subtree for discoverability.
- Ensure every status-board row links to a decision entry or rationale.
- Keep implemented entries short and link to technical details elsewhere.
- Add a visible note: "Check historical suggestions before submitting."
- Keep stable anchors for pages that the dashboard or changelog links to.

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column count.
- Ensure link text is descriptive.
- Use explicit dates and statuses to avoid ambiguity.
- Avoid color-only status indicators; pair badges with text labels.

## Implementation sequence

1. Publish `index.md`, `how-to-submit.md`, `status-board.md`, and `template.md`.
2. Add `decisions.md` once the first triage cycle produces rationale worth preserving.
3. Add `implemented.md` when the first suggestion ships under this framework.
4. Add front matter validation and generated indexes after the markdown format stabilizes.
