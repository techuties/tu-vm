---
title: Platform Redis Durability Contract
description: Constructional contract for making ai_redis AOF/RDB and the existing redis_data volume an explicit policy, without sharing affine_redis or introducing a second cache product.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Platform Redis Durability Contract

## Problem

Platform Redis already has a named volume, but persistence is turned off:

```text
command: redis-server --requirepass … --maxmemory … --save "" --appendonly no --tcp-keepalive 60
volumes:
  - redis_data:/data
```

Open WebUI sessions and config keys (`open-webui:config:…`) live in this instance. `tu-vm.sh` already reads and writes those keys through `redis-cli`. A recreate or crash drops them even though `redis_data` is mounted and already listed in `create_backup()`.

Stage 20 covers **AFFiNE** Redis, which has no volume today. This page is the **platform** Redis (`ai_redis` / service `redis`) only.

Community PRs that notice “Open WebUI forgot STT settings after recreate” tend to propose Redis Cloud, KeyDB, or pointing AFFiNE at the same cache.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `redis` | Digest-pinned; `redis_data:/data`; `--save "" --appendonly no` |
| `tu-vm.sh` STT helpers | `redis-cli` GET/SET on `open-webui:config:*` |
| `create_backup()` | Already tars `docker_redis_data` when the volume exists |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Day-to-day Redis hygiene, not AOF policy |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Archive format |
| Stage 20 `affine-redis-durability-contract.md` (expected sibling) | Dedicated AFFiNE Redis only |

Out of scope:

- Merging AFFiNE onto `ai_redis`
- Redis Sentinel / Cluster / a hosted cache
- Changing `--maxmemory` / LRU as a substitute for durability
- Enabling AOF on `affine_redis` (Stage 20)

## Proposal

Name the durability choice for platform Redis and make the existing volume do real work.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Policy | `redis` `command:` | Document AOF vs RDB vs keep-ephemeral |
| Volume | `redis_data:/data` | Already present—do not add a second volume |
| Backup | `create_backup()` | Keep `docker_redis_data`; no new dump tool |
| Energy | AOF fsync | Laptop-friendly `everysec` if AOF is on |
| Isolation | Service name | Never point AFFiNE at `redis` / `ai_redis` |

### Rules

1. **Keep a dedicated platform Redis.** Open WebUI / n8n cache must not share `affine_redis`.
2. **Name the choice.** Either (a) keep ephemeral and say so, or (b) enable `--appendonly yes` (prefer `appendfsync everysec`) so `/data` is meaningful. A volume with `--appendonly no --save ""` is worse than either explicit choice.
3. **Default recommendation.** Prefer AOF + the existing volume. Operators who want zero Redis disk can keep the current flags behind a comment.
4. **Do not invent `redis-dump`.** Backups stay the volume tarball already in `create_backup()`.
5. **Healthcheck stays `redis-cli ping`.** Durability must not break `service_healthy` for Open WebUI.
6. **Password and maxmemory stay.** Durability is orthogonal to `--requirepass` and LRU.
7. **GitHub remains intake.** Requests for ElastiCache stay Issues.

### Suggested contributor checklist

```text
1. Read the redis service in docker-compose.yml
2. Leave redis_data:/data in place
3. Set appendonly/save flags to match the chosen policy
4. Keep requirepass, maxmemory, and ping healthcheck
5. Confirm create_backup() still includes docker_redis_data
6. Confirm affine_redis is unchanged
7. Note disk/energy cost of AOF on laptops
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Cache durability | Official Redis AOF + existing volume | KeyDB / Redis Cloud |
| Backup | Existing `create_backup()` volume loop | A platform-only Redis dump CLI |
| Isolation | Current `redis` vs `affine_redis` | Sharing one Redis |
| Repair | Existing `tu-vm.sh` redis-cli helpers | A new cache admin UI |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `--appendonly yes --appendfsync everysec` (or an explicit ephemeral comment) on service `redis` only.
3. Optional: `redis-cli INFO persistence` in `tu-vm.sh doctor` when `ai_redis` is up.

## Acceptance criteria

- [ ] Dedicated platform Redis rule is stated.
- [ ] Ephemeral vs AOF is an explicit, documented choice.
- [ ] Recommended path reuses `redis_data` (no second volume).
- [ ] AFFiNE Redis is out of scope.
- [ ] Backup loop does not gain a new dump format.

## Rollback

Restore `--save "" --appendonly no`. The named volume can remain. AFFiNE Redis and Postgres are unaffected.

## Success metrics

- Recreating `ai_redis` does not silently wipe Open WebUI config keys when durability is on.
- Backup archives still include `docker_redis_data` without a new tool.
- No PR merges AFFiNE onto the platform Redis.
