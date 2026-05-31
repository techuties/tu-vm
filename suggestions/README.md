# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

GitHub Issues remain the live intake and discussion path. These markdown files provide the reusable history, decision context, and website-ready proposal library.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs, operations, and community.
2. Community governance and contribution workflow.
3. Practical contributor tooling for day-to-day operations.
4. A roadmap built from already proposed feature directions.

## Canonical files

Start with these files before adding new suggestions:

- [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md)
  Markdown-first website publishing model, metadata schema, duplicate-avoidance workflow, and framework recommendations.

- [`website-historical-baseline.md`](./website-historical-baseline.md)
  Historical suggestion patterns and how they were merged into a single framework.

- [`website-information-architecture.md`](./website-information-architecture.md)
  Detailed website structure, content model, and docs framework recommendation.

- [`website-community-framework.md`](./website-community-framework.md)
  Community operating model, governance, ownership, and review standards.

- [`website-contributor-tooling.md`](./website-contributor-tooling.md)
  Concrete tooling proposals that improve day-to-day contributor productivity.

- [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md)
  Sequenced roadmap that maps historical suggestions to implementation milestones.

- [`implementation-backlog.md`](./implementation-backlog.md)
  Trimmed backlog with implemented items removed and prioritized next recommendations.

Other similarly named files in this folder are historical drafts unless this hub links to them as canonical.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page, GitHub Issues, and GitHub Actions).
2. Prefer mature frameworks such as Docusaurus, MkDocs Material, Astro Starlight, pre-commit, markdownlint, link checkers, and Trivy before custom tooling.
3. Add modular improvements over deep rewrites.
4. Keep secure defaults and LAN-first behavior as non-negotiable.
5. Prioritize contribution quality, reproducibility, and maintainability.

## Before creating a new suggestion file

1. Search this folder for related topics.
2. Check [`implementation-backlog.md`](./implementation-backlog.md) for open or completed work.
3. Extend an existing canonical page if the new idea is a refinement.
4. Create a new page only for a distinct decision or implementation track.
5. Include frontmatter and required sections from [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md).

To submit an idea via GitHub, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root for Issues, labels, and PR expectations.
