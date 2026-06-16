# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework:

- **Primary recommendation**: Docusaurus
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure

- **Alternative**: MkDocs Material
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

- **Alternative for richer public pages**: Astro Starlight
  - Static output with a strong markdown pipeline
  - Useful if the site needs both documentation and more flexible public landing pages

## Framework selection guardrails

Pick the tool that keeps community work simple:

1. **Markdown remains the authoring format** so contributors can review proposals through normal pull requests.
2. **Static output is preferred** so deployment can stay compatible with Nginx and Docker Compose.
3. **Search and navigation are built in or available through maintained plugins**.
4. **Versioning or release-aware docs are supported** before the project needs a custom roadmap database.
5. **Accessibility defaults are strong** and can be validated with common lint/browser tooling.

Do not build a custom website application until the static-site path can no longer support the required community workflow.

## Information architecture

Proposed top-level site sections:

1. **Getting Started**
   - Quick setup
   - System overview
   - Core workflows

2. **Suggestions**
   - New suggestions
   - Accepted suggestions
   - Implemented suggestions
   - Archived/deferred suggestions

3. **Operations**
   - Runbooks
   - Troubleshooting
   - Security practices

4. **Community**
   - Contribution guide
   - Review process
   - Governance model

## Suggestion page design

Each suggestion page should include:

- Title + one-line summary
- Status badge (`draft`, `review`, `accepted`, etc.)
- Problem and context
- Existing alternatives reviewed
- Proposed approach
- Impact and risks
- Implementation checklist
- Decision log entries (if any)

## Website markdown file model

Recommended first website pages, all backed by markdown:

```text
docs/
  getting-started/
    overview.md
    install.md
  operations/
    playbooks.md
    troubleshooting.md
  security/
    overview.md
    reporting.md
  community/
    overview.md
    contributing.md
    governance.md
  suggestions/
    index.md
    template.md
    accepted.md
    implemented.md
    deferred.md
  roadmap.md
```

Suggestion markdown should use a small frontmatter contract so indexes and dashboards can be generated without a database:

```yaml
---
id: SUG-0001
title: Short descriptive title
status: draft
area: docs
owner: unassigned
related:
  - suggestions/website-roadmap-from-historical-suggestions.md
---
```

Required body sections:

1. Problem statement
2. Existing solutions or historical suggestions checked
3. Proposed approach
4. Implementation notes
5. Risks and rollback
6. Success metrics
7. Review and ownership path

This lets the community browse proposals as normal website pages while maintainers can still automate status pages from plain files.

## Website automation suggestions

### Link and structure quality
- Run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing
- Validate frontmatter status values against an allowed list

### Search and discoverability
- Enable full-text search (Algolia or local search plugin)
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Link implemented suggestions to changelog entries and release notes

### Duplicate prevention
- Generate a simple overlap report from titles, tags, and required sections before review.
- Link related historical suggestions in frontmatter rather than copying their content into a new file.
- Prefer extending an accepted roadmap item over opening a second proposal with the same outcome.

## Accessibility and readability baseline

- Minimum heading hierarchy consistency (no skipped levels)
- Meaningful link text (avoid "click here")
- Code blocks with language annotations
- Table usage only when semantic and readable on mobile
- Keep pages concise; move deep implementation detail to linked runbooks

## Editorial model

Recommended lightweight roles:

- **Docs maintainers**: curate structure and quality bar
- **Domain maintainers**: approve technical correctness
- **Community contributors**: submit and improve suggestions

## Incremental rollout plan

### Phase 1: Static markdown foundation
- Select Docusaurus, MkDocs Material, or Astro Starlight using the guardrails above.
- Create the website directory structure and navigation from existing repository docs.
- Publish the suggestion template, status taxonomy, and historical suggestion index.

### Phase 2: Quality gates and contributor support
- Add markdown lint, link checks, and required-section validation.
- Add contributor-facing examples for a good suggestion, a rejected duplicate, and an accepted proposal.
- Cross-link `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, playbooks, and suggestion pages.

### Phase 3: Automation without custom platform risk
- Generate suggestion indexes from frontmatter.
- Produce duplicate/overlap reports from the existing `suggestions/` folder.
- Surface safe community stats on the landing page or helper API while keeping privileged control endpoints private.

### Phase 4: Scale only where needed
- Add browser smoke tests for website navigation and core dashboard flows.
- Consider a lightweight component framework only if static markdown pages cannot support the desired interaction.
- Add feature flags for experimental community widgets before exposing them broadly.
