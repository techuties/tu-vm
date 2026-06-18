# Website Markdown Publishing System

## Purpose

Create a reusable markdown-first website system for community suggestions, roadmap updates, and contributor guidance without rebuilding capabilities already provided by mature documentation frameworks and GitHub workflows.

This proposal is a consolidation layer for the existing historical suggestions in this folder. It should be treated as the canonical website publishing recommendation when future contributors ask how suggestions become public website content.

## Historical suggestions reused

The existing suggestion set repeatedly points to the same needs:

- A public place where contributors can discover accepted, active, deferred, and shipped suggestions.
- A consistent suggestion template with problem, evidence, impact, risks, and validation criteria.
- Lightweight governance that keeps discussion public and decisions traceable.
- Day-to-day maintainer tools for deduplication, triage, status updates, release notes, and stale item review.
- A website framework that supports markdown well enough that contributors can write content without learning a custom app.

This recommendation keeps those themes and removes the need for a custom suggestion database or bespoke website CMS at the first stage.

## Recommended framework approach

### Primary path: static docs framework

Start with a static documentation site that renders markdown or MDX:

- **Docusaurus** when versioned docs, plugin ecosystem, and community familiarity matter most.
- **Astro Starlight** when fast static output, simple content collections, and low JavaScript overhead matter most.
- **MkDocs Material** when the project wants a Python-friendly docs stack with excellent markdown defaults.

Any of these options can consume the same markdown content model. The choice should be made on maintenance fit, not on custom feature ambition.

### Keep existing surfaces authoritative

Do not move operational truth out of the current repository:

- `README.md` remains the broad operator entry point.
- `CONTRIBUTING.md` remains the contribution policy entry point.
- `CHANGELOG.md` remains the release history source.
- `docs/playbooks/` remains the operator runbook area.
- `suggestions/` remains the historical and planning archive.
- `nginx/html/index.html` remains the local operational dashboard until a replacement has proven parity.

The website should publish and organize this content; it should not become a second source of truth.

## Suggested website markdown files

Create the public website pages from markdown files under a single community subtree:

```text
community/
  suggestions/
    index.md
    how-to-submit.md
    status-board.md
    decisions.md
    implemented.md
    template.md
  roadmap/
    index.md
  contribute/
    index.md
```

### `community/suggestions/index.md`

Purpose:

- Explain the suggestion lifecycle.
- Link to the current status board, submission guide, decision log, implemented ideas, and historical archive.
- Tell contributors to search existing suggestions before opening a new one.

Required sections:

- What suggestions are for.
- Current lifecycle states.
- How to avoid duplicates.
- Links to GitHub Issues, Discussions, and relevant repository files.

### `community/suggestions/how-to-submit.md`

Purpose:

- Help contributors write high-signal suggestions.
- Reduce maintainer back-and-forth.
- Encourage reuse of existing tools and frameworks.

Required sections:

- Problem statement.
- Existing suggestions reviewed.
- Existing frameworks/tools reviewed.
- Proposed implementation path.
- Security and operational impact.
- Acceptance criteria.
- Rollback or deprecation strategy.

### `community/suggestions/status-board.md`

Purpose:

- Show the current suggestion pipeline without requiring maintainers to write status posts manually.

Recommended columns:

- ID
- Title
- Status
- Area
- Owner or reviewer
- Last updated
- Evidence link

Keep this page generated from metadata when possible so it does not drift from source files.

### `community/suggestions/decisions.md`

Purpose:

- Record accepted, declined, deferred, and superseded decisions with rationale.

Each entry should include:

- Decision date.
- Suggestion ID and title.
- Decision.
- Rationale.
- Alternatives considered.
- Follow-up action or reopen condition.

### `community/suggestions/implemented.md`

Purpose:

- Show community impact by connecting shipped work to suggestions.

Each entry should include:

- Suggestion ID and title.
- Release or changelog link.
- What changed for operators or contributors.
- Validation evidence.

### `community/suggestions/template.md`

Purpose:

- Provide the copyable source template for new suggestion pages.

The template should include both frontmatter and body sections, so humans and automation can rely on the same structure.

## Suggestion frontmatter schema

Use a small metadata block for every suggestion page:

```yaml
id: SUG-YYYY-NNN
title: Short descriptive title
status: draft
area: docs
impact: medium
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
source:
  issue: ""
  pull_request: ""
  changelog: ""
supersedes: []
related: []
```

Allowed `status` values:

- `draft`
- `triaged`
- `accepted`
- `in_progress`
- `shipped`
- `deferred`
- `declined`
- `superseded`

Allowed `area` values should start with the repository's real ownership boundaries:

- `dashboard`
- `docs`
- `scripts`
- `compose`
- `security`
- `helper-api`
- `document-pipeline`
- `community`
- `automation`

## Suggestion body template

Each page should use these headings:

```markdown
# Suggestion title

## Summary

## Problem

## Historical context and related suggestions

## Existing frameworks or tools reviewed

## Proposed approach

## Security and operational impact

## Implementation checklist

## Acceptance criteria

## Rollback or exit strategy

## Decision log
```

The "Historical context and related suggestions" section is mandatory. It is the main guardrail against reinventing work already captured in this folder.

## Day-to-day tooling recommendations

### 1. Suggestion validator

Add a script or CI check that verifies:

- Required frontmatter keys exist.
- Status and area values are valid.
- Required body headings exist.
- Each new suggestion links at least one related historical suggestion or explicitly states that none were found.
- Shipped suggestions link a changelog entry or release note.

Start as a warning-only check, then make it required after the schema stabilizes.

### 2. Suggestion index generator

Generate status pages from frontmatter:

- `status-board.md`
- "recently updated" list
- "implemented ideas" list
- per-area suggestion indexes

The generator can be a small Python script using the standard library plus a YAML parser if the repository already adopts one. Avoid adding a full database until comments, voting, or user-specific state are actually needed.

### 3. Duplicate detection helper

Provide a local command that compares a new suggestion title and tags against existing files in `suggestions/` and website content.

The first version can use simple keyword matching:

- normalized title tokens
- area tags
- related file names
- repeated nouns in summary/problem sections

It should return "possible related suggestions" rather than blocking contributions.

### 4. Release note helper integration

Extend the release note workflow so shipped suggestions are visible:

- Pull request references suggestion ID.
- Changelog entry references suggestion ID.
- Implemented website page links to changelog or release.

This connects community input to delivered work.

### 5. Markdown quality checks

Use established tools instead of custom parsers where possible:

- `markdownlint` or `remark-lint` for markdown style.
- `lychee` or an equivalent link checker for links.
- `cspell` or `codespell` for spelling if noise is manageable.
- `pa11y` or Playwright accessibility checks once pages are rendered.

Keep the initial rule set narrow so contributors can pass checks without fighting formatting preferences.

## Website integration model

### Navigation

Add a "Community" section with these entries:

1. Suggestions
2. How to submit
3. Status board
4. Decisions
5. Implemented suggestions
6. Contributor guide

### Search

Enable framework-native search:

- Docusaurus local search plugin or Algolia DocSearch.
- Starlight Pagefind integration.
- MkDocs Material search.

Search should index title, summary, area, status, and body content.

### Dashboard cross-links

The existing local dashboard should only link out to community pages; it should not own the community workflow.

Useful dashboard links:

- "Suggest an improvement"
- "View community roadmap"
- "Read contributor playbooks"
- "See latest release notes"

## Governance rules

1. Every significant suggestion must link related historical suggestions.
2. Every accepted suggestion must name a reviewer or owning area.
3. Every declined or deferred suggestion must include rationale.
4. Every shipped suggestion must link evidence.
5. Website content must be generated from repository-tracked files or clearly mark external data as cached.

## Implementation sequence

### Stage 1: Content model

- Adopt the frontmatter schema.
- Add `template.md`.
- Update the suggestions hub to explain canonical statuses and required sections.

### Stage 2: Website publishing

- Choose Docusaurus, Astro Starlight, or MkDocs Material.
- Render the community suggestion pages from markdown.
- Add navigation and search.

### Stage 3: Automation

- Add schema validation.
- Add index generation.
- Add related-suggestion detection.
- Add changelog linkage reminders.

### Stage 4: Community operations

- Publish decision log.
- Publish implemented suggestions page.
- Review stale suggestions during release preparation.
- Promote beginner-friendly accepted suggestions.

## Acceptance criteria

- A contributor can find historical suggestions before submitting a new idea.
- A maintainer can triage a suggestion using consistent metadata and required sections.
- The website can show suggestions by status without manual duplicate tables.
- Shipped suggestions are linked to release or changelog evidence.
- The system remains markdown-first and repository-owned until a dynamic community application is justified.

## Anti-patterns to avoid

- Building a custom CMS before markdown and GitHub-native workflows are insufficient.
- Creating separate status trackers that can drift from repository files.
- Adding voting, comments, or accounts before moderation and privacy rules are defined.
- Treating the website as a replacement for the local operational dashboard.
- Letting generated pages become unreviewed sources of operational truth.
