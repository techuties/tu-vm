# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

Recent repository history also shows this folder has been iterated several times through commits such as `Document community suggestion system`, `docs: consolidate community website suggestions`, and multiple merged `community-suggestions-framework-*` / `community-suggestions-documentation-*` branches. Treat this folder as the historical archive and starting point for new website/community work.

## Canonical website suggestion set

Use these files first when planning website or community-system work:

- `website-historical-baseline.md`  
  What was already proposed repeatedly, what should be preserved, and where duplicate proposals should be merged.

- `website-information-architecture.md`  
  Recommended website structure, docs taxonomy, content model, accessibility baseline, and static-site framework choices.

- `website-community-framework.md`  
  Governance, roles, review lanes, ownership expectations, and security guardrails for community contributions.

- `website-contributor-tooling.md`  
  Developer/contributor tools that make day-to-day work easier without replacing the existing `tu-vm.sh` and script model.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced implementation roadmap that carries forward historical feature directions.

- `implementation-backlog.md`  
  Current trimmed backlog with implemented/superseded items separated from next recommendations.

## Reuse-first standards

Before creating a new suggestion file or proposing a custom subsystem:

1. Search this folder for an existing overlapping suggestion.
2. Prefer mature frameworks and existing repository surfaces:
   - GitHub Issues, labels, templates, Discussions, Release Drafter, Dependabot, and Actions for community workflow.
   - Docusaurus or Astro/Starlight for a markdown-first website, rather than custom routing/build logic.
   - Existing `tu-vm.sh`, helper API, Nginx dashboard, scripts, and playbooks for operator workflows.
3. Add implementation steps, risks, rollback notes, and measurable success signals.
4. Link accepted/implemented suggestions to issues, PRs, commits, changelog entries, or releases.

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
