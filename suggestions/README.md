# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Start here

The folder contains historical documents from many earlier suggestion branches. Use this maintained path before opening or adding another proposal:

1. [`index.md`](./index.md) — current scope and execution sequence.
2. [`community-system-framework.md`](./community-system-framework.md) — proposal review and decision model.
3. [`website-and-docs-framework.md`](./website-and-docs-framework.md) — reuse-first website architecture and framework adoption gates.
4. [`website-community-pages.md`](./website-community-pages.md) — canonical lifecycle, Markdown metadata, and publishing workflow.
5. [`day-to-day-tooling.md`](./day-to-day-tooling.md) — contributor and maintainer tooling.
6. [`extensions-and-integration-framework.md`](./extensions-and-integration-framework.md) — safe community extension contract.
7. [`implementation-backlog.md`](./implementation-backlog.md) — implemented baseline and prioritized next work.
8. [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md) — historical product direction; the implementation backlog controls current execution order.

The other files are useful historical evidence. They are not separate sources of truth. If a new idea overlaps an existing canonical page, update that page and link the relevant GitHub issue instead of adding another Markdown file.

## Historical baseline

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Reuse and de-duplication rule

Before changing this folder:

1. Search canonical pages and GitHub issues for the problem, not only the proposed solution name.
2. Mark the current repository behavior with file-level evidence.
3. Extend the closest canonical page; do not create a parallel framework comparison or roadmap.
4. Use the lifecycle defined in [`website-community-pages.md`](./website-community-pages.md); do not introduce another status vocabulary.
5. Link implementation to an issue/PR and release note rather than maintaining a second private status database.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the trimmed backlog, implemented baseline, and prioritized next recommendations, see [`implementation-backlog.md`](./implementation-backlog.md).
