# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Publishable website markdown (start here)

Curated, read-only pages for a future static docs site live in [`website/`](./website/index.md).

**Stage 6** (current) adds content integrity, operator reliability, and non-MCP community catalogs:

- Suggestion corpus registry (stop duplicate reinvention)
- Website frontmatter / link CI contract
- n8n workflow catalog
- Observability contribution contract (Prometheus/Grafana)
- Backup/restore community drill
- Air-gapped docs mirror
- Deprecation notice framework

Stages 1–5 sibling pages are expected from open PRs #27–#31; merge hubs using the Stage 4 `stage-merge-playbook.md` (extend merge order through Stage 6) rather than rewriting those contracts here.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Files in this folder

- [`website/`](./website/index.md) — Publishable website markdown (canonical community site content root until docs-framework adoption).
- `website-historical-baseline.md` — Historical suggestion patterns and how they were merged into a single framework.
- `website-information-architecture.md` — Detailed website structure, content model, and docs framework recommendation.
- `website-community-framework.md` — Community operating model, governance, ownership, and review standards.
- `website-contributor-tooling.md` — Concrete tooling proposals that improve day-to-day contributor productivity.
- `website-roadmap-from-historical-suggestions.md` — Sequenced roadmap that maps historical suggestions to implementation milestones.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
