# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving TU-VM with a community-first website and contributor system.

The recommendations focus on:

- reusing mature frameworks instead of rebuilding solved docs/community capabilities,
- improving daily contributor and maintainer workflows,
- keeping suggestions transparent from intake to decision to release evidence,
- preserving TU-VM's secure-by-default, self-hosted posture.

## Why this exists

Historical suggestion branches repeatedly converged on the same needs: better website structure, clearer community governance, easier day-to-day tools, and a roadmap that turns ideas into shipped improvements. This hub consolidates those ideas so future work starts from existing context.

## Canonical suggestion map

1. [Historical Suggestions Baseline](./website-historical-baseline.md)  
   Identifies repeated historical patterns and the existing project assets to reuse.

2. [Website Information Architecture](./website-information-architecture.md)  
   Recommends the website framework path, navigation model, page taxonomy, and accessibility standards.

3. [Community Framework and Governance](./website-community-framework.md)  
   Defines suggestion lifecycle states, decision lanes, roles, ownership, and review expectations.

4. [Contributor Tooling and Day-to-Day Operations](./website-contributor-tooling.md)  
   Details tools that reduce repetitive work for contributors and maintainers.

5. [Roadmap From Historical Suggestions](./website-roadmap-from-historical-suggestions.md)  
   Sequences the suggestions into low-risk implementation phases.

6. [Implementation Backlog](./implementation-backlog.md)  
   Separates completed/superseded work from current high-value recommendations.

## Working principles

- **Community-first:** proposals are public, discussable, and traceable.
- **Reuse-first:** use GitHub-native workflows, static site frameworks, and existing TU-VM tools before adding new systems.
- **Low-friction contribution:** templates, examples, and validation should help first-time contributors succeed.
- **Operational reliability:** every accepted idea includes validation and rollback guidance.
- **Security and privacy by default:** community growth must not weaken local-first or control-plane boundaries.

## Suggested execution sequence

### Phase 1: Foundation

Already covered in the repository: suggestion and PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/config checks, starter [`docs/playbooks/`](../docs/playbooks/README.md), and landing-page community links.

Still open:

- choose the docs site framework and navigation conventions,
- publish explicit maintainer label and ownership conventions beside the issue workflow,
- normalize active suggestions against the status model in [`README.md`](./README.md).

### Phase 2: Acceleration

- Add docs quality gates for the website-ready Markdown set.
- Add lightweight suggestion metadata validation.
- Surface roadmap and playbook links from the dashboard or future docs site.
- Produce local, privacy-preserving community health summaries.

### Phase 3: Scale

- Create a curated integrations/tooling catalog.
- Publish recurring roadmap and retrospective summaries.
- Expand browser/UI smoke tests once the website layer becomes more interactive.

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and prioritized next recommendations.
