# Community Suggestions Index

This index is the short path into the constructive suggestion system for TU-VM. It points contributors toward the current recommendation set, explains what has already been considered, and reduces duplicate effort.

## Current recommendation

Build the community system in layers:

1. Keep GitHub Issues, PRs, Discussions, labels, and release notes as the source of truth for public collaboration.
2. Add a static documentation website layer using a mature Markdown-first framework.
3. Generate suggestion indexes, status views, and quality reports from Markdown metadata.
4. Surface high-value community state in the existing landing dashboard only after the data model is stable.

This approach gives the project a community-facing website without replacing the workflows that already work.

## Primary suggestion pages

| Topic | Start here | What it decides |
|---|---|---|
| Website framework | [`website-and-docs-framework.md`](./website-and-docs-framework.md) | Docusaurus vs MkDocs Material vs Astro Starlight, website structure, publishing model. |
| Community governance | [`community-system-framework.md`](./community-system-framework.md) | Suggestion lifecycle, roles, labels, decision records, review expectations. |
| Daily tooling | [`website-tools-and-automation.md`](./website-tools-and-automation.md) | Duplicate detection, Markdown checks, dashboard metrics, maintainer helpers. |
| Historical reuse | [`historical-patterns-from-project.md`](./historical-patterns-from-project.md) | Existing TU-VM patterns to extend before adding new systems. |
| Implementation backlog | [`implementation-backlog.md`](./implementation-backlog.md) | Completed items, open backlog, and prioritized next recommendations. |

## Community system shape

### Suggestion lifecycle

1. **Idea**: short GitHub issue or draft Markdown page.
2. **Discovery**: check historical suggestions and related files.
3. **Proposal**: structured suggestion with problem, reuse scan, risks, and acceptance criteria.
4. **Review**: community feedback plus maintainer review for architecture/security impact.
5. **Decision**: accepted, deferred, rejected, merged with existing suggestion, or implemented.
6. **Delivery**: linked PRs, verification notes, changelog entry, and retrospective notes when needed.

### Recommended metadata for suggestion pages

Use frontmatter when a docs framework is adopted:

```yaml
title: Short suggestion title
status: draft
area: website
owner: unassigned
related:
  - historical-suggestions.md
  - implementation-backlog.md
```

Statuses should be limited to `draft`, `review`, `accepted`, `deferred`, `rejected`, `implemented`, and `superseded`.

## Website strategy

Recommended starting point:

- **Docusaurus** for the community docs website when versioning, sidebars, and contributor familiarity matter most.
- **MkDocs Material** if the maintainers want the lightest possible Markdown publishing path.
- **Astro Starlight** if the website needs richer landing pages and custom content layouts.

The first website pass should publish:

- Getting started
- Operations
- Security
- Community
- Suggestions
- Changelog/release notes

## Day-to-day tooling priorities

The next practical tools should make maintenance easier before adding new community features:

1. Suggestion structure validator for required sections and metadata.
2. Duplicate/overlap report against existing `suggestions/` files.
3. Markdown link and heading checks for docs and suggestion pages.
4. Generated suggestion index grouped by status and area.
5. Optional helper API or dashboard widget for aggregate suggestion counts.

## Working principles

- **Reuse first**: extend existing scripts, docs, helper endpoints, and landing page patterns.
- **Community-first**: proposals should be public, discussable, and traceable.
- **Low-friction contribution**: templates, examples, and automation should guide contributors.
- **Operational reliability**: accepted ideas must include rollout, rollback, and validation notes.
- **Security by default**: website/community growth must not weaken private-AI defaults.

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and prioritized next work.
