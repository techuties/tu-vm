# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

This README is the primary folder entry point. The shorter
[`index.md`](./index.md) is an execution overview and should link back here
rather than define a separate source of truth.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Canonical reading path

The folder contains historical variants from earlier suggestion rounds. Start
with this short path rather than treating similarly named files as competing
plans:

1. [`website-historical-suggestions.md`](./website-historical-suggestions.md) —
   existing project ideas and the duplicate-prevention baseline.
2. [`website-and-docs-framework.md`](./website-and-docs-framework.md) — static
   website architecture, framework decision, delivery stages, and guardrails.
3. [`website-community-pages.md`](./website-community-pages.md) — detailed
   website page set, Markdown metadata contract, lifecycle, and publishing
   acceptance criteria.
4. [`website-community-governance.md`](./website-community-governance.md) —
   roles, quality bar, decisions, and communication standards.
5. [`website-day-to-day-tooling.md`](./website-day-to-day-tooling.md) —
   reuse-first validation, generation, triage, CI, and maintainer commands.
6. [`implementation-backlog.md`](./implementation-backlog.md) — current
   repository baseline and prioritized implementation slices.

Other files are retained as historical research until maintainers complete an
archive/consolidation pass. A new proposal should extend a canonical file when
the problem and desired outcome already match.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

To submit an idea via GitHub, see
[`CONTRIBUTING.md`](../CONTRIBUTING.md) at the repository root. GitHub Issues
remain the intake and discussion system; the proposed website is a static,
curated view rather than a second suggestions database.

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
