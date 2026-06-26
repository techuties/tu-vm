# Website and Documentation Framework

## Goal

Create a Markdown-first website that helps users operate TU-VM, helps contributors understand the project, and lets community suggestions move from idea to implementation without duplicate effort.

The website should not replace the existing landing dashboard or GitHub workflows. It should organize and publish the knowledge that already exists in the repository.

## Historical context to reuse

Existing assets already cover much of the product surface:

- [`README.md`](../README.md): complete technical narrative and setup guidance.
- [`QUICK_REFERENCE.md`](../QUICK_REFERENCE.md): command-level operator shortcuts.
- [`CONTRIBUTING.md`](../CONTRIBUTING.md): contribution flow, issue templates, labels, and release notes.
- [`CHANGELOG.md`](../CHANGELOG.md): release history and future direction.
- [`docs/playbooks/`](../docs/playbooks/README.md): stable anchors for dashboard-linked runbooks.
- [`nginx/html/index.html`](../nginx/html/index.html): current web entrypoint and operator dashboard.

The website should pull these into a navigable structure, then add community and suggestion pages around them.

## Recommended framework choice

### Primary: Docusaurus

Use Docusaurus if the project wants a public community docs website with versioned docs, strong sidebars, plugin ecosystem, and easy Markdown contributions.

Recommended Docusaurus fit:

- Docs versioning for releases.
- Sidebar navigation for install, operations, security, and community sections.
- Generated suggestion indexes from Markdown frontmatter.
- Search via local search plugin first, Algolia DocSearch later if public hosting warrants it.
- GitHub edit links so contributors can improve pages directly.

### Lightweight alternative: MkDocs Material

Use MkDocs Material if maintainers prefer the smallest docs stack and Python-based tooling.

Recommended MkDocs fit:

- Fast static site setup.
- Strong Markdown ergonomics.
- Excellent built-in search.
- Lower customization overhead for a docs-only site.

### Content-rich alternative: Astro Starlight

Use Astro Starlight if the website needs richer landing pages, marketing-style content, or component-driven pages beyond docs.

Recommended Astro fit:

- Custom homepage and community landing pages.
- Markdown/MDX content with design flexibility.
- Easy future integration with static JSON generated from `suggestions/`.

### Selection rule

Choose the simplest framework that satisfies these needs:

| Need | Best fit |
|---|---|
| Versioned docs, sidebars, broad community familiarity | Docusaurus |
| Minimal docs-only publishing path | MkDocs Material |
| Rich custom website plus docs | Astro Starlight |

Avoid a custom website generator unless none of these tools meet a concrete requirement.

## Information architecture

Recommended top-level website sections:

1. **Home**
   - What TU-VM is.
   - Who it is for.
   - Quick links to install, dashboard, security, and suggestions.
2. **Install**
   - Prerequisites.
   - First-run setup.
   - SSL, `.env`, and Docker Compose expectations.
   - Common startup failures.
3. **Operate**
   - Service tiers.
   - `tu-vm.sh` command workflows.
   - Backup/restore.
   - Health checks and daily checkups.
   - Playbooks.
4. **Security**
   - LAN-first model.
   - Secure/public/lock modes.
   - Control token and allowlist behavior.
   - Reporting process.
5. **Community**
   - Contribution guide.
   - Roles and review expectations.
   - Good-first contribution path.
   - Maintainer responsibilities.
6. **Suggestions**
   - Historical baseline.
   - Active proposals.
   - Accepted proposals.
   - Implemented proposals.
   - Superseded or archived suggestions.
7. **Release Notes**
   - Changelog summaries.
   - Delivered community suggestions.
   - Migration notes.

## Suggestion page contract

Each website-rendered suggestion page should use a consistent structure:

```yaml
title: Community suggestion title
status: draft
area: website
owner: unassigned
reviewers: []
related:
  - historical-suggestions.md
```

Required body sections:

1. **Problem statement**: the pain or opportunity.
2. **Historical overlap**: related files or issues already reviewed.
3. **Existing solutions to reuse**: frameworks, scripts, GitHub features, or TU-VM components.
4. **Proposed approach**: what changes and what stays the same.
5. **Implementation outline**: incremental work items.
6. **Risks and mitigations**: security, operations, maintenance, and community risks.
7. **Acceptance criteria**: observable conditions for done.
8. **Rollback or exit path**: how to disable, revert, or archive if it fails.

## Publishing model

Start with repository-backed static publishing:

1. Source content from Markdown in `docs/`, root docs, and `suggestions/`.
2. Generate indexes from frontmatter and headings.
3. Keep GitHub Issues and PRs as the collaboration workflow.
4. Add dashboard links to published website pages only after the structure is stable.

This keeps community activity auditable through git while avoiding a custom CMS.

## Automation suggestions

### Markdown quality

- Check internal links.
- Check heading hierarchy.
- Require language identifiers on fenced code blocks where practical.
- Validate required suggestion sections and allowed statuses.

### Suggestion indexes

Generate static JSON and website pages grouped by:

- status
- area
- owner
- last reviewed date
- related historical files

### Duplicate discovery

Before a new suggestion is accepted for review, automation should print the most similar existing suggestions by title, headings, and tags.

Start with simple keyword matching. Consider embeddings/Qdrant only if the folder grows large enough that keyword matching becomes noisy.

### Dashboard integration

The existing landing page can eventually show:

- total suggestions by status
- recently accepted suggestions
- implemented community suggestions in the latest release
- links to active discussion areas

Keep this display read-only at first. Do not add moderation controls to the operator dashboard until permission boundaries are explicitly designed.

## Accessibility and readability baseline

- Use semantic headings without skipped levels.
- Provide meaningful link text.
- Keep contrast high and avoid color-only status indicators.
- Ensure keyboard navigation for any interactive components.
- Keep tables responsive or replace them with cards on small screens.
- Use concise summaries with links to deeper implementation detail.

## Editorial model

Recommended lightweight roles:

- **Docs maintainers**: own navigation, style, and information architecture.
- **Domain maintainers**: approve technical correctness for areas such as Docker, nginx, security, helper API, and processing pipeline.
- **Community reviewers**: test instructions, spot unclear language, and report missing context.
- **Proposal champions**: keep suggestion pages current while a proposal is active.

## Implementation sequence

1. Select Docusaurus, MkDocs Material, or Astro Starlight using the framework selection rule.
2. Create the website skeleton and navigation.
3. Import root docs and playbooks without large rewrites.
4. Add the suggestions section and generated index.
5. Add Markdown quality checks and duplicate detection.
6. Add links from the landing dashboard and README.
7. Add optional dashboard summary widgets after suggestion metadata is reliable.

## Acceptance criteria

- A new user can find install, operate, and security guidance without scanning the full README.
- A contributor can find the suggestion workflow, template, and current proposal status from one index page.
- Suggestion pages have consistent metadata and required sections.
- The website build is reproducible locally and in CI.
- Broken links or invalid suggestion statuses fail the quality check.
- The operator dashboard remains compatible with current nginx/static hosting patterns.
