---
title: Compose Stop Grace Period Contract
description: Constructional contract for SIGTERM drain via Compose stop_grace_period on stateful Tier 1 services, without a shutdown sidecar or a second orchestrator.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Compose Stop Grace Period Contract

## Problem

`docker compose stop` / `restart` / host reboot send SIGTERM, then SIGKILL after **10 seconds** (Compose default). None of the services in `docker-compose.yml` set `stop_grace_period` or `stop_signal`.

That default is too short for:

- **postgres** and **affine_postgres** — checkpoint, WAL flush, clean shutdown
- **qdrant** — HNSW / collection flush into `qdrant_data`
- **minio** — in-flight PUT/COPY and erasure-coded writes
- **open-webui** — in-flight embeddings and upload sync
- **tika** — OCR jobs that already use 15-minute XML timeouts

Laptop energy work already lengthened **healthcheck** intervals to 180s. Stop paths were never given the same honesty. Operators see "unhealthy after reboot" or silent RAG corruption that looks like a product bug.

Stage 10 covers **volume/disk hygiene**. Stage 13 covers **probe commands**. Stage 21 covers **Qdrant snapshots**. Stage 22 covers **Postgres dump-plus-volume**. This page is only **how long Compose waits after SIGTERM before SIGKILL**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `stop` / `restart` | Default 10s grace |
| `tu-vm.sh` start/stop / daily checkup | Calls Compose; does not wrap shutdown |
| Postgres / Qdrant / MinIO official images | Handle SIGTERM if given time |
| Stage 7 `tier2-idle-autostop-policy.md` (expected sibling) | When to stop Tier 2, not how long to wait |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | CPU/memory; not shutdown timers |
| Stage 21 `qdrant-snapshot-compaction-contract.md` (expected sibling) | Snapshot API, not process drain |
| Stage 22 `postgres-wal-pitr-policy-contract.md` (expected sibling) | Backup policy, not stop grace |

Out of scope:

- A shutdown sidecar, `wait-for-it`, or helper that polls "quiet" before stop
- Changing `restart:` policies or Tier 1 vs Tier 2 membership
- Kubernetes `terminationGracePeriodSeconds` or Swarm
- Lengthening Tika **request** timeouts (that is the XML config contract)

## Proposal

Set explicit `stop_grace_period` on stateful and long-job services. Keep the Compose default only for truly stateless proxies that already drain in <10s (Nginx, helper). Prefer official image SIGTERM behavior over a custom `stop_signal`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Datastores | `postgres`, `affine_postgres`, `qdrant`, `minio`, `redis`, `affine_redis` | `stop_grace_period: 60s` (or 30s for Redis) |
| Long jobs | `tika`, `tika_minio_processor`, `open-webui` | `90s` so OCR/upload can finish or abort cleanly |
| Stateless | `nginx`, `helper_index`, `pihole` | Keep default or document why 10s is enough |
| Tier 2 | ollama, n8n, MCP tools | Optional 30s; do not block energy autostop |

### Rules

1. **Name the timer in Compose.** Do not rely on the undocumented 10s default for services that flush disks.
2. **Do not invent a drain supervisor.** Official images already handle SIGTERM. Extra wrappers hide failures.
3. **Do not use SIGKILL as the first signal.** Leave `stop_signal` unset unless a vendor image ignores SIGTERM (document that exception).
4. **Tier 2 idle-stop stays Stage 7.** Longer grace must not prevent opt-in autostop; 30–60s is enough.
5. **Backup jobs stay Stage 18/22.** Graceful stop is not a substitute for `tu-vm.sh backup`.
6. **GitHub remains intake.** Requests for a global "smart shutdown orchestrator" stay Issues.

### Suggested contributor checklist

```text
1. List services that persist volumes or run multi-minute jobs
2. Add stop_grace_period (30s Redis, 60s datastores, 90s Tika/Open WebUI)
3. Leave nginx/helper on default unless a hang is proven
4. Do not add a shutdown sidecar or helper pre-stop hook
5. Confirm docker compose config still renders
6. On a test stack, compose stop postgres and confirm a clean log line before kill
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Process drain | Compose `stop_grace_period` + image SIGTERM | Custom pre-stop containers |
| Snapshot/backup | Existing `tu-vm.sh backup` / Qdrant API | Treating grace as a backup |
| Idle stop | Stage 7 policy | Blocking autostop with 10-minute grace |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add grace periods on postgres, qdrant, minio, tika, and open-webui first.
3. Comment any service that keeps the 10s default on purpose.

## Acceptance criteria

- [ ] Stateful Tier 1 services declare `stop_grace_period` ≥ 30s.
- [ ] No shutdown sidecar or helper orchestrator is added.
- [ ] `stop_signal` stays default unless a vendor image requires an exception.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] A local `compose stop postgres` shows a clean shutdown in logs (no immediate SIGKILL).

## Rollback

Remove `stop_grace_period` keys. Images and volumes are unchanged.

## Success metrics

- Reboot/restart tickets citing "corrupt Qdrant / MinIO after stop" drop.
- Processor/Tika logs show SIGTERM abort instead of mid-write kill.
- Contributors set grace in Compose instead of proposing a new orchestrator.
