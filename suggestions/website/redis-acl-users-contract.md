---
title: Redis ACL Users Contract
description: Constructional contract for optional Redis ACL users on top of today's requirepass, without Redis Cluster, Redis Stack, or a shared password across every client.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: security
impact: medium
---

# Redis ACL Users Contract

## Problem

Platform Redis (`ai_redis`) authenticates with a single `--requirepass` and the implicit `default` user. Open WebUI already connects as `redis://default:${REDIS_PASSWORD}@redis:6379`. Every other client that learns that password gets `+@all`.

ACL files, per-service users, and command categories are unused. `affine_redis` is a separate instance with no password at all (Stage 20 durability is about AOF/RDB, not auth).

A contributor who wants "safer Redis" often proposes Redis Stack, Redis Cluster, or a sidecar ACL UI. None of those are needed for a single-node LAN cache.

Stage 20 covers AFFiNE Redis **volume durability**. Stage 21 covers platform Redis **AOF/RDB policy**. This page is only **how optional ACL users layer on requirepass**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `redis.command` | `--requirepass` + maxmemory; `--save "" --appendonly no` |
| Open WebUI `REDIS_URL` | Already uses the `default` user |
| `env.example` `REDIS_PASSWORD` | Single shared secret |
| Stage 20 `affine-redis-durability-contract.md` (expected sibling) | AFFiNE Redis volume / AOF; do not share `ai_redis` |
| Stage 21 `platform-redis-durability-contract.md` (expected sibling) | Persistence policy for `ai_redis` |
| Stage 22 `compose-secrets-contribution-contract.md` (expected sibling) | Optional `*_FILE`; `.env` stays clone path |

Out of scope:

- Redis Cluster, Sentinel, or Redis Stack / RedisInsight products
- Replacing Redis with KeyDB or Dragonfly
- Putting AFFiNE on platform Redis
- Changing maxmemory policy in the same PR as ACL work

## Proposal

Keep `--requirepass` as the clone-path default. Add an **opt-in** ACL file only when a second client needs a narrower user.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | `redis.command` `--requirepass` | Unchanged for new clones |
| Opt-in ACL | bind-mount `redis/users.acl` + `--aclfile` | `user default` plus named users |
| Clients | Open WebUI `REDIS_URL`, future helper cache | User in the URL, not a new client library |
| Secrets | existing `REDIS_PASSWORD` | Optional `REDIS_OPENWEBUI_PASSWORD` later |

### Rules

1. **requirepass remains the default.** Do not force ACL on every laptop clone.
2. **Official ACL file, not a custom auth proxy.** Use `redis-server --aclfile`. Do not add a Redis GUI or operator portal.
3. **One user per client that needs isolation.** Start with `default` (full) and a read/write-limited `openwebui` user if a second writer appears. Do not invent a user per dashboard widget.
4. **AFFiNE Redis stays separate.** Passwording `affine_redis` is allowed only in an AFFiNE-specific PR and must not reuse `REDIS_PASSWORD`.
5. **Durability stays Stage 21.** ACL work must not flip `--appendonly` as a side effect.
6. **GitHub remains intake.** Requests for Redis Cluster stay Issues.

### Suggested contributor checklist

```text
1. Read redis.command and Open WebUI REDIS_URL
2. Keep --requirepass as the no-ACL path
3. If a second writer exists, add redis/users.acl with user default + one named user
4. Mount the file :ro and pass --aclfile /etc/redis/users.acl
5. Point only that client at the named user
6. Leave affine_redis and maxmemory policy unchanged
7. Confirm redis-cli AUTH still matches the healthcheck
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Multi-user Redis | Official ACL file | Redis Stack, ACL UIs, custom proxies |
| Secret delivery | Existing `.env` / optional Stage 22 `*_FILE` | Baking passwords into the image |
| Persistence | Stage 21 AOF/RDB contract | Tying ACL to a durability rewrite |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** only when a second Redis client needs a narrower user.
3. Until then, document that `default` + `REDIS_PASSWORD` is the supported model.

## Acceptance criteria

- [ ] Fresh clones still start with `--requirepass` only.
- [ ] An opt-in ACL file uses official `--aclfile` syntax.
- [ ] Open WebUI keeps a working `REDIS_URL` (default user or named user).
- [ ] `affine_redis` is not merged into `ai_redis`.
- [ ] No Redis Cluster / Stack product is introduced.

## Rollback

Remove `--aclfile` and the mount. Restore `--requirepass` and the `default` URL. Data in `redis_data` remains valid.

## Success metrics

- A second Redis client can be scoped without sharing `+@all`.
- Contributors stop proposing Redis Cluster for a LAN cache.
- Healthcheck AUTH continues to use the documented secret.
