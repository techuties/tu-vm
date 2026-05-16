# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework:

- **Primary recommendation: Docusaurus**
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure
  - Good fit when suggestions, decisions, governance pages, and release notes need long-lived routes

- **Alternative: MkDocs Material**
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

Keep the existing `nginx/html/index.html` dashboard as the operational surface. The docs framework should publish a static community/documentation site that can be served by Nginx, linked from the dashboard, and generated from repository Markdown. Do not introduce a database-backed CMS unless Markdown review flow becomes the bottleneck.

## Source-of-truth model

Use repository files as the canonical record:

- `README.md` - project overview and architecture.
- `QUICK_REFERENCE.md` - operator command reference.
- `CHANGELOG.md` - shipped changes and release summaries.
- `CONTRIBUTING.md` - contributor workflow and GitHub setup.
- `suggestions/*.md` - active, accepted, rejected, and historical proposals.
- `docs/playbooks/*.md` - operator playbooks linked from the dashboard.

The website should render these records; it should not create a second proposal store in the first implementation.

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

Recommended frontmatter fields:

- `id`: stable short identifier, for example `website-community-platform`
- `status`: `proposed`, `triaged`, `accepted`, `implemented`, `deferred`, `rejected`, or `superseded`
- `area`: `docs`, `dashboard`, `governance`, `automation`, `security`, `operations`
- `owner`: maintainer or role responsible for the next action
- `created` / `updated`: ISO dates
- `canonical_of`: optional list of historical duplicates merged into this record
- `risk`: `low`, `medium`, or `high`
- `discussion`: optional GitHub Issue or Discussion URL

## Website automation suggestions

### Link and structure quality
- Run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing
- Generate a suggestion index from frontmatter so status and owner do not drift

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

## Rollout phases

### Phase 1: Framework selection and content contract
- Pick framework (Docusaurus or MkDocs)
- Create initial docs structure and migration map
- Define required suggestion frontmatter and page template

### Phase 2: Content migration and website baseline
- Migrate high-value existing docs
- Publish suggestion template pages and review guide
- Link the website from `README.md` and the existing dashboard

### Phase 3: Automation and community visibility
- Add CI checks (lint, links, spelling optional)
- Enable search and auto-generated suggestion indexes
- Publish contribution dashboard for transparency
