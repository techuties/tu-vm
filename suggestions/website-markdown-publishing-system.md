---
title: Website Markdown Publishing System
description: Reuse-first proposal for publishing community suggestions as website-ready markdown.
---

# Website Markdown Publishing System

## Objective

Create a markdown-first website publishing system for community suggestions that keeps GitHub as the source of truth, avoids a custom CMS, and makes historical proposals easy to discover before contributors submit new work.

The system should turn files in `suggestions/` and future website docs pages into a navigable community suggestion area with clear status, ownership, decisions, and implementation links.

## Why this is needed

The repository already contains many historical suggestion files. Without a consistent publishing model, contributors can easily:

- Re-submit ideas that already exist.
- Miss the latest canonical recommendation.
- Struggle to tell whether a suggestion is proposed, accepted, shipped, or superseded.
- Force maintainers to manually explain process and status in every thread.

A markdown-first approach keeps the barrier low while still enabling automation.

## Reuse-first framework recommendation

Do not build a custom suggestion app first. Use proven tooling in layers:

1. **Authoring and review:** GitHub Issues, Pull Requests, templates, labels, and CODEOWNERS.
2. **Content source:** Markdown files with frontmatter in `suggestions/` and a future docs website subtree.
3. **Website rendering:** A mature static docs framework when the project is ready for a public website:
   - **Docusaurus** for versioned docs, mature plugins, and strong navigation.
   - **MkDocs Material** for a lightweight Python-based docs site with excellent readability defaults.
   - **Astro Starlight** for a fast modern docs site with flexible content collections.
4. **Search:** Local static search first (Pagefind, Lunr, or framework-native search). Use hosted search only if public traffic and maintenance policy justify it.
5. **Automation:** Small scripts and CI checks that validate markdown metadata, links, and duplicate risk.

This sequence preserves the current GitHub-native workflow while leaving a clean path to a website.

## Canonical content model

Every website-ready suggestion should use a predictable frontmatter block:

```yaml
id: SUG-YYYY-NNN
title: Short action-oriented title
summary: One sentence describing the outcome
status: proposed
theme: community
area: website
owner: unassigned
source:
  - suggestions/historical-suggestions.md
related:
  - suggestions/website-community-pages.md
risk_level: low
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
decision: pending
implementation_links: []
```

Recommended status values:

- `draft` - not ready for review.
- `proposed` - ready for triage.
- `triaged` - reviewed for scope, duplicates, and risk.
- `accepted` - approved for implementation.
- `in_progress` - implementation has started.
- `shipped` - delivered and linked to release notes or changelog.
- `deferred` - valid but not currently planned.
- `superseded` - replaced by a newer canonical suggestion.

## Required markdown sections

Use this structure for individual suggestion pages:

1. `## Problem`
   - What pain point exists today?
   - Who is affected?
2. `## Existing work and historical references`
   - Which files, issues, or changelog entries already mention this?
   - Which related suggestions should readers review first?
3. `## Recommended approach`
   - What should be implemented?
   - Which existing framework or project capability should be reused?
4. `## Community workflow impact`
   - How does this help contributors, maintainers, or operators?
5. `## Implementation outline`
   - Concrete tasks, affected paths, and integration points.
6. `## Risks and guardrails`
   - Security, privacy, maintenance, and compatibility concerns.
7. `## Acceptance criteria`
   - Verifiable conditions that show the suggestion is complete.
8. `## Decision log`
   - Dates, decisions, rationale, and links.

## Suggested website pages

Publish the community suggestion system as a small website section:

| Page | Purpose | Source of truth |
|---|---|---|
| `community/suggestions/index.md` | Overview, lifecycle, and quick links | Generated from markdown metadata |
| `community/suggestions/how-to-submit.md` | Contributor guide and quality checklist | `CONTRIBUTING.md` + suggestion template |
| `community/suggestions/status-board.md` | Current suggestions grouped by status | Generated index from frontmatter |
| `community/suggestions/decisions.md` | Accepted, rejected, deferred, and superseded rationale | Decision log entries |
| `community/suggestions/implemented.md` | Shipped community ideas with release links | `CHANGELOG.md` + release notes |
| `community/suggestions/history.md` | Historical patterns and superseded duplicates | `suggestions/historical-suggestions.md` |

Keep pages short and link to implementation details instead of duplicating long technical docs.

## Dedupe workflow

Before adding a new suggestion:

1. Search `suggestions/` for similar titles, themes, and keywords.
2. Check the generated status board for accepted or shipped work.
3. If a similar proposal exists, update the existing page or add a "supersedes" relationship.
4. Only create a new file when the problem, approach, or affected subsystem is materially different.

For maintainers, triage should record one of these outcomes:

- **Merged with existing suggestion:** Link to the canonical page.
- **Split into separate suggestion:** Explain the new boundary.
- **Accepted as unique:** Assign owner, status, and next action.
- **Deferred or rejected:** Capture rationale and re-open conditions.

## Automation suggestions

Add lightweight checks before adding services or complex dashboards:

- Validate required frontmatter fields and status values.
- Generate a machine-readable `suggestions-index.json` from markdown.
- Detect duplicate or near-duplicate titles.
- Check that all `related` paths exist.
- Require a decision entry before moving to `accepted`, `deferred`, `rejected`, or `superseded`.
- Require changelog or release links before moving to `shipped`.
- Render status counts for a dashboard or docs landing page.

These checks can start as a small Python script in `scripts/` and later feed a docs website or helper API endpoint.

## Day-to-day contributor tools

To reduce maintenance load, provide:

- A `new-suggestion` template with the required frontmatter and section headings.
- A local validation command wrapped by the existing pre-push workflow.
- A generated "related suggestions" list for each proposal.
- A maintainer triage checklist for labels, owner, risk, and decision state.
- A release-note helper section that lists shipped suggestion IDs.

The goal is to make high-quality suggestions easy and low-quality duplicates less likely.

## Community governance guardrails

This publishing system should preserve TU-VM's security and operations posture:

- No suggestion should silently weaken private-by-default behavior.
- Website content should clearly mark experimental, accepted, and shipped work.
- Major changes should link to an RFC-lite decision record.
- Community recognition should include docs, testing, triage, and operations contributions, not only code.
- Automation should assist maintainers without making irreversible decisions.

## Implementation outline

1. Mark canonical historical files in `suggestions/README.md` and `suggestions/index.md`.
2. Adopt the frontmatter schema for new or substantially revised suggestion pages.
3. Add a suggestion template and validation script.
4. Generate a status-board markdown page or JSON file from metadata.
5. Add website navigation once a docs framework is selected.
6. Link shipped suggestion IDs from `CHANGELOG.md` or release notes.

## Acceptance criteria

- Contributors can find the canonical suggestion index from the repository README or docs navigation.
- Every website-ready suggestion has status, theme, source, related links, and acceptance criteria.
- Duplicate submissions are routed to existing suggestions with a clear rationale.
- Shipped suggestions link to release notes, changelog entries, or merged PRs.
- The system works as plain markdown in GitHub before any static site framework is adopted.
