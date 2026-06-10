# Website Markdown Publishing System

## Purpose

Create a website-ready markdown system for community suggestions that is easy to review, publish, search, and maintain without building a custom suggestions application first.

This extends the historical suggestions corpus by turning existing ideas into a concrete publishing model. The goal is to reuse mature static-site tooling and GitHub workflows before adding new runtime services.

## Reuse-first recommendation

Use markdown as the source of truth and publish it with a mature docs framework:

1. **Docusaurus** for the primary website path when versioning, navigation, plugin ecosystem, and contributor familiarity are priorities.
2. **Astro Starlight** when the site needs a stronger marketing/community front page while still treating docs as first-class content.
3. **MkDocs Material** when the team wants the smallest operational footprint and very fast docs iteration.

Avoid introducing a CMS, custom voting app, or database-backed suggestion service until markdown plus GitHub Issues can no longer support the actual community workflow.

## Suggested folder model

Keep the repository-level planning archive in `/suggestions/`, then publish selected website-facing pages into a docs-site subtree when a website framework is added.

```text
suggestions/
  README.md
  index.md
  implementation-backlog.md
  website-markdown-publishing-system.md

website-or-docs-content/
  community/
    suggestions/
      index.md
      how-to-submit.md
      status-board.md
      decisions.md
      implemented.md
      archive.md
    governance/
      review-process.md
      maintainer-roles.md
```

The `/suggestions/` folder remains the historical and design archive. The website subtree becomes the curated public experience.

## Website markdown files to publish

### `community/suggestions/index.md`

Purpose:

- Explain what suggestions are for and how the lifecycle works.
- Link to GitHub Issues, accepted proposals, implemented work, and archived decisions.
- Show a short "before submitting" checklist that points contributors back to historical suggestions.

Recommended sections:

- Why community suggestions matter
- Lifecycle: idea -> triage -> review -> accepted/deferred/rejected -> implementation
- Quick links
- Current focus areas
- How to avoid duplicate proposals

### `community/suggestions/how-to-submit.md`

Purpose:

- Help contributors write high-signal suggestions that maintainers can evaluate quickly.
- Reduce duplicate and underspecified proposals.

Recommended sections:

- Search first: issues, PRs, `/suggestions/`, changelog, and playbooks
- Required fields: problem, current workaround, proposed change, alternatives, risks, validation path
- Good example and weak example
- Security and privacy checklist
- What happens after submission

### `community/suggestions/status-board.md`

Purpose:

- Give the community a readable view of suggestion movement without requiring a custom dashboard.

Recommended sections:

- Status taxonomy
- Active review table
- Accepted / in-progress table
- Deferred / rejected table with rationale links
- Last generated timestamp or manual update note

Start manually maintained. Later, generate the tables from GitHub labels or frontmatter.

### `community/suggestions/decisions.md`

Purpose:

- Preserve accepted, rejected, and deferred decision rationale so the project does not repeatedly re-litigate old proposals.

Recommended sections for each entry:

- Decision ID
- Linked issue or suggestion page
- Context
- Decision
- Alternatives considered
- Follow-up conditions

### `community/suggestions/implemented.md`

Purpose:

- Show contributors that suggestions can become real improvements.
- Connect shipped work to changelog and release notes.

Recommended sections:

- Implemented suggestion
- What changed
- Release or changelog link
- Validation evidence
- Follow-up ideas

### `community/suggestions/archive.md`

Purpose:

- Keep historical suggestions findable without cluttering active pages.

Recommended sections:

- Superseded by existing implementation
- Deferred until a dependency exists
- Rejected with rationale
- Merged into another proposal

## Frontmatter standard

Use a small, strict frontmatter schema so pages can be indexed, linted, and eventually rendered into status views.

```yaml
---
title: "Short page title"
summary: "One sentence summary for indexes and previews."
status: "draft"
area: "community"
tags:
  - suggestions
  - docs
owner: "maintainers"
last_reviewed: "YYYY-MM-DD"
---
```

For individual suggestion pages, add:

```yaml
suggestion_id: "SUG-YYYY-NNN"
decision: "undecided"
github_issue: "https://github.com/techuties/tu-vm/issues/NNN"
risk: "low"
reuse_first: true
```

Suggested statuses:

- `draft`
- `triage`
- `review`
- `accepted`
- `in-progress`
- `implemented`
- `deferred`
- `rejected`
- `archived`

## Suggestion page template

Each detailed suggestion should use the same shape:

```markdown
# Suggestion title

## Summary

One concise paragraph describing the suggested change.

## Problem

What pain exists today? Who experiences it?

## Existing work to reuse

List related files, issues, prior suggestions, upstream frameworks, or tools.

## Proposed approach

Describe the smallest useful change and how it fits the current architecture.

## Alternatives considered

Explain why other options were not chosen.

## Impact

- Community impact
- Operator impact
- Security/privacy impact
- Maintenance impact

## Rollout and rollback

How to introduce the change safely and how to undo it.

## Validation

How contributors and maintainers can prove it works.

## Decision log

- YYYY-MM-DD: Initial draft.
```

## Automation and quality gates

Start with checks that match the repo's current script-and-CI style:

1. Markdown link checks for root docs, `/docs/`, and website suggestion pages.
2. Frontmatter schema validation for website-published suggestion pages.
3. Required-heading validation for suggestion pages.
4. Duplicate-title detection across active suggestions.
5. Optional generated indexes by `status`, `area`, and `tag`.

These checks can run in CI and can later be exposed through a `tu-vm.sh docs` or `tu-vm.sh suggestions` command if the project wants a single local entry point.

## Day-to-day workflow

1. Contributor opens a GitHub suggestion issue.
2. Maintainer checks for duplicates in Issues, CHANGELOG, docs, and `/suggestions/`.
3. If the idea needs deeper design, the contributor or maintainer creates a markdown suggestion page.
4. Reviewers update the page status through frontmatter and leave rationale in the decision log.
5. Accepted work links implementation PRs back to the suggestion.
6. Shipped work moves to `implemented.md` and receives a changelog or release-note link.

This keeps GitHub as the intake and discussion layer while markdown remains the durable knowledge base.

## Governance guardrails

- No accepted suggestion without an owner and validation path.
- No runtime or network change without security notes and rollback steps.
- No duplicate website page when an existing `/suggestions/` document can be updated.
- No custom service until the static markdown workflow has a documented limitation.
- Archive superseded ideas with rationale instead of deleting historical context.

## Implementation phases

### Phase A: Curate and publish

- Select canonical `/suggestions/` pages for public navigation.
- Create the initial website markdown files listed above.
- Add a simple frontmatter schema and page template.
- Link website pages back to GitHub Issues and existing playbooks.

### Phase B: Validate and index

- Add CI checks for links, frontmatter, and required headings.
- Generate status and tag indexes from markdown metadata.
- Add docs-site navigation for community suggestions, governance, operations, and security.

### Phase C: Automate carefully

- Sync GitHub issue labels to suggestion status tables where useful.
- Add release/changelog cross-links for implemented suggestions.
- Publish maintainer review dashboards only after the static workflow is stable.

### Phase D: Consider dynamic features only if needed

- Add a helper endpoint, database table, or community web app only when GitHub plus markdown cannot handle moderation, search, or status visibility.
- Keep control-plane endpoints and public community endpoints separate.

## Acceptance criteria

- Contributors can find how to submit suggestions from the website navigation.
- Each active suggestion has a status, owner, area, risk note, and validation path.
- Historical and rejected decisions remain searchable.
- Maintainers can update suggestion state with normal markdown review.
- The publishing path works without weakening TU-VM's private, LAN-first posture.
