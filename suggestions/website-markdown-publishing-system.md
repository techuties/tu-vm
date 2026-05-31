---
title: Website Markdown Publishing System
description: A reuse-first proposal for publishing community suggestions as website-ready markdown without creating a parallel ticket system.
status: draft
source: historical community-suggestions branches
---

# Website Markdown Publishing System

## Summary

Create a markdown-first publishing system for community suggestions that can work today in GitHub and later feed a docs website without reauthoring content. The system should reuse the repository's existing GitHub Issues, `CONTRIBUTING.md`, playbooks, CI checks, helper dashboard, and `suggestions/` history instead of building a custom suggestions application.

The goal is not to replace Issues. Issues remain the live intake and discussion channel. Markdown pages provide the durable, curated website layer: accepted patterns, decision rationale, implementation guidance, and reusable templates.

## Problems to solve

- Historical suggestions are spread across many similarly named files, making it hard for contributors to know which guidance is canonical.
- New contributors need a simple way to check prior thinking before opening another proposal.
- Website-ready suggestion pages need consistent metadata so a future static site can generate indexes, status pages, and search facets.
- Maintainers need a lightweight process that improves quality without adding another manual queue.
- Day-to-day operators need links from the landing dashboard and README to the right suggestion entry points.

## Existing project surfaces to reuse

Use these before introducing new infrastructure:

- `suggestions/` as the historical and canonical proposal library.
- GitHub Issues and issue templates as the live intake path.
- `CONTRIBUTING.md` for labels, review expectations, and release linkage.
- `docs/playbooks/README.md` for operator runbooks with stable anchors.
- `nginx/html/index.html` for dashboard links to community entry points.
- Existing validation scripts such as `scripts/pre-push-check.sh`, `scripts/smoke-test.sh`, and `scripts/validate_status_full_contract.py`.
- Existing GitHub Actions for CI, docs link checks, Trivy config scanning, Release Drafter, stale automation, and Dependabot.

## Recommended framework path

### Phase A: GitHub-rendered markdown

Start with plain markdown in this repository:

- Keep canonical proposal pages in `suggestions/`.
- Add frontmatter to pages that should be publishable later.
- Link the hub from `README.md` and the dashboard.
- Keep Issues as the active discussion and triage system.

This path has the lowest maintenance cost and works immediately for contributors.

### Phase B: Static docs site

When the project wants a standalone website, use a mature docs framework rather than a custom renderer.

Recommended options:

1. **Docusaurus**
   - Strong markdown and MDX support.
   - Built-in versioning and mature plugin ecosystem.
   - Good fit if the project wants docs, blog-style updates, generated sidebars, and search.
2. **MkDocs Material**
   - Simple markdown authoring flow.
   - Fast local preview and strong readability defaults.
   - Good fit if the site should stay lightweight and mostly documentation-oriented.
3. **Astro Starlight**
   - Modern static-site architecture.
   - Strong docs UX with flexible component options.
   - Good fit if the project later wants richer landing pages around the docs.

Avoid a custom website framework until an existing framework blocks a concrete requirement.

## Suggested website information architecture

Future website paths can map directly to the existing repository content:

```text
community/
  suggestions/
    index.md
    how-to-submit.md
    status-board.md
    decisions.md
    implemented.md
operations/
  playbooks/
    safe-update.md
    recovery.md
    pihole-tailscale.md
    mcp-smoke.md
project/
  roadmap.md
  changelog.md
```

In the current repository, those pages should be represented by curated markdown in `suggestions/` and links to existing docs. Do not duplicate full playbooks into suggestions; link to `docs/playbooks/README.md` until a docs framework exists.

## Canonical suggestion metadata

Use this frontmatter for website-publishable suggestion pages:

```yaml
---
title: Short human-readable title
description: One sentence summary for indexes and search results.
status: draft
theme: community
impact: medium
owner: maintainers
source: historical community-suggestions branches
updated: YYYY-MM-DD
---
```

Recommended `status` values:

- `draft`: written proposal that still needs maintainer review.
- `triaged`: reviewed for duplicates and basic fit.
- `accepted-for-trial`: approved for a limited implementation.
- `implemented`: shipped and linked to release notes or a changelog entry.
- `deferred`: valid idea, not active now.
- `rejected`: not planned, with rationale and alternatives.
- `superseded`: replaced by a newer canonical page.

Recommended `theme` values:

- `website`
- `community`
- `operations`
- `automation`
- `security`
- `developer-experience`
- `docs`

## Standard page sections

Each detailed suggestion should include:

1. **Summary** - What changes and why.
2. **Problem** - The contributor or operator pain being solved.
3. **Historical reuse** - Existing suggestions, docs, scripts, workflows, or external frameworks being reused.
4. **Proposed approach** - The concrete implementation path.
5. **Alternatives considered** - Especially mature frameworks or existing project surfaces.
6. **Impact and risks** - Security, privacy, maintenance, UX, and operational effects.
7. **Rollout stages** - Small, reversible implementation steps.
8. **Validation** - Static checks, smoke tests, docs checks, or manual review evidence.
9. **Ownership** - Maintainer area, reviewers, and community champion if known.
10. **Success signals** - Observable outcomes such as fewer duplicate issues or faster contributor onboarding.

## Duplicate-avoidance workflow

Before adding a new suggestion page:

1. Search `suggestions/` for related terms.
2. Check `implementation-backlog.md` for open or completed work.
3. Check `CHANGELOG.md` and recent releases for shipped work.
4. Check open GitHub Issues for active discussion.
5. Extend the closest canonical page if the idea is a refinement.
6. Create a new page only when the topic introduces a distinct decision or implementation track.

If a duplicate historical page must remain for traceability, add a short note at the top:

```markdown
> Status: superseded by [Canonical page title](./canonical-page.md).
```

## Day-to-day tooling suggestions

These tools reduce maintainer and contributor friction while staying compatible with the current Compose-based repository:

- **Markdown linting**: Add markdownlint with a narrow, documented rule set for root policy docs, `docs/`, and canonical `suggestions/` pages.
- **Link checking**: Keep using the existing docs link workflow; expand coverage as the website grows.
- **Frontmatter validation**: Add a small script or docs-framework plugin to ensure publishable suggestion pages include required fields.
- **Suggestion index generation**: Generate indexes by status/theme once frontmatter is consistent.
- **Local preview**: If a static site is adopted, provide one command for docs preview through `make`, `just`, or an npm script.
- **Issue-to-doc linkage**: Require accepted suggestion pages to link to their tracking issue or implementation PR.
- **Dashboard links**: Keep the landing page pointed at the canonical hub, Issues, CONTRIBUTING, playbooks, releases, and changelog.

## Community workflow

Recommended lifecycle:

1. Contributor opens an Issue using the suggestion template.
2. Maintainers check for overlap with existing suggestion pages.
3. If the idea needs durable design detail, a markdown suggestion page is added or updated.
4. Review happens on the Issue or PR.
5. Accepted work links to implementation tasks.
6. Shipped work updates the suggestion status, changelog/release notes, and any dashboard links if needed.

This keeps discussion in GitHub while giving the website a clean, reviewed knowledge layer.

## Acceptance criteria

- `suggestions/README.md` identifies the canonical suggestion set and explains that duplicate files are historical drafts unless linked from the hub.
- `README.md` links to the suggestions hub next to Issues, CONTRIBUTING, and playbooks.
- The landing dashboard links to the suggestion history/hub for operators and contributors.
- Future website-publishable suggestion pages use consistent frontmatter and required sections.
- New proposal pages demonstrate reuse of existing frameworks or project surfaces before suggesting custom code.

## Risks and controls

- **Risk: another source of truth.** Control by keeping Issues as live intake and markdown as curated history/design.
- **Risk: duplicated proposal pages.** Control with the duplicate-avoidance workflow and a canonical hub.
- **Risk: static-site maintenance burden.** Control by staying markdown-only until a docs framework has clear value.
- **Risk: stale statuses.** Control by linking accepted suggestions to Issues/PRs and reviewing status during release-note preparation.

## Next implementation steps

1. Link this page from the suggestions hub.
2. Add a visible suggestions link to the README and dashboard.
3. Gradually add `superseded` notes to duplicate historical files as they are touched.
4. Add frontmatter validation after the canonical pages settle.
5. Decide between Docusaurus, MkDocs Material, and Astro Starlight only when publishing beyond GitHub-rendered markdown becomes necessary.
