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

3. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)  
   Covers operational tooling, automation, quality gates, and contributor productivity.

4. [Community Suggestions Platform](./website-community-platform.md)  
   Defines the staged website/community system that starts with GitHub + Markdown and only adds custom helper APIs after clear demand.

5. [Implementation Backlog](./implementation-backlog.md)  
   Prioritizes next steps after removing completed or superseded historical items.

## Current recommended path

Use a staged system instead of building a custom community platform immediately:

1. **Canonical records first** - keep proposal state in Markdown files under `suggestions/` with consistent status, owner, risk, and acceptance sections.
2. **GitHub-native workflow** - use Issues, PRs, labels, Discussions, and Release Drafter for intake, review, and change history.
3. **Static website publishing** - expose the Markdown suggestions through a docs framework so contributors can browse decisions and roadmap items.
4. **Dashboard integration** - add read-only cards or cached summaries to the existing landing page once the source records are stable.
5. **Custom APIs only when needed** - add writable helper endpoints for voting or submission only after abuse controls, auth, and maintenance ownership are clear.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value
- **No duplicate proposal churn**: historical suggestions should be linked, superseded, or merged into canonical pages

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
