# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework and keep the first implementation markdown-first:

- **Primary recommendation**: Docusaurus
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure

- **Lean alternative**: MkDocs Material
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

- **Content-heavy alternative**: Astro Starlight
  - Strong static output and modern content collections
  - Good if the website later needs richer landing pages around docs content

Avoid a custom CMS for the first slice. Markdown with frontmatter is enough for suggestion pages, status indexes, and decision logs while keeping review visible in Git.

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

## Website markdown publishing model

The detailed page set is defined in [`website-community-pages.md`](./website-community-pages.md). The key recommendation is:

1. Store suggestions and community process pages as markdown.
2. Add frontmatter for status, owner, area, and links.
3. Generate indexes from frontmatter when automation becomes useful.
4. Keep GitHub Issues and PRs as the write/review system until a dedicated intake service is justified.

This keeps the public website easy to render while preserving GitHub-native review, history, and moderation controls.

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
- Check duplicate titles or related tags against existing `/suggestions/` files

### Search and discoverability
- Enable full-text search (Algolia or local search plugin)
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)
- Keep canonical URLs stable so old suggestions and changelog entries keep working

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Render implemented suggestions beside release/changelog links

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

### Stage 1 - Static markdown foundation
- Pick a framework or keep repository-rendered markdown while content stabilizes.
- Publish the community suggestions index, how-to-submit guide, and status-board shape.
- Link the entry points from `README.md`, `CONTRIBUTING.md`, and the landing dashboard.

### Stage 2 - Quality gates
- Add frontmatter validation for suggestion pages.
- Add link checking and heading-structure checks.
- Add duplicate-topic hints against historical suggestions.

### Stage 3 - Generated indexes
- Generate status, area, and recently-updated indexes from markdown metadata.
- Add a "shipped suggestions" view that requires changelog/release references.
- Publish archive pages for merged, rejected, or superseded ideas.

### Stage 4 - Optional dynamic layer
- Add a read-only API or helper-generated JSON only if static markdown indexes become difficult to maintain.
- Keep write paths moderated through GitHub until the team has a clear need for website-native submission.

## Acceptance criteria

- The website can explain how to submit, review, decide, implement, and archive suggestions.
- Contributors can discover related historical suggestions before proposing a new one.
- Maintainers can update status through markdown/frontmatter without changing application code.
- Any future dynamic system reuses the same metadata and lifecycle rather than replacing it.
