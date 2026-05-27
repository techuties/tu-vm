# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly.

## Recommended stack

To avoid custom reinvention, use a mature docs framework and keep authoring markdown-first:

- **Primary recommendation**: Docusaurus
  - Excellent markdown support, versioning, and community plugin ecosystem
  - Built-in search integration options
  - Strong navigation and contributor-friendly structure

- **Alternative**: Astro Starlight
  - Strong markdown and MDX pipeline
  - Good fit if the project later needs richer marketing or landing pages
  - Fast static output with accessible defaults

- **Alternative**: MkDocs Material
  - Fast setup, strong markdown ergonomics, strong readability defaults
  - Good for lightweight docs sites with lower maintenance overhead

Selection guidance:

- Choose Docusaurus when docs versioning, sidebars, and proposal pages are the center of gravity.
- Choose Astro Starlight when a broader website with custom content blocks becomes important.
- Choose MkDocs Material when the team wants the lowest maintenance static docs path.

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

For the concrete website markdown page set, use [`website-community-pages.md`](./website-community-pages.md) as the source proposal.

## Website automation suggestions

### Link and structure quality
- Run markdown lint and link checks in CI on every PR
- Prevent merges when required suggestion fields are missing
- Validate front matter fields for suggestion IDs, status, theme, and update date
- Detect missing reciprocal links between status board rows and decision records

### Search and discoverability
- Enable full-text search (Algolia or local search plugin)
- Add tags for domains (`docs`, `automation`, `infra`, `security`, `ux`)
- Generate tag pages or filtered indexes from markdown metadata

### Status surfacing
- Auto-generate suggestion indexes by status from frontmatter
- Add "recently updated suggestions" page for contributor visibility
- Include shipped suggestion IDs in release-note helper output when possible

### Contributor guardrails
- Provide a local command or CI job that reports:
  - broken internal links
  - missing required headings
  - duplicate suggestion IDs
  - suggestions without rollback or validation notes
- Keep failures actionable with file names and section names.

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

### Stage 1: Static markdown baseline
- Choose Docusaurus, Astro Starlight, or MkDocs Material.
- Create the initial docs tree and sidebar/navigation map.
- Publish suggestion landing, submission, status, and template pages.
- Link back to `suggestions/` as historical source material.

### Stage 2: Community workflow integration
- Normalize proposal front matter and status values.
- Add decision-log and implemented-suggestions pages.
- Cross-link accepted suggestions to Issues, PRs, and `CHANGELOG.md`.
- Add ownership guidance for docs, operations, security, and dashboard areas.

### Stage 3: Automation and dashboard surfacing
- Add link checks, metadata checks, and duplicate ID checks in CI.
- Enable local search and generated suggestion indexes.
- Surface key community links from `nginx/html/index.html` without moving runtime controls out of their secured paths.
- Add release-note helper support for shipped suggestion IDs.

## Acceptance criteria

- A new contributor can find how to submit a suggestion from the docs home or landing dashboard.
- The status board links each active item to either a proposal, issue, or decision note.
- Each accepted suggestion includes validation and rollback notes.
- Website checks can run non-interactively in CI and produce clear errors.
- Security-sensitive runtime controls remain behind existing TU-VM access protections.
