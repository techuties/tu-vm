# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Canonical reading path

This folder has accumulated multiple overlapping suggestion drafts across historical branches. Use the files below as the canonical path before creating or editing any other suggestion file:

- `website-historical-baseline.md`  
  Historical suggestion patterns and how they were merged into a single framework.

- `website-information-architecture.md`  
  Detailed website structure, content model, and docs framework recommendation.

- `website-and-docs-framework.md`
  Reuse-first static website framework, Markdown publishing model, metadata schema, automation checks, and adoption sequence.

- `website-community-pages.md`
  Detailed website Markdown page set for suggestion intake, status board, decision log, implemented suggestions, and proposal template.

- `community-system-framework.md`
  Community operating model, governance, ownership, lifecycle, and review standards.

- `day-to-day-tooling.md`
  Concrete tooling proposals that improve day-to-day contributor and maintainer productivity.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced roadmap that maps historical suggestions to implementation milestones.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.
5. Update a canonical file above before adding another similarly named suggestion file.

## Website suggestion direction

The recommended community website approach is:

1. Keep GitHub Issues and pull requests as the intake and implementation records.
2. Keep `suggestions/` as the historical planning archive.
3. Publish website-facing Markdown pages under a future docs/community subtree.
4. Generate status boards and indexes from frontmatter instead of maintaining duplicate lists by hand.
5. Link implemented suggestions to changelog, release, PR, and validation evidence.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
