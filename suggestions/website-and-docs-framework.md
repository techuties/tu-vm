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

For the detailed publishing contract, frontmatter model, build flow, and Nginx integration, see [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md).

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

### Stage 1: Framework decision and content map
- Confirm Docusaurus as the default framework unless project requirements favor MkDocs Material.
- Map existing `README.md`, `QUICK_REFERENCE.md`, `docs/playbooks/`, and `suggestions/` content into the proposed navigation.
- Identify which historical suggestions should remain archive-only and which should become published docs pages.

### Stage 2: Website scaffold and initial pages
- Create a dedicated docs website scaffold when implementation starts.
- Publish high-value pages first: getting started, operations, security, community suggestions, and review guidance.
- Keep the existing Nginx landing dashboard as the operator home page and link from it to the generated docs site.

### Stage 3: Automation and discoverability
- Add CI checks for links, required frontmatter, heading structure, and static-site build.
- Enable search and auto-generated suggestion indexes from frontmatter.
- Publish status-board and decision-log pages for transparent community follow-through.

## Acceptance criteria

- Contributors can discover how to submit, track, and extend suggestions without reading the full repository.
- The docs website builds from markdown using documented commands.
- Published suggestion pages link back to historical sources or decision records.
- Website publishing does not weaken existing Nginx control-plane or allowlist boundaries.
