# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a
community-driven website and contributor system without reinventing existing
work. The folder already acts as the historical suggestion archive, so new
website ideas should either update one of the canonical files below or clearly
explain why a separate page is needed.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*`
branches and the current files in this folder so repeated ideas are reused
instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Canonical reading path

Use these files as the current source of truth before opening another
suggestion page:

1. [`website-historical-baseline.md`](./website-historical-baseline.md) -
   historical patterns and what should be reused.
2. [`index.md`](./index.md) - community suggestion map and execution sequence.
3. [`community-system-framework.md`](./community-system-framework.md) -
   lifecycle, roles, scorecards, and governance.
4. [`website-and-docs-framework.md`](./website-and-docs-framework.md) -
   recommended website/docs stack, information architecture, and acceptance
   criteria.
5. [`website-community-pages.md`](./website-community-pages.md) - concrete
   website markdown pages, frontmatter, status taxonomy, and dedupe workflow.
6. [`day-to-day-tooling.md`](./day-to-day-tooling.md) and
   [`website-day-to-day-tooling.md`](./website-day-to-day-tooling.md) -
   maintainer/contributor tools that reduce daily operational friction.
7. [`implementation-backlog.md`](./implementation-backlog.md) and
   [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md) -
   prioritized next work and feature roadmap continuity.

Older overlapping files remain useful as raw historical context, but the
canonical path above should be updated first.

## Website markdown suggestion standard

Community website suggestions should be markdown-first and framework-neutral
until the project chooses a static-site framework. Each page should include:

- frontmatter with `title`, `description`, `status`, `owner`,
  `last_updated`, and `related_issue` where available
- a problem statement tied to an existing contributor or operator pain point
- historical overlap checked against this folder
- reusable framework/tool choices considered before custom implementation
- rollout, rollback, security, and maintenance notes
- measurable acceptance criteria and links to validation evidence

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.
5. Prefer GitHub-native community workflow first, then add external tools only
   when they remove real maintainer toil.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
