# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: discover proposals, understand standards, and contribute quickly while reusing the repository's existing Markdown, GitHub workflows, dashboard links, and operational scripts.

The website should be a publishing layer over the repository, not a separate product database. GitHub Issues remain the intake path, `suggestions/` remains the historical planning archive, and the docs site makes that material easier to search, triage, and discuss.

## Reuse-first stack recommendation

Do not build a custom CMS or bespoke suggestion tracker unless the GitHub-native workflow stops meeting real needs. Use a mature static documentation framework that can render Markdown from this repository:

1. **Primary recommendation: Docusaurus**
   - Strong Markdown/MDX support, sidebars, versioning, search integrations, and plugin ecosystem.
   - Good fit if the community site grows into tutorials, release notes, API references, and contributor guides.
   - Can generate suggestion indexes from frontmatter with small Node scripts or existing plugins.

2. **Lightweight alternative: Astro Starlight**
   - Modern content collections and schema validation for Markdown frontmatter.
   - Good fit if the site should stay fast, static, and content-driven with minimal client JavaScript.

3. **Python-oriented alternative: MkDocs Material**
   - Excellent readability defaults and simple configuration.
   - Good fit if maintainers prefer Python tooling for docs validation and generation.

Selection criteria:

- Must render ordinary Markdown files without locking content into a proprietary format.
- Must support generated navigation from frontmatter or a simple manifest.
- Must have CI-friendly build, link-check, and accessibility validation.
- Must keep private/LAN-first TU-VM deployment guidance clear and prominent.

## Information architecture

Proposed top-level site sections:

1. **Getting Started**
   - Quick setup
   - System overview
   - Core workflows
   - Supported environments and secure defaults

2. **Operate**
   - Daily commands (`./tu-vm.sh`, service tiers, backups)
   - Playbooks from [`docs/playbooks/`](../docs/playbooks/README.md)
   - Troubleshooting and recovery
   - Status endpoint contract references

3. **Security**
   - LAN-first architecture
   - Control endpoint allowlisting
   - Vulnerability reporting through [`SECURITY.md`](../SECURITY.md)
   - Secret and `.env` handling

4. **Community**
   - Contribution guide
   - Review process
   - Ownership and CODEOWNERS expectations
   - Release and changelog process

5. **Suggestions**
   - Historical baseline
   - Active proposals
   - Accepted / in-progress / implemented suggestions
   - Deferred or rejected suggestions with rationale

## Suggested repository-backed website layout

Keep website content close to existing repository content so contributors can edit it through normal pull requests:

```text
docs/
  getting-started/
  operate/
  security/
  community/
  suggestions/
    index.md
    how-to-submit.md
    status-board.md
    decisions.md
    implemented.md
suggestions/
  website-historical-baseline.md
  community-system-framework.md
  website-and-docs-framework.md
  day-to-day-tooling.md
```

Use `docs/community/suggestions/*` for public website pages and `suggestions/*` for planning records. When a planning suggestion becomes public guidance, link it from the website page rather than copying the full content.

## Suggestion page design

Each website-facing suggestion page should include:

- Title and one-line summary
- Status badge (`idea`, `draft`, `triage`, `review`, `accepted`, `in-progress`, `implemented`, `deferred`, `rejected`, `superseded`)
- Problem and current behavior
- Historical overlap check with links into `suggestions/`
- Existing tools or frameworks reviewed
- Proposed approach
- Operational, security, and maintenance impacts
- Implementation checklist
- Validation evidence required before closure
- Decision log entries and reopen conditions

Suggested frontmatter:

```yaml
id: SUG-YYYY-NNN
title: Short human-readable title
summary: One sentence explaining the value.
status: draft
theme: community
impact: medium
risk: low
owner: unassigned
source_issue: https://github.com/techuties/tu-vm/issues/NNN
related:
  - ../../suggestions/website-historical-baseline.md
updated: YYYY-MM-DD
```

## Automation suggestions

### Link and structure quality

- Run Markdown style checks on docs and suggestions content.
- Run link checks for internal repository links and stable external URLs.
- Fail CI when required frontmatter fields are missing from website-facing suggestion pages.
- Warn, rather than fail initially, when a proposal lacks a historical-overlap link.

### Search and discoverability

- Enable full-text search with a local/static search plugin when possible.
- Add tags for domains such as `docs`, `automation`, `infra`, `security`, `ux`, `dashboard`, and `operations`.
- Generate status-specific indexes from frontmatter so maintainers do not manually edit status tables.
- Add "recently updated suggestions" and "needs reviewer" lists for contributor visibility.

### GitHub-native synchronization

- Keep GitHub Issues as the canonical intake and discussion surface.
- Require accepted suggestion pages to link to issues, pull requests, changelog entries, or release notes.
- Use labels from [`CONTRIBUTING.md`](../CONTRIBUTING.md) as the shared taxonomy between Issues, PRs, release notes, and website pages.
- Use Release Drafter output and [`CHANGELOG.md`](../CHANGELOG.md) to populate implemented suggestion summaries.

### Day-to-day maintainer tooling

- Add a small validation script that scans website suggestion frontmatter and reports missing fields, stale statuses, and broken local references.
- Generate a JSON index that the landing dashboard can eventually consume for counts by status.
- Add an optional digest command that summarizes new, changed, accepted, and implemented suggestions since a selected git ref.
- Keep automation explainable; duplicate detection and priority scoring should show matching files and score inputs, not opaque decisions.

## Accessibility and readability baseline

- Use consistent heading hierarchy with no skipped levels.
- Use meaningful link text and avoid generic "click here" links.
- Add language annotations to code blocks.
- Keep tables narrow enough for mobile; prefer lists when table width would be excessive.
- Write summaries before deep implementation detail.
- For any future charts or dashboards, provide labels, accessible colors, keyboard-friendly interaction, and non-visual summaries.

## Editorial model

Recommended lightweight roles:

- **Docs maintainers** curate structure, navigation, and readability.
- **Domain maintainers** confirm technical correctness and operational risk.
- **Community contributors** submit suggestions, reproduce issues, and improve examples.
- **Proposal champions** keep accepted suggestion pages current until implementation is closed.

## Adoption sequence

1. **Framework choice and structure**
   - Pick Docusaurus, Astro Starlight, or MkDocs Material.
   - Publish a minimal website skeleton that renders existing Markdown.
   - Add a migration map from current repository docs to website sections.

2. **Suggestion publishing baseline**
   - Add website-facing suggestion pages for index, submission guidance, status board, decisions, and implemented work.
   - Add frontmatter schema validation and internal link checks.
   - Link historical suggestion files instead of duplicating their content.

3. **Community operations**
   - Generate indexes by status and theme.
   - Publish decision logs for accepted, rejected, deferred, and superseded suggestions.
   - Add lightweight digest output for maintainers and contributors.

4. **Dashboard and release integration**
   - Surface high-level suggestion counts or recently shipped items on the existing landing page.
   - Link implemented suggestions to Release Drafter output and `CHANGELOG.md`.
   - Keep dashboard additions optional and cache-friendly so the LAN-first dashboard remains reliable.

## Acceptance criteria

- Contributors can find how to submit a suggestion and how it will be evaluated from the website navigation.
- Every public suggestion page links to historical overlap or states that no overlap was found.
- Accepted suggestions include owner, validation method, rollout/rollback notes, and affected repository areas.
- Implemented suggestions link to merged code, release notes, changelog entry, or validation evidence.
- Website build, Markdown checks, link checks, and frontmatter validation can run in CI without requiring the full Docker stack.
