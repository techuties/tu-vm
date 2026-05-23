# Website Markdown Publishing System

## Purpose

Create a community-based website workflow where proposals, documentation, and roadmap notes are authored as Markdown, reviewed in Git, and rendered by a mature static documentation framework.

This suggestion consolidates repeated historical themes from the existing `suggestions/` archive so the project can reuse proven patterns instead of building a custom publishing, voting, or governance system from scratch.

## Historical suggestions reused

This proposal builds directly on:

- [`website-historical-baseline.md`](./website-historical-baseline.md) - repeated historical themes and quality rules
- [`website-and-docs-framework.md`](./website-and-docs-framework.md) - docs site structure and framework options
- [`website-platform-frameworks.md`](./website-platform-frameworks.md) - static website architecture behind Nginx
- [`website-tooling-framework.md`](./website-tooling-framework.md) - validation, duplicate detection, and maintainer tooling
- [`implementation-backlog.md`](./implementation-backlog.md) - trimmed backlog of shipped and open community-system work

## Recommended architecture

### 1. Keep the operations dashboard separate

The current `nginx/html/index.html` dashboard should remain the operational control surface for service status, shortcuts, and LAN-first operator actions.

The community website should be a separate static documentation/community app served by Nginx under a route such as `/community` or `/docs`, or by a dedicated host such as `docs.techuties.com`.

Benefits:

- avoids regressions in runtime service controls
- lets contributors update community pages through Markdown-only pull requests
- keeps public/community content separate from local control endpoints

### 2. Use a mature docs framework

Use a framework that already solves navigation, search, content collections, edit links, and accessibility basics.

Recommended decision path:

1. **Docusaurus** as the default when the main need is docs, suggestions, release notes, and governance pages.
2. **Astro + Starlight** when the project wants a richer public website plus a high-performance docs section.
3. **MkDocs Material** when maintainers prefer a Python-oriented, lightweight docs stack with minimal frontend complexity.
4. **Next.js or another server-rendered app** only after static publishing is insufficient for real interactive community features.

The first implementation should not require a custom backend. GitHub Issues, pull requests, Discussions, labels, and the existing repository history already provide the durable community workflow.

### 3. Treat Markdown files as the source of truth

The existing `suggestions/*.md` files should remain the source archive for proposal history. A future website can either render these files directly or mirror selected files into a `website/` content collection with generated indexes.

Suggested content paths:

```text
suggestions/                       # canonical historical and active proposal archive
website/                           # optional static site source, if a framework is adopted
website/content/suggestions/       # generated or curated proposal pages
website/content/community/         # governance, contribution, maintainer pages
website/content/operations/        # playbooks and day-to-day operator docs
```

Avoid maintaining two manually edited copies of the same suggestion. If content is copied into a website source tree later, add a script or documented sync rule so reviewers can see which file is canonical.

## Suggestion page metadata

Every new website-ready suggestion should include a small metadata block. The exact parser can be added later, but the fields should be stable from the start.

Recommended frontmatter:

```yaml
---
title: "Short descriptive title"
summary: "One sentence explaining the value of the proposal."
status: proposed
category: docs
owner: docs-maintainers
source: "suggestions/website-historical-baseline.md"
related:
  - "suggestions/website-and-docs-framework.md"
  - "suggestions/website-tooling-framework.md"
last_reviewed: "2026-05-23"
---
```

Allowed statuses:

- `proposed`
- `triaged`
- `accepted`
- `in_progress`
- `released`
- `declined`
- `superseded`
- `needs_clarification`

Recommended categories:

- `docs`
- `community`
- `automation`
- `operations`
- `security`
- `ux`
- `integrations`

## Website-ready suggestion template

Each detailed suggestion should follow this structure:

1. **Summary** - short value statement
2. **Problem and context** - what pain or duplication exists
3. **Historical reuse** - existing files, branches, scripts, or frameworks being reused
4. **Options considered** - mature frameworks or existing project surfaces reviewed
5. **Recommended approach** - the smallest useful implementation path
6. **Community workflow** - how contributors propose, discuss, and update the idea
7. **Operational impact** - runtime, deployment, maintenance, and rollback notes
8. **Security and privacy impact** - especially for public docs, analytics, and external services
9. **Implementation checklist** - concrete, reviewable work items
10. **Acceptance criteria** - observable conditions for completion
11. **Decision log** - accepted, declined, or superseded notes with links

This keeps suggestions comparable without requiring a heavy RFC process for every small improvement.

## Community workflow

### Intake

1. Contributor searches `suggestions/` and open GitHub Issues for related ideas.
2. If a similar idea exists, they update the existing suggestion or link the new context to it.
3. If the idea is new, they open a GitHub Issue or pull request with a Markdown suggestion page.

### Triage

Maintainers classify the proposal as:

- duplicate or superseded by an existing suggestion
- small improvement suitable for a direct pull request
- larger change needing design review
- declined with a clear reason

### Implementation

Accepted suggestions should link to:

- the tracking issue
- implementation pull requests
- release notes or `CHANGELOG.md`
- rollback instructions when runtime behavior changes

### Publication

When a suggestion becomes `released`, the website should display it as implemented and retain the original decision history. This avoids losing context and helps future contributors understand why a direction was chosen.

## Day-to-day tooling recommendations

### Markdown validation

Add a lightweight validation path before adopting a full website build:

- check required frontmatter fields for new `suggestions/*.md` files
- reject unknown statuses and duplicate slugs
- run markdown linting with a narrow rule set
- run link checks against internal relative links
- verify that released suggestions include a changelog or release reference

This can start as a small script, for example `scripts/suggestions-lint.sh`, and later become part of a framework-specific docs build.

### Generated indexes

Generate website indexes from metadata instead of manually maintaining many list pages.

Useful generated views:

- active suggestions by status
- accepted but not released
- released suggestions by version
- suggestions grouped by category
- recently updated pages
- superseded ideas with links to replacements

### Contributor shortcuts

Expose common commands through the existing control script or a simple task runner only after the checks exist:

```text
./tu-vm.sh docs-check          # future wrapper for markdown/link checks
./tu-vm.sh suggestions-check   # future wrapper for suggestion metadata checks
```

If a separate task runner is introduced later, prefer one predictable entrypoint and document it in `CONTRIBUTING.md`.

### Search

Use the docs framework search path before adding a custom service:

- Docusaurus local search or DocSearch for docs-first deployments
- Pagefind for static Astro/Starlight output
- Meilisearch or Typesense only if local/self-hosted search becomes a stronger requirement

Avoid third-party analytics or tracking defaults that conflict with the private-AI and LAN-first posture.

## Website pages to render

Recommended first community pages:

1. **Suggestions index** - generated from status/category metadata
2. **Accepted roadmap** - accepted suggestions not yet released
3. **Released suggestions** - implemented items linked to changelog entries
4. **Contributor guide** - how to create or update suggestion Markdown
5. **Maintainer guide** - triage labels, review rules, and decision-log examples
6. **Operations handbook** - curated links to playbooks and day-to-day tooling

These pages should link back to the canonical repository files so edits remain transparent in pull requests.

## Implementation checklist

1. Mark this document as the canonical Markdown publishing proposal from the suggestion hub.
2. Choose one initial docs framework using the decision path above.
3. Add a minimal website scaffold without changing the existing dashboard behavior.
4. Define the frontmatter schema for new suggestion pages.
5. Add a metadata/link validation script for `suggestions/*.md`.
6. Generate a suggestions index grouped by status and category.
7. Add docs build and suggestion validation to CI.
8. Link the website from the dashboard and `README.md` after the static build path is stable.

## Acceptance criteria

- A contributor can add or update a community suggestion with a Markdown-only pull request.
- The website can render suggestion pages without a custom backend.
- Suggestion status, category, and related links are visible in generated indexes.
- CI catches missing required metadata, broken internal links, and invalid statuses.
- The existing Nginx operations dashboard continues to behave the same.
- Released suggestions link to `CHANGELOG.md`, GitHub Releases, or the implementing pull request.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Duplicate suggestion pages continue to grow | Require related-link metadata and generated indexes that show superseded entries. |
| Framework choice causes churn | Start with static output and keep content portable Markdown/MDX. |
| CI becomes too strict for casual contributors | Begin with required metadata and internal links only; add style checks gradually. |
| Public website accidentally exposes operator-only controls | Keep the docs/community site separate from the local dashboard and review Nginx routes explicitly. |
| Manual index pages become stale | Generate indexes from metadata once the schema is adopted. |

## Rollback path

If the website framework or publishing flow does not work well:

1. Keep `suggestions/*.md` as the canonical archive.
2. Remove the static-site Nginx route or generated build artifacts.
3. Keep GitHub Issues, pull requests, and `CONTRIBUTING.md` as the community workflow.
4. Retain the metadata schema only if it continues to help maintainers triage proposals.

