# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Suggestion map

Start with these curated files before reading the broader historical archive:

1. [Historical Suggestions Baseline](./website-historical-baseline.md)
   Explains the repeated themes already found in prior community-suggestions branches.

2. [Website and Documentation Framework](./website-and-docs-framework.md)
   Recommends a reuse-first docs website stack and contribution model for clear public communication.

3. [Website Community Pages](./website-community-pages.md)
   Defines the markdown page set, templates, metadata, and publishing rules for a website suggestions area.

4. [Website Community Framework](./website-community-framework.md)
   Defines governance, ownership, review lanes, and decision standards.

5. [Website Day-to-Day Tooling](./website-day-to-day-tooling.md)
   Covers operational tooling, automation, quality gates, and maintainer productivity.

6. [Implementation Backlog](./implementation-backlog.md)
   Lists shipped/superseded work and prioritized next recommendations.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value
- **Reuse before build**: existing GitHub workflows, static markdown, `tu-vm.sh`, helper APIs, and the nginx dashboard should be extended before adding new services

## Suggested execution sequence

### Phase 1 - Foundation

Done on the GitHub-native path: suggestion + PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links.

Still open:

- Dedicated docs site structure and navigation (optional static site later)
- Explicit maintainer label/ownership conventions documented beside Issues
- Canonical website suggestions page set generated or curated from `/suggestions/`

### Phase 2 - Acceleration

- Automation for triage and stale-issue workflows (labels, bots)
- Playbook surfacing from the dashboard with clear anchors
- Lightweight adoption metrics (release cadence, time-to-close by label)
- Duplicate-detection hints against historical suggestion files

### Phase 3 - Scale

- Open community working groups
- Create plugin/integration curation process
- Publish quarterly roadmap and retrospective summaries
- Add a searchable public suggestions archive once manual curation proves useful

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
