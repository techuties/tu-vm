---
title: Community Suggestions Website
description: Publishable Stage 61 website markdown for the missing n8n Postgres schema, the Open WebUI Qdrant client memory budget, and Tier 2 MCP restart policies.
last_updated: 2026-10-27
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#86 already specify the docs framework, governance, and most product contracts.

**Stage 61** (this run) records three defects checked on 2026-10-27 against the tree on `dev`, n8n 2.25.7, and Open WebUI revision `02dc3e689ceac915a870b373318b99c029ddf603`. They are not restatements of Stages 1–60.

- `docker-compose.yml` sets `DB_POSTGRESDB_SCHEMA: n8n` on the shared `ai_platform` database. No init script, `tu-vm.sh` step, or n8n 2.25.7 migration creates that schema. TypeORM 0.3.20 `hasTable` only looks in `information_schema`, then `createTable` targets `"n8n"."migrations"`.
- Open WebUI selects `qdrant_multitenancy.py` because `ENABLE_QDRANT_MULTITENANCY_MODE` defaults to true. That client creates collections with `on_disk` false and uses a 5-second HTTP timeout. `get()` and `query()` scroll with limit `999999999`. The Qdrant container is capped at 1G.
- `mcp-filesystem`, `mcp-fetch`, and `mcp-memory` set `restart: unless-stopped`. The other Tier 2 services, including `mcp-playwright`, set `restart: "no"`. Stage 18 (open PR #44) already says Tier 2 restart stays manual.

The contracts:

- Create schema `n8n` with the Postgres user this stack already has, on first init and on later starts. Keep n8n on that schema so its tables stay beside Open WebUI, not mixed into `public`.
- Set the Open WebUI client flags the pinned image already reads (`QDRANT_ON_DISK`, `QDRANT_TIMEOUT`). Leave server-side HNSW and quantization on the Stage 23 page.
- Set `restart: "no"` on the three MCP tool services so a reboot does not bring them back.

No second database, second vector engine, or new process supervisor.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–60 website pages (open PRs #27–#86) | Implement those contracts in code; do not rewrite them here |
| Official Postgres image `psql` | The client that should create schema `n8n` |
| Pinned Open WebUI Qdrant client | The code that already reads `QDRANT_ON_DISK` and `QDRANT_TIMEOUT` |
| `tu-vm.sh` Tier 2 list and dashboard start | The start path these MCP tools should keep using |

Do **not** republish Stage 60's metadata flag, `/meta` Accept header, or sync image pins. Stage 50 (open PR #76) owns AFFiNE compose start. Stage 48 (open PR #74) owns the Qdrant curl healthcheck. Stage 32 (open PR #58) owns the Qdrant API key. Stage 23 (open PR #49) owns Qdrant server HNSW and quantization. Stage 42 (open PR #68) owns MCP image pins and listener auth. Stage 18 (open PR #44) owns the memory budget and the Tier 2 restart rule this stage applies to three services.

## Page map (Stage 61)

| Page | Purpose |
|---|---|
| [n8n Postgres schema](./n8n-postgres-schema-contract.md) | Schema `n8n` exists before n8n migrates |
| [Open WebUI Qdrant client budget](./openwebui-qdrant-client-budget-contract.md) | New collections and client calls follow the flags the pinned image reads |
| [MCP tool restart policy](./mcp-tool-restart-policy-contract.md) | Filesystem, fetch, and memory stay stopped until an operator starts them |

## Expected sibling pages

Stages 1–60 live on open PRs #27–#86 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `compose-resource-budget-contract.md`, `qdrant-hnsw-quantization-contract.md`, `qdrant-api-key-contract.md`, `mcp-tool-listener-auth-contract.md`, `affine-compose-start-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 61** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| n8n tables | Official `DB_POSTGRESDB_SCHEMA` plus `CREATE SCHEMA IF NOT EXISTS` | A second Postgres service for n8n |
| Vector storage | `QDRANT_ON_DISK` and `QDRANT_TIMEOUT` on the pinned client | A second vector database |
| MCP tool lifetime | `restart: "no"` and the existing dashboard start | A new supervisor |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: n8n can migrate because schema `n8n` exists
3. Operator day-to-day: Qdrant collections created by Open WebUI fit the 1G cap the client is told to use
4. Maintainer day-to-day: Tier 2 MCP tools follow the same restart rule as the rest of Tier 2

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
