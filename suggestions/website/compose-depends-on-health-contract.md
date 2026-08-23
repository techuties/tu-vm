---
title: Compose Depends-On Health Contract
description: Constructional contract for aligning depends_on conditions with existing healthchecks, without a custom orchestrator or rewriting tu-vm.sh tier start maps.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Compose Depends-On Health Contract

## Problem

Compose already declares dependencies, but conditions are inconsistent:

- `open-webui` waits for `postgres` `service_healthy`, then `redis`, `qdrant`, `tika`, and `minio` as `service_started` even though those four have healthchecks.
- `tika_minio_processor` uses `service_started` for `tika` and `minio`.
- `nginx` lists `helper_index` with no condition (and helper has no healthcheck).
- AFFiNE correctly uses `service_healthy` and `service_completed_successfully`.
- `n8n` waits for Postgres healthy but not for Redis (it does not use platform Redis).

A laptop cold start can mark Open WebUI "up" while Qdrant or MinIO is still booting. Dashboard and RAG then fail in ways that look like product bugs.

Stage 7 covers **tu-vm.sh dependency maps** for Tier 2 start/stop. Stage 13 covers **honest healthcheck probes**. This page is only **which Compose `depends_on` condition to use when a healthcheck already exists**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `depends_on` | Mixed `service_started` / `service_healthy` |
| Service `healthcheck` blocks | Present on postgres, redis, qdrant, minio, tika, nginx, AFFiNE deps |
| `tu-vm.sh` start/stop | Tier arrays; does not replace Compose conditions |
| Stage 7 `service-dependency-map.md` (expected sibling) | CLI/dashboard start ordering |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Probe honesty (`nginx -t`, `pg_isready`) |
| Stage 19 `compose-native-profiles-contract.md` (expected sibling) | profiles vs tier arrays |

Out of scope:

- A custom orchestrator, `wait-for-it` sidecar, or restart loop in helper
- Adding healthchecks to intentionally on-demand Tier 2 services (Ollama, n8n)
- Changing probe intervals (that is the healthcheck-interval env contract)
- Introducing Kubernetes / Swarm

## Proposal

When a dependency **has** a healthcheck, dependents use `condition: service_healthy`. When a dependency **intentionally** has no healthcheck (Tier 2 manual services, helper to avoid a cycle), keep `service_started` or omit `depends_on`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Healthy wait | `open-webui`, `tika_minio_processor` | `service_healthy` on redis/qdrant/tika/minio |
| No-cycle | `nginx` → `helper_index` | Keep started/omit; do not add a helper healthcheck just to satisfy nginx |
| Tier 2 | ollama, n8n | No new healthcheck; n8n may keep postgres healthy only |
| Docs | this page + compose comments | Why a given edge is started vs healthy |

### Rules

1. **Healthcheck exists ⇒ healthy condition.** Do not use `service_started` to "save a few seconds" on a service that already has a probe.
2. **No healthcheck ⇒ do not fake one.** Tier 2 idle services stay healthcheck-free so Compose will not keep them "unhealthy" while stopped.
3. **Do not create cycles.** Nginx must not wait for helper health if helper would wait for nginx. Document the cycle; prefer `service_started` or omit.
4. **CLI maps stay Stage 7.** `tu-vm.sh start-service` may still start Ollama when Open WebUI needs it; that is not a Compose `depends_on`.
5. **Energy intervals stay separate.** Switching to `service_healthy` uses the **existing** probe; do not tighten 180s intervals in the same PR.
6. **GitHub remains intake.** Requests for Kubernetes or a start orchestrator stay Issues.

### Suggested contributor checklist

```text
1. List every depends_on edge and the dependency's healthcheck
2. Flip service_started to service_healthy where a probe already exists
3. Leave Tier 2 services without healthchecks
4. Do not add wait-for-it containers
5. Comment any remaining service_started edge (cycle or no probe)
6. Confirm docker compose config still renders
7. Keep tu-vm.sh tier arrays unchanged unless Stage 7 work is explicit
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Startup gating | Compose `condition: service_healthy` | `wait-for-it`, custom ready loops |
| On-demand order | Stage 7 `tu-vm.sh` maps | Compose depends_on for stopped Tier 2 |
| Probe design | Stage 13 healthcheck contract | Dummy `exit 0` healthchecks |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: align Open WebUI and `tika_minio_processor` conditions with existing probes.
3. Record leftover `service_started` edges in compose comments.

## Acceptance criteria

- [ ] Dependents of postgres/redis/qdrant/tika/minio use `service_healthy` when those probes exist.
- [ ] Tier 2 services without healthchecks are unchanged.
- [ ] No wait-for-it sidecar or helper-based orchestrator is added.
- [ ] Nginx/helper cycle is documented, not "fixed" with a fake probe.
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Restore previous `condition:` values. Images and volumes are unchanged.

## Success metrics

- Open WebUI first request after a cold start sees Qdrant/MinIO ready.
- Processor logs stop showing connection retries that are really start races.
- Contributors extend `depends_on` with a condition, not a new tool.
