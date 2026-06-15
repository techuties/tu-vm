# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework and keep markdown records as the source of truth. The detailed publishing model, metadata contract, and duplicate-handling process live in [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md).

- **Primary recommendation**: Docusaurus
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure

- **Alternative**: Astro with Starlight
  - Strong fit if custom website pages become as important as documentation
  - Keeps markdown content central while allowing richer interactive sections

- **Lightweight fallback**: MkDocs Material
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

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

## Implementation stages

### Stage 1: Decide and standardize
- Treat Docusaurus as the default docs-site path unless the team explicitly chooses Astro/Starlight or MkDocs for documented reasons.
- Keep `suggestions/` as the source of truth for proposal records.
- Apply the metadata contract from [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md) to website-published suggestions.

### Stage 2: Publish the core community pages
- Add suggestions index, how-to-submit, status-board, decisions, and implemented pages.
- Link GitHub Issue intake and `CONTRIBUTING.md` prominently.
- Include the duplicate-search workflow from [`website-suggestion-dedupe-map.md`](./website-suggestion-dedupe-map.md).

### Stage 3: Automate quality and visibility
- Add markdown lint, link checks, and suggestion metadata validation.
- Generate status indexes from markdown metadata.
- Surface implemented suggestions and release links on the website.

### Stage 4: Scale only where needed
- Add richer search, related-suggestion helpers, or interactive dashboards only after the static markdown flow is working.
- Avoid adding a custom suggestions API or database until GitHub-native workflows become a clear bottleneck.
