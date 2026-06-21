# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

The website should treat repository markdown as the durable source of truth. See [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md) for the suggested frontmatter schema, duplicate checks, and status index model.

## Recommended stack

To avoid custom reinvention, use a mature docs framework:

- **Primary recommendation**: Docusaurus
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure

- **Alternative**: MkDocs Material
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
- Stable suggestion ID and `related` entries in frontmatter
- Problem and context
- Existing alternatives reviewed
- Historical suggestions checked before creating a new page
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
- Link released suggestions to changelog or release-note entries

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

### Stage 1 - Markdown source of truth
- Pick framework (Docusaurus, MkDocs Material, or Astro Starlight).
- Create initial docs structure and migration map.
- Publish suggestion template pages and review guide.

### Stage 2 - Historical migration and indexes
- Normalize high-value historical suggestions into the required page structure.
- Add frontmatter status fields and related suggestion links.
- Generate status and theme indexes from markdown.

### Stage 3 - Quality automation
- Add CI checks for required fields, markdown links, and approved status values.
- Enable search and auto-generated suggestion indexes.
- Publish contribution dashboard or status-board page for transparency.
