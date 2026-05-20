# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework:

- **Primary recommendation: Docusaurus**
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure
  - Good fit for suggestion pages with frontmatter, generated sidebars, and release notes
  - Can be published as static assets without changing the current Docker Compose runtime

- **Alternative: MkDocs Material**
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

- **Interactive-site option: Astro Starlight or Nextra**
  - Consider only if the website must combine documentation with richer interactive components
  - Keep static output and simple hosting as a hard requirement

## Reuse-first architecture

Start with the tools the repository already has before adding new services:

1. **GitHub Issues** remain the public suggestion intake path.
2. **GitHub Discussions** can host early design conversations when enabled.
3. **Markdown in `suggestions/`** stores durable decisions, historical context, and implementation-ready proposals.
4. **Release Drafter and `CHANGELOG.md`** close the loop when suggestion-driven work ships.
5. **The existing nginx landing page** links to the current roadmap, playbooks, and contribution entry points.

Avoid a custom suggestions database or voting service until GitHub-native workflows and markdown indexes no longer cover the community workload.

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

Suggested frontmatter for website-ready markdown:

```yaml
---
title: "Short suggestion title"
status: proposed
area: docs
impact: community
owner: unassigned
last_reviewed: YYYY-MM-DD
---
```

Recommended statuses:

- `proposed` - captured but not yet triaged
- `review` - under maintainer/community discussion
- `accepted` - approved with implementation criteria
- `implemented` - shipped and linked to release notes
- `deferred` - valid idea, not currently prioritized
- `superseded` - replaced by another suggestion or shipped through a different path

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

### Community workflow automation
- Use issue labels such as `suggestion`, `triage`, `accepted`, `implemented`, and `deferred`.
- Add an optional CI check that verifies suggestion markdown contains required frontmatter.
- Generate a small `suggestions/index.json` artifact only if the website needs client-side filtering.
- Publish release notes that link back to accepted suggestions so contributors can see outcomes.

### Day-to-day tooling
- Add a docs command to the existing validation path rather than introducing a separate toolchain first.
- Prefer `pre-commit` hooks for markdown hygiene, link checks, and YAML sanity.
- Use n8n later for reminders or summary workflows only after the manual label flow is stable.

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

## Suggested rollout sequence

### Phase 1: Website baseline
- Pick framework (Docusaurus or MkDocs Material).
- Create initial docs structure and migration map.
- Link the existing `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `docs/playbooks/`, and `suggestions/` content.
- Publish the current suggestions hub as the canonical starting point.

### Phase 2: Suggestion workflow
- Add suggestion page frontmatter and a reusable template.
- Generate status/category indexes from markdown.
- Document labels, ownership, and decision criteria beside the suggestion template.

### Phase 3: Quality and discovery
- Add CI checks for markdown structure, links, and optional spelling.
- Enable search and auto-generated suggestion indexes.
- Surface "recently updated", "accepted", and "implemented" suggestions.

### Phase 4: Community operations
- Add dashboard or website summaries for active suggestions.
- Use n8n/AFFiNE for maintainer reminders, decision notes, and review summaries when the community process needs automation.
- Track metrics from [`community-system-framework.md`](./community-system-framework.md) to confirm the process reduces duplicate work.
