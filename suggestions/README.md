# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

Use this directory as the historical suggestion archive and the canonical place to refine community-system proposals before they become website pages, GitHub Issues, or implementation work.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Canonical website suggestion set

The folder contains many historical and exploratory files. Start with these canonical pages before creating anything new:

- `website-historical-baseline.md`  
  Historical suggestion patterns and how they were merged into a single framework.

- `website-information-architecture.md`  
  Detailed website structure, content model, and docs framework recommendation.

- `website-community-framework.md`  
  Community operating model, governance, ownership, and review standards.

- `website-community-pages.md`  
  Proposed markdown page set for the public community suggestions area.

- `website-markdown-publishing-system.md`  
  Markdown-first publishing model, frontmatter schema, dedupe workflow, and automation recommendations for website-ready suggestions.

- `website-contributor-tooling.md`  
  Concrete tooling proposals that improve day-to-day contributor productivity.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced roadmap that maps historical suggestions to implementation milestones.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

## How to add or revise suggestions

1. Search this folder for similar proposals by title, theme, and subsystem.
2. Prefer updating a canonical page or linking to a related historical page instead of creating a near-duplicate.
3. When a new page is warranted, include problem, historical references, recommended approach, risks, acceptance criteria, and decision notes.
4. Mark superseded or merged ideas clearly so future contributors can trace the decision.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
