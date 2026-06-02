# Website Markdown Publishing System

## Purpose

Create a community-facing website publishing model where suggestions are easy to write, review, publish, and maintain as markdown. The goal is to reuse mature documentation frameworks and GitHub workflows instead of building a custom suggestion platform from scratch.

This recommendation treats `suggestions/` as the historical proposal archive and uses a future docs website as the public reading surface.

## Existing work to reuse

The repository already has several surfaces that should remain the source of truth:

- `suggestions/` for historical and active proposal material.
- `README.md`, `QUICK_REFERENCE.md`, and `CHANGELOG.md` for project narrative, command reference, and release history.
- `CONTRIBUTING.md`, issue templates, and the pull request template for GitHub-native intake.
- `docs/playbooks/` for operator recipes that can be linked from suggestion outcomes.
- `nginx/html/index.html` for the current local dashboard and high-value community links.

Do not duplicate this information in a separate database until the markdown-first workflow becomes a bottleneck.

## Framework recommendation

### Primary path: Docusaurus

Use Docusaurus when the project wants a community documentation site with strong markdown authoring, sidebars, versioning, plugin support, and familiar contribution patterns.

Recommended use:

- Publish proposal pages from markdown.
- Generate navigation from a small sidebar config.
- Add local search once content grows.
- Preserve GitHub pull requests as the review mechanism.

### Secondary path: Astro Starlight

Use Astro Starlight if the site needs more flexible marketing or landing-page composition while keeping docs content markdown-first.

Recommended use:

- Keep docs and suggestion pages in content collections.
- Add typed frontmatter validation.
- Use static output behind Nginx.

### Lightweight fallback: MkDocs Material

Use MkDocs Material if the team wants the fastest docs-only path with very low JavaScript overhead.

Recommended use:

- Publish operational docs and suggestion pages quickly.
- Keep customization minimal.
- Use built-in navigation and search features.

## Suggested source layout

Keep the proposal archive and website content clearly separated:

```text
suggestions/
  README.md
  website-historical-baseline.md
  website-markdown-publishing-system.md
  website-community-framework.md
  website-contributor-tooling.md
  website-roadmap-from-historical-suggestions.md

docs/
  community/
    suggestions/
      index.md
      how-to-submit.md
      status-board.md
      decisions.md
      implemented.md
```

The `suggestions/` folder remains the planning and historical baseline. The `docs/community/suggestions/` pages become the polished website-facing version once a static site framework is introduced.

## Website markdown page inventory

### `docs/community/suggestions/index.md`

Purpose:

- Explain how community suggestions work.
- Link to active, accepted, deferred, rejected, and implemented suggestions.
- Point readers to the historical baseline before they submit a new idea.

Required sections:

- What suggestions are for.
- How to submit.
- How review works.
- Where to see decisions.
- Recently implemented ideas.

### `docs/community/suggestions/how-to-submit.md`

Purpose:

- Help contributors submit high-signal, non-duplicative suggestions.

Required sections:

- Dedupe checklist.
- Required proposal fields.
- Good example.
- Weak example and how to improve it.
- Security and resource-impact reminders.

### `docs/community/suggestions/status-board.md`

Purpose:

- Show where proposals are in the lifecycle.

Required sections:

- Status definitions.
- Active proposal table.
- Accepted proposal table.
- Deferred or rejected proposal table.
- Last review date.

### `docs/community/suggestions/decisions.md`

Purpose:

- Keep decision rationale visible so contributors do not repeat settled debates.

Required sections:

- Decision ID.
- Proposal link.
- Outcome.
- Rationale.
- Reopen conditions.
- Related release or changelog link.

### `docs/community/suggestions/implemented.md`

Purpose:

- Show community impact by connecting shipped work back to the original proposal.

Required sections:

- Implemented suggestion.
- What changed.
- Validation evidence.
- Release or changelog link.
- Follow-up opportunities.

## Frontmatter schema

Use frontmatter so the website can generate indexes without custom data stores.

### Standard website page frontmatter

```yaml
title: Community Suggestions
description: How TU-VM community suggestions are proposed, reviewed, and tracked.
owner: maintainers
status: published
last_updated: YYYY-MM-DD
```

### Individual suggestion frontmatter

```yaml
id: SUG-YYYY-NNN
title: Short suggestion title
status: draft
area: docs
impact: medium
risk: low
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related_issue: URL-or-blank
related_pr: URL-or-blank
```

Allowed statuses:

- `draft`
- `triage`
- `accepted`
- `in-progress`
- `implemented`
- `deferred`
- `rejected`
- `superseded`

## Suggestion quality template

Every proposal should include:

1. Problem statement.
2. Current state and existing work reviewed.
3. Proposed change.
4. Frameworks or tools to reuse.
5. Security and privacy impact.
6. Resource impact.
7. Implementation outline.
8. Rollback or disable path.
9. Validation plan.
10. Success metrics.

This keeps the community system practical and reviewable without creating heavyweight governance.

## Automation and day-to-day tooling

Start with small checks that help contributors immediately:

1. Markdown link check for `docs/`, `suggestions/`, and root policy files.
2. Required-frontmatter validation for website suggestion pages.
3. Duplicate-title check across active suggestions.
4. Generated status index grouped by frontmatter status.
5. Release-note helper prompt for implemented suggestions.
6. Optional docs preview command once a static site framework exists.

Prefer commands that are easy for agents and humans to run:

```bash
./scripts/docs-check.sh
./scripts/suggestion-index.sh --check
./scripts/suggestion-index.sh --write
```

These scripts do not need to exist before the website framework is selected, but their interface should stay simple, deterministic, and CI-friendly.

## Community workflow

### Intake

- Contributors open a GitHub issue with the suggestion template.
- Maintainers or stewards check for duplicates against `suggestions/` and the website status board.
- Accepted proposals receive a stable suggestion ID.

### Review

- Low-risk docs or copy improvements use the normal pull request path.
- Changes affecting security, networking, backups, service controls, or exposed APIs use the RFC-lite fields from `website-community-framework.md`.
- Reviewers require validation evidence before moving a proposal to implemented.

### Publication

- Draft proposal material can begin in `suggestions/`.
- Website-ready material moves to `docs/community/suggestions/`.
- Implemented proposals link to `CHANGELOG.md` or release notes.

## Accessibility and UX requirements

Website markdown pages should be readable and navigable for a broad community:

- Use one `h1` per page and a logical heading hierarchy.
- Use descriptive link text.
- Keep status labels text-based, not color-only.
- Keep tables narrow enough for mobile layouts.
- Provide alt text for images or diagrams.
- Prefer short sections with clear next actions.

## Implementation stages

### Stage 1: Consolidate proposal history

- Keep `suggestions/README.md` and `suggestions/index.md` as the canonical archive entry points.
- Link this publishing-system proposal from both hub files.
- Mark duplicate older proposals as historical context rather than new direction when practical.

### Stage 2: Add website-ready markdown pages

- Create the `docs/community/suggestions/` page set.
- Add frontmatter to each page.
- Link from the main docs or dashboard community area.

### Stage 3: Choose and configure the docs framework

- Select Docusaurus, Astro Starlight, or MkDocs Material using the criteria above.
- Generate a static site that Nginx can serve.
- Keep GitHub pull requests as the publishing approval path.

### Stage 4: Add validation and generated indexes

- Add markdown link checking.
- Validate required frontmatter.
- Generate status-board content from frontmatter.
- Fail CI on broken internal links or invalid suggestion metadata.

### Stage 5: Connect implemented suggestions to releases

- Link implemented pages to release notes and `CHANGELOG.md`.
- Add release-note helper prompts for community impact.
- Publish periodic retrospectives from implemented suggestion data.

## Acceptance criteria

The markdown publishing system is successful when:

- Contributors can find the suggestion process from the website in two clicks or fewer.
- A new suggestion can be checked for duplicates against visible historical and active proposal pages.
- Accepted, deferred, rejected, and implemented proposals have visible rationale.
- Website pages can be updated through normal pull requests.
- CI catches broken links and invalid suggestion metadata.
- Implemented suggestions link back to validation evidence and release notes.
