# Website Community Pages and Markdown Publishing System

This is the canonical suggestion for turning repository markdown into a community-facing suggestions website without rebuilding forum, docs, or governance systems from scratch.

## Objectives

- Make high-quality suggestions easy to write, review, discover, and archive.
- Reuse existing repository assets before introducing new services.
- Keep suggestion history searchable so contributors do not repeat prior work.
- Give maintainers structured metadata for triage, automation, release notes, and roadmap views.
- Preserve TU-VM's secure-by-default posture by keeping runtime controls separate from public community pages.

## Historical suggestions to reuse

The existing `/suggestions/` folder already contains many related proposals. This page should be treated as the publishing layer for those ideas, not as a competing process.

Reuse these files as source material:

- [`website-historical-baseline.md`](./website-historical-baseline.md) for repeated historical patterns.
- [`website-information-architecture.md`](./website-information-architecture.md) for top-level navigation.
- [`website-and-docs-framework.md`](./website-and-docs-framework.md) for framework choices and docs automation.
- [`community-system-framework.md`](./community-system-framework.md) for lifecycle and governance.
- [`day-to-day-tooling.md`](./day-to-day-tooling.md) for maintainer and contributor tooling.
- [`implementation-backlog.md`](./implementation-backlog.md) for already-shipped items and next recommendations.

## Recommended implementation framework

### Primary path: markdown-first static docs

Use a mature documentation framework such as Docusaurus, MkDocs Material, Astro Starlight, or VitePress. All of these support:

- markdown-authored pages that are easy to review in pull requests;
- generated navigation from folders and frontmatter;
- search plugins;
- static output that can be served behind the existing Nginx layer;
- CI-friendly linting and link checks.

### Selection rule

- Choose **Docusaurus** when versioned docs, plugin ecosystem, and contributor familiarity are most important.
- Choose **MkDocs Material** when a lightweight Python-friendly docs stack is preferred.
- Choose **Astro Starlight** when fast static output and richer content composition matter more than docs-versioning depth.
- Choose **VitePress** when the project wants a compact Vue-oriented docs system with simple static deployment.

Avoid a custom suggestion database until markdown + GitHub Issues/Discussions + labels can no longer handle the workflow.

## Recommended website markdown file set

These files can live under a future docs website subtree such as `website/docs/community/suggestions/` or `docs/community/suggestions/`. Until then, this `/suggestions/` folder can remain the source-of-truth archive.

### 1) `community/suggestions/index.md`

Purpose:

- Landing page for all community suggestions content.
- Explains the lifecycle and links to active suggestions, decisions, and implemented work.
- Shows "check historical suggestions first" guidance above the submission call-to-action.

Suggested sections:

- What suggestions are for
- How suggestions are evaluated
- Current status lanes
- Quick links: submit, status board, decision log, implemented ideas
- Link to historical baseline

### 2) `community/suggestions/how-to-submit.md`

Purpose:

- Contributor guide for writing high-signal, non-duplicative suggestions.

Suggested sections:

- Before submitting: search `/suggestions/`, issues, discussions, changelog, and roadmap.
- Required fields: problem, current state, proposed change, alternatives reviewed, risks, success criteria.
- Example of improving an existing idea instead of opening a duplicate.
- Security note for runtime controls, networking, auth, secrets, and public exposure.

### 3) `community/suggestions/status-board.md`

Purpose:

- Human-readable view of the suggestion pipeline.
- Can be generated from markdown frontmatter or manually curated at first.

Suggested sections:

- New
- Needs clarification
- In review
- Accepted
- Planned
- In progress
- Implemented
- Deferred or declined

Each item should link to a suggestion page, issue/discussion, owner, next action, and decision rationale when available.

### 4) `community/suggestions/decisions.md`

Purpose:

- Decision log for accepted, deferred, declined, and superseded ideas.

Suggested sections:

- Decision entry format
- Accepted with tradeoffs
- Deferred with reopening conditions
- Declined with alternatives
- Superseded by existing feature, merged suggestion, or implementation

Decision entries should be short enough to read quickly but complete enough to preserve trust.

### 5) `community/suggestions/implemented.md`

Purpose:

- Changelog-adjacent showcase of suggestions that shipped.

Suggested sections:

- Implemented suggestion summary
- What changed for users/operators/contributors
- Validation evidence
- Links to PRs, release notes, changelog entries, and docs

### 6) `community/suggestions/templates/suggestion.md`

Purpose:

- Copyable template for new markdown-backed suggestion pages.

Suggested sections:

- Summary
- Problem
- Current state and historical overlap
- Existing frameworks or tools to reuse
- Proposed approach
- Implementation path
- Risks and mitigations
- Security and privacy impact
- Resource impact
- Rollout and rollback
- Success metrics
- Decision log

### 7) `community/suggestions/archive.md`

Purpose:

- Keeps old or superseded ideas discoverable without crowding the active board.

Suggested sections:

- Superseded by implementation
- Merged into another suggestion
- Deferred because prerequisites are missing
- Declined with rationale

## Frontmatter schema

Use consistent YAML frontmatter so the website can generate indexes, status boards, and dashboards from markdown.

### Website page frontmatter

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
status: active
owner: maintainers
last_updated: YYYY-MM-DD
source: suggestions
```

### Individual suggestion frontmatter

```yaml
id: SUG-YYYY-NNN
title: Short suggestion title
summary: One-sentence outcome-focused summary.
status: draft
category: docs
impact: medium
risk: low
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - ./website-historical-baseline.md
```

Recommended status values:

- `draft`
- `needs-clarification`
- `review`
- `accepted`
- `planned`
- `in-progress`
- `implemented`
- `deferred`
- `declined`
- `superseded`

Recommended categories:

- `docs`
- `community`
- `operations`
- `automation`
- `security`
- `dashboard`
- `integrations`
- `performance`

## Suggestion page template

Each suggestion markdown page should use this structure.

```markdown
# Suggestion Title

## Summary

One paragraph describing the desired outcome.

## Problem

What pain exists today, who experiences it, and why existing behavior is insufficient.

## Historical overlap

Links to related suggestions, issues, changelog items, or implemented work.

## Reuse-first options

Existing frameworks, project components, or external tools that can solve part of the problem.

## Proposed approach

The smallest practical change that delivers the outcome.

## Implementation path

1. Step that can be reviewed independently.
2. Step that connects the work to docs, scripts, or UI.
3. Step that validates behavior and updates release notes.

## Risks and mitigations

- Risk: ...
  Mitigation: ...

## Security and privacy impact

State whether auth, secrets, network exposure, runtime controls, logs, or user data are affected.

## Rollout and rollback

How to ship safely and how to disable or revert if it causes issues.

## Success metrics

Signals that show whether the suggestion improved contributor or operator experience.

## Decision log

- YYYY-MM-DD: Draft opened.
```

## Automation recommendations

Start with checks that help maintainers without blocking useful contributions too early.

### Quality checks

- Markdown lint with a narrow rule set.
- Link checks for internal and external references.
- Heading hierarchy checks.
- Required frontmatter validation.
- Required section validation for suggestion pages.

### Generated pages

- Generate status-board rows from frontmatter.
- Generate category indexes for docs, security, operations, dashboard, and automation suggestions.
- Generate "recently updated" and "implemented" pages from `updated_at` and `status`.
- Generate duplicate-warning hints from title, category, and keywords.

### Maintainer workflow helpers

- Add CI comments when required fields are missing.
- Suggest labels based on `category`, `risk`, and `impact`.
- Remind maintainers when `needs-clarification` items have no response.
- Prompt for changelog and release-note links when status changes to `implemented`.

## Information architecture guidance

- Keep suggestion pages in one website subtree for discoverability.
- Keep archived and implemented ideas searchable.
- Link every status-board row to either a suggestion page or a decision entry.
- Keep "implemented" entries short and link to technical details elsewhere.
- Display a visible note: "Check historical suggestions before submitting."
- Keep runtime control documentation separate from public community pages.

## Accessibility and readability guidance

- Use short sections and bullet-heavy structure for quick scanning.
- Keep tables concise and avoid excessive column counts on mobile.
- Use descriptive link text.
- Use explicit dates and statuses to avoid ambiguity.
- Do not rely on color alone for status labels.
- Preserve visible focus states and keyboard navigation in generated website pages.

## Rollout stages

1. Publish the markdown page structure and template.
2. Normalize the highest-value existing suggestion files with frontmatter.
3. Add a manually curated status board using the normalized metadata.
4. Add CI checks for frontmatter, links, headings, and required sections.
5. Generate indexes and status pages automatically once the schema is stable.
6. Add interactive voting or dashboards only if markdown + GitHub-native workflows become insufficient.

## Acceptance criteria

- Contributors can find the suggestion workflow from the website navigation.
- New suggestions include required metadata, historical-overlap checks, risks, and success metrics.
- Duplicate suggestions are redirected to existing canonical pages or merged with rationale.
- Maintainers can generate or curate a status board without custom backend work.
- Implemented suggestions link to validation evidence and release/changelog notes.
