# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Canonical reading path

Use these files first when planning community or website work:

1. [`index.md`](./index.md) - short hub page for the suggestions system.
2. [`historical-suggestions.md`](./historical-suggestions.md) and [`website-historical-baseline.md`](./website-historical-baseline.md) - prior ideas and recurring patterns that should be checked before proposing new work.
3. [`website-and-docs-framework.md`](./website-and-docs-framework.md) - recommended website/docs stack and content model.
4. [`community-system-framework.md`](./community-system-framework.md) - suggestion lifecycle, governance, ownership, and quality gates.
5. [`day-to-day-tooling.md`](./day-to-day-tooling.md) and [`implementation-backlog.md`](./implementation-backlog.md) - practical tooling and prioritized next work.

If a new idea overlaps one of those documents, update the existing page instead of creating another near-duplicate suggestion file.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Files in this folder

- `website-historical-baseline.md`  
  Historical suggestion patterns and how they were merged into a single framework.

- `website-information-architecture.md`  
  Detailed website structure, content model, and docs framework recommendation.

- `website-community-framework.md`  
  Community operating model, governance, ownership, and review standards.

- `website-contributor-tooling.md`  
  Concrete tooling proposals that improve day-to-day contributor productivity.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced roadmap that maps historical suggestions to implementation milestones.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.
5. Prefer GitHub-native collaboration (Issues, Discussions, labels, PR templates, Release Drafter) before adding custom service code.
6. When a framework is useful, choose mature documentation and automation tools with active ecosystems rather than building bespoke workflow engines.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
