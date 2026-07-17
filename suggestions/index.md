# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

This page summarizes execution stages. Use
[`README.md`](./README.md) as the primary folder entry point and canonical
reading order.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Canonical suggestion map

1. [Historical suggestions](./website-historical-suggestions.md) — checks
   project and proposal history before a new idea is created.
2. [Website and documentation framework](./website-and-docs-framework.md) —
   recommends a static, Markdown-first docs site that reuses Nginx and GitHub.
3. [Website community pages](./website-community-pages.md) — defines the page
   set, frontmatter contract, lifecycle, deduplication, and publishing rules.
4. [Community governance](./website-community-governance.md) — defines
   submission quality, human decisions, ownership, and transparent rationale.
5. [Day-to-day tooling](./website-day-to-day-tooling.md) — specifies established
   tools and deterministic automation for validation, generation, and triage.
6. [Implementation backlog](./implementation-backlog.md) — separates shipped
   capabilities from the next implementation slices.

The folder also preserves older variants for historical context. New work
should update the canonical path above when its problem and outcome overlap,
rather than creating another similarly named file.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value

## Suggested execution sequence

### Phase 1 (Foundation)

Done on the GitHub-native path: suggestion + PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links.

Still open:

- Representative MkDocs Material spike and framework decision record
- Static `/docs/` site structure and navigation
- Adopt the specified suggestion frontmatter schema and generate its views
- Replace the CODEOWNERS placeholder and seed the documented label set

### Phase 2 (Acceleration)

- Schema, Markdown, link, static-build, and accessibility checks
- Human-reviewed duplicate suggestions and stale-record reminders
- Link the static docs site from the existing dashboard playbook shortcuts
- Lightweight adoption metrics (release cadence, time-to-close by label)

### Phase 3 (Scale)

- Open community working groups
- Create plugin/integration curation process
- Publish quarterly roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
