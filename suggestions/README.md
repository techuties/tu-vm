# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

Start with [`website-community-system-blueprint.md`](./website-community-system-blueprint.md). It is the current canonical synthesis of the historical suggestion files, recommended framework path, community lifecycle, governance model, and day-to-day tooling ideas.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Files in this folder

- `website-community-system-blueprint.md`  
  Canonical current blueprint for the website/community system, including framework recommendation, suggestion lifecycle, tooling, governance, and implementation order.

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
5. Prefer GitHub-native workflows and static Markdown pages before building custom community services.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
