# Website Suggestion: Community Suggestions Platform

## Summary

Build a community-based suggestion system for TU-VM by reusing existing project surfaces first:

- GitHub Issues, PRs, labels, Discussions, and Release Drafter for public collaboration.
- Markdown files in `suggestions/` as the durable proposal and decision record.
- A static docs website for browsing suggestions, governance, roadmap, and playbooks.
- The existing `nginx/html/index.html` dashboard for read-only community highlights.
- Helper API extensions only after the Markdown/GitHub workflow proves insufficient.

This is a staged system, not a request to build a custom application on day one.

## Historical scan findings

The existing `suggestions/` folder contains repeated recommendations in four areas:

1. Docs-first website structure around install, operation, security, community, and suggestions.
2. Lightweight governance with duplicate checks, status transitions, owners, and decision rationale.
3. Day-to-day maintainer tools such as doctor checks, smoke tests, release-note helpers, and docs quality gates.
4. Dashboard evolution through modular assets and optional status/community panels.

The constructional recommendation is to consolidate these into a single workflow instead of creating another isolated suggestion store.

## Problem statement

Community collaboration is currently spread across long-form docs, issue templates, prior suggestion files, and dashboard links. Without a clear system:

- duplicate proposals are likely,
- contributors cannot easily see whether an idea is active, accepted, rejected, or shipped,
- maintainers have to manually connect issues, PRs, docs, changelog entries, and dashboard links,
- website improvements risk becoming a custom platform before the process is mature.

## Proposed staged architecture

### Stage 1: Markdown and GitHub as source of truth

Keep suggestion records in repository Markdown and use GitHub for discussion:

- Each canonical suggestion gets one Markdown page under `suggestions/`.
- The page links to related GitHub Issues, PRs, Discussions, and changelog entries.
- Duplicate historical files are merged into the canonical page and listed in `canonical_of`.
- Status changes happen through PR review so decisions are auditable.

Recommended frontmatter:

```yaml
id: website-community-platform
title: Community Suggestions Platform
status: proposed
area: community
owner: maintainers
risk: medium
created: 2026-05-16
updated: 2026-05-16
canonical_of:
  - community-system-suggestions.md
  - community-suggestions-framework.md
discussion: null
```

Recommended body sections:

1. Problem statement
2. Historical context and duplicates reviewed
3. Proposed approach
4. Reused components and frameworks
5. Implementation steps
6. Security, abuse, and resource impact
7. Rollback or disable path
8. Acceptance criteria
9. Success metrics
10. Decision log

### Stage 2: Static website publishing

Publish `suggestions/` through a docs framework such as Docusaurus or MkDocs Material:

- Generate indexes by `status`, `area`, `owner`, and `updated`.
- Add full-text search for proposals, decisions, and playbooks.
- Show "recently changed suggestions" and "accepted next work" pages.
- Link from the existing dashboard and root `README.md`.

This gives the community a website experience while keeping review and history in Git.

### Stage 3: Dashboard community summary

Add a read-only community panel to the existing dashboard after the static records are stable:

- latest accepted suggestions,
- recently implemented suggestions,
- top open requests by issue reactions or label priority,
- links to the docs website, GitHub Issues, and contribution guide.

Implementation should avoid direct browser calls to third-party APIs from private LAN dashboards. Prefer a generated static JSON artifact, build-time data, or a same-origin cached helper endpoint.

### Stage 4: Optional writable helper API

Only add custom helper endpoints if the community needs in-dashboard submission or voting and maintainers are ready to operate abuse controls.

Candidate endpoints:

- `GET /suggestions` - list generated or cached suggestion summaries.
- `GET /suggestions/<id>` - return a single generated record.
- `POST /suggestions` - create a proposal draft after auth and rate-limit checks.
- `POST /suggestions/<id>/vote` - record a signal, never a binding decision.
- `POST /suggestions/<id>/status` - maintainer-only status transition with audit note.

Gate this stage on:

- clear auth model,
- rate limiting and spam handling,
- audit trail,
- backup/restore behavior,
- owner for ongoing moderation.

## Frameworks and tools to reuse

- **Docusaurus or MkDocs Material** for static docs and suggestion pages.
- **GitHub Issues and Discussions** for collaboration instead of custom comment storage.
- **Release Drafter and CHANGELOG.md** for shipped-suggestion closure.
- **Existing docs-links workflow** as the starting point for link checks.
- **Markdown lint and frontmatter validation** for suggestion quality.
- **Existing helper API and Nginx routing** for any eventual read-only dashboard integration.
- **Existing `tu-vm.sh` and scripts** for contributor checks, not a separate CLI.

## Detailed website pages

### Suggestions index

Purpose: show all canonical proposals with filters.

Fields:

- title,
- status,
- area,
- owner,
- risk,
- updated date,
- linked issue/discussion,
- next action.

### Suggestion detail page

Purpose: make one proposal understandable and reviewable.

Required content:

- problem and user impact,
- what existing tools/frameworks are reused,
- implementation outline,
- security and resource impact,
- acceptance criteria,
- validation plan,
- rollback path,
- decision log.

### Governance page

Purpose: explain how the community moves ideas forward.

Content:

- lifecycle states,
- duplicate policy,
- roles and owners,
- decision rubric,
- completion criteria.

### Roadmap page

Purpose: connect suggestions to implementable work.

Content:

- accepted suggestions,
- current priority order,
- dependencies,
- completed and superseded items,
- links to changelog entries when shipped.

### Contributor start page

Purpose: reduce day-to-day friction.

Content:

- how to open a suggestion,
- how to run local checks,
- how to link PRs and issues,
- how to update docs and changelog,
- what validation evidence maintainers expect.

## Duplicate prevention workflow

Before accepting a new suggestion:

1. Search `suggestions/` for the problem area and related terms.
2. Search GitHub Issues and Discussions for matching requests.
3. Check `CHANGELOG.md` for already shipped behavior.
4. If overlap exists, update the canonical suggestion instead of creating a new file.
5. If the new idea is distinct, link nearby historical suggestions in the "Historical context" section.

## Acceptance criteria

- The website can list canonical suggestions by status and area.
- Every canonical suggestion has required fields and a decision log.
- Duplicate historical suggestions are linked or merged into canonical records.
- The dashboard links to the community/suggestions website without changing secure defaults.
- No writable custom API is introduced before auth, rate limiting, audit, and moderation ownership are defined.

## Risks and mitigations

1. **Risk: duplicate Markdown records continue to grow.**
   - Mitigation: require canonical ownership fields and reject new files when an existing canonical page fits.
2. **Risk: website status drifts from GitHub and changelog reality.**
   - Mitigation: generate indexes from source files and require shipped suggestions to link PRs or changelog entries.
3. **Risk: custom voting becomes a popularity contest.**
   - Mitigation: treat votes as advisory input; require security, operations, and maintenance review before acceptance.
4. **Risk: dashboard calls leak private operator traffic.**
   - Mitigation: use same-origin cached/generated data for community summaries.
5. **Risk: docs framework adds maintenance burden.**
   - Mitigation: start static, keep Markdown portable, and avoid framework-specific syntax where plain Markdown works.

## Success metrics

- Fewer duplicate suggestion files or issues over time.
- New contributors can find the suggestion process from the website in two clicks.
- Accepted suggestions include owner, next action, validation path, and rollback notes.
- Implemented suggestions are linked from PRs and `CHANGELOG.md`.
- Dashboard/community links improve discoverability without adding new Tier 1 runtime dependencies.
