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

- **Alternative**: Astro Starlight
  - Fast content site with strong accessibility-oriented defaults
  - Good fit when the website needs richer landing-page components over time

Selection should favor the framework that lets maintainers publish Markdown,
generate indexes from front matter, and preview locally with the least custom
application code.

## Reuse-first implementation choices

Use existing project surfaces as the first publishing layer:

- Keep GitHub Issues as the default suggestion intake path.
- Keep `CONTRIBUTING.md` as the source for contributor expectations.
- Keep `CHANGELOG.md` and Release Drafter as the release communication path.
- Link operational runbooks from `docs/playbooks/` instead of duplicating them.
- Treat `/suggestions/` as the historical and planning archive.

Only add a custom service when static Markdown, GitHub labels, and generated
indexes can no longer represent the workflow clearly.

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
- Links to related historical suggestions
- Rollback or exit criteria for accepted work

## Website automation suggestions

### Link and structure quality
- Run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing

### Search and discoverability
- Enable full-text search (Algolia or local search plugin)
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Publish shipped items into a short "implemented suggestions" page that links
  to releases, changelog entries, or PRs

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

## Phased rollout plan

### Phase 1: Publish the curated structure
- Pick the framework (Docusaurus, MkDocs Material, or Astro Starlight).
- Create the top-level navigation and migration map.
- Publish the core suggestion pages from
  [`website-community-pages.md`](./website-community-pages.md).

### Phase 2: Migrate high-value content
- Move or mirror the most-used setup, operations, and contribution guidance.
- Keep deep operational details linked to existing runbooks.
- Add related-suggestion links so contributors can trace historical context.

### Phase 3: Add quality automation
- Add Markdown linting, link checking, and front matter validation.
- Enable search and generated suggestion indexes.
- Publish lightweight community status summaries from existing labels or
  front matter.

### Phase 4: Scale carefully
- Add richer dashboard widgets only after the static content model is stable.
- Prefer generated pages over a bespoke database-backed suggestion app.
- Review duplicate rates and contributor feedback before adding new tooling.
