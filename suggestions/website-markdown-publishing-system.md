# Website Markdown Publishing System

## Purpose

Create a markdown-first website publishing model for TU-VM community suggestions, docs, and operations guidance.

This fills the gap between the existing suggestion archive and a future published website: historical suggestions already describe what pages and workflows should exist, but this document defines how markdown becomes a maintainable public site without building a custom CMS.

## Design principles

1. **Reuse mature tooling** instead of custom website infrastructure.
2. **Keep the existing dashboard intact**: `nginx/html/index.html` remains the LAN/operator surface.
3. **Treat markdown as the source of truth** for suggestions, docs, decisions, and contributor guidance.
4. **Make proposal history discoverable** so contributors can extend prior work instead of duplicating it.
5. **Preserve secure-by-default behavior**: publishing docs must not expose secrets, local status data, or control endpoints.

## Framework decision

### Primary recommendation: Docusaurus

Use Docusaurus as the first static-site generator when the team is ready to publish a dedicated docs/community website.

Why it fits this repository:

- Markdown and MDX authoring are first-class.
- Sidebars, versioned docs, tags, search plugins, and edit links are established patterns.
- Contributors can submit normal pull requests without learning a custom content system.
- Generated static assets can be served by the existing Nginx container.

### Acceptable alternative: Astro with Starlight

Use Astro with Starlight only if the website grows beyond documentation into a broader marketing/community portal with custom layouts.

### Avoid

- A bespoke CMS for suggestions.
- Runtime database-backed website pages for content that can be reviewed in Git.
- Client-side calls from public docs pages to local helper/control endpoints.

## Repository model

Recommended future layout:

```text
website/
  docusaurus.config.js
  sidebars.js
  src/
    pages/
docs/
  getting-started/
  operations/
  security/
  community/
  suggestions/
suggestions/
  README.md
  website-historical-baseline.md
  website-information-architecture.md
  website-community-pages.md
  website-markdown-publishing-system.md
```

Keep this repository's current `suggestions/` folder as the historical proposal archive. Published docs can either:

- import selected pages from `suggestions/`, or
- mirror accepted content into `docs/suggestions/` while linking back to the archive source.

The important rule is that every published suggestion page must link to its historical source or decision record.

## Page types

### 1) Suggestion pages

Suggestion pages describe proposed improvements.

Required frontmatter:

```yaml
id: SUG-YYYY-NNN
title: Short descriptive title
summary: One-sentence summary
status: draft
theme: community
impact: medium
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
source_links:
  - ../../suggestions/website-historical-baseline.md
```

Allowed `status` values:

- `draft`
- `triage`
- `accepted`
- `in-progress`
- `implemented`
- `deferred`
- `rejected`

Suggested body sections:

1. Problem
2. Current state
3. Historical suggestions checked
4. Proposed approach
5. Reused framework or tool
6. Implementation outline
7. Security and resource impact
8. Rollback path
9. Success criteria

### 2) Decision pages

Decision pages explain why a suggestion was accepted, deferred, or rejected.

Required frontmatter:

```yaml
title: Decision title
decision_id: DEC-YYYY-NNN
related_suggestion: SUG-YYYY-NNN
status: accepted
decided_at: YYYY-MM-DD
deciders:
  - maintainer-or-team
```

Decision pages should include tradeoffs, alternatives considered, and reopen conditions for deferred work.

### 3) Operations pages

Operations pages turn repeated support topics into reusable runbooks.

They should link to:

- relevant `tu-vm.sh` commands
- existing scripts in `scripts/`
- helper status endpoints when applicable
- rollback or safe-stop instructions

### 4) Community pages

Community pages explain contribution roles, issue labels, review expectations, and release communication.

They should reuse the governance model in [`website-community-framework.md`](./website-community-framework.md).

## Publishing pipeline

### Authoring flow

1. Contributor checks [`website-historical-baseline.md`](./website-historical-baseline.md) and the suggestion index before opening a new idea.
2. Contributor drafts markdown with required frontmatter.
3. Maintainers triage for duplicate history, security impact, and implementation fit.
4. Accepted pages are linked from the docs sidebar and suggestion status board.
5. Implemented items link back to release notes or `CHANGELOG.md`.

### Build flow

1. Static site generator reads markdown from `docs/` and selected `suggestions/` pages.
2. CI runs markdown structure checks, link checks, and the static site build.
3. Build output is copied into an Nginx-served path such as `nginx/html/docs/`.
4. The existing dashboard links to `/docs/`, while `/` remains the operator dashboard.

### Local contributor commands

Recommended commands once the website scaffold exists:

```sh
npm run docs:start
npm run docs:build
npm run docs:check
```

If the project avoids Node tooling, use MkDocs Material with equivalent commands:

```sh
mkdocs serve
mkdocs build --strict
```

## Quality gates

### Required before publishing

- Markdown link check for local links.
- Heading hierarchy check.
- Required-frontmatter validation for suggestion and decision pages.
- Static-site build in CI.
- Secret scanning or a rule that blocks committed `.env` values and token-like strings.

### Recommended as the site matures

- Spell check with a small project dictionary.
- Accessibility smoke checks for generated HTML.
- Search index validation.
- Redirect checks for renamed docs pages.
- Dead-page detection for orphaned markdown files.

## Integration with current project surfaces

### `nginx/html/index.html`

Keep as the current operator dashboard. Add only a small docs/community entry point that links to the generated site.

### `helper/uploader.py`

Do not make public docs pages depend on helper runtime data. Helper endpoints are operational APIs, not a content backend.

### `tu-vm.sh`

Future convenience commands can wrap docs checks, for example:

```sh
./tu-vm.sh docs-preview
./tu-vm.sh docs-check
```

These should be thin aliases over the underlying static-site tooling.

### `CHANGELOG.md`

Implemented suggestions should link to changelog entries, and changelog entries should reference shipped community suggestions when practical.

## Community operating model

### Ownership

Recommended ownership lanes:

- Docs maintainers own site navigation, frontmatter conventions, and broken-link hygiene.
- Domain maintainers own technical accuracy.
- Security reviewers own pages that change access, networking, secrets, or control-plane behavior.

### Duplicate prevention

Before a new suggestion is accepted, reviewers should check:

- `suggestions/README.md`
- `suggestions/index.md`
- [`website-historical-baseline.md`](./website-historical-baseline.md)
- similarly named historical proposal files
- existing GitHub issues or discussions

If a proposal overlaps previous work, update or extend the existing page instead of creating another parallel recommendation.

## Implementation stages

### Stage 1: Content contract

- Adopt the frontmatter fields above.
- Mark `suggestions/README.md` as the canonical archive entry point.
- Add a status index for active suggestion pages.

### Stage 2: Static site scaffold

- Add the selected docs framework in a dedicated `website/` directory.
- Import a small subset of high-value pages first:
  - getting started
  - operations
  - security
  - community suggestions
- Keep generated output out of source control unless deployment requires committed static assets.

### Stage 3: Dashboard integration

- Link the generated docs site from the landing dashboard.
- Keep control actions and local status on the dashboard, not in the public docs section.
- Validate that the Nginx route does not weaken allowlist or control-plane boundaries.

### Stage 4: Automation

- Add CI checks for markdown, links, frontmatter, and static-site build.
- Add optional local helper commands for contributors.
- Generate suggestion indexes from frontmatter once the page set is stable.

## Acceptance criteria

- Contributors can find historical suggestions before submitting new ones.
- Every published suggestion page has status, owner, source links, and success criteria.
- The docs website can be built from markdown with one documented command.
- Nginx serves the generated site without changing existing dashboard behavior.
- Docs quality checks catch broken links and malformed suggestion metadata before merge.

## Risks and mitigations

### Risk: framework churn

Mitigation: pick one primary framework for the first implementation and document why. Revisit only if the website requirements change materially.

### Risk: duplicate content between `docs/` and `suggestions/`

Mitigation: keep `suggestions/` as the historical archive and require published pages to link back to source suggestions.

### Risk: docs expose operational internals

Mitigation: block secrets in CI, avoid live helper calls from public docs, and keep control-plane guidance focused on safe operator workflows.

### Risk: contributor friction from too many rules

Mitigation: start with a small required metadata set, then add stricter validation only after patterns stabilize.

## Related suggestion files

- [`website-historical-baseline.md`](./website-historical-baseline.md)
- [`website-information-architecture.md`](./website-information-architecture.md)
- [`website-community-pages.md`](./website-community-pages.md)
- [`website-community-framework.md`](./website-community-framework.md)
- [`website-contributor-tooling.md`](./website-contributor-tooling.md)
