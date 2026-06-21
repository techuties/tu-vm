# Website Markdown Publishing System

## Purpose

Create a community-facing website suggestion system that starts from markdown files in this repository, not a custom database or new application stack. This keeps suggestions reviewable in pull requests, searchable in Git, and easy to publish through a static documentation framework later.

## Historical reuse baseline

Before accepting or drafting a new website suggestion, compare it against the existing suggestion archive:

- [`historical-suggestions.md`](./historical-suggestions.md)
- [`website-historical-baseline.md`](./website-historical-baseline.md)
- [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md)
- [`implementation-backlog.md`](./implementation-backlog.md)

The goal is not to create a new suggestion for every repeated idea. The preferred outcome is one of:

1. Update an existing suggestion with new evidence or acceptance criteria.
2. Link related suggestions together and mark one as canonical.
3. Create a new suggestion only when the problem, scope, or implementation path is distinct.

## Recommended publishing model

Use markdown as the source of truth and generate website views from frontmatter.

### Source layout

Recommended future website/docs layout:

```text
docs/
  community/
    suggestions/
      index.md
      how-to-submit.md
      status-board.md
      decisions.md
      implemented.md
      templates/
        suggestion.md
      items/
        SUG-YYYY-NNN-short-title.md
```

The current repository can keep proposal drafts in `suggestions/` until a website/docs framework is adopted. When the website exists, either:

- copy approved pages into `docs/community/suggestions/`, or
- configure the docs framework to read this folder directly.

## Suggestion frontmatter schema

Each individual suggestion page should include a small, stable metadata block:

```yaml
---
id: SUG-YYYY-NNN
title: Short descriptive title
status: draft
theme: community
area: website
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - SUG-YYYY-NNN
source:
  - historical-suggestions
---
```

### Status values

Use a narrow status vocabulary so website indexes remain simple:

- `draft` - proposed but not yet triaged
- `triaged` - reviewed for duplicates and basic fit
- `needs-revision` - useful idea, but missing scope, risks, or acceptance criteria
- `accepted` - approved for implementation planning
- `in-progress` - actively being implemented
- `released` - shipped and linked to changelog/release notes
- `deferred` - valid idea, intentionally postponed
- `rejected` - closed with a documented rationale
- `superseded` - replaced by another canonical suggestion

## Required page structure

Use the same structure for proposal-style website suggestion pages:

1. **Problem**
   - What user, contributor, or maintainer pain does this address?
2. **Historical context**
   - Which existing suggestions, docs, or changelog notes already cover similar ground?
3. **Reuse-first approach**
   - Which existing TU-VM surfaces are reused (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, `helper/uploader.py`, `nginx/html/index.html`, GitHub Issues/PRs)?
4. **Recommended framework or tool**
   - Prefer mature frameworks such as Docusaurus, Astro Starlight, or MkDocs Material for docs pages.
   - Prefer GitHub-native Issues, labels, PR templates, Release Drafter, and CI checks for workflow before adding a custom community app.
5. **Implementation checklist**
   - Concrete changes, in delivery order.
6. **Risks and mitigations**
   - Security, maintenance, moderation, contributor experience, and rollback notes.
7. **Success criteria**
   - Observable outcomes that prove the suggestion helped.

## Website index generation

The first automation should be a local script that reads markdown frontmatter and emits a static index file, for example:

```json
{
  "total": 42,
  "by_status": {
    "draft": 10,
    "accepted": 4,
    "released": 8
  },
  "recent": [
    {
      "id": "SUG-2026-001",
      "title": "Website suggestion status board",
      "status": "accepted",
      "path": "docs/community/suggestions/items/SUG-2026-001-status-board.md"
    }
  ]
}
```

This JSON can power:

- a static `status-board.md` table,
- a dashboard card in `nginx/html/index.html`,
- a future Docusaurus/Astro/MkDocs suggestions page,
- a helper API endpoint if dynamic status is justified later.

## Duplicate detection workflow

Start with deterministic checks before considering semantic search:

1. Normalize file titles, headings, tags, and `related` entries.
2. Compare new suggestions against existing titles and themes.
3. Print the top related files and require the contributor to choose:
   - "extends existing suggestion",
   - "supersedes existing suggestion",
   - "distinct new suggestion".
4. Fail only on exact ID/title collisions; warn on fuzzy similarity.

If community volume grows, Qdrant can be used for semantic similarity because it already exists in the TU-VM stack. Keep that as an enhancement, not a prerequisite.

## Day-to-day maintainer tools

Recommended commands for contributors and maintainers:

- `suggestions validate` - required frontmatter and required section checks
- `suggestions index` - regenerate status/index JSON
- `suggestions related <file>` - show probable duplicates or extensions
- `suggestions promote <id>` - prepare a draft for accepted/in-progress status changes
- `suggestions release <id>` - verify changelog/release links before `released`

These can begin as simple Python scripts under `scripts/` and later be wrapped by `tu-vm.sh` if they become common operator tasks.

## Website framework recommendation

Use this selection rule:

- **Docusaurus** if the priority is versioned docs, sidebars, search, and contributor-friendly markdown pages.
- **Astro Starlight** if the website needs richer landing pages while still keeping strong markdown docs.
- **MkDocs Material** if the team wants the smallest documentation-only stack.

Avoid introducing a custom suggestion service until markdown plus GitHub workflow automation no longer meets the community need.

## Validation gates

Minimum checks before publishing website suggestion pages:

- frontmatter contains required fields,
- markdown links resolve,
- heading hierarchy is consistent,
- status values match the approved vocabulary,
- related suggestion IDs resolve or are explicitly marked external,
- accepted/released suggestions include decision or changelog links,
- no page exposes secrets, private hostnames beyond documented examples, or privileged control endpoints.

## Acceptance criteria

The markdown publishing system is successful when:

- contributors can find, draft, and submit a suggestion without maintainer hand-holding,
- reviewers can identify duplicates before discussion fragments,
- website pages can be generated from repository markdown without copying data by hand,
- released community suggestions are traceable from proposal to PR to changelog,
- the system remains useful even if no custom community application is built.
