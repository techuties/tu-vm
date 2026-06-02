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

Use [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md) as the detailed publishing policy for suggestion page inventory, frontmatter, statuses, and automation.

Each suggestion page should include:

- Title + one-line summary
- Status badge (`draft`, `triage`, `accepted`, `implemented`, etc.)
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

### Stage 1: Choose the static docs path

- Pick Docusaurus, Astro Starlight, or MkDocs Material using the criteria above and in the markdown publishing system proposal.
- Create the initial docs structure and migration map.
- Keep `suggestions/` as the historical proposal archive.

### Stage 2: Publish community suggestion pages

- Migrate high-value existing docs.
- Publish suggestion template pages, review guide, status board, and decision log.
- Link the website pages back to historical suggestions for duplicate checks.

### Stage 3: Add quality gates and discovery

- Add CI checks for markdown links, required frontmatter, and heading structure.
- Enable search and auto-generated suggestion indexes.
- Publish contribution and suggestion status views for transparency.
