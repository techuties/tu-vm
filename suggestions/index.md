# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Suggestion map

1. [Community System Framework](./community-system-framework.md)  
   Defines how suggestions are proposed, reviewed, accepted, and implemented.

2. [Website and Documentation Framework](./website-and-docs-framework.md)  
   Recommends a docs website stack and contribution model for clear public communication.

3. [Website Community Pages](./website-community-pages.md)
   Defines the concrete markdown pages, frontmatter schema, status taxonomy,
   and dedupe workflow for a suggestions section on the website.

4. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)  
   Covers operational tooling, automation, quality gates, and contributor productivity.

5. [Website Day-to-Day Tooling](./website-day-to-day-tooling.md)
   Converts the framework into website-specific tooling such as schema checks,
   generated indexes, release linkage, and contributor dashboards.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value

## Suggested execution sequence

### Stage 1: Foundation

Done on the GitHub-native path: suggestion + PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links.

Still open:

- Dedicated docs site structure and navigation, with static-site adoption only
  after the markdown content model is stable
- Explicit maintainer label/ownership conventions documented beside Issues
- Suggestion page frontmatter and generated status indexes

### Stage 2: Acceleration

- Automation for triage and stale-issue workflows (labels, bots)
- Playbook surfacing from the dashboard with clear anchors
- Lightweight adoption metrics (release cadence, time-to-close by label)
- Markdown lint, link checks, and suggestion schema validation in CI
- Searchable website pages for historical, accepted, deferred, and shipped
  suggestions

### Stage 3: Scale

- Open community working groups
- Create plugin/integration curation process
- Publish quarterly roadmap and retrospective summaries
- Optional public roadmap dashboards generated from issue labels and suggestion
  frontmatter

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
