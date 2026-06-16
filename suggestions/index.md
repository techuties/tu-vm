# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Suggestion map

Use this map as the canonical entry point. Several older files in this directory intentionally preserve historical proposals; the files below are the current synthesis to consult before creating anything new.

1. [Community System Framework](./community-system-framework.md)  
   Defines how suggestions are proposed, reviewed, accepted, and implemented.

2. [Website and Documentation Framework](./website-and-docs-framework.md)  
   Recommends mature website/docs frameworks, markdown page structure, and contribution tooling.

3. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)  
   Covers operational tooling, automation, quality gates, and contributor productivity.

4. [Implementation Backlog](./implementation-backlog.md)
   Tracks what is already covered in the repository and what remains valuable.

## Constructive website suggestion set

The website should start as a markdown-first community surface and only add custom application behavior where it creates durable value.

### Framework choices to reuse

- **Docusaurus**: best default when versioned docs, sidebars, markdown proposals, and a plugin ecosystem matter most.
- **MkDocs Material**: strong alternative for a lighter Python-based documentation pipeline with excellent markdown ergonomics.
- **Astro Starlight**: useful if the website later needs richer landing pages while preserving markdown docs.

Selection rule: choose the smallest framework that supports search, navigation, versioning or release-aware docs, and community contribution review without custom infrastructure.

### Website markdown pages to publish first

- `community/overview.md`: what the community system is for and how decisions are made.
- `community/contributing.md`: links to GitHub Issues, PR expectations, security reporting, and validation commands.
- `suggestions/index.md`: generated or curated list of active, accepted, implemented, and deferred suggestions.
- `suggestions/template.md`: proposal template with problem, existing solutions scan, rollout, rollback, and success metrics.
- `operations/playbooks.md`: curated entry point to day-to-day operator recipes and troubleshooting.
- `roadmap.md`: short status-oriented view that links accepted suggestions to implementation work.

### Day-to-day tools that reduce maintainer burden

- Markdown structure checks for required suggestion sections.
- Link validation for website and docs pages.
- Duplicate/overlap report against historical files in `suggestions/`.
- Release-note helper integration so shipped community work is visible in `CHANGELOG.md`.
- Optional dashboard widget that shows suggestion counts by status without exposing privileged control APIs.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value

## Suggested execution sequence

### Phase 1 (Foundation)

Done on the GitHub-native path: suggestion + PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links.

Still open:

- Dedicated docs site structure and navigation (optional static site later)
- Explicit maintainer label/ownership conventions documented beside Issues

### Phase 2 (Acceleration)

- Automation for triage and stale-issue workflows (labels, bots)
- Playbook surfacing from the dashboard with clear anchors
- Lightweight adoption metrics (release cadence, time-to-close by label)

### Phase 3 (Scale)

- Open community working groups
- Create plugin/integration curation process
- Publish recurring roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
