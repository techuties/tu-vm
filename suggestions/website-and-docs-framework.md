# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework:

- **Primary recommendation**: Docusaurus
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure
  - Mature sidebar/versioning conventions for docs-first communities
  - Straightforward GitHub Pages or static hosting deployment path

- **Alternative**: MkDocs Material
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

- **Alternative**: Astro with Starlight
  - Strong fit when the project needs a polished website shell plus docs
  - Keeps markdown authoring central while allowing richer custom pages

Selection guidance: start with the smallest static-site framework that can render markdown, sidebars, search, and generated suggestion indexes. Avoid a custom application until community workflow requirements exceed static content plus GitHub-native issue/discussion tooling.

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

Recommended frontmatter:

```yaml
---
id: unique-suggestion-id
title: Human readable title
status: draft
area: docs
risk: low
source: historical-baseline
updated: 2026-05-17
---
```

This keeps proposal pages easy to render into indexes by status, area, and risk.

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

### GitHub-native workflow integration
- Link each accepted suggestion to the canonical issue or PR
- Mirror completed items to `CHANGELOG.md` or Release Drafter output
- Use labels and CODEOWNERS to route review before adding custom moderation tooling
- Keep Discussions as the early design forum when enabled; otherwise use idea/suggestion issues

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

## Rollout sequence

### Phase 1: Static website foundation
- Pick framework (Docusaurus, MkDocs Material, or Astro/Starlight)
- Create initial docs structure and migration map
- Import existing `README.md`, `QUICK_REFERENCE.md`, `CONTRIBUTING.md`, playbooks, and canonical suggestion pages by link or normalized copy

### Phase 2: Suggestion system pages
- Publish suggestion template pages and review guide
- Add indexes for proposed, accepted, implemented, deferred, and declined suggestions
- Link suggestion pages to GitHub issues, PRs, changelog entries, and releases

### Phase 3: Quality and discoverability
- Add CI checks for markdown style, internal links, heading structure, and required frontmatter
- Enable search and auto-generated suggestion indexes
- Publish community health and contribution dashboard content when data is reliable

### Phase 4: Only-if-needed application layer
- Add a small community API or authenticated app only if static pages plus GitHub Issues/Discussions cannot satisfy voting, moderation, or reporting needs
- Reuse PostgreSQL already present in the stack if persistent community data becomes necessary
- Keep runtime service controls separated from community-facing endpoints
