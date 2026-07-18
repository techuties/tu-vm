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
   Defines the Markdown publishing model, metadata, page set, and GitHub linkage.

4. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)
   Covers operational tooling, automation, quality gates, and contributor productivity.

5. [Extensions and Integration Framework](./extensions-and-integration-framework.md)
   Defines a safe contract for community integrations without repeated core edits.

6. [Implementation Backlog](./implementation-backlog.md)
   Separates shipped foundations from the next implementation-ready recommendations.

7. [Historical Product Roadmap](./website-roadmap-from-historical-suggestions.md)
   Preserves long-range product direction; the implementation backlog controls current priority.

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
- Replace placeholder CODEOWNERS identities with active maintainers
- Map the canonical lifecycle to one documented GitHub Project field or label model

### Phase 2 (Acceleration, partially delivered)

- Done: stale/needs-info automation, Release Drafter, playbook surfacing, and dashboard community links
- Add a lightweight suggestions linter and generated canonical index
- Pilot a validated community extension package
- Lightweight adoption metrics (release cadence, time-to-close by label)

### Phase 3 (Scale)

- Open community working groups
- Curate extension compatibility and security review
- Publish quarterly roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
