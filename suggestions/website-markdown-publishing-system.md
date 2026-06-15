# Website Markdown Publishing System

## Purpose

Create a community-facing website system where suggestions are written once as markdown, reviewed in public, and published into a clear website experience without building a custom suggestions application first.

This proposal consolidates repeated historical ideas around:

- a docs-first website,
- a community suggestion lifecycle,
- markdown/frontmatter-driven pages,
- lightweight maintainer automation,
- secure-by-default TU-VM operations.

## Decision summary

Use markdown as the source of truth and publish it with a mature static documentation framework.

Recommended path:

1. Keep `suggestions/` as the canonical repository source for proposal records.
2. Use GitHub Issues for intake, discussion, labels, and moderation.
3. Publish curated suggestion pages through a static docs framework.
4. Generate indexes, status boards, and related-suggestion links from markdown metadata.
5. Avoid a custom database-backed suggestion portal until GitHub-native workflows become a clear bottleneck.

## Framework recommendation

### Primary framework: Docusaurus

Docusaurus should be the first website framework choice for a community suggestion site because it provides:

- strong markdown and MDX support,
- versioned documentation when TU-VM releases diverge,
- sidebar and category generation,
- mature search integrations,
- a broad plugin ecosystem,
- familiar contribution patterns for open-source communities.

Use Docusaurus when the site is primarily documentation, governance, proposals, release notes, and guides.

### Secondary framework: Astro with Starlight

Astro with Starlight is the best alternative if the project wants a more custom marketing/product website while still keeping documentation strong.

Choose Astro/Starlight when:

- custom landing pages are a major goal,
- the site needs richer interactive islands,
- markdown content remains central,
- the team accepts a slightly more custom integration surface.

### Lightweight fallback: MkDocs Material

MkDocs Material is a practical fallback when the team wants minimal JavaScript tooling and fast markdown publishing.

Choose MkDocs Material when:

- the site should stay mostly static documentation,
- Python-based tooling is preferred,
- advanced React/MDX customization is not needed.

### Avoid for the first iteration

Do not start with:

- a custom suggestion API,
- a custom moderation database,
- a client-side single-page application for suggestions,
- a separate identity system,
- bespoke search before static search plugins are evaluated.

Those pieces add operational weight without improving the day-to-day contributor loop enough to justify the maintenance burden.

## Source-of-truth model

The repository should have one authoritative source for every suggestion:

```text
suggestions/
  README.md
  index.md
  website-markdown-publishing-system.md
  website-suggestion-dedupe-map.md
  <area-specific-suggestion>.md
```

Future website content can either:

- render directly from `suggestions/`, or
- copy curated records into a docs tree during a build step.

If a docs-site source tree is introduced later, keep a clear rule:

> Suggestion records live in `suggestions/`; generated website pages may mirror them, but must not become a competing source of truth.

## Suggested website pages

### `community/suggestions/index.md`

Purpose:

- explain how the suggestion system works,
- link to the active GitHub issue template,
- list current suggestion statuses,
- highlight implemented community ideas.

Required sections:

- "Before submitting"
- "How suggestions are reviewed"
- "Current priority areas"
- "Recently shipped from community input"
- "Historical suggestions and canonical records"

### `community/suggestions/how-to-submit.md`

Purpose:

- help contributors write useful suggestions,
- reduce duplicate submissions,
- clarify what maintainers need to evaluate an idea.

Required sections:

- problem statement checklist,
- existing work search instructions,
- impact and risk prompts,
- rollout and rollback prompts,
- examples of strong and weak suggestions.

### `community/suggestions/status-board.md`

Purpose:

- provide a transparent view of proposal state without maintainers manually rewriting summaries.

Recommended columns:

- suggestion ID,
- title,
- status,
- area,
- owner/reviewer,
- last reviewed,
- next decision needed,
- implementation or release link.

### `community/suggestions/decisions.md`

Purpose:

- keep lightweight decision notes for accepted, deferred, rejected, or superseded proposals.

Decision entries should include:

- decision date,
- status,
- rationale,
- tradeoffs,
- follow-up criteria,
- links to the suggestion, issue, PR, and release note when available.

### `community/suggestions/implemented.md`

Purpose:

- show contributors that suggestions lead to visible outcomes.

Each entry should include:

- shipped feature or docs change,
- original suggestion link,
- release/changelog link,
- validation evidence,
- remaining follow-up work if any.

## Suggestion metadata contract

Every website-published suggestion should include a metadata block.

```yaml
id: SUG-YYYY-NNN
title: Short human-readable title
summary: One sentence describing the proposed change
status: draft
area: website
kind: framework
impact: medium
effort: medium
owner: unassigned
reviewers:
  - docs
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
last_reviewed_at: YYYY-MM-DD
related:
  - suggestions/website-historical-baseline.md
supersedes: []
superseded_by: null
implementation_links: []
release_links: []
```

### Status values

Use a small lifecycle to keep the website readable:

- `draft` - incomplete proposal or early idea,
- `needs-info` - contributor/maintainer input required,
- `triaged` - reviewed and categorized,
- `accepted` - approved for implementation,
- `in-progress` - active work is underway,
- `implemented` - shipped or documented,
- `deferred` - valid but not currently planned,
- `declined` - not aligned with project goals,
- `superseded` - replaced by a canonical proposal.

### Area values

Start with broad areas rather than many fine-grained labels:

- `website`
- `docs`
- `operations`
- `security`
- `automation`
- `dashboard`
- `community`
- `developer-experience`

### Kind values

Use `kind` to separate the shape of the proposal:

- `framework`
- `feature`
- `tooling`
- `process`
- `policy`
- `quality`
- `research`

## Markdown page template

New detailed suggestion files should use this structure unless a narrower format is clearly better:

```markdown
# Suggestion title

## Summary

One paragraph explaining the suggested change.

## Problem

What is hard, slow, risky, or unclear today?

## Historical context

Which existing suggestions, repository files, or prior decisions does this build on?

## Proposed approach

Concrete implementation direction.

## Reuse before building

Existing frameworks, scripts, services, templates, or docs that should be reused.

## Implementation outline

Ordered technical steps with clear boundaries.

## Acceptance criteria

Observable signals that the work is complete.

## Risks and mitigations

Security, maintenance, resource, UX, and community risks.

## Rollback / exit strategy

How to revert or retire the change if it does not work.

## Related suggestions

Links to canonical, duplicate, or superseded suggestions.
```

## Dedupe workflow

Before adding a new suggestion file:

1. Search `suggestions/` for similar words and areas.
2. Read `website-suggestion-dedupe-map.md`.
3. Prefer updating the canonical file for the relevant cluster.
4. If a new file is still needed, add `related`, `supersedes`, or `superseded_by` metadata.
5. Update `suggestions/README.md` and `suggestions/index.md` only when the new file is canonical or broadly useful.

Suggested local search examples:

```bash
rg -i "docusaurus|astro|mkdocs|vitepress" suggestions/
rg -i "suggestion lifecycle|status board|dedupe|superseded" suggestions/
rg -i "dashboard|helper api|status/full|playwright" suggestions/
```

## Automation suggestions

### 1. Metadata validator

Add a small script that checks:

- required metadata fields,
- allowed status/area/kind values,
- valid relative links,
- no duplicate suggestion IDs,
- implemented suggestions have implementation or release links.

### 2. Generated index

Generate a website-ready JSON or markdown index with:

- suggestions by status,
- suggestions by area,
- recently updated suggestions,
- implemented suggestions,
- superseded suggestions and their canonical replacements.

### 3. Related-suggestion helper

Use keyword matching to suggest related files during review.

The helper should not block merges at first. It should report:

- likely duplicates,
- missing related links,
- candidate canonical files.

### 4. Website status board

Render the generated index into `community/suggestions/status-board.md` or a static page.

The first implementation can be plain markdown. A richer interactive board should wait until there is enough proposal volume to justify it.

### 5. Release linkage check

When a suggestion moves to `implemented`, require one of:

- a changelog entry,
- a release note,
- a merged PR link,
- a docs page showing validation evidence.

## Acceptance criteria

This proposal is successful when:

- contributors can find the canonical suggestion process from the website,
- every published suggestion has consistent metadata,
- duplicate suggestions link back to a canonical record,
- maintainers can generate a status board without manual copy/paste,
- framework choice is explicit enough to prevent repeated Docusaurus/Astro/VitePress debates,
- the system remains compatible with the current static Nginx dashboard and GitHub-native workflow.

## Risks and mitigations

### Risk: too much process for a small community

Mitigation:

- keep metadata minimal,
- make automation advisory before making it blocking,
- allow short proposals for small documentation or typo fixes.

### Risk: framework churn

Mitigation:

- choose Docusaurus as the default docs-site path,
- document conditions for switching to Astro/Starlight or MkDocs Material,
- avoid migrating content until the markdown contract is stable.

### Risk: duplicate sources of truth

Mitigation:

- keep suggestion records in `suggestions/`,
- generate website pages from those records,
- link GitHub Issues back to canonical markdown records.

### Risk: privacy and security drift

Mitigation:

- avoid client-side calls from the LAN dashboard to third-party APIs by default,
- use static/generated release and suggestion data where possible,
- keep moderation and user identity in GitHub unless a clear need emerges.

## Related suggestions

- [`website-historical-baseline.md`](./website-historical-baseline.md)
- [`website-and-docs-framework.md`](./website-and-docs-framework.md)
- [`website-community-pages.md`](./website-community-pages.md)
- [`website-platform-frameworks.md`](./website-platform-frameworks.md)
- [`website-suggestion-dedupe-map.md`](./website-suggestion-dedupe-map.md)
- [`implementation-backlog.md`](./implementation-backlog.md)
