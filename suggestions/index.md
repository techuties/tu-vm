# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Suggestion map

Start with the [Suggestions Hub README](./README.md) for the canonical reading path and file inventory.

1. [Historical Suggestions](./historical-suggestions.md) and [Website Historical Baseline](./website-historical-baseline.md)
   Check these first so new work extends earlier ideas instead of duplicating them.

2. [Community System Framework](./community-system-framework.md)
   Defines how suggestions are proposed, reviewed, accepted, and implemented.

3. [Website and Documentation Framework](./website-and-docs-framework.md)
   Recommends a docs website stack and contribution model for clear public communication.

4. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)
   Covers operational tooling, automation, quality gates, and contributor productivity.

5. [Implementation Backlog](./implementation-backlog.md)
   Lists shipped baselines, remaining recommendations, and implementation-ready next steps.

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
- Publish quarterly roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
