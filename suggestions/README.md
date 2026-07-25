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

Start here (avoid the overlapping historical drafts elsewhere in this folder):

1. [`index.md`](./index.md) — community system overview
2. [`website/`](./website/index.md) — **publishable website markdown** (Stage 2 living artifacts)
3. [`community-system-framework.md`](./community-system-framework.md) — lifecycle and decision scorecard
4. [`website-and-docs-framework.md`](./website-and-docs-framework.md) — static docs framework gates
5. [`day-to-day-tooling.md`](./day-to-day-tooling.md) — operator/contributor tooling pillars
6. [`implementation-backlog.md`](./implementation-backlog.md) — trimmed execution backlog

## Website markdown (Stage 2)

Publishable community pages live under [`website/`](./website/index.md):

| Page | Focus |
|---|---|
| [`website/index.md`](./website/index.md) | Community suggestions hub and boundaries |
| [`website/hardware-compatibility-matrix.md`](./website/hardware-compatibility-matrix.md) | Living host/RAM/GPU/storage fit artifact |
| [`website/persona-entry-paths.md`](./website/persona-entry-paths.md) | First-hour routes that only link existing commands/docs |
| [`website/operator-service-profiles.md`](./website/operator-service-profiles.md) | Named Tier 1/Tier 2 profiles for day-to-day ops |

Stage 1 siblings (submit guide, status board, day-to-day tools hub, MCP catalog) are proposed on a parallel branch under the same folder naming; keep one content root after merge. Vocabulary source: [`website-community-pages.md`](./website-community-pages.md).

After a static docs framework is adopted, map `website/` into the docs content root once—do not maintain two editable copies.

## Historical planning files (reference only)

Older overlapping drafts remain for archaeology (`website-*-framework.md`, numbered `0x-*.md`, etc.). Prefer the canonical path above and the `website/` pages when proposing new work.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page, `mcp-gateway`, `mcp-tools/`).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.
5. Keep suggestion intake GitHub-native; website pages are read-only guides and catalogs.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
