---
title: Website Markdown Publishing System
status: proposed
category: website
tags:
  - markdown
  - documentation
  - community
  - tooling
---

# Website Markdown Publishing System

## Purpose

Create a markdown-first publishing model for the TU-VM website and community suggestion system. The goal is to make proposals easy to write, review, render on a website, and trace through implementation without introducing a custom CMS or heavyweight governance stack.

This suggestion consolidates recurring historical ideas from:

- [`website-historical-baseline.md`](./website-historical-baseline.md)
- [`website-information-architecture.md`](./website-information-architecture.md)
- [`website-and-docs-framework.md`](./website-and-docs-framework.md)
- [`community-system-framework.md`](./community-system-framework.md)
- [`day-to-day-tooling.md`](./day-to-day-tooling.md)
- [`implementation-backlog.md`](./implementation-backlog.md)

## Recommendation summary

Use plain markdown files as the source of truth for website pages, suggestion records, decision logs, and contributor guidance.

Render those files through a mature static documentation framework:

1. **Primary path: Docusaurus**
   - Strong Markdown and MDX support.
   - Versioned docs, sidebars, blog/news pages, and edit links.
   - Good plugin ecosystem for search, generated indexes, and community documentation.
   - Familiar GitHub contribution flow for open-source communities.
2. **Lean path: Astro with Starlight**
   - Fast static output and accessible docs defaults.
   - Excellent fit if the website later needs richer landing pages or component islands.
   - Pagefind can provide static search without adding a search service.
3. **Lightweight fallback: MkDocs Material**
   - Excellent readability and built-in search.
   - Strong choice if maintainers prefer a Python-based docs toolchain.

Do not build a custom database-backed proposal app until Markdown + GitHub Issues + CI checks no longer meet the project's needs.

## Existing surfaces to reuse

The publishing system should build on current project assets:

- `suggestions/` as the durable proposal archive.
- `README.md`, `QUICK_REFERENCE.md`, and `CHANGELOG.md` as high-value source content.
- `CONTRIBUTING.md` and `.github/ISSUE_TEMPLATE/suggestion.yml` as intake guidance.
- `docs/playbooks/` as operator-focused website content.
- `nginx/html/index.html` as the current landing/dashboard surface.
- `tu-vm.sh` and `scripts/` as validation and operations entry points.

This keeps the website aligned with how the project already works instead of creating a separate content silo.

## Content model

Each website-ready suggestion markdown file should contain frontmatter with a small stable schema:

```yaml
---
title: Short human-readable title
status: proposed
category: website
tags:
  - community
  - docs
owners:
  - maintainers
created: YYYY-MM-DD
updated: YYYY-MM-DD
related:
  - ./historical-suggestions.md
---
```

Recommended status values:

- `proposed`
- `triage`
- `accepted`
- `in-progress`
- `implemented`
- `deferred`
- `rejected`
- `superseded`

Recommended categories:

- `website`
- `community`
- `operations`
- `security`
- `automation`
- `developer-experience`
- `documentation`

## Required page sections

Use the same section structure for proposal-style pages:

1. **Purpose** - what outcome the suggestion is trying to create.
2. **Current state** - what already exists in the repository or platform.
3. **Historical overlap check** - links to related suggestions so duplicates are avoided.
4. **Proposed approach** - what should change and which framework/tool should be reused.
5. **Implementation checklist** - small reviewable steps.
6. **Security and privacy impact** - effects on tokens, network exposure, data, or local-only defaults.
7. **Operational impact** - service, script, CI, or dashboard behavior changes.
8. **Rollback path** - how to revert safely if the change causes problems.
9. **Success signals** - how maintainers know the change helped.
10. **Decision log** - accepted, deferred, rejected, or superseded notes with rationale.

## Website routing model

Suggested website routes:

| Route | Source | Purpose |
|---|---|---|
| `/docs/` | `README.md`, `QUICK_REFERENCE.md`, curated docs pages | Main documentation entry point |
| `/docs/playbooks/` | `docs/playbooks/` | Operator recipes and troubleshooting |
| `/community/` | `CONTRIBUTING.md`, governance docs | Contributor onboarding |
| `/suggestions/` | `suggestions/index.md` and proposal files | Public suggestion archive |
| `/suggestions/status/proposed/` | generated from frontmatter | Ideas awaiting review |
| `/suggestions/status/implemented/` | generated from frontmatter | Shipped community ideas |
| `/roadmap/` | `suggestions/implementation-backlog.md` | Prioritized next work |

If the selected framework cannot read Markdown outside its docs root cleanly, add a small sync or generation step that copies `suggestions/*.md` into the website build directory while preserving the repository files as the source of truth.

## Day-to-day tooling proposal

Add a lightweight validation path before the website build becomes mandatory:

1. **Markdown link checks**
   - Extend existing docs link checks to include high-value suggestion files.
   - Keep `lychee.toml` as the single link-check configuration.
2. **Suggestion schema check**
   - Validate frontmatter keys and known status/category values.
   - Fail CI when website-published suggestion pages omit required fields.
3. **Duplicate suggestion hinting**
   - Compare new suggestion titles, tags, and key phrases against existing files.
   - Emit warnings with likely related files; do not block on fuzzy matches.
4. **Generated indexes**
   - Generate status/category indexes from frontmatter.
   - Keep generated output out of the proposal source files unless the team explicitly wants committed static indexes.
5. **Contributor wrapper**
   - Expose checks through a predictable command such as `./tu-vm.sh docs-check` or `./scripts/check-suggestions.py`.
   - The wrapper should be non-interactive by default and return clear exit codes for automation.

## Community workflow

1. A contributor opens a GitHub suggestion issue or edits a Markdown proposal.
2. Maintainers check historical overlap using `suggestions/README.md`, `suggestions/index.md`, and related proposal links.
3. The proposal receives a status and category in frontmatter.
4. CI validates links, schema, and required sections.
5. Reviewers decide: accept, accept with changes, defer, reject, or mark superseded.
6. Accepted suggestions get linked implementation issues or pull requests.
7. When shipped, update the suggestion status, link validation evidence, and note the release or changelog entry.

## Implementation checklist

- [ ] Select the static docs framework: Docusaurus, Astro Starlight, or MkDocs Material.
- [ ] Define the minimal frontmatter schema and status taxonomy.
- [ ] Normalize the canonical suggestion pages to the schema.
- [ ] Add website navigation for `/suggestions/`, `/community/`, `/docs/playbooks/`, and `/roadmap/`.
- [ ] Extend link checks to cover the suggestion hub and canonical proposal files.
- [ ] Add a schema checker for website-published suggestion Markdown.
- [ ] Add generated indexes by status and category.
- [ ] Document the contributor flow in `CONTRIBUTING.md`.
- [ ] Keep rollback simple: the repository remains usable as plain Markdown even if the website build is disabled.

## Security and privacy impact

- Keep website output static unless there is a specific need for runtime behavior.
- Do not expose local operator status, tokens, hostnames, logs, or helper control endpoints through the public docs site.
- Keep dashboard actions behind the existing LAN-first Nginx/helper controls.
- Treat proposal metadata as public; do not place secrets or private operator details in suggestion pages.

## Operational impact

This change should not alter Docker Compose runtime services at first. The first implementation slice is documentation and CI-only:

- no new always-on container;
- no new network exposure;
- no dependency on Tier 2 services;
- no change to helper API behavior;
- no change to `tu-vm.sh start` behavior.

If a docs website container is added later, it should be optional and static, with clear ports, resource expectations, and rollback instructions.

## Rollback path

Because Markdown remains the source of truth:

1. Disable the website build workflow or remove it from CI.
2. Keep `suggestions/*.md` readable directly on GitHub.
3. Revert framework-specific config without deleting proposal history.
4. Continue intake through GitHub Issues and existing Markdown files.

## Success signals

- Contributors can find active and historical suggestions from one index.
- New proposals include status, category, impact, validation, and rollback notes.
- Duplicate proposal rate drops because historical overlap is easy to inspect.
- Maintainers spend less review time asking for missing context.
- Website pages can be generated from repository Markdown without manual copy/paste.

## Decision log

- **Proposed:** Adopt a markdown-first website publishing system and defer any custom CMS or database-backed suggestion app until static docs and GitHub-native workflows are insufficient.
