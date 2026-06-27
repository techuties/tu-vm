# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on
the project website/docs surface. The intent is to publish community guidance
with ordinary markdown files first, then let Docusaurus, MkDocs Material, Astro
Starlight, or another mature static-site framework render those files later.

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
- Points contributors to the historical archive before they create a new idea.

Suggested sections:

- Why suggestions matter
- How suggestions are evaluated
- Quick links (submit, status board, decisions, implemented ideas)
- Current status counts by lifecycle state
- Maintainer contact and escalation path for stuck proposals

Suggested frontmatter:

```yaml
title: Community Suggestions
description: Start here to propose, review, and track TU-VM community ideas.
status: published
owner: maintainers
last_updated: YYYY-MM-DD
source: suggestions
```

### 2) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.

Suggested sections:

- Before you submit (dedupe checks)
- Required template fields
- Example strong suggestion
- Example extension (instead of duplicate)
- Security and privacy boundaries for public discussion
- How to link GitHub Issues, PRs, and release notes

Required contributor checklist:

1. Search open issues and existing suggestion markdown.
2. Read the historical baseline for related themes.
3. Identify existing frameworks or project tools that can be reused.
4. State rollout, rollback, risk, and acceptance criteria.
5. Link implementation evidence once the suggestion ships.

### 3) `community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of suggestion pipeline.

Suggested sections:

- Table by status (new, triaged, accepted, in-progress, shipped)
- Last-updated timestamp
- Links to decision records
- Filters by domain (`docs`, `operations`, `security`, `automation`, `ux`)
- Duplicate/merged suggestions with canonical target links

Recommended columns:

| Field | Purpose |
|-------|---------|
| ID | Stable reference such as `SUG-2026-001` |
| Title | Human-readable suggestion name |
| Status | Current lifecycle state |
| Theme | Primary domain |
| Owner | Maintainer or champion |
| Updated | Last meaningful status change |
| Links | Issue, PR, decision, release evidence |

### 4) `community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted/rejected/deferred items.

Suggested sections:

- Decision entry format
- Accepted with tradeoffs
- Deferred with re-open conditions
- Rejected with alternatives
- Superseded suggestions and where the current canonical version lives

Decision entry format:

```markdown
## DEC-YYYY-NNN: Decision title

- Suggestion: SUG-YYYY-NNN
- Decision: accepted | accepted-with-changes | deferred | rejected | superseded
- Deciders: maintainer names or team
- Rationale: short explanation
- Trade-offs: what was accepted or avoided
- Follow-up: linked issues, PRs, or reopen conditions
```

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.

Suggested sections:

- Implemented suggestion summary
- What changed in product/operations
- Validation evidence
- Link to release/changelog entry
- Lessons learned and follow-up suggestions
- Rollback or disable path if the shipped change is optional

### 6) `community/suggestions/template.md`

Purpose:

- Copyable starting point for new suggestion pages when an issue becomes a
  durable website proposal.

Suggested sections:

- Summary
- Problem and current state
- Historical overlap checked
- Existing tools/frameworks considered
- Proposal
- Alternatives
- Rollout and rollback
- Security, privacy, and resource impact
- Acceptance criteria
- Validation evidence
- Decision log

### 7) `community/suggestions/archive.md`

Purpose:

- Preserve historical context without cluttering the active status board.

Suggested sections:

- Superseded ideas merged into canonical suggestions
- Deferred ideas with reopen conditions
- Rejected ideas with rationale and alternate paths
- Links to older markdown files in `/suggestions/` where useful

## Suggested metadata format (front matter)

Use a consistent metadata block in each website markdown page:

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
status: published
last_updated: YYYY-MM-DD
owner: maintainer-or-team
source: suggestions
```

For individual suggestion entries (if represented as markdown pages):

```yaml
id: SUG-YYYY-NNN
status: triaged
theme: operations
impact: high
risk: low
owner: unassigned
related_issue:
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
```

Allowed `status` values:

- `draft`: proposal is incomplete or author-owned
- `triage`: maintainers are checking duplicates, scope, and safety
- `review`: community and domain owners are providing feedback
- `accepted`: proposal is approved but not yet implemented
- `in-progress`: implementation work is linked and active
- `shipped`: implementation is released or documented as available
- `deferred`: valid idea, but blocked by prerequisites or priority
- `rejected`: not planned; rationale and alternatives are documented
- `superseded`: folded into another canonical suggestion

## Information architecture guidance

- Keep suggestion pages in a single docs subtree for discoverability.
- Ensure every status-board row links to a decision entry or rationale.
- Keep "implemented" entries short and link to technical details elsewhere.
- Add a visible note: "Check historical suggestions before submitting."
- Keep historical pages searchable, but direct active navigation to the
  canonical status board and template.
- Prefer generated indexes from frontmatter once the site framework supports
  them.
- Link website pages back to GitHub Issues and PRs so discussion remains
  reviewable.

## Duplicate-prevention workflow

1. Search the current `/suggestions/` folder by keyword and theme.
2. Search open and closed GitHub Issues with the `suggestion` label.
3. Compare against [`website-historical-baseline.md`](./website-historical-baseline.md).
4. If an idea overlaps, update the canonical page and mark the old entry as
   `superseded`.
5. If an idea is genuinely new, create a new issue first; add website markdown
   only when the idea needs durable docs, decision history, or implementation
   tracking.

## Day-to-day maintainer workflow

1. New issue arrives with the `suggestion` label.
2. Triage checks required fields and duplicate overlap.
3. Maintainer assigns a theme and status.
4. Accepted proposals get a markdown page or update an existing canonical page.
5. Status board is updated from frontmatter or a curated table.
6. Shipped proposals link to PRs, releases, changelog entries, and validation
   evidence.

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column count.
- Ensure link text is descriptive (avoid generic "click here").
- Use explicit dates and statuses to avoid ambiguity.

## Rollout recommendation

1. Publish `index.md`, `how-to-submit.md`, and `status-board.md` first.
2. Add `decisions.md` once first triage cycle completes.
3. Add `template.md` before accepting durable website suggestions.
4. Add `implemented.md` when first suggestion ships under this framework.
5. Add `archive.md` after the first dedupe pass through historical files.
