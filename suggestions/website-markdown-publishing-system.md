# Website Markdown Publishing System

## Purpose

Create a community-first website content system that uses Markdown as the source of truth for documentation, suggestions, decisions, and operational guidance.

This suggestion consolidates the repeated historical recommendations into one publishing model so the project does not build a custom community platform before exhausting mature, well-supported tools.

## Historical context reused

Prior suggestions repeatedly converged on the same direction:

- Keep the existing dashboard and helper API as operational surfaces.
- Add a docs-first website layer for install, operations, security, community, and suggestions.
- Use GitHub Issues and pull requests for intake and review.
- Store durable proposal history in version-controlled Markdown.
- Add automation for linting, link checks, indexes, and duplicate detection before adding new services.

The publishing system should therefore extend:

- `README.md` for the long-form project narrative.
- `QUICK_REFERENCE.md` for command lookup.
- `CHANGELOG.md` for release history.
- `CONTRIBUTING.md` for contributor workflow.
- `docs/playbooks/` for operator recipes.
- `suggestions/` for reusable proposal history.
- `nginx/html/index.html` for the existing landing/dashboard entrypoint.

## Recommended website framework

### Primary recommendation: Docusaurus

Docusaurus is the best fit when the project wants a public community docs site with minimal custom work:

- Markdown-native authoring with frontmatter.
- Versioned docs and sidebars for release-aligned documentation.
- Mature plugin ecosystem for search, sitemap generation, and edit links.
- Familiar contribution flow for open-source contributors.
- Static output that can be served behind the existing Nginx layer.

### Secondary option: Astro with Starlight

Astro with Starlight is a strong alternative if the website needs more marketing-style pages or custom content layouts alongside docs.

Use it if the project expects rich landing pages, showcases, or custom UI blocks to become as important as the docs themselves.

### Lightweight option: MkDocs Material

MkDocs Material remains a good fallback if the team wants a Python-centered, low-maintenance docs site with excellent readability defaults.

### Selection rule

Choose Docusaurus unless a concrete requirement needs richer custom page composition. This keeps the first implementation focused on docs quality, proposal history, and contributor workflow instead of website framework exploration.

## Proposed website structure

Use one docs tree and one suggestions source of truth:

```text
docs/
  getting-started/
  operations/
  security/
  community/
  suggestions/
suggestions/
  README.md
  website-historical-baseline.md
  website-markdown-publishing-system.md
  website-information-architecture.md
  website-community-framework.md
  website-contributor-tooling.md
  implementation-backlog.md
```

The `docs/suggestions/` pages should be generated from, or manually synchronized with, the durable proposal records in `suggestions/`. The repository should avoid maintaining separate, conflicting proposal histories.

## Website Markdown page set

### `docs/suggestions/index.md`

Purpose:

- Explain how suggestions move from idea to implementation.
- Link to the active GitHub Issues view for new proposals.
- Link to accepted, deferred, rejected, and implemented suggestions.
- Point contributors to the historical baseline before they submit.

Suggested sections:

- What counts as a constructive suggestion.
- How to check whether an idea already exists.
- Current lifecycle states.
- Links to proposal template, status board, decision log, and backlog.

### `docs/suggestions/how-to-submit.md`

Purpose:

- Help contributors write complete, actionable suggestions.
- Reduce maintainer follow-up on missing context.
- Encourage extension of existing work instead of duplicate proposals.

Suggested sections:

- Before submitting: search Issues, `suggestions/`, `CHANGELOG.md`, and docs.
- Required fields: problem, current state, proposal, implementation path, risks, validation, rollback.
- What makes a suggestion community-friendly.
- Examples of a strong proposal and a duplicate that should be merged into an existing item.

### `docs/suggestions/status-board.md`

Purpose:

- Provide a human-readable snapshot of suggestion progress.
- Keep community members from guessing whether an idea is active.

Suggested fields:

- ID
- Title
- Status
- Theme
- Owner or reviewer group
- Last updated
- Decision or implementation link

The page can start as hand-maintained Markdown and later become generated from frontmatter or GitHub labels.

### `docs/suggestions/decisions.md`

Purpose:

- Preserve why important suggestions were accepted, deferred, rejected, or superseded.
- Prevent the community from re-litigating decisions without new evidence.

Suggested decision entry:

```markdown
## DEC-YYYY-NNN: Short decision title

- **Status:** accepted | deferred | rejected | superseded
- **Related suggestion:** SUG-YYYY-NNN
- **Decision owner:** maintainer or subsystem group
- **Context:** what problem was evaluated
- **Decision:** what was chosen
- **Alternatives considered:** what was not chosen and why
- **Review trigger:** what new information would justify revisiting
```

### `docs/suggestions/implemented.md`

Purpose:

- Show visible community impact.
- Link shipped suggestions to releases, PRs, and validation evidence.

Suggested sections:

- Recently shipped suggestions.
- Operational impact.
- Screenshots or command output where relevant.
- Release or changelog links.

## Frontmatter schema

Use consistent metadata for all durable suggestion records:

```yaml
---
id: SUG-YYYY-NNN
title: Short descriptive title
status: draft
theme: docs
impact: medium
risk: low
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
supersedes: []
related_issues: []
related_prs: []
---
```

Recommended status values:

- `draft`
- `triage`
- `accepted`
- `in-progress`
- `implemented`
- `deferred`
- `rejected`
- `superseded`

Recommended themes:

- `docs`
- `community`
- `operations`
- `security`
- `dashboard`
- `automation`
- `release`

## Proposal body template

Every website-published suggestion should include:

1. Problem statement.
2. Current state and reused project assets.
3. Proposed change.
4. Frameworks or tools considered.
5. Implementation outline.
6. Security, privacy, and resource impact.
7. Rollback or disable path.
8. Success criteria.
9. Open questions.

This structure keeps suggestions useful for maintainers and approachable for community contributors.

## Automation recommendations

### Required first checks

- Markdown lint with a narrow project rule set.
- Link checking for root docs, `docs/`, and canonical suggestion files.
- Frontmatter validation for required suggestion fields.
- Duplicate title and keyword hints against existing `suggestions/` files.

### Useful follow-up tools

- Generated suggestion index grouped by status and theme.
- "Recently updated suggestions" page from Git history or frontmatter.
- Release-note reminder when a suggestion reaches `implemented`.
- Accessibility checks for generated website pages.
- Optional local docs preview command through an existing script or task runner.

### Tools to prefer before custom services

- Docusaurus plugins for docs, search, and edit links.
- GitHub Issue forms for public intake.
- GitHub labels and saved views for triage.
- Existing scripts for smoke checks and release helpers.
- Existing helper API and dashboard announcement patterns for surfaced status.

Avoid building a separate voting system, custom moderation portal, or new database until GitHub-native and Markdown-native workflows are clearly insufficient.

## Governance model

Use two lanes:

### Fast lane

For low-risk docs, wording, link, and small UX improvements:

- Issue or PR can be enough.
- Reviewer verifies clarity and consistency.
- Changelog entry is optional unless user-facing behavior changes.

### Proposal lane

For new services, network behavior, security posture, dashboard controls, data retention, or automation that changes operator behavior:

- Durable Markdown suggestion required.
- Risk and rollback sections required.
- Subsystem owner or maintainer review required.
- Decision entry required when accepted, rejected, or superseded.

## Anti-duplication rules

Before adding another website/community/framework file:

1. Check whether the idea belongs in `website-markdown-publishing-system.md`, `website-information-architecture.md`, `website-community-framework.md`, `website-contributor-tooling.md`, or `implementation-backlog.md`.
2. Search for the problem statement, not only the proposed solution.
3. Prefer extending an existing suggestion with a new "Alternative" or "Decision" section.
4. Mark obsolete proposals as `superseded` instead of leaving parallel guidance active.
5. Keep one canonical index in `suggestions/README.md`.

## Implementation sequence

### Stage 1: Canonical content model

- Confirm Docusaurus as the default docs framework.
- Add the suggestion frontmatter schema.
- Publish the website suggestion page set as Markdown.
- Update `suggestions/README.md` as the canonical hub.

### Stage 2: Quality gates

- Add Markdown linting for root docs, `docs/`, and canonical suggestion files.
- Add link checks for website-published pages.
- Add frontmatter validation for suggestion records.

### Stage 3: Static site integration

- Scaffold the docs website.
- Import existing playbooks and community pages.
- Serve generated static output behind the existing Nginx path.
- Add edit links back to repository Markdown.

### Stage 4: Community visibility

- Generate status and implemented-suggestion pages from metadata.
- Surface selected suggestion status on the existing dashboard using current announcement patterns.
- Link shipped suggestions to releases and changelog entries.

## Acceptance criteria

- Contributors can find how to submit suggestions from the website navigation.
- Suggestion pages use one consistent metadata schema.
- Historical suggestions are searchable and linked from the canonical hub.
- Duplicate proposals can be identified before maintainers review them.
- Website content can be previewed and checked locally.
- The docs site can be served as static files without weakening LAN-first and secure-by-default behavior.

