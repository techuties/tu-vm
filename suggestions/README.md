# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Current review note

The `suggestions/` folder already exists and contains historical website, tooling, and governance proposals. Treat this folder as the source of truth for constructional suggestions: before adding a new proposal, check for overlap and merge useful detail into the closest canonical file.

Current canonical files for the website/community system:

- `website-community-platform.md` - staged community suggestion system architecture.
- `website-and-docs-framework.md` - website/docs framework recommendation and publishing model.
- `community-workflow-and-governance.md` - lifecycle, triage, roles, scoring, and completion rules.
- `day-to-day-tooling-and-automation.md` - practical tools for maintainers and contributors.
- `implementation-backlog.md` - trimmed implementation backlog and priority order.

Older overlapping files are still useful historical material, but new work should update the canonical files above unless a genuinely new topic appears.

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

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
