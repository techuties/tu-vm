# Website Markdown Publishing System

## Purpose

Create a reusable markdown-first publishing model for community suggestions, website content, and day-to-day contributor guidance. The system should reuse the existing repository, GitHub workflow, dashboard, helper API, and documentation files before introducing new services.

This proposal consolidates recurring historical suggestions into one implementation contract so future website work can use proven frameworks instead of rebuilding a custom content management system.

## Historical suggestions reused

The existing `suggestions/` archive repeatedly recommends:

- A community-facing website or docs section for proposals and decisions
- Markdown source files with consistent metadata
- A public suggestion lifecycle, status board, and decision log
- Automation that reduces maintainer triage and release-note work
- Framework reuse through Docusaurus, Astro/Starlight, MkDocs Material, GitHub labels, n8n, AFFiNE, and existing TU-VM scripts

This document turns those repeated ideas into a single source-of-truth publishing contract.

## Recommended architecture

### 1) Keep the current operational dashboard

Do not replace `nginx/html/index.html` or the helper API with a new website stack. The existing dashboard is the operator control plane and should stay focused on local status, controls, playbook links, and safe LAN-first interactions.

The community website should complement it by publishing:

- Suggestion intake guidance
- Active and historical suggestion indexes
- Governance and review standards
- Implementation decisions
- Contributor playbooks and reusable tools

### 2) Use markdown as the canonical source

Store proposal content as plain markdown with structured frontmatter. Markdown keeps reviews simple, works in GitHub before any website is deployed, and can later be rendered by Docusaurus, Astro/Starlight, MkDocs Material, or another static site generator.

Recommended source locations:

```text
suggestions/                         # Historical and planning source of truth
docs/community/                      # Contributor guides and governance
docs/playbooks/                      # Day-to-day operator/contributor workflows
website/ or docs-site/               # Optional generated/static site source
```

### 3) Prefer a mature static-site framework

Recommended default: **Docusaurus**.

Use it when the main need is versioned docs, sidebars, search, markdown pages, and low-friction contributor pull requests.

Acceptable alternatives:

- **Astro + Starlight** when the website needs richer custom landing pages while staying markdown-first.
- **MkDocs Material** when the maintainers prefer a lightweight Python documentation stack.

Avoid building a custom renderer unless a mature framework cannot meet a clearly documented requirement.

## Website markdown page set

The community website should publish these markdown pages first:

### `community/suggestions/index.md`

Purpose:

- Explain what constructive suggestions are for
- Link to historical suggestions before users submit a new one
- Show the lifecycle from proposal to shipped change
- Link to active GitHub issue/discussion views

Required sections:

- Why suggestions matter
- Before you submit
- Suggestion lifecycle
- Where decisions are recorded
- Links to accepted, deferred, shipped, and historical suggestions

### `community/suggestions/how-to-submit.md`

Purpose:

- Help contributors write high-signal suggestions
- Reduce duplicate submissions
- Make security and rollback expectations explicit

Required sections:

- Problem statement
- Existing historical suggestion checked
- Proposed approach
- Alternatives considered
- Operational impact
- Security/privacy impact
- Rollout and rollback notes
- Validation plan

### `community/suggestions/status-board.md`

Purpose:

- Provide a human-readable suggestion pipeline
- Show current status without requiring maintainers to write manual updates

Recommended statuses:

- `draft`
- `triage`
- `accepted`
- `in-progress`
- `shipped`
- `deferred`
- `rejected`
- `superseded`

### `community/suggestions/decisions.md`

Purpose:

- Preserve why suggestions were accepted, deferred, rejected, or merged with older work
- Prevent repeated architectural debates

Each decision entry should include:

- Decision ID
- Related suggestion IDs or files
- Decision outcome
- Rationale
- Alternatives considered
- Reopen conditions, if deferred or rejected

### `community/suggestions/implemented.md`

Purpose:

- Show community members that suggestions lead to shipped work
- Connect releases, pull requests, and changelog entries back to original ideas

Each entry should include:

- Suggestion title and ID
- What changed
- Release or changelog reference
- Validation evidence
- Follow-up opportunities

## Suggestion frontmatter schema

Use consistent metadata for every proposal-style markdown file:

```yaml
id: SUG-YYYY-NNN
title: Short descriptive title
status: draft
area: website
priority: medium
owner: unassigned
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
related:
  - suggestions/historical-suggestions.md
tags:
  - community
  - tooling
  - docs
```

Recommended status values:

- `draft`: idea is being shaped
- `triage`: maintainers are checking fit and duplicates
- `accepted`: ready for implementation planning
- `in-progress`: actively being implemented
- `shipped`: delivered and linked to release evidence
- `deferred`: valid idea, not currently scheduled
- `rejected`: not aligned with project goals or safety posture
- `superseded`: merged into another suggestion

## Day-to-day tooling suggestions

### Suggestion validator

Add a small script that validates:

- Required frontmatter fields
- Allowed status values
- Unique suggestion IDs
- Presence of problem, approach, risks, and validation sections
- Internal markdown links

This can start as a repository script before being wired into CI.

### Suggestion index generator

Generate machine-readable indexes from markdown frontmatter:

- `suggestions-by-status.json`
- `suggestions-by-area.json`
- `recently-updated-suggestions.json`

The helper API or static site can consume these files later without changing the markdown source format.

### Duplicate suggestion helper

Before a contributor submits a new idea, provide a lightweight search helper that compares title, tags, and keywords against existing suggestion files. The output should recommend related files rather than blocking submission.

### Release note helper integration

Extend the existing release-note workflow so shipped suggestions can appear under a community section:

- Suggestion ID
- Contributor attribution when appropriate
- Pull request or changelog link
- Follow-up suggestion links

### Maintainer digest

Generate a recurring digest from the same markdown metadata:

- New suggestions needing triage
- Accepted suggestions without an owner
- Stale in-progress suggestions
- Shipped suggestions missing release references
- Deferred suggestions with reopen conditions

This can later be automated through GitHub Actions or n8n.

## Governance model

### Roles

- **Contributor**: submits or refines suggestions.
- **Triage maintainer**: checks duplicates, scope, labels, and security concerns.
- **Domain maintainer**: validates technical direction.
- **Docs maintainer**: keeps public website pages readable and linked.

### Review expectations

Every accepted suggestion should answer:

1. What problem does this solve?
2. Which historical suggestion or existing project surface does it reuse?
3. What framework/tool is being reused instead of built from scratch?
4. What operator or contributor workflow improves?
5. What are the security, privacy, and rollback considerations?
6. How will the project know the change worked?

## Implementation stages

### Stage 1: Canonical markdown contract

- Adopt the frontmatter schema.
- Link this proposal from `suggestions/README.md` and `suggestions/index.md`.
- Normalize new suggestion files to use the same lifecycle language.

### Stage 2: Website-ready page set

- Create the community suggestion website pages from this page set.
- Keep content usable in GitHub even before a static site is deployed.
- Cross-link pages from `CONTRIBUTING.md`, `README.md`, and the landing dashboard where appropriate.

### Stage 3: Automation

- Add frontmatter and internal-link validation.
- Generate suggestion indexes.
- Add duplicate suggestion recommendations.
- Produce maintainer digests.

### Stage 4: Framework deployment

- Choose Docusaurus by default, or Astro/Starlight if custom site composition becomes more important than docs versioning.
- Publish the markdown pages through the selected framework.
- Keep the existing Nginx dashboard focused on operations.

## Acceptance criteria

- New contributors can find historical suggestions before submitting a new idea.
- Every new suggestion has consistent metadata, status, and validation notes.
- Maintainers can generate a status index without manually editing multiple pages.
- Shipped community suggestions link to changelog or release evidence.
- The website can move between Docusaurus, Astro/Starlight, or MkDocs without rewriting suggestion content.
- Day-to-day tooling reduces duplicate triage, stale accepted ideas, and untracked shipped work.
