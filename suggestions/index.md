# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Suggestion map

1. [Website Historical Baseline](./website-historical-baseline.md)  
   Summarizes historical suggestion work and the reuse-first baseline.

2. [Website Information Architecture](./website-information-architecture.md)  
   Defines the community website structure, content model, and framework selection rules.

3. [Website and Documentation Framework](./website-and-docs-framework.md)  
   Recommends mature static-site tooling and generated suggestion indexes.

4. [Website Community Framework](./website-community-framework.md)  
   Defines governance, ownership, decision lanes, and review standards.

5. [Website Contributor Tooling](./website-contributor-tooling.md)  
   Covers diagnostics, docs checks, release hygiene, and day-to-day contributor productivity.

6. [Website Roadmap From Historical Suggestions](./website-roadmap-from-historical-suggestions.md)  
   Converts repeated historical themes into a phased implementation path.

7. [Implementation Backlog](./implementation-backlog.md)  
   Separates completed/superseded items from the next practical recommendations.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value

## Suggested execution sequence

### Phase 1 (Foundation)

Done on the GitHub-native path: suggestion + PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links.

Still open:

- Dedicated docs site structure and navigation (Docusaurus, MkDocs Material, or Astro/Starlight)
- Explicit maintainer label/ownership conventions documented beside Issues
- Suggestion frontmatter convention and generated website indexes

### Phase 2 (Acceleration)

- Automation for triage and stale-issue workflows (labels, bots)
- Playbook surfacing from the dashboard with clear anchors
- Lightweight adoption metrics (release cadence, time-to-close by label)
- Changelog/release linkage for completed suggestions

### Phase 3 (Scale)

- Open community working groups
- Create plugin/integration curation process
- Publish quarterly roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
