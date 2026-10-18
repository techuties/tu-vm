---
title: Redis Memory Headroom Contract
description: Constructional contract so platform Redis evicts inside the 256M cgroup instead of sharing that exact byte count with maxmemory and a 1GB client query cap.
last_updated: 2026-10-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Redis Memory Headroom Contract

## Problem

Platform Redis is given two memory ceilings that are the same number, plus a client buffer default that is larger than the container.

The `redis` service runs:

```text
redis-server ... --maxmemory ${REDIS_MAXMEMORY:-256mb} --maxmemory-policy ${REDIS_MAXMEMORY_POLICY:-allkeys-lru} --save "" --appendonly no
```

The same service sets `deploy.resources.limits.memory: 256M`.

The image pin `redis@sha256:09160599abd229764c0fb44cb6be640294e1d360a54b19985ab4843dcf2d90f1` reports `REDIS_VERSION=8.8.0` (image created 2026-05-26). In that tag, `memtoull` maps the unit `mb` to `1024*1024`. `256mb` is 268435456 bytes. Docker's `256M` is 256 mebibytes, the same count.

Redis eviction watches `used_memory` against `maxmemory`. The cgroup kills the process when RSS reaches the limit. Those counters are not the same: RSS includes allocator overhead above the dataset Redis is willing to evict. With the two limits equal, that overhead has no spare mebibytes inside the cgroup.

The same Redis 8.8.0 tree sets `client-query-buffer-limit` with default `1024*1024*1024` (`src/config.c`). The Compose command does not override it. One large command may grow that buffer toward 1GB. The cgroup is 256M. Key eviction does not shrink the buffer of the command Redis is still reading.

Persistence is already off (`--save ""` and `--appendonly no`), so this is not a fork-on-rewrite double. `allkeys-lru` is already the policy. The gap is headroom, not a missing eviction policy.

Checked on 2026-10-18 against `docker-compose.yml` and Redis tag `8.8.0` (`src/util.c` `memtoull`, `src/config.c` `client-query-buffer-limit`). No Redis process was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `redis` `command` | Password, maxmemory, policy, disabled persistence, keepalive |
| `deploy.resources.limits.memory: 256M` | Cgroup the command must fit |
| Redis 8.8.0 `memtoull` | Unit table that makes `256mb` equal `256M` |
| Redis 8.8.0 `client-query-buffer-limit` | 1GB default the command never sets |
| Stage 21 Redis durability (open PR #47) | AOF/RDB choice. That page says not to swap maxmemory in as a durability substitute. This page does not enable persistence |
| Stage 24 Redis ACL (open PR #50) | Users and the password. Leave `--requirepass` alone |
| Stage 29 healthcheck auth (open PR #55) | `redis-cli -a` ping. Leave the healthcheck alone |
| `affine_redis` | Separate service, no maxmemory and no password. Stage 28 owns its `requirepass`. Do not retune it here |

Out of scope:

- Raising the 256M limit in the same change
- Enabling RDB or AOF
- Redis Sentinel, Redis Cluster, or a second cache
- Changing `REDIS_PASSWORD` or the healthcheck
- AFFiNE's Redis

## Proposal

Keep the official image, the password, `allkeys-lru`, and disabled persistence. Put both Redis limits under the cgroup that already exists.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Dataset | `--maxmemory` | `192mb` while the limit stays `256M` (192 mebibytes of dataset, about 64 mebibytes of spare RSS) |
| Query cap | `--client-query-buffer-limit` | `32mb`, which is under the cgroup and far under the 1GB default |
| Env | `REDIS_MAXMEMORY` | Default `192mb` in Compose and `env.example` if that key is documented. Do not leave the default at `256mb` |
| Proof | `CONFIG GET` | `maxmemory` is 201326592 and `client-query-buffer-limit` is 33554432. `INFO memory` shows `maxmemory` below `total_system_memory` when the cgroup is visible |

Example command, with the password and the other flags unchanged:

```text
redis-server --requirepass <existing password flag> --maxmemory ${REDIS_MAXMEMORY:-192mb} --client-query-buffer-limit 32mb --maxmemory-policy ${REDIS_MAXMEMORY_POLICY:-allkeys-lru} --save "" --appendonly no --tcp-keepalive 60
```

### Rules

1. **Leave a gap under the cgroup.** `maxmemory` in bytes must be lower than `256M`.
2. **Cap the query buffer.** `client-query-buffer-limit` must be lower than the cgroup. 32mb is enough for session cache commands.
3. **Keep eviction.** `allkeys-lru` stays. This page does not switch to `noeviction`.
4. **Keep persistence off.** Durability is Stage 21. Do not add `--appendonly yes` here.
5. **Do not touch AFFiNE Redis.** Different container, different contract.

### Suggested contributor checklist

```text
1. Render the redis command and confirm maxmemory is 192mb
2. Confirm client-query-buffer-limit is present and at most 32mb
3. Confirm the memory limit is still 256M
4. Confirm --save "" and --appendonly no are still on the command
5. On a running container, CONFIG GET maxmemory is below 268435456
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Dataset cap | `--maxmemory` on the existing `redis-server` command | A memory sidecar |
| Query cap | `--client-query-buffer-limit` | A proxy in front of Redis |
| Eviction | Existing `allkeys-lru` | `noeviction` plus a larger VM |
| Image | The pinned Redis 8.8.0 digest | A rebuilt Redis |
