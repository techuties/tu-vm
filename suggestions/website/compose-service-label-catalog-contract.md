---
title: Compose Service Label Catalog Contract
description: Constructional contract for official Compose labels (tu-vm.tier, tu-vm.role) so the dashboard, CLI, and future docs site read one catalog instead of hardcoded service lists.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: community
impact: high
---

# Compose Service Label Catalog Contract

## Problem

`docker-compose.yml` has **zero** `labels:`. Tier membership, energy class, and docs links live in comments, `README.md` tables, `tu-vm.sh` arrays, and helper Python. Those copies drift: CHANGELOG 2.2 moved Tika/Qdrant/MinIO to Tier 2; current Compose and README treat them as Tier 1 again.

A future community website (and the landing dashboard) cannot generate a service catalog from Compose without scraping comments. The Compose Specification already has `labels` / `deploy.labels` for this. Stage 19 `compose-native-profiles-contract.md` is about `profiles:` for start-sets. This page is leftover **metadata** so generators and `docker ps --filter label=` stay honest.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose service keys | Source of truth for what exists |
| `README.md` Tier 1 / Tier 2 tables | Human catalog (drifts) |
| `tu-vm.sh` start/stop / doctor | Likely hardcoded name lists |
| Helper `/status/full` | Dashboard status; should consume labels later |
| `fixtures/status-full-contract.json` | JSON contract — extend, do not replace |
| Stage 7 `service-dependency-map.md` (expected sibling) | Declared start order |
| Stage 19 `compose-native-profiles-contract.md` (expected sibling) | `profiles:` for optional start, not metadata |
| Stage 6 `suggestion-corpus-registry.md` (expected sibling) | YAML for suggestions, not running services |

Out of scope:

- A new service registry microservice
- Writing labels into the helper SQLite/JSON store
- Replacing GitHub Issues as suggestion intake
- Changing `restart:` (Stage 26) or `profiles:` (Stage 19) in this PR

## Proposal

Add a small, stable label set on **every** service:

```yaml
labels:
  tu-vm.tier: "1"          # "1" always-on, "2" on-demand
  tu-vm.role: "datastore"  # datastore | proxy | dns | ai | automation | control | mcp
  tu-vm.docs: "https://github.com/techuties/tu-vm#services"
```

Suggested role map (adjust only with a README table change in the same PR):

| Role | Services (current Compose) |
|---|---|
| `datastore` | `postgres`, `redis`, `qdrant`, `minio`, `affine_postgres`, `affine_redis` |
| `ai` | `open-webui`, `ollama`, `tika`, `tika_minio_processor` |
| `automation` | `n8n`, `n8n_mcp` |
| `proxy` | `nginx` |
| `dns` | `pihole` |
| `control` | `helper_index` |
| `workspace` | `affine`, `affine_migration` |
| `mcp` | `mcp_gateway`, `langgraph_supervisor`, `browserless`, `mcp-playwright`, `mcp-filesystem`, `mcp-fetch`, `mcp-memory` |

Optional later keys (do not invent them until a consumer exists): `tu-vm.vhost`, `tu-vm.playbook`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | every service `labels` | `tier` + `role` (+ docs URL) |
| `tu-vm.sh` | doctor / help | Prefer `docker compose config --format json` labels over copied arrays |
| Helper | `/status/full` (follow-up) | Echo `tier` / `role` when present; keep fixture in sync |
| Website | this folder | Generate the service table from labels after Stage 3 docs adoption |
| README | Services tables | Must match labels in the same PR |

### Rules

1. **Compose is the catalog.** README and the website project it; they do not own a second list.
2. **Keys are namespaced.** `tu-vm.*` only. No unprefixed `tier=` that collides with other stacks.
3. **Do not use labels as a control plane.** Start/stop stays dashboard / `tu-vm.sh`. Labels classify.
4. **A new service PR must include labels.** Same bar as Stage 18 resource budgets.
5. **GitHub remains intake.** Taxonomy changes (new roles) are Issues, not silent key invention.

### Suggested contributor checklist

```text
1. Add tu-vm.tier and tu-vm.role to every service
2. Match README Tier 1/2 tables in the same commit
3. Do not add profiles: or change restart in this PR
4. docker compose config and docker compose config --format json
5. docker ps --filter label=tu-vm.tier=1 (when stack is up)
6. If helper grows a field, update fixtures/status-full-contract.json
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Service metadata | Compose `labels` | A YAML registry beside Compose |
| Optional start sets | Stage 19 `profiles:` | Encoding start policy in labels |
| Website table | Static generation from Compose JSON | Hand-maintained HTML service cards |
| Intake | GitHub Issues | Dashboard voting on labels |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: labels on all services + README alignment.
3. Helper/CLI consumers are a second PR so `/status/full` stays stable.

## Acceptance criteria

- [ ] Every service in `docker-compose.yml` has `tu-vm.tier` and `tu-vm.role`.
- [ ] README Tier tables match those labels.
- [ ] No new running service or database is added.
- [ ] `docker compose config` still renders.
- [ ] `/status/full` fixture remains valid unless a documented field was added.

## Rollback

Delete the `labels` blocks. Runtime behavior is unchanged. Generators fall back to comments/README.

## Success metrics

- New-service PRs include labels without a review round-trip.
- Website and README stop disagreeing about Tier 1 vs Tier 2.
- `docker ps --filter label=tu-vm.tier=2` lists only on-demand containers when they are running.
