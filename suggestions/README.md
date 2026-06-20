# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

The repository already contains many historical suggestion files. Treat this page as the curated entry point: read the canonical files below first, then use the older files as supporting context when a proposal needs deeper background.

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

- `website-and-docs-framework.md`
  Reuse-first website stack recommendation, documentation information architecture, and quality gates.

- `website-community-pages.md`
  Detailed markdown page set for publishing community suggestions on the website, including templates and status-board guidance.

- `website-community-framework.md`  
  Community operating model, governance, ownership, and review standards.

- `website-day-to-day-tooling.md`
  Practical automation and maintainer tools that ease recurring triage, release, and contributor support work.

- `implementation-backlog.md`
  Trimmed backlog with implemented items removed and prioritized next recommendations.

## How to use this folder

1. Start with the historical baseline to understand repeated community themes.
2. Check the canonical website/community files above before creating a new suggestion.
3. If an idea overlaps an existing file, extend that file instead of adding another near-duplicate.
4. For implementation work, link the suggestion to a GitHub issue or pull request and update the backlog when the status changes.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.
5. Prefer mature frameworks and small tools that improve day-to-day community operations over custom systems with unclear maintenance ownership.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
