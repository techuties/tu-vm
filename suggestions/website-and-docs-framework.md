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
  - Modern content collections and fast static output
  - Strong fit if the project wants custom landing pages while keeping docs simple

### Selection criteria

Choose the framework by matching project needs, not novelty:

| Need | Best fit | Why |
|---|---|---|
| Versioned public docs and plugin ecosystem | Docusaurus | Mature docs primitives and broad contributor familiarity |
| Minimal setup and Python-friendly tooling | MkDocs Material | Simple markdown workflow and low maintenance overhead |
| Custom marketing/community pages around docs | Astro Starlight | Flexible layouts with structured content collections |

All options should keep markdown and GitHub review as the source of truth.

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

For a full website-ready metadata model, use [Website Markdown Publishing System](./website-markdown-publishing-system.md).

## Website automation suggestions

### Link and structure quality
- Run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing
- Validate frontmatter status values and related-file links
- Flag likely duplicates before maintainers spend review time

### Search and discoverability
- Enable full-text search (Algolia or local search plugin)
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)
- Generate index pages by status, theme, and subsystem from markdown metadata

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Link shipped suggestions to release notes, changelog entries, or merged PRs

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

## Implementation sequence

### Foundation
- Pick the docs framework using the selection criteria above.
- Create a migration map from current repository docs to website sections.
- Mark canonical suggestion pages in `suggestions/README.md` and `suggestions/index.md`.

### Publishing workflow
- Adopt the suggestion frontmatter schema for new and substantially revised website-ready proposals.
- Publish template pages for submission, status, decisions, and implemented ideas.
- Add CI checks for metadata, markdown structure, and links.

### Community visibility
- Enable search and auto-generated suggestion indexes.
- Publish contributor-facing status and decision pages.
- Surface shipped community suggestions in release notes and the dashboard where useful.

## Acceptance criteria

- Contributors can find how to submit a suggestion from the website navigation.
- Historical suggestions are searchable and linked before new duplicates are accepted.
- Suggestion status is visible without reading maintainers' private notes.
- Docs changes can be reviewed through ordinary GitHub pull requests.
- The selected framework does not require a custom backend for the initial community workflow.
