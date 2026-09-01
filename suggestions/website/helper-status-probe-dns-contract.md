---
title: Helper Status Probe DNS Contract
description: Constructional contract so helper TCP probes use Compose service DNS consistently, matching Stage 28–30 leftover URL cleanup.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Helper Status Probe DNS Contract

## Problem

`helper/uploader.py` already mixes two hostname styles for **TCP liveness** probes:

| Host used today | Style | Endpoints |
|---|---|---|
| `postgres`, `redis`, `qdrant`, `ollama` | Compose **service** name | Shared `/status` bundle |
| `ai_tika`, `ai_minio`, `ai_openwebui`, `ai_n8n`, `ai_affine`, `ai_mcp_gateway`, `ai_langgraph_supervisor`, `ai_pihole`, `ai_ollama`, `ai_qdrant` | Compose **`container_name`** | Per-service `/status/*` routes |

Docker Engine inspect correctly uses `container_name` (`ai_nginx`, `ai_minio`, …). That is the Docker API identifier, not DNS.

TCP `create_connection((host, port))` from inside `ai_helper_index` should use the Compose **service** name (`minio`, `tika`, `open-webui`, …). Both resolve on `ai_network` today because Docker also registers `container_name`, but Stages 28–30 already told contributors to stop teaching `ai_*` as the application hostname. New status routes copy the nearest existing call, so the leftover style spreads.

This is not a “service discovery microservice.” It is the same leftover-DNS cleanup as Stage 30, applied to the helper.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` TCP probes | Dashboard `/status/*` |
| `docker_inspect('ai_*')` | Engine API — keep container names |
| Control start/stop map | Already pairs `(container_name, service_name)` |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | How `/status/full` may evolve |
| Stage 21 `nginx-upstream-dns-contract.md` (expected sibling) | Nginx resolver / service names |
| Stage 27 `helper-status-healthcheck-honesty-contract.md` (expected sibling) | Helper `/health` — do not rewrite |
| Stage 28/29/30 leftover service-DNS pages | Compose env URLs, not helper Python |

Out of scope:

- A Consul / CoreDNS / custom discovery container
- Renaming `container_name` values
- Changing `/status/full` JSON keys (those are product names, not DNS)
- Rewriting Stage 27 helper healthcheck or Stage 7 payload contract

## Proposal

1. Keep **Docker API** calls on `container_name`.
2. Keep **TCP / HTTP probes** on Compose **service** names.
3. Add a single module-level map (the start/stop table already has this pairing) and use it in both places so new routes cannot drift.
4. Prefer `minio` not `ai_minio`, `tika` not `ai_tika`, `open-webui` not `ai_openwebui`, `n8n` not `ai_n8n`, `pihole` not `ai_pihole`.

Do not add env vars like `MINIO_STATUS_HOST` for each probe unless a contributor is pointing the helper at a remote stack (not the default).

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Helper | `uploader.py` TCP helpers | Service DNS |
| Helper | `docker_inspect` / start / kill | Unchanged container names |
| Tests | `validate_status_full_contract.py` | JSON shape unchanged |
| Docs | Helper contribution contract | One sentence: API vs DNS |

### Rules

1. **Engine API ≠ DNS.** `container_name` for inspect/start/stop/kill.
2. **Network probes use service names.** Same rule as Compose env URLs.
3. **Do not change JSON field names** just to match DNS (`minio` stays `minio`).
4. **No discovery product.** Docker embedded DNS is the framework.
5. **GitHub remains intake.**

### Suggested contributor checklist

```text
1. Grep create_connection and docker_inspect in helper/uploader.py
2. Split “engine id” vs “dns name” in the existing pair map
3. Point TCP probes at service names
4. python3 -m py_compile helper/uploader.py
5. python3 scripts/validate_status_full_contract.py
6. Live: /status/minio and /status/tika still flip true/false
7. Do not add a discovery sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Container identity | Existing `container_name` + Docker API | Renaming every container |
| In-network reachability | Compose service DNS | `ai_*` folklore in new code |
| Status contract | Existing fixture validator | A new status schema |
| Helper health | Stage 27 `/health` | Scraping Docker as a healthcheck |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one helper PR. Restart `helper_index` (bind-mount already picks up the file after recreate).
3. Dashboard behavior is unchanged if both names still resolve; the win is consistency for the next contributor.

## Acceptance criteria

- [ ] New and existing TCP probes use service names.
- [ ] Docker inspect/start/stop still use `container_name`.
- [ ] `/status/full` fixture still validates.
- [ ] No discovery service is added.
- [ ] Stage 27 helper `/health` page is not rewritten.

## Rollback

Restore the previous host strings. Both names resolve on the current network.

## Success metrics

- New `/status/*` routes copy the service-name helper, not `ai_*`.
- Stage 28–30 DNS cleanup has a Python counterpart.
- Fewer “MinIO is down” false reports if someone later drops `container_name`.
