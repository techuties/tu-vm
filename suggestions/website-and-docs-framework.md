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

Each suggestion page should follow the canonical template in [`website-community-pages.md`](./website-community-pages.md). At minimum, include:

- Title + one-line summary
- Status badge (`draft`, `review`, `accepted`, etc.)
- Problem and context
- Existing alternatives reviewed
- Proposed approach
- Impact and risks
- Implementation checklist
- Decision log entries (if any)
- Rollout/rollback notes
- Success metrics

Use frontmatter for status, category, owner, impact, risk, and related links so indexes can be generated from markdown rather than manually maintained.

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

## Rollout stages

### Stage 1: Framework and content map
- Pick the docs framework (Docusaurus, MkDocs Material, Astro Starlight, or VitePress).
- Define the initial navigation and migration map.
- Link the existing `/suggestions/` archive as historical source material.

### Stage 2: Markdown suggestion workflow
- Publish the suggestion template pages and review guide.
- Normalize high-value existing suggestion files with frontmatter.
- Add a manually curated status board while the schema stabilizes.

### Stage 3: Automation and discoverability
- Add CI checks for markdown style, links, headings, and required frontmatter.
- Enable search and generated suggestion indexes.
- Publish a contributor-facing status dashboard once generated data is reliable.
