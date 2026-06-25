# Website Markdown Publishing System

## Purpose

Create a community-facing website suggestion system that starts from markdown in this repository, reuses mature documentation tooling, and keeps the current TU-VM operations dashboard stable.

The goal is not to build a custom community platform first. The goal is to make suggestions easy to discover, submit, review, implement, and archive using patterns that contributors already understand.

## Historical suggestions reused

This proposal consolidates recurring ideas already present in this folder:

- Keep `nginx/html/index.html` focused on the local operations dashboard.
- Publish community and docs content from markdown instead of inventing a bespoke CMS.
- Use frontmatter so suggestions can be indexed by status, area, priority, and owner.
- Add lightweight automation for link checks, duplicate detection, and status indexes.
- Preserve secure-by-default behavior for anything connected to runtime controls.

Related files to keep aligned:

- [`website-and-docs-framework.md`](./website-and-docs-framework.md)
- [`website-community-pages.md`](./website-community-pages.md)
- [`website-day-to-day-tooling.md`](./website-day-to-day-tooling.md)
- [`community-system-framework.md`](./community-system-framework.md)
- [`implementation-backlog.md`](./implementation-backlog.md)

## Recommended framework path

### First choice: markdown-first static documentation site

Use a mature static documentation framework before adding an application backend:

- **Docusaurus** when versioned docs, strong plugin support, and generated navigation matter most.
- **Astro Starlight** when fast static output, clean content collections, and low client JavaScript are priorities.
- **MkDocs Material** when the team wants a Python-friendly, minimal-maintenance docs site.

Any of these can render markdown suggestion pages, generate indexes, and support search without creating a custom web application.

### Keep the operations dashboard separate

The existing Nginx dashboard should remain the operational control plane:

- `/` remains the private operator dashboard.
- `/docs` or `/community` can serve generated static community pages.
- Runtime control endpoints stay behind the existing helper API and access controls.
- Website content never needs direct write access to VM services.

This split lets contributors improve community content without touching service control flows.

## Suggested website markdown tree

Use one predictable subtree for published community pages:

```text
docs/community/
  index.md
  suggestions/
    index.md
    how-to-submit.md
    status-board.md
    decisions.md
    implemented.md
    template.md
  roadmap.md
  governance.md
```

Use this repository's `suggestions/` folder as the source of detailed planning notes and historical context. The website pages should present the polished, contributor-facing version of that material.

## Required frontmatter

Every published suggestion page should include structured metadata:

```yaml
---
title: "Short suggestion title"
summary: "One-sentence explanation of the value."
status: proposed
area: docs
priority: medium
owner: unassigned
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: "suggestions/file-name.md"
---
```

Recommended values:

- `status`: `proposed`, `triaged`, `accepted`, `in-progress`, `implemented`, `deferred`, `rejected`, `superseded`
- `area`: `docs`, `dashboard`, `helper-api`, `orchestration`, `security`, `automation`, `community`, `operations`
- `priority`: `low`, `medium`, `high`

The metadata should be strict enough for automation, but simple enough for casual contributors.

## Suggestion page template

Each suggestion should use this content shape:

```markdown
# Suggestion title

## Problem

What pain exists today? Who experiences it?

## Existing work to reuse

Which files, tools, frameworks, or historical suggestions already solve part of this?

## Proposed approach

What should change? Keep the scope specific.

## Community impact

How does this help contributors, operators, maintainers, or users?

## Operational and security impact

Does this affect services, networking, secrets, local data, or control paths?

## Implementation checklist

- [ ] Documentation updated
- [ ] Validation path documented
- [ ] Rollback path documented for runtime changes
- [ ] Changelog or release-note impact considered

## Decision log

- YYYY-MM-DD: Proposed.
```

## Reuse-first submission workflow

Before a new suggestion is accepted into review, contributors should complete a quick reuse check:

1. Search `suggestions/` for matching keywords.
2. Check [`implementation-backlog.md`](./implementation-backlog.md) for already-prioritized work.
3. Link related historical suggestions in the new page.
4. Explain whether the new idea extends, replaces, or supersedes existing work.

If the idea mostly duplicates an existing suggestion, update the existing page instead of creating a new one.

## Automation recommendations

### Markdown quality gate

Add a narrow markdown check that validates:

- Required frontmatter fields exist.
- Internal links resolve.
- Headings increase one level at a time.
- Code blocks declare a language where useful.
- Tables are not used for large mobile-unfriendly content.

Start as a non-blocking CI warning, then make required fields and links blocking once the rules are stable.

### Generated indexes

Generate website indexes from frontmatter:

- Suggestions by status.
- Suggestions by area.
- Recently updated suggestions.
- Implemented suggestions linked to changelog or release notes.
- Deferred or rejected suggestions with rationale.

This keeps the community website current without manual index editing.

### Duplicate detection helper

Add a small script or workflow that compares new suggestion titles and summaries against existing pages. The first version can use simple keyword overlap and shared tags; maintainers can override false positives.

The output should be advisory:

```text
Possible related suggestions:
- suggestions/website-community-pages.md
- suggestions/community-system-framework.md
```

### Changelog and release linkage

When a suggestion becomes `implemented`, require one of:

- A linked changelog entry.
- A linked release note.
- A documented reason why no user-facing note is needed.

This makes community contributions visible and avoids losing context after merge.

## Day-to-day contributor tools

Add one contributor-facing command or script that can run locally:

```text
./scripts/docs-check.sh
```

Recommended checks:

- Validate suggestion frontmatter.
- Check internal markdown links.
- Report duplicate-looking suggestion titles.
- Print the generated status-board preview.

This gives contributors fast feedback before they open a pull request.

## Governance rules

Use the existing community framework for decisions:

- Small docs clarifications can use normal pull request review.
- New website sections, new dependencies, or runtime-facing features require a short proposal.
- Security-sensitive suggestions require maintainer review before implementation starts.
- Rejected and deferred suggestions should include rationale and reopen conditions.

## Acceptance criteria

This publishing system is ready when:

- Website suggestion pages render from markdown without a custom CMS.
- Every published suggestion has required frontmatter and a clear status.
- Contributors can find existing related suggestions before submitting a new one.
- Maintainers can generate a status board from repository content.
- Implemented suggestions link back to releases, changelog entries, or validation evidence.
- The operational dashboard remains separate from public community content.

## Practical next steps

1. Choose one static site framework: Docusaurus, Astro Starlight, or MkDocs Material.
2. Create the `docs/community/` page tree with the suggested markdown pages.
3. Add a suggestion template page and frontmatter schema.
4. Add a local docs check script for links and required metadata.
5. Generate the first status board from existing `suggestions/` files.
