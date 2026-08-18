---
title: AFFiNE Redis Durability Contract
description: Constructional contract for giving affine_redis a named volume and an explicit AOF/RDB policy so collaborative workspace cache survives container recreation without a second Redis product.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# AFFiNE Redis Durability Contract

## Problem

`affine_redis` runs:

```text
command: redis-server --save "" --appendonly no --tcp-keepalive 60
```

with **no named volume**. Persistence is intentionally off. `affine_postgres_data`, `affine_storage`, and `affine_config` already exist; Stage 19 asks `create_backup()` to include those volumes. Redis for AFFiNE is still ephemeral: `docker compose up -d --force-recreate affine_redis` drops cache, pub/sub state, and any AFFiNE features that expect Redis to outlive the container.

Community PRs that notice “AFFiNE forgot my session” tend to propose Redis Cloud, KeyDB, or a second cache container.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `affine_redis` | `redis` digest; `--save "" --appendonly no`; no `volumes:` |
| `affine_postgres_data` / `affine_storage` / `affine_config` | Durable AFFiNE data today |
| `redis` (platform) | Separate Tier-1 Redis for Open WebUI / n8n — do not share |
| Stage 9 `affine-collaboration-contribution-contract.md` (expected sibling) | Product recipes, not Redis durability |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Postgres/Redis/Qdrant hygiene for the **platform** Redis |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Archive format |
| Stage 19 `affine-backup-volume-coverage-contract.md` (expected sibling) | Backup loop for existing named volumes |

Out of scope:

- Merging AFFiNE Redis into the platform `redis` service
- Redis Sentinel / Cluster / a hosted cache
- Changing AFFiNE Postgres as a substitute for Redis durability
- Enabling AOF on the **platform** Redis without its own contract

## Proposal

Give `affine_redis` an **explicit durability policy** and a named volume, then include that volume in the existing backup loop.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Volume | `affine_redis_data:/data` | New named volume next to `affine_postgres_data` |
| Policy | `command:` | Document AOF vs RDB vs keep-ephemeral |
| Backup | `tu-vm.sh` `create_backup()` | Add `affine_redis_data` only after it exists |
| Energy | AOF fsync | Laptop-friendly `everysec` if AOF is on |
| Isolation | Compose service name | Never point AFFiNE at `ai_redis` |

### Rules

1. **Keep a dedicated Redis.** AFFiNE must not share the Open WebUI/n8n Redis. Different restart and credential domains.
2. **Name the choice.** Either (a) keep ephemeral and document it, or (b) mount `/data` and enable `--appendonly yes` (prefer `appendfsync everysec`). Silent `--save "" --appendonly no` with a volume is worse than either explicit choice.
3. **Default recommendation.** For a collaborative workspace, prefer AOF + named volume. Operators who want zero Redis disk can keep the current flags behind a comment, not as an undocumented surprise.
4. **Do not dump RDB into Postgres backups.** `database.sql` stays platform Postgres; AFFiNE Postgres stays `affine-database.sql` per Stage 19. Redis is a volume tarball.
5. **Healthcheck stays `redis-cli ping`.** Durability must not break the existing `service_healthy` gate for `affine` / `affine_migration`.
6. **GitHub remains intake.** Requests for ElastiCache/Redis Cloud stay Issues.

### Suggested contributor checklist

```text
1. Read affine_redis in docker-compose.yml
2. Add affine_redis_data:/data (or document remaining ephemeral)
3. Set appendonly/save flags to match the chosen policy
4. Keep the ping healthcheck
5. If durable, add the volume to create_backup() in the same PR
6. Confirm platform redis is unchanged
7. Note disk/energy cost of AOF on laptops
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Cache durability | Official Redis AOF + named volume | KeyDB / Redis Cloud |
| Backup | Existing `create_backup()` volume loop | An AFFiNE-only Redis dump tool |
| Isolation | Current `affine_redis` service | Sharing `ai_redis` |
| Restore | Stage 18 restore path | Manual `docker cp` runbooks only |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: named volume + `--appendonly yes --appendfsync everysec` (or an explicit ephemeral comment) and backup-loop inclusion.
3. Optional: `redis-cli INFO persistence` in `tu-vm.sh doctor` when AFFiNE is up.

## Acceptance criteria

- [ ] Dedicated AFFiNE Redis rule is stated.
- [ ] Ephemeral vs AOF is an explicit, documented choice.
- [ ] Recommended path uses a named volume on `/data`.
- [ ] Backup loop inclusion is tied to the volume existing.
- [ ] Platform Redis is out of scope.

## Rollback

Remove the volume mount and restore `--save "" --appendonly no`. Drop `affine_redis_data` from backup independently. AFFiNE Postgres volumes are unaffected.

## Success metrics

- Recreating `affine_redis` does not silently wipe workspace cache when durability is on.
- Backup archives include Redis data only when the named volume exists.
- No PR merges AFFiNE onto the platform Redis.
