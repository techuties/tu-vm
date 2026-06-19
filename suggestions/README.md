# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

The repository already has a broad historical suggestion set. Treat the files listed below as the current website-ready proposal set, and treat the remaining suggestion files as historical source material unless they are explicitly promoted into this hub.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Files in this folder

- `index.md`  
  Short map for website/community readers who need the canonical path through the suggestion set.

- `historical-suggestions.md` and `website-historical-baseline.md`  
  Historical suggestion patterns and the backlog themes that should be reused before opening a new proposal.

- `website-and-docs-framework.md`  
  Recommended website stack, navigation model, content source of truth, page schema, and rollout checks.

- `website-community-framework.md` and `community-system-framework.md`  
  Community operating model, governance, ownership, suggestion lifecycle, and review standards.

- `day-to-day-tooling.md` and `website-tools-and-automation.md`  
  Concrete tooling proposals that improve day-to-day contributor productivity and maintainer operations.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced roadmap that maps historical suggestions to implementation milestones.

- `implementation-backlog.md`  
  Trimmed backlog with already-delivered items removed and next recommendations kept actionable.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

## Source-of-truth model

- **Community intake:** GitHub Issues using the `Idea / suggestion` template.
- **Discussion:** GitHub Discussions when enabled; otherwise continue in the issue.
- **Canonical proposal pages:** Markdown files in this folder when an idea needs design depth, duplicate analysis, or implementation sequencing.
- **Public website output:** generated from the canonical Markdown pages rather than maintained as a separate content copy.
- **Delivery trace:** linked issues/PRs plus `CHANGELOG.md` or Release Drafter notes.

This keeps the community system auditable in Git while still allowing a polished website to be generated later.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
