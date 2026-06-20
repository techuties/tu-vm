# Website Community Pages (Markdown Suggestions)

These are suggested markdown pages for a community-facing suggestions system on the project website/docs surface. The goal is to publish a useful community system with static markdown first, then add automation only where it reduces real maintainer work.

## Goals

- Make it obvious how to submit high-quality suggestions.
- Show transparent status and decision rationale.
- Help contributors avoid duplicates before submitting.
- Keep maintainers from manually repeating the same guidance.
- Keep the first website version compatible with static-site frameworks such as Docusaurus, MkDocs Material, Astro Starlight, or a simple markdown-to-HTML build.
- Preserve the current TU-VM operational dashboard instead of coupling community content to runtime control surfaces.

## Recommended website markdown tree

Use this page tree when a docs website is added. Until then, the same content can live in `/suggestions/` and be linked from `README.md`, `CONTRIBUTING.md`, and the landing dashboard.

```text
community/
  index.md
  suggestions/
    index.md
    how-to-submit.md
    status-board.md
    decisions.md
    implemented.md
    archive.md
  governance/
    roles-and-review.md
    security-review.md
  tooling/
    contributor-shortcuts.md
    maintainer-automation.md
```

### 1) `community/index.md`

Purpose:

- Provide the community landing page.
- Explain how TU-VM balances private-AI defaults, local operations, and public collaboration.
- Link to suggestions, governance, contribution docs, releases, and security reporting.

Suggested sections:

- What the community can help with
- Where to ask questions or propose ideas
- Current focus areas
- Safety and privacy expectations

### 2) `community/suggestions/index.md`

Purpose:

- Landing page for all community suggestions content.
- Explains lifecycle and links to active suggestion board.
- Calls out the requirement to check historical suggestions before opening a new one.

Suggested sections:

- Why suggestions matter
- How suggestions are evaluated
- Suggestion lifecycle overview
- Quick links: submit, status board, decisions, implemented ideas, archive
- "Before proposing" checklist that points back to historical files

### 3) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.
- Prevent duplicate or under-specified requests.

Suggested sections:

- Before you submit (dedupe checks)
- Required template fields
- Example strong suggestion
- Example extension (instead of duplicate)
- What happens after submission
- What belongs in GitHub Issues vs. Discussions vs. security reporting

### 4) `community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of suggestion pipeline.
- Give contributors a single place to see progress without asking maintainers for updates.

Suggested sections:

- Table by status (`new`, `triaged`, `accepted`, `in-progress`, `shipped`, `deferred`, `rejected`)
- Last-updated timestamp
- Owner or reviewer field
- Links to decision records, implementation PRs, and changelog entries
- "Needs community feedback" area for proposals that need testing or alternatives

### 5) `community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted/rejected/deferred items.
- Create institutional memory so repeated proposals can reference prior reasoning.

Suggested sections:

- Decision entry format
- Accepted with tradeoffs
- Deferred with re-open conditions
- Rejected with alternatives
- Superseded or merged suggestions

### 6) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.
- Close the loop between community input and delivered project value.

Suggested sections:

- Implemented suggestion summary
- What changed in product/operations
- Validation evidence
- Link to release/changelog entry
- Follow-up ideas or known limitations

### 7) `community/suggestions/archive.md`

Purpose:

- Keep old, rejected, merged, or obsolete ideas discoverable without cluttering active planning.

Suggested sections:

- Archived suggestion table
- Reason for archive
- Re-open criteria
- Link to replacement suggestion when merged or superseded

### 8) Governance and tooling pages

Use supporting pages when repeated review questions appear:

- `community/governance/roles-and-review.md`: maintainer roles, reviewer expectations, decision lanes.
- `community/governance/security-review.md`: extra checks for networking, auth, secrets, backups, and control endpoints.
- `community/tooling/contributor-shortcuts.md`: commands for local validation, docs preview, and smoke checks.
- `community/tooling/maintainer-automation.md`: triage helpers, digest generation, release-note reminders, and dedupe checks.

## Suggested metadata format (front matter)

Use a consistent metadata block in each website markdown page so a static-site generator or helper script can build indexes later.

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
status: active
area: community
last_updated: YYYY-MM-DD
owner: maintainer-or-team
source: suggestions/website-community-pages.md
```

For individual suggestion entries (if represented as markdown pages):

```yaml
id: SUG-YYYY-NNN
title: Short user-facing title
summary: One sentence explaining the proposal
status: triaged
area: operations
impact: high
risk: medium
champion: github-handle-or-team
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - SUG-YYYY-NNN
links:
  issue: https://github.com/techuties/tu-vm/issues/NNN
  decision: ./decisions.md#sug-yyyy-nnn
```

## Individual suggestion template

Each suggestion page or issue should answer the same questions. This makes reviews comparable and helps automation generate status boards.

```markdown
# SUG-YYYY-NNN: Title

## Summary
One paragraph describing the proposed improvement.

## Problem
What pain exists today? Who experiences it?

## Historical overlap
Which existing `/suggestions/` files or GitHub issues were checked?

## Existing frameworks or tools to reuse
Name mature options first. Example: Docusaurus, MkDocs Material, GitHub Issue Forms, Release Drafter, markdownlint, lychee, Playwright, Trivy.

## Proposed approach
What changes in the website, docs, workflow, scripts, or services?

## Alternatives considered
What was rejected and why?

## Security, privacy, and resource impact
Does this affect network exposure, control endpoints, secrets, storage, CPU, memory, or operator privacy?

## Rollout and rollback
How can it be enabled safely, and how can maintainers revert it?

## Acceptance criteria
- Clear, testable result 1
- Clear, testable result 2
- Documentation updated where contributors will look

## Status log
- YYYY-MM-DD: Created / triaged / accepted / implemented
```

## Status taxonomy

Use a small, visible lifecycle:

| Status | Meaning | Required next action |
|---|---|---|
| `new` | Submitted but not reviewed | Check completeness and duplicates |
| `triaged` | Valid and categorized | Assign owner or request more context |
| `needs-feedback` | Community input required | Ask a specific question and link testing steps |
| `accepted` | Approved for implementation | Create issue/PR task and acceptance checklist |
| `in-progress` | Work is underway | Link implementation branch or PR |
| `shipped` | Released or merged | Link changelog/release and validation evidence |
| `deferred` | Useful but not ready | Record blocker and re-open criteria |
| `rejected` | Not aligned or unsafe | Record rationale and safer alternatives |
| `merged` | Covered by another suggestion | Link canonical replacement |
| `archived` | No longer relevant | Keep historical context only |

## Information architecture guidance

- Keep suggestion pages in a single docs subtree for discoverability.
- Ensure every status-board row links to a decision entry or rationale.
- Keep "implemented" entries short and link to technical details elsewhere.
- Add a visible note: "Check historical suggestions before submitting."
- Separate public community pages from private or operator-only control surfaces.
- Link back to canonical repository files instead of copying long operational instructions into multiple pages.
- Favor short pages with strong cross-links over one very long community manual.

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column count.
- Ensure link text is descriptive (avoid generic "click here").
- Use explicit dates and statuses to avoid ambiguity.
- Do not rely on color alone for statuses; pair badges with text labels.
- Keep heading order consistent so screen readers can navigate the suggestion archive.
- For dashboards or cards, expose the same information in a semantic table or list.

## Tooling hooks for markdown pages

Start with simple scripts or CI checks before introducing a custom application:

- Frontmatter validator for required fields.
- Link checker for internal links and GitHub references.
- Duplicate-topic hinting based on title, tags, and keywords across `/suggestions/`.
- Status-board generator that reads frontmatter and outputs markdown or JSON.
- Release-note helper that lists suggestions marked `shipped` without changelog links.
- Accessibility smoke checks when markdown becomes rendered website pages.

## Acceptance criteria for the first website slice

- Community landing and suggestions index are reachable from the main docs or dashboard.
- A contributor can find how to submit, how status is decided, and where shipped suggestions are listed.
- Each active suggestion has an owner/status/rationale or an explicit "needs feedback" question.
- Existing historical suggestions remain linked so repeat ideas are extended instead of recreated.
- No anonymous website form can trigger service control actions or write directly to trusted runtime paths.

## Rollout recommendation

1. Publish `index.md`, `how-to-submit.md`, and `status-board.md` first.
2. Add `decisions.md` once first triage cycle completes.
3. Add `implemented.md` when first suggestion ships under this framework.
4. Add archive/governance/tooling pages only after repeated questions prove they reduce maintainer effort.
