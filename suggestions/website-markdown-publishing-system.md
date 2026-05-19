---
title: "Website Markdown Publishing System"
status: draft
area: website
priority: P1
owner: unassigned
source: historical-suggestions
updated: 2026-05-19
---

# Website Markdown Publishing System

## Purpose

Build the community website around maintainable markdown pages so suggestions,
decisions, operator guides, and release notes stay easy to review in GitHub and
easy to publish through a static-site framework later.

This is a consolidation point for recurring historical suggestions. It does not
replace GitHub Issues, pull requests, `CONTRIBUTING.md`, or `CHANGELOG.md`; it
turns accepted and high-value community knowledge into durable website content.

## Historical suggestions reused

The existing suggestion archive repeatedly points to the same foundations:

1. Reuse mature documentation frameworks instead of building a custom CMS.
2. Keep GitHub Issues, PRs, `CONTRIBUTING.md`, and `CHANGELOG.md` as the source
   workflow for community input.
3. Publish a clear website information architecture for operators and
   contributors.
4. Add lightweight automation for markdown quality, links, ownership, and status
   indexes.
5. Preserve TU-VM's LAN-first, secure-by-default operating posture.

This page translates those themes into a markdown-first publishing model.

## Recommended framework path

### Primary: Docusaurus

Use Docusaurus if the project wants versioned docs, community pages, generated
sidebars, MDX support, and plugin-based search.

Best fit for:

- Versioned operator documentation
- Suggestion pages with frontmatter-driven indexes
- Contributor-friendly navigation
- Future blog or release-highlight pages

### Lightweight alternative: MkDocs Material

Use MkDocs Material if the project wants a simpler docs stack with excellent
markdown ergonomics and a smaller frontend footprint.

Best fit for:

- Fast publishing of existing markdown
- Minimal JavaScript customization
- A documentation site that stays close to repository files

### Decision rule

Start with plain markdown that works in GitHub. Choose the static-site framework
only after the content model and review workflow are stable. This keeps framework
churn from blocking useful community documentation.

## Proposed website markdown sections

Create or migrate website pages into these sections when a site framework is
adopted:

| Section | Purpose | Source material to reuse |
|---------|---------|--------------------------|
| `getting-started/` | Installation, first boot, service tiers, dashboard tour | `README.md`, `QUICK_REFERENCE.md` |
| `operate/` | Daily operations, updates, backup/recovery, troubleshooting | `docs/playbooks/`, `tu-vm.sh help` |
| `security/` | LAN-first posture, reporting, access modes, sensitive workflows | `SECURITY.md`, nginx/helper docs |
| `community/` | Contribution flow, labels, ownership, review standards | `CONTRIBUTING.md`, `CODEOWNERS`, PR template |
| `suggestions/` | Historical baseline, active proposals, accepted/rejected decisions | existing `suggestions/*.md`, issue template |
| `reference/` | API contracts, scripts, status endpoint shapes, config variables | `fixtures/`, `env.example`, helper API docs |

## Suggestion page frontmatter

Every website suggestion page should include a small frontmatter block so indexes
can be generated without parsing prose.

```yaml
---
title: "Short suggestion title"
status: draft # draft | review | accepted | implemented | deferred | rejected
area: website # website | docs | cli | helper-api | nginx | security | automation
priority: P1 # P0 | P1 | P2
owner: unassigned
source: historical-suggestions
updated: 2026-05-19
---
```

### Required body sections

Use the same body structure for proposal-grade pages:

1. **Problem** - what user or contributor pain this solves.
2. **Current state** - existing repo surfaces, scripts, docs, and constraints.
3. **Recommendation** - the proposed change and the framework/tool to reuse.
4. **Implementation outline** - small, reviewable steps.
5. **Security and privacy impact** - especially for network, control, telemetry,
   or publishing changes.
6. **Operational impact** - startup, resource, rollback, and support
   implications.
7. **Acceptance criteria** - how maintainers know the work is complete.
8. **Related links** - issues, PRs, docs, scripts, and historical suggestions.

## Website markdown content types

### 1. Proposal pages

Proposal pages are for meaningful changes that affect behavior, architecture,
public docs, community process, or operator workflow.

Recommended filename pattern:

```text
suggestions/YYYY-MM-short-topic.md
```

Keep the current historical files as-is unless consolidating them intentionally.
New proposal pages should link back to the relevant historical baseline rather
than duplicate it.

### 2. Decision pages

Decision pages capture the outcome of proposal-lane work. They should be short
and factual:

- Decision
- Date
- Alternatives considered
- Why this option was chosen
- Follow-up work

These can stay under `suggestions/` until a formal `decisions/` section exists.

### 3. Operator guide pages

Operator guides should live in `docs/playbooks/` first, then be mirrored or
linked from the website. The website should not fork operational instructions
from working repository docs.

### 4. Community guide pages

Community pages should reuse `CONTRIBUTING.md` and GitHub templates as source
material. Website pages can explain the workflow in friendlier terms, but GitHub
files remain the executable process for templates and automation.

## Markdown quality gates

Add checks incrementally so contributors get helpful feedback without noisy
failures.

### P0 checks

- Broken internal links in `README.md`, `CONTRIBUTING.md`, `docs/`, and
  `suggestions/`
- Markdown syntax sanity
- Duplicate heading anchors inside the same page
- Required frontmatter fields for new proposal-grade suggestion pages

### P1 checks

- Heading hierarchy warnings
- Meaningful link text checks
- Code fence language checks
- Optional spelling or terminology checks with a project dictionary

### P2 checks

- Generated suggestion index by `status`, `area`, and `priority`
- Dead-page detection for files not linked from any hub page
- Site build preview on PRs after a framework is selected

## Day-to-day contributor tooling

Expose documentation checks through existing project patterns instead of adding a
separate workflow surface.

Recommended commands:

```bash
./tu-vm.sh docs-check
./scripts/docs-check.sh
```

Expected behavior:

- Run quickly on a normal checkout.
- Print actionable file and line references.
- Exit non-zero only for failures that should block review.
- Support a local mode that does not require Docker.
- Support a CI mode that can run link checks and future static-site builds.

Suggested implementation order:

1. Add `scripts/docs-check.sh` for markdown, link, and frontmatter checks.
2. Add `./tu-vm.sh docs-check` as a thin alias.
3. Wire the script into the existing docs links workflow.
4. Add static-site build checks only after Docusaurus or MkDocs is selected.

## Community workflow for markdown suggestions

1. **Idea intake** - contributor opens an Idea / suggestion issue.
2. **Discovery** - maintainer links related historical suggestion files.
3. **Draft** - contributor adds or updates one markdown page with frontmatter and
   acceptance criteria.
4. **Review** - maintainers check security, operational impact, duplication, and
   implementation shape.
5. **Decision** - page status changes to `accepted`, `deferred`, or `rejected`.
6. **Implementation** - code/docs work links back to the accepted suggestion.
7. **Retrospective** - implemented pages record what shipped and what changed.

## Governance rules to prevent reinvention

- Search `suggestions/` before adding a new proposal file.
- Prefer updating canonical hub pages over creating another parallel framework
  page.
- Link to historical suggestions when reusing an existing idea.
- Mark superseded pages clearly rather than deleting useful context.
- Keep GitHub Issues as the discussion entry point and markdown as the durable
  decision record.
- Require explicit security notes for website changes that expose data, call
  external services, or alter dashboard control paths.

## Acceptance criteria for adopting this system

- A contributor can find the suggestion workflow from `README.md`,
  `CONTRIBUTING.md`, or the website hub.
- New website suggestion pages use frontmatter consistently.
- The suggestion index can be generated or manually maintained without reading
  every file.
- CI catches broken links and required-field omissions before merge.
- Accepted suggestions link to implementation PRs or tracking issues.
- Implemented suggestions are moved out of active proposal lists without losing
  historical context.

## First practical next steps

1. Treat this page as the canonical markdown publishing policy for future website
   suggestions.
2. Update the suggestion hub when a page is accepted, implemented, or superseded.
3. Add a narrow markdown style lint item to the implementation backlog.
4. Pilot the frontmatter schema on one new proposal before bulk-editing
   historical files.
5. Choose Docusaurus or MkDocs only after the first frontmatter/index workflow is
   proven.
