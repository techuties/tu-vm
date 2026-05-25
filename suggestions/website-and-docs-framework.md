# Website and Documentation Framework

## Goal

Create a documentation website that makes community participation simple: contributors can discover proposals, understand standards, reuse existing project knowledge, and submit improvements without maintainers manually curating every step.

This framework should be implemented as a website layer, not as a rewrite of the current TU-VM operations dashboard.

## Historical baseline

The repository already contains a large `suggestions/` archive. New website work should treat these files as the historical source material rather than starting a new tracker from scratch.

Reusable anchors:

- [`website-historical-baseline.md`](./website-historical-baseline.md) for repeated historical themes.
- [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md) for Markdown source-of-truth, frontmatter, and generated index guidance.
- [`community-system-framework.md`](./community-system-framework.md) for governance and review lifecycle.
- [`day-to-day-tooling.md`](./day-to-day-tooling.md) for practical automation and validation tools.
- [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed, current backlog.

## Recommended stack

Use a mature static documentation framework and keep content in Markdown.

### Primary recommendation: Docusaurus

Docusaurus is the strongest default for a community-based documentation and suggestion system because it provides:

- Markdown/MDX authoring with edit links.
- Versioned docs for release-aware operator guidance.
- Sidebars, tags, generated indexes, blog/news pages, and search integrations.
- A broad plugin ecosystem and familiar GitHub contribution model.

Best fit:

- Documentation, proposals, governance, roadmaps, release notes, and contributor onboarding.

### Lean alternative: Astro with Starlight

Astro + Starlight is a strong fit if the site needs richer landing pages while remaining static and fast.

Best fit:

- Docs plus custom landing/community pages, static search with Pagefind, and occasional interactive components.

### Lightweight fallback: MkDocs Material

MkDocs Material is a good fallback if maintainers prefer a Python-based docs toolchain and want excellent readability with minimal custom frontend work.

Best fit:

- A docs-first site with simple navigation, search, and a small maintainer surface.

### Avoid for the first iteration

- A custom CMS.
- A bespoke voting database.
- A full dynamic community application before Markdown + GitHub Issues + CI validation have been exhausted.

## Information architecture

Proposed top-level site sections:

1. **Getting Started**
   - Quick setup
   - System overview
   - First boot and validation checks
2. **Operations**
   - Service tier model
   - Runbooks and troubleshooting
   - Security practices
   - Rollback and recovery guidance
3. **Suggestions**
   - Active suggestions
   - Accepted suggestions
   - Implemented suggestions
   - Deferred, rejected, or superseded suggestions
   - Historical baseline and decision logs
4. **Community**
   - Contribution guide
   - Review process
   - Governance model
   - Maintainer ownership and label conventions
5. **Roadmap**
   - Prioritized next work from the implementation backlog
   - Links to issues, pull requests, releases, and changelog entries

## Suggestion page design

Each website-rendered suggestion page should use the Markdown publishing standards in [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md).

Required fields and sections:

- Title and one-line summary.
- Frontmatter status (`proposed`, `triage`, `accepted`, `in-progress`, `implemented`, `deferred`, `rejected`, or `superseded`).
- Category and tags.
- Problem and context.
- Historical overlap check with links to related suggestions.
- Existing frameworks or tools considered.
- Proposed approach.
- Security, privacy, and operational impact.
- Implementation checklist.
- Rollback path.
- Success signals.
- Decision log entries.

## Website automation suggestions

### Link and structure quality

- Extend existing docs link checks to include canonical suggestion files.
- Add Markdown style checks with a narrow rule set that supports existing docs.
- Validate frontmatter status/category values for website-published suggestion pages.
- Fail CI only on objective errors; emit warnings for fuzzy duplicate matches.

### Search and discoverability

- Enable full-text search with a framework-native plugin, Pagefind, Algolia DocSearch, Typesense, or another maintained option.
- Add tags for domains such as `docs`, `automation`, `infra`, `security`, `ux`, `community`, and `developer-experience`.
- Generate index pages by status, category, and update date.
- Provide "Edit this page" links to lower contribution friction.

### Status surfacing

- Auto-generate suggestion indexes by status from frontmatter.
- Add a "recently updated suggestions" page for contributor visibility.
- Link implemented suggestions to `CHANGELOG.md`, releases, and merged pull requests.
- Keep declined or superseded suggestions visible with rationale so the same work is not repeatedly re-proposed.

## Accessibility and readability baseline

- Use semantic headings and landmarks.
- Do not skip heading levels in authored content.
- Use meaningful link text.
- Annotate code blocks with language names.
- Keep tables readable on mobile; avoid wide tables when lists are clearer.
- Provide keyboard-accessible navigation, search, and menus.
- Maintain visible focus styles and sufficient color contrast.
- Keep pages concise; move deep implementation detail to linked runbooks or proposal files.

## Editorial and governance model

Recommended lightweight roles:

- **Docs maintainers** curate structure, naming, navigation, and accessibility.
- **Domain maintainers** approve technical correctness for operations, security, dashboard, helper API, and automation content.
- **Proposal champions** keep suggestion pages current through review and implementation.
- **Community contributors** submit ideas, improve docs, and test instructions in real operator workflows.

Review rules:

- Every proposal should link related historical suggestions before review.
- Every accepted proposal should include validation and rollback notes.
- Every implemented proposal should link evidence: pull request, commit, release note, or changelog entry.
- Every rejected or superseded proposal should include a concise rationale.

## Rollout sequence

### Phase 1: Source-of-truth cleanup

- Pick the static docs framework.
- Define the frontmatter schema and status taxonomy.
- Normalize canonical suggestion pages first.
- Add navigation entries for `suggestions/`, `docs/playbooks/`, `community/`, and `roadmap/`.

### Phase 2: Validation and publishing

- Add link, Markdown, and frontmatter checks.
- Generate suggestion indexes by status and category.
- Publish the site as static output behind Nginx or through a public docs host.
- Keep the current `nginx/html/index.html` dashboard as the operational control plane.

### Phase 3: Community workflow automation

- Add duplicate suggestion hints.
- Publish periodic digest pages for new, accepted, shipped, and blocked suggestions.
- Connect accepted suggestions to implementation issues and release notes.
- Consider n8n/AFFiNE workflows only after the GitHub-native path is clear and stable.

## Success signals

- Contributors can find historical and active suggestions from one website path.
- New suggestions consistently include required context, impact, validation, and rollback notes.
- Maintainers spend less review time asking for missing information.
- Duplicate proposals decrease because historical overlap is visible.
- Website content can be updated through Markdown pull requests without touching runtime control code.
