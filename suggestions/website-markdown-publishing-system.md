---
title: Website Markdown Publishing System
status: proposed
owner: community-maintainers
source: historical-suggestions
---

# Website Markdown Publishing System

## Purpose

Create a community-focused website system from markdown files first, then add
automation and richer interfaces only where they reduce repeated maintainer work.

This recommendation exists because the project already has many historical
suggestions with the same themes:

- publish a clear website/docs structure;
- keep suggestions public, traceable, and deduplicated;
- reuse mature frameworks instead of building a custom CMS;
- add tools that make daily triage and release work easier.

The goal is not to replace the current TU-VM dashboard. The existing Nginx
landing page, helper API, shell scripts, GitHub workflows, and release notes
remain the operational center of gravity.

## Success state

A successful implementation should let a contributor:

1. Read active, accepted, implemented, and archived suggestions on the website.
2. Understand how to submit a high-quality idea before opening an issue or PR.
3. See whether a similar suggestion already exists.
4. Follow a suggestion from proposal -> decision -> implementation -> changelog.
5. Run local checks that catch broken links, missing metadata, and weak structure.

Maintainers should be able to:

1. Triage suggestions with consistent statuses and labels.
2. Generate website indexes from markdown metadata.
3. Publish community summaries without hand-maintaining duplicate lists.
4. Keep public community pages separate from private runtime control endpoints.

## Reuse-first framework recommendation

### Baseline: markdown as the source of truth

Keep suggestion content in versioned markdown under `suggestions/` and expose the
same content through the website. This keeps review, history, and rollback simple
because Git remains the canonical workflow.

### Primary website option: Docusaurus

Use Docusaurus when the community site is mainly documentation, proposals,
roadmap pages, and release communication.

Why it fits:

- strong markdown and MDX support;
- mature docs navigation, versioning, and search plugins;
- contributor-friendly editing model;
- easy generated sidebars and indexes from metadata.

### Secondary website option: Astro with Starlight

Use Astro with Starlight when the website needs a richer marketing/community
front page while keeping docs fast and static.

Why it fits:

- excellent static output;
- strong component model for cards, dashboards, and community highlights;
- Starlight gives docs structure without building one from scratch.

### Lightweight option: MkDocs Material

Use MkDocs Material if the team wants the smallest operational footprint and a
Python-friendly toolchain.

Why it fits:

- fast setup;
- readable defaults;
- simple markdown navigation;
- low maintenance burden.

### Avoid initially

- A custom CMS for suggestions.
- A new database-backed community service before the markdown workflow proves its
  limits.
- Public endpoints that can affect VM runtime services.
- A full dashboard rewrite just to add community pages.

## Suggested website page set

Publish these pages from markdown, either directly in a docs framework or by
mirroring the existing files into a future `website/` tree.

### `community/suggestions/index.md`

Purpose:

- introduce the suggestion system;
- show current status categories;
- link to how-to-submit, status board, decisions, implemented items, and archive.

Recommended sections:

- what suggestions are for;
- what belongs in an issue versus a suggestion;
- quick links;
- current maintainer review expectations;
- link to historical suggestions.

### `community/suggestions/how-to-submit.md`

Purpose:

- reduce low-context submissions;
- teach contributors how to check for existing work.

Recommended sections:

- search existing suggestions first;
- required suggestion template fields;
- examples of strong proposals;
- examples of extensions to existing ideas;
- security and privacy considerations.

### `community/suggestions/status-board.md`

Purpose:

- make the pipeline visible without manual status posts.

Recommended sections:

- status summary table generated from frontmatter;
- recently updated suggestions;
- items needing maintainer input;
- items needing contributor help;
- link to implementation tasks or PRs.

### `community/suggestions/decisions.md`

Purpose:

- preserve decision rationale.

Recommended sections:

- accepted decisions;
- accepted with changes;
- deferred decisions with reopen conditions;
- rejected decisions with alternatives;
- duplicate items linked to canonical suggestions.

### `community/suggestions/implemented.md`

Purpose:

- connect community input to shipped work.

Recommended sections:

- implemented suggestion summary;
- linked PRs, commits, and changelog entries;
- validation evidence;
- follow-up work.

### `community/roadmap.md`

Purpose:

- show accepted and planned work without promising calendar deadlines.

Recommended sections:

- active implementation themes;
- accepted suggestions grouped by component;
- dependencies and risks;
- recently completed work;
- next recommendations from the backlog.

## Frontmatter contract

Use frontmatter so indexes, dashboards, and checks can be generated without a
custom database.

### Website page metadata

```yaml
title: Community Suggestions - Status Board
description: Public status and progress of community suggestions.
status: active
owner: community-maintainers
last_updated: YYYY-MM-DD
```

### Individual suggestion metadata

```yaml
id: SUG-YYYY-NNN
title: Short actionable title
status: draft
theme: docs
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - SUG-YYYY-NNN
duplicate_of:
decision:
changelog:
```

### Required statuses

Use a small taxonomy so contributors can understand the board quickly:

- `idea`: early, low-structure input;
- `draft`: structured proposal being shaped;
- `review`: ready for maintainer/community feedback;
- `accepted`: approved for implementation;
- `in-progress`: linked implementation is active;
- `implemented`: shipped and linked to release notes;
- `deferred`: useful, but not active;
- `rejected`: closed with rationale;
- `duplicate`: redirected to a canonical suggestion.

## Suggestion template

Every detailed suggestion should include:

1. **Problem**: what user or maintainer pain exists?
2. **Historical overlap**: which existing files, issues, or changelog items were
   checked?
3. **Proposed solution**: what changes and what stays the same?
4. **Reuse plan**: which existing TU-VM components, scripts, workflows, or docs
   should be extended?
5. **Framework/tooling choice**: which mature framework or tool should be used,
   and why?
6. **Security and privacy impact**: does it expose new network, auth, data, or
   secret-handling concerns?
7. **Operational impact**: how does it affect Docker Compose, Nginx, helper API,
   scripts, backups, or upgrades?
8. **Acceptance criteria**: what proves the suggestion is complete?
9. **Rollback path**: how can maintainers safely undo it?
10. **Community value**: how does it help contributors or operators day to day?

## Deduplication workflow

Before accepting a new suggestion:

1. Search titles and headings in `suggestions/`.
2. Search `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, and `docs/`.
3. Compare against the active backlog in `implementation-backlog.md`.
4. Link related items in frontmatter or a "Related suggestions" section.
5. If overlap is high, mark the new item as `duplicate` and link it to the
   canonical suggestion instead of maintaining two threads.

Start with simple keyword matching. Add semantic search later only if keyword
matching becomes noisy at higher volume.

## Day-to-day tooling suggestions

### 1. Suggestion structure checker

Add a script that validates:

- required frontmatter fields;
- required template headings;
- unique suggestion IDs;
- valid status values;
- no unresolved `duplicate_of` references;
- links to local files resolve.

The first version should warn. After the rules stabilize, CI can fail on clear
contract violations.

### 2. Generated suggestion indexes

Generate JSON or markdown indexes grouped by:

- status;
- theme;
- owner;
- recently updated;
- needs decision;
- implemented but missing changelog link.

The website can consume these indexes without adding a new backend service.

### 3. Duplicate hinting

For each new suggestion, print the most similar existing titles and headings.
This gives contributors a useful "extend this existing idea" path.

### 4. Release note linkage

Extend the existing release-note helper pattern so implemented suggestions are
listed in changelog/release output when a PR references a suggestion ID.

### 5. Community dashboard widget

Add a read-only dashboard block only after generated indexes exist. The widget
should show:

- total active suggestions;
- accepted/in-progress/implemented counts;
- items needing maintainer decision;
- latest implemented community item.

Runtime control actions should remain behind existing secured control surfaces.

### 6. AI-assisted review prompts

Use local or project-approved AI assistance to summarize suggestions, highlight
risks, and identify possible duplicates. AI output should remain advisory and
should never make final accept/reject decisions.

## Governance model

### Maintainers

- own final decisions;
- enforce security and operational boundaries;
- merge duplicates into canonical suggestions;
- ensure accepted work has validation and rollback notes.

### Proposal champions

- write or refine the suggestion;
- answer clarifying questions;
- help connect implementation PRs to the original idea.

### Community reviewers

- test proposed workflows;
- identify missing risks;
- suggest framework or tooling alternatives;
- validate that website pages are clear for new contributors.

## Implementation stages

### Stage 0: Normalize the existing folder

- Keep `suggestions/` as the canonical source.
- Reduce future duplicate files by updating hub/index pages first.
- Mark canonical reading paths clearly.

### Stage 1: Add publishing contract

- Adopt frontmatter fields.
- Add suggestion template requirements.
- Add status taxonomy.
- Add dedupe process.

### Stage 2: Add static generation

- Generate status/theme indexes from markdown.
- Publish the indexes through a docs framework.
- Add link checks and metadata checks in CI.

### Stage 3: Add maintainer tooling

- Add duplicate hinting.
- Add release note linkage.
- Add weekly or release-based community digest output.

### Stage 4: Add richer website components

- Add status-board cards, filters, or charts if static pages become hard to
  scan.
- Keep the public community site read-only unless moderation/auth requirements
  are explicitly designed.

## Risks and safeguards

### Risk: suggestion sprawl

Safeguard:

- keep one canonical suggestion for each topic;
- link duplicates instead of copying guidance;
- maintain this publishing-system page as the contract.

### Risk: over-engineering

Safeguard:

- start with markdown and generated static indexes;
- add databases, votes, or APIs only after markdown cannot support the workflow.

### Risk: public/private boundary confusion

Safeguard:

- community pages are public/read-only by default;
- VM runtime control stays behind token and allowlist protections;
- security-sensitive proposals require maintainer review before publication.

### Risk: automation discourages contributors

Safeguard:

- begin with warnings and helpful examples;
- document every rule in plain language;
- allow maintainers to override low-confidence duplicate or quality findings.

## Acceptance criteria for first implementation

- The website page set is documented and linked from the suggestion hub.
- New suggestions follow a consistent frontmatter and template contract.
- A dedupe process is documented before adding new suggestion files.
- At least one generated index can be produced from markdown metadata.
- Link and structure checks run locally and in CI.
- Implemented suggestions can link to a changelog or release note.

## Related existing files

- `suggestions/README.md`
- `suggestions/index.md`
- `suggestions/website-historical-baseline.md`
- `suggestions/website-and-docs-framework.md`
- `suggestions/website-community-pages.md`
- `suggestions/website-day-to-day-tooling.md`
- `suggestions/implementation-backlog.md`
