# Website Community Pages (Markdown Suggestions)

These are suggested Markdown pages for a community-facing suggestions system on the project website/docs surface. The pages should publish the community process in a friendly format while keeping GitHub Issues, pull requests, and the repository as the system of record.

## Goals for website pages

- Make it obvious how to submit high-quality suggestions.
- Show transparent status and decision rationale.
- Help contributors avoid duplicates before submitting.
- Keep maintainers from manually repeating the same guidance.
- Connect shipped work back to changelog and release evidence.
- Preserve TU-VM's private, LAN-first operating model in every proposal.

## Page set to publish

### 1) `docs/community/suggestions/index.md`

Purpose:

- Landing page for all community suggestions content.
- Explains the lifecycle and links to active suggestion surfaces.
- Gives newcomers a simple "start here" path.

Suggested sections:

- Why suggestions matter
- What already exists
  - GitHub Issues suggestion template
  - `suggestions/` historical archive
  - `CONTRIBUTING.md` labels and release guidance
- How suggestions are evaluated
- Quick links:
  - Submit a GitHub suggestion issue
  - Search existing issues
  - Browse status board
  - Read decision log
  - View implemented suggestions

Maintenance notes:

- This page should be short and stable.
- It should link to detailed pages rather than duplicating the framework.
- The first screen should answer "where do I submit an idea?" and "how do I avoid duplicates?"

### 2) `docs/community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal suggestions.
- Replaces repeated maintainer comments with one canonical checklist.

Suggested sections:

- Before you submit
  - Search open issues.
  - Search `suggestions/`.
  - Check [`CHANGELOG.md`](../CHANGELOG.md) for shipped or superseded ideas.
  - Check [`docs/playbooks/`](../docs/playbooks/README.md) for existing operational guidance.
- Required fields
  - Problem statement
  - Current workaround
  - Proposed change
  - Existing frameworks/tools reviewed
  - Security and LAN-first impact
  - Validation method
  - Rollback or disable path
- Example strong suggestion
- Example extension of an existing suggestion
- Example duplicate closure response

Suggested callout:

> If an idea overlaps prior work, submit it as an extension proposal and link the historical suggestion. This keeps the community from re-solving the same problem.

### 3) `docs/community/suggestions/status-board.md`

Purpose:

- Public, human-readable view of the suggestion pipeline.
- Reduces "what happened to my idea?" ambiguity.

Suggested sections:

- Status definitions:
  - `idea`: submitted but not reviewed
  - `triage`: dedupe and scope check in progress
  - `draft`: needs proposal details
  - `review`: ready for maintainer/community feedback
  - `accepted`: approved but not started
  - `in-progress`: linked implementation exists
  - `implemented`: shipped and validated
  - `deferred`: valid but waiting on prerequisites
  - `rejected`: declined with rationale
  - `superseded`: replaced by another suggestion
- Table by status
- Last-updated timestamp
- Owner or reviewer column
- Links to issue, decision entry, implementation PR, and changelog when available

Implementation recommendation:

- Generate the table from frontmatter instead of editing it manually.
- Keep manual fallback content for the first version if no generator exists yet.
- Mark generated sections clearly so maintainers know what not to hand-edit.

### 4) `docs/community/suggestions/decisions.md`

Purpose:

- Decision log with rationale for accepted, rejected, deferred, and superseded items.
- Creates trust by explaining tradeoffs, not just outcomes.

Suggested sections:

- Decision entry format
- Accepted with tradeoffs
- Accepted with scope changes
- Deferred with re-open conditions
- Rejected with alternatives
- Superseded by newer work

Decision entry template:

```markdown
## SUG-YYYY-NNN - Short title

- Status: accepted | deferred | rejected | superseded
- Date: YYYY-MM-DD
- Decision owner: maintainer/team
- Related issue: #NNN
- Related suggestion files:
  - ../../suggestions/example.md

### Decision

One paragraph summary.

### Rationale

- Main reason 1
- Main reason 2

### Re-open conditions

Specific evidence or prerequisite that would justify another review.
```

### 5) `docs/community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.
- Helps contributors see that suggestions can become real improvements.

Suggested sections:

- Implemented suggestion summary
- What changed in product, documentation, operations, or automation
- Validation evidence
- Link to release, changelog, issue, and pull request
- Follow-up ideas that remain open

Recommended format:

```markdown
## SUG-YYYY-NNN - Short title

- Released in: vX.Y.Z or unreleased
- PR: #NNN
- Changelog: ../../CHANGELOG.md#anchor
- Validation: command, screenshot, test run, or manual evidence

Short plain-language summary of the delivered value.
```

### 6) `docs/community/suggestions/template.md`

Purpose:

- Copyable template for proposal pages when an issue becomes an accepted or review-ready website suggestion.
- Makes the required fields visible before automation enforces them.

Suggested template body:

```markdown
---
id: SUG-YYYY-NNN
title: Short title
summary: One sentence value statement.
status: draft
theme: operations
impact: medium
risk: low
owner: unassigned
source_issue: https://github.com/techuties/tu-vm/issues/NNN
related:
  - ../../suggestions/website-historical-baseline.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Short title

## Problem

What pain exists today?

## Current state and historical overlap

What already exists in the repository, docs, scripts, dashboard, or historical suggestions?

## Proposal

What should change?

## Existing frameworks or tools to reuse

Which mature tools, libraries, GitHub features, or TU-VM components avoid custom reinvention?

## Impact and risks

- Community impact:
- Operations impact:
- Security/privacy impact:
- Maintenance impact:

## Rollout and rollback

How can this be introduced safely, and how can it be disabled or reverted?

## Validation

How will maintainers know it works?

## Decision log

Add links to decision entries or pull requests.
```

## Shared metadata format

Use a consistent metadata block in each website Markdown page:

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
last_updated: YYYY-MM-DD
owner: maintainer-or-team
```

For individual suggestion entries:

```yaml
id: SUG-YYYY-NNN
status: triage
theme: operations
impact: high
risk: medium
owner: maintainer-or-team
source_issue: https://github.com/techuties/tu-vm/issues/NNN
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
```

## Deduplication workflow

Before a suggestion moves from `idea` to `review`, maintainers should check:

1. Open GitHub Issues with the `suggestion` label.
2. [`suggestions/website-historical-baseline.md`](./website-historical-baseline.md).
3. [`suggestions/historical-suggestions.md`](./historical-suggestions.md).
4. Existing scripts and docs:
   - [`tu-vm.sh`](../tu-vm.sh)
   - [`scripts/`](../scripts/)
   - [`docs/playbooks/`](../docs/playbooks/README.md)
   - [`CONTRIBUTING.md`](../CONTRIBUTING.md)
5. [`CHANGELOG.md`](../CHANGELOG.md) for already shipped work.

Decision outcomes:

- **Duplicate**: close or mark superseded with a link.
- **Partial overlap**: convert to extension proposal.
- **Already solved**: link the existing command, doc, workflow, or release note.
- **Net new**: move to triage/review with required fields complete.

## Automation suggestions for these pages

- Validate required frontmatter fields.
- Generate `status-board.md` rows from suggestion pages.
- Generate "recently updated" and "needs reviewer" lists.
- Report likely duplicates by comparing title, summary, tags, and related files.
- Check internal links to historical suggestions and repository docs.
- Produce a small JSON index for optional dashboard consumption.

Automation should start in advisory mode, then become blocking only after maintainers trust the checks.

## Information architecture guidance

- Keep suggestion pages in a single docs subtree for discoverability.
- Ensure every status-board row links to a decision entry or rationale.
- Keep "implemented" entries short and link to technical details elsewhere.
- Add a visible note: "Check historical suggestions before submitting."
- Prefer generated indexes over hand-maintained duplicate lists.

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column count.
- Ensure link text is descriptive.
- Use explicit dates and statuses to avoid ambiguity.
- Include plain-language summaries before detailed technical sections.

## Rollout recommendation

1. Publish `index.md`, `how-to-submit.md`, `status-board.md`, and `template.md`.
2. Add `decisions.md` once the first proposal reaches a decision.
3. Add `implemented.md` when a suggestion ships with validation evidence.
4. Add generated indexes only after the manual page structure is stable.
