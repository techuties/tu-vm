# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework and keep the operational dashboard separate from the community/docs site.

- **Primary recommendation: Docusaurus**
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure
  - Good fit for generated sidebars, docs versioning, blog-style updates, and community pages

- **Alternative: MkDocs Material**
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

- **Alternative: Astro Starlight**
  - Strong modern static-site foundation and accessibility defaults
  - Best if the project later wants richer custom components without becoming a full app

### Framework decision

Choose **Docusaurus first** unless maintainers explicitly prefer Python tooling. TU-VM is already Docker Compose and script driven, so a Node-based static docs build can stay isolated from runtime services and avoid changing the production stack. The site should publish static assets only; it should not become a new control plane.

## Source-of-truth model

Use one content path instead of parallel systems:

1. **Initial idea:** GitHub Issue using the existing `Idea / suggestion` template.
2. **Design depth:** Markdown proposal in `suggestions/` when the idea needs architecture, governance, or rollout detail.
3. **Website rendering:** generated from repository Markdown plus frontmatter.
4. **Implementation trace:** PR links, release notes, and `CHANGELOG.md` entries.

Do not build a custom database-backed suggestion tracker until issue volume clearly exceeds what GitHub Issues, labels, and generated indexes can handle.

## Information architecture

Proposed top-level site sections:

1. **Getting Started**
   - Quick setup
   - System overview
   - Core workflows
   - First successful local validation

2. **Suggestions**
   - How to submit a good suggestion
   - Open / in-review suggestions
   - Accepted suggestions
   - Implemented suggestions
   - Archived or deferred suggestions
   - Historical suggestion patterns

3. **Operations**
   - Runbooks
   - Troubleshooting
   - Security practices
   - Backup, restore, and update playbooks

4. **Community**
   - Contribution guide
   - Review process
   - Governance model
   - Maintainer ownership map
   - Release and changelog expectations

5. **Reference**
   - `tu-vm.sh` command reference
   - Service matrix
   - API/status contract notes
   - Environment and Docker Compose reference

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

### Suggested frontmatter

Use structured frontmatter so the website can generate indexes without hand-maintained lists:

```yaml
---
title: Community suggestion lifecycle dashboard
summary: Show proposal status and recent decisions without a custom tracker.
status: draft # idea | draft | review | accepted | implemented | deferred | rejected
area: community # community | docs | automation | infra | ux | security | operations
source_issue: 123
owner: unassigned
reviewers:
  - docs
  - operations
updated: 2026-06-19
---
```

### Required sections

Every website-ready suggestion should include:

1. Problem statement.
2. Existing work and alternatives reviewed.
3. Proposed solution.
4. Reuse of existing TU-VM components.
5. Security, privacy, and resource impact.
6. Rollout and rollback.
7. Acceptance criteria.
8. Links to related suggestions or issues.

## Website-to-dashboard boundary

Keep responsibilities clear:

- The **docs website** explains how the community works and renders proposal pages.
- The existing **Nginx landing dashboard** remains the operator control and status surface.
- The **helper API** may expose read-only community status summaries later, but it should not own proposal state.
- Any dashboard community widget should consume generated static JSON or a safe read-only endpoint.

This prevents community features from increasing risk around service control endpoints.

## Website automation suggestions

### Link and structure quality
- Run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing
- Validate suggestion frontmatter values against the status and area taxonomy
- Check that accepted suggestions include rollout, rollback, and validation notes

### Search and discoverability
- Enable full-text search (Algolia or local search plugin)
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)
- Add a related-suggestions block using keyword matching first, semantic lookup later if needed

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Add a compact community dashboard data file with counts by status and area

### Duplicate avoidance
- Require contributors to search existing issues and `suggestions/`
- Generate a duplicate hint report for new proposal files
- Prefer merging overlapping proposals into one roadmap item with a clear "supersedes" note

## Accessibility and readability baseline

- Minimum heading hierarchy consistency (no skipped levels)
- Meaningful link text (avoid "click here")
- Code blocks with language annotations
- Table usage only when semantic and readable on mobile
- Keep pages concise; move deep implementation detail to linked runbooks
- Search, filters, and status boards must be keyboard-accessible
- Status color must be paired with text labels; do not rely on color alone
- Proposal cards should expose title, status, summary, and last updated date to screen readers

## Editorial model

Recommended lightweight roles:

- **Docs maintainers**: curate structure and quality bar
- **Domain maintainers**: approve technical correctness
- **Community contributors**: submit and improve suggestions
- **Release steward**: confirms accepted suggestions are reflected in release notes when shipped

## Rollout plan

### Phase 1: Framework and content contract
- Confirm Docusaurus as the default static website framework
- Define suggestion frontmatter, status taxonomy, and required sections
- Create the initial navigation map from existing root docs, playbooks, and suggestions
- Keep the current Nginx dashboard unchanged except for links to the generated site

### Phase 2: Generated indexes and quality checks
- Generate suggestion index pages by status and area
- Add markdown/frontmatter validation for canonical suggestion files
- Extend link checks to include the canonical website proposal pages
- Document the duplicate-check expectation beside the suggestion template

### Phase 3: Community visibility
- Publish accepted/implemented proposal pages
- Add a small dashboard or website block for proposal counts and recent decisions
- Add release-note links from shipped suggestions back to issues and PRs
- Review metrics and archive stale proposals with a clear rationale

## Acceptance criteria

- Contributors can find how to submit a suggestion from the website in one navigation step.
- Every canonical suggestion page has required metadata, status, ownership, and acceptance criteria.
- The website can be generated from Markdown without copying proposal content into a second system.
- Existing operational dashboard controls remain unaffected.
- CI validates links and proposal structure for the canonical pages.
- Security-sensitive suggestions are routed to the stronger review lane before implementation.
