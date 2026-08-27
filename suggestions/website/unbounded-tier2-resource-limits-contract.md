---
title: Unbounded Tier 2 Resource Limits Contract
description: Constructional contract for deploy.resources on n8n, AFFiNE, MCP gateway, LangGraph supervisor, and n8n-mcp—the leftover unbounded on-demand services after Stages 26 and 27.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Unbounded Tier 2 Resource Limits Contract

## Problem

Stage 18 asked every Compose change to declare an energy-aware budget. Stage 26 covered the unbounded **Tier 1** pair (Tika, MinIO). Stage 27 covered `helper_index`. These **on-demand** services still have no `deploy.resources`:

| Service | Why it hurts when started |
|---|---|
| `n8n` | Changelog once cited 768M / 0.4 CPU; Compose no longer states it |
| `affine` / `affine_migration` | Node workspace can grow without a cap |
| `affine_postgres` / `affine_redis` | Dedicated data plane, still uncapped |
| `mcp_gateway` | First-party Python; no cgroup budget |
| `langgraph_supervisor` | First-party Python; no cgroup budget |
| `n8n_mcp` | Enrichment sidecar; no cgroup budget |

Ollama, Open WebUI, browserless, and `mcp-tools/*` already have limits. Starting “just n8n + AFFiNE” on an 8 GB laptop can still OOM the host because those stacks are unlimited.

This is not a new governor. It is the leftover of Stage 18 / 26 / 27.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Existing `deploy.resources` on postgres, redis, qdrant, ollama, open-webui, pihole, nginx, browserless, mcp-tools, processor | Pattern to copy |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | Community budget rules |
| Stage 26 `tika-minio-resource-limits-contract.md` (expected sibling) | Same key, Tier 1 leftover |
| Stage 27 `helper-resource-limits-contract.md` (expected sibling) | Same key, helper leftover |
| CHANGELOG 2.0 n8n 768M / 0.4 CPU | Historical starting point |

Out of scope:

- `cpu_shares` / `blkio_weight` (Stage 27) and `oom_score_adj` (Stage 26)
- Tika / MinIO / helper budgets (already specified)
- A Kubernetes-style HPA or a custom cgroup daemon
- Changing `restart: "no"` (Stage 26 MCP honesty)

## Proposal

Add `deploy.resources` to every remaining unbounded service. Start from documented historical values; do not invent a second budget file.

### Suggested starting budgets

| Service | Memory limit | CPU limit | Notes |
|---|---|---|---|
| `n8n` | 768M | 0.40 | Restore CHANGELOG 2.0 numbers |
| `n8n_mcp` | 512M | 0.25 | Sidecar, not the editor |
| `affine` | 1G | 0.50 | Workspace UI + API |
| `affine_migration` | 512M | 0.25 | One-shot; can be higher if migrate OOMs |
| `affine_postgres` | 512M | 0.50 | Match platform postgres |
| `affine_redis` | 128M | 0.10 | Smaller than platform redis |
| `mcp_gateway` | 512M | 0.50 | Until measured otherwise |
| `langgraph_supervisor` | 512M | 0.50 | Until measured otherwise |

Reservations should stay at about half the limit so several Tier 2 services can be **stopped** without hoarding RAM.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | listed services | `deploy.resources` limits + reservations |
| Docs | this page + Stage 18 | Unbounded Tier 2 is a defect |
| Dashboard | no change | Start/stop already exists |

### Rules

1. **Copy the existing key.** Use `deploy.resources`, not a wrapper script that runs `docker update`.
2. **Do not share platform Redis or Postgres** to “save” AFFiNE budget (Stage 20).
3. **Raise via Issue + measurement**, not by deleting the limit.
4. **Keep `restart: "no"`.** Limits are not a license to auto-start.
5. **GitHub remains intake.** Requests for “unlimited when on AC power” stay Issues (Stage 7 profiles).

### Suggested contributor checklist

```text
1. Confirm Tika, MinIO, helper, Ollama, browserless already have limits
2. Add deploy.resources to n8n, n8n_mcp, affine*, mcp_gateway, langgraph_supervisor
3. Use the table above as the first PR; do not invent a budgets.yaml
4. Confirm docker compose config still renders
5. Start n8n alone and confirm docker stats respects the cap
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| RAM/CPU cap | Compose `deploy.resources` | Unbounded on-demand images |
| Historical n8n numbers | CHANGELOG 2.0 | Guessing 4G “to be safe” |
| Community changes | Stage 18 budget rules | A new resource-governor service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose PR for the leftover services.
3. If AFFiNE migrate OOMs, raise `affine_migration` only.

## Acceptance criteria

- [ ] `n8n`, `n8n_mcp`, `affine`, `affine_migration`, `affine_postgres`, `affine_redis`, `mcp_gateway`, and `langgraph_supervisor` declare `deploy.resources`.
- [ ] n8n’s first numbers match CHANGELOG 2.0 unless an Issue records a measured change.
- [ ] Reservations do not exceed half the limit without a comment.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] `restart:` policies are unchanged.

## Rollback

Delete the new `deploy.resources` blocks. Volumes and env are unchanged.

## Success metrics

- Starting n8n + AFFiNE on 8 GB no longer has uncapped first-party containers.
- Stage 18 reviews reject new Tier 2 services without a budget.
- Helper / Tika / MinIO pages stay the source for those services.
