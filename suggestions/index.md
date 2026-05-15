# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Historical review result

The existing suggestions archive already covers website frameworks, community governance, contribution flow, and day-to-day tooling. The current canonical direction is:

- keep the live Nginx dashboard focused on operator controls and status;
- add a static Markdown-based docs/community website when implementation begins;
- use GitHub Issues/Discussions for workflow rather than building a custom tracker first;
- index this `suggestions/` folder as the durable history of accepted, deferred, duplicate, and superseded ideas;
- prioritize small maintainer tools that make repeated community work easier.

Recommended framework selection is documented in [`website-information-architecture.md`](./website-information-architecture.md), with Docusaurus as the docs-first default and Astro/Starlight as the richer content-site alternative.

## Suggestion map

1. [Community System Framework](./community-system-framework.md)  
   Defines how suggestions are proposed, reviewed, accepted, and implemented.

2. [Website and Documentation Framework](./website-and-docs-framework.md)  
   Recommends a docs website stack and contribution model for clear public communication.

3. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)  
   Covers operational tooling, automation, quality gates, and contributor productivity.

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
- Suggestion archive metadata and canonical duplicate/superseded links

### Phase 2 (Acceleration)

- Automation for triage and stale-issue workflows (labels, bots)
- Playbook surfacing from the dashboard with clear anchors
- Lightweight adoption metrics (release cadence, time-to-close by label)
- Local website preview and docs quality checks for contributors

### Phase 3 (Scale)

- Open community working groups
- Create plugin/integration curation process
- Publish quarterly roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
