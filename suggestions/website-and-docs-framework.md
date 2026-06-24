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

Each suggestion page should follow the reusable metadata and lifecycle contract in [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md). At minimum, each suggestion page should include:

- Title + one-line summary
- Status badge (`draft`, `review`, `accepted`, etc.)
- Problem and context
- Existing alternatives reviewed
- Proposed approach
- Impact and risks
- Implementation checklist
- Decision log entries (if any)

## Markdown publishing contract

Keep proposal content portable across website frameworks:

- Author suggestion content in markdown first.
- Add structured frontmatter for ID, status, area, owner, dates, tags, and related files.
- Generate status indexes from metadata instead of manually duplicating tables.
- Preserve GitHub readability so the community process works before a dedicated website exists.
- Treat the static site framework as a renderer, not the source of truth.

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

### Stage 1: Normalize markdown source

- Adopt the markdown publishing contract.
- Link the historical suggestions baseline, page set, and framework recommendations from one hub.
- Normalize new suggestion files around the same status lifecycle and required sections.

### Stage 2: Choose the website renderer

- Use Docusaurus by default for docs-first navigation, search, versioning, and community contributions.
- Use Astro/Starlight if custom website composition becomes more important than docs versioning.
- Use MkDocs Material if the team prefers a lightweight Python docs stack.

### Stage 3: Publish community suggestion pages

- Publish the index, how-to-submit guide, status board, decision log, and implemented suggestions page.
- Cross-link the pages from `README.md`, `CONTRIBUTING.md`, and the existing dashboard where appropriate.
- Keep the operational dashboard separate from the public docs/community website.

### Stage 4: Automate quality and visibility

- Add markdown/frontmatter validation.
- Generate suggestion indexes by status, area, and recent update.
- Add duplicate-suggestion recommendations.
- Publish contributor-facing status summaries from the same metadata.
