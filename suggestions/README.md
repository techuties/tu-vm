# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Start here

Use this canonical reading path before creating new suggestion files:

1. `website-historical-baseline.md` - historical suggestion patterns and how
   repeated ideas were merged into a single framework.
2. `website-and-docs-framework.md` - recommended Markdown-first website stack,
   information architecture, and reuse-first publishing approach.
3. `website-community-pages.md` - detailed website Markdown page set,
   front matter schema, publishing workflow, and duplicate-avoidance process.
4. `community-system-framework.md` - suggestion lifecycle, governance,
   ownership, and review standards.
5. `day-to-day-tooling.md` - practical tooling for contributor and maintainer
   workflows.
6. `implementation-backlog.md` - shipped, superseded, and next-priority work.

## Historical archive guidance

The folder intentionally keeps historical suggestion files so prior work remains
discoverable. When adding new guidance:

- Search this folder first.
- Extend the closest canonical file instead of creating a near-duplicate.
- Link related historical files from the new or updated section.
- Mark ideas as superseded, merged, or implemented in
  `implementation-backlog.md` when applicable.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
