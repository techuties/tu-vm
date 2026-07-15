# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework and keep the content
portable markdown:

- **Primary recommendation: Docusaurus**
  - Excellent markdown/MDX support, versioning, sidebars, tags, and a large
    community plugin ecosystem.
  - Good fit when the site needs docs, blog-style release notes, generated
    indexes, search, and community pages under one framework.
  - Strong contributor experience because docs can stay close to GitHub PRs.

- **Lightweight alternative: MkDocs Material**
  - Fast setup, strong markdown ergonomics, readable defaults, and simple
    navigation.
  - Good fit if the team wants minimal JavaScript and a docs-only publishing
    path.

- **Content-focused alternative: Astro Starlight**
  - Strong accessibility defaults, modern static output, and flexible component
    boundaries.
  - Good fit if the landing dashboard and docs site later share visual
    components.

Recommended decision rule: start with portable markdown files and frontmatter,
then pick the framework whose native features replace the most custom scripts.

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

5. **Integrations**
   - Optional tools and connectors
   - Security review expectations
   - Maintainer support status

6. **Release Notes**
   - Changelog highlights
   - Shipped suggestions
   - Migration notes

## Markdown content model

Keep website source pages as regular markdown so they remain reviewable in
GitHub and portable across Docusaurus, MkDocs, or Starlight.

### Required frontmatter for website pages

```yaml
title: Short human title
description: One-sentence page purpose
page_status: draft
owner: maintainers
last_updated: YYYY-MM-DD
source: suggestions
```

Use `page_status: draft | published | archived` for website publication state.
Reserve `status` for the lifecycle of an individual suggestion.

### Required frontmatter for individual suggestions

```yaml
id: SUG-YYYY-NNN
title: Short human title
status: draft
theme: docs
impact: medium
risk: low
owner: unassigned
related_issue:
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
```

Status values should be constrained to `draft`, `triage`, `review`,
`accepted`, `in-progress`, `shipped`, `deferred`, `rejected`, or
`superseded`.

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
- Expand the existing hub/index/backlog link check to all canonical suggestion
  pages, then run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing
- Check same-repository relative links so moved pages do not silently break
- Require unique suggestion IDs and stable anchors for decision records

### Search and discoverability
- Enable framework-native local full-text search first; adopt a hosted service
  such as Algolia DocSearch only after privacy, availability, and maintenance
  trade-offs are approved
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)
- Generate tag landing pages from frontmatter rather than maintaining them by
  hand
- Preserve a historical suggestions page so contributors can find prior art

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Link shipped suggestions to release notes and relevant changelog entries
- Link deferred/rejected suggestions to clear reopening conditions

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

### Stage 1: Markdown baseline
- Normalize suggestion pages around the frontmatter model.
- Create a generated or manually curated index by status.
- Document how contributors check for historical overlap before submitting.

### Stage 2: Static-site framework
- Pick Docusaurus, MkDocs Material, or Astro Starlight using the decision rule
  above.
- Import the existing markdown without changing proposal semantics.
- Add navigation for Getting Started, Operations, Community, Suggestions, and
  Release Notes.

### Stage 3: Automation and transparency
- Add CI checks for markdown style, links, and suggestion frontmatter.
- Enable search and auto-generated suggestion indexes.
- Publish a contributor-facing status view showing active, accepted, shipped,
  deferred, and rejected ideas.

## Acceptance criteria

- A first-time contributor can find the suggestion process, template, status
  board, and historical archive from the website navigation.
- A maintainer can review a suggestion without asking for missing problem,
  risk, rollout, rollback, or acceptance-criteria details.
- Every shipped suggestion links to implementation evidence and release notes.
- Every rejected or deferred suggestion includes a rationale and reopen path.
