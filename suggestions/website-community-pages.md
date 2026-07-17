# Website Community Pages and Markdown Publishing Model

## Status

**Proposed.** This page defines the canonical website page set and the contract
for publishing community suggestions from Markdown.

## Problem

TU-VM already has a GitHub suggestion Issue Form, contribution guidance, a
large historical `suggestions/` corpus, and a static Nginx dashboard. Creating a
new submission database or embedding a custom forum would duplicate those
systems and create another security boundary.

The missing layer is a clear website view that turns existing records into:

- instructions for contributors;
- a deduplicated status board;
- durable decision rationale; and
- evidence that accepted ideas were actually delivered.

## Source-of-truth model

| Information | Canonical source | Website behavior |
|---|---|---|
| New idea and discussion | GitHub Issue using `suggestion.yml` | Link to Issue; do not copy comments |
| Stable proposal | One curated file in `suggestions/` | Render as a suggestion page |
| Lifecycle and owner | Suggestion frontmatter | Generate status views |
| Decision rationale | Suggestion decision section | Include in decisions index |
| Implementation | Pull request, commit, and release | Link from the suggestion |
| Operational instructions | Existing docs/playbooks | Link; do not duplicate |

Website indexes are generated views. Contributors update one suggestion record,
not a status board, decision log, and showcase independently.

## Recommended website page set

### `community/suggestions/index.md`

The landing page should include:

- a plain-language explanation of how community suggestions influence TU-VM;
- one primary **Submit an idea** link to the existing GitHub Issue Form;
- links to active, decided, implemented, and archived views;
- the lifecycle and expected information at each state;
- a warning to search Issues and historical suggestions before submission; and
- the date and revision used to build the page.

### `community/suggestions/how-to-submit.md`

This contributor guide should provide:

1. Search instructions for open/closed Issues and this folder.
2. A checklist for identifying an extension to an existing proposal.
3. Required problem, current behavior, constraints, reuse, risk, and success
   fields.
4. One strong example and one duplicate-to-extension example.
5. Security reporting boundaries, with a link to `SECURITY.md`.
6. What happens after submission and how decisions are communicated.

It should link directly to the Issue Form rather than implementing a website
form.

### `community/suggestions/status.md`

Generate this page from frontmatter and group records into:

- needs triage;
- under discussion;
- accepted;
- in progress;
- needs rework;
- deferred; and
- recently implemented.

Each entry should show only ID, title, theme, status, owner, last review date,
and a link. Keep long descriptions on the detail page so the board remains
usable on mobile.

### `community/suggestions/decisions.md`

Generate accepted, rejected, deferred, and superseded decisions. Each row must
link to a record containing:

- decision date and outcome;
- concise rationale;
- material constraints or trade-offs;
- alternatives considered; and
- re-open conditions where applicable.

An empty rationale is a publishing error, not a valid decision.

### `community/suggestions/implemented.md`

Generate a compact record of delivered ideas. Every entry must include:

- implementation PR or commit;
- release or changelog reference;
- validation evidence;
- rollout and rollback notes where behavior changed; and
- measured result or a scheduled measurement action.

This is a community impact view, not a replacement changelog.

### `community/suggestions/archive.md`

Generate rejected, superseded, and withdrawn items. Archive entries stay
searchable because their rationale prevents the same proposal from being
recreated later.

### `community/suggestions/<id>-<slug>.md`

Render one detail page per curated proposal. The page should expose source
metadata, proposal content, relationships, decision history, and delivery
evidence without importing Issue comments.

## Suggestion metadata contract

Use YAML frontmatter on curated records:

```yaml
---
id: SUG-2026-001
title: Short, specific title
summary: One sentence describing the user or operator outcome.
status: discussing
theme: documentation
owner: "@github-handle-or-team"
source_issue: 123
created: 2026-07-17
last_reviewed: 2026-07-17
related:
  - SUG-2026-000
supersedes: []
implementation: []
---
```

### Required fields

| Field | Rule |
|---|---|
| `id` | Stable `SUG-YYYY-NNN`; never reused |
| `title` | Unique, descriptive, and free of status text |
| `summary` | One sentence; describes outcome rather than implementation |
| `status` | One value from the lifecycle below |
| `theme` | `documentation`, `operations`, `security`, `automation`, `ui`, `integration`, or `governance` |
| `owner` | Accountable GitHub user/team, or `unassigned` before triage |
| `source_issue` | Public Issue number; omit only for imported historical records |
| `created` | ISO date |
| `last_reviewed` | ISO date updated by a meaningful review |
| `related` | IDs checked during deduplication; may be empty |
| `supersedes` | IDs replaced by this record; may be empty |
| `implementation` | PR, commit, or release links; required when implemented |

Do not add vote totals, priority scores, or comment counts to source files.
Those are changing GitHub data and should be displayed only when fetched during
a build with a safe fallback.

## Lifecycle

Use one vocabulary across Issues, Markdown, labels, and website filters:

| Status | Meaning | Required next action |
|---|---|---|
| `submitted` | Intake received; not reviewed | Assign triage owner |
| `triaged` | Scope and duplicate search complete | Open or schedule discussion |
| `discussing` | Alternatives and constraints are being evaluated | Record decision |
| `accepted` | Approved and scoped | Link implementation work |
| `in-progress` | An implementation PR or branch exists | Validate and release |
| `needs-rework` | Valuable idea lacks required evidence or scope | Contributor revises |
| `deferred` | Valid but blocked by a named condition | Record re-open condition |
| `implemented` | Released with evidence | Measure result |
| `rejected` | Decision made not to proceed | Preserve rationale |
| `superseded` | Replaced by a linked proposal | Follow replacement |
| `withdrawn` | Author or maintainer closed before decision | Preserve short reason |

Statuses describe lifecycle, not priority. Priority belongs in planning tools
and can change without rewriting history.

## Required suggestion body

Every curated detail page should use this structure:

```markdown
# <Title>

## Summary
## Problem and current evidence
## Existing capabilities and related suggestions
## Proposed outcome
## Alternatives considered
## Security, privacy, and operational impact
## Implementation slices
## Rollout and rollback
## Success measures
## Decision
## Delivery evidence
```

Historical imports may use `not-applicable` for missing fields, but new records
must not.

## Deduplication workflow

Before promoting an Issue into a curated Markdown record:

1. Search Issue titles and bodies for the problem and proposed outcome.
2. Search `suggestions/` by component, theme, and synonyms.
3. Check [`website-historical-suggestions.md`](./website-historical-suggestions.md)
   and `CHANGELOG.md`.
4. Link all related IDs in `related`.
5. Extend an existing record when the new idea has the same problem and desired
   outcome.
6. Create a new record only when scope or acceptance criteria materially differ.
7. If replacing prior guidance, set `supersedes` and mark the old record
   `superseded`.

Automated similarity checks may suggest matches but must not close or merge a
community contribution without human review.

## Validation and generation

Use established tools before writing custom infrastructure:

- a JSON Schema-compatible YAML validator for metadata;
- Markdownlint for style and heading consistency;
- the existing Lychee setup for links;
- MkDocs Material for rendering and local search;
- GitHub Issue Forms and labels for intake and workflow; and
- a small deterministic index generator only for repository-specific status
  views.

The generator should sort by stable keys, emit no timestamps unless explicitly
requested, fail on duplicate IDs, and produce identical output from identical
input.

## Accessibility and privacy requirements

- Status must be represented by text, not color alone.
- Tables require useful headers and must collapse cleanly on narrow screens.
- All filters and search controls must be keyboard operable.
- Dates use unambiguous ISO format.
- Focus order follows visual order and visible focus is retained.
- Do not publish email addresses, private Issue content, raw analytics, tokens,
  hostnames, or local service data.
- Do not load third-party analytics or hosted search by default.

## Acceptance criteria

- Contributors can find the submission path and duplicate-search instructions
  within two navigation actions.
- One metadata edit updates all generated views without manual synchronization.
- Invalid status, duplicate ID, missing decision rationale, and implemented
  records without delivery links fail validation.
- Rejected and superseded ideas remain searchable.
- All pages work with JavaScript disabled except enhanced local search/filtering.
- A clean build makes no network request at runtime.
- The published page identifies its source revision and supports an
  **Edit this page** link.

## Related suggestions

- [Website and documentation framework](./website-and-docs-framework.md)
- [Website community governance](./website-community-governance.md)
- [Website day-to-day tooling](./website-day-to-day-tooling.md)
- [Historical suggestions baseline](./website-historical-suggestions.md)
