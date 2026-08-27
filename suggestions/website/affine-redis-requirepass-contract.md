---
title: AFFiNE Redis Requirepass Contract
description: Constructional contract for requirepass on affine_redis so the dedicated AFFiNE cache matches platform Redis auth, without sharing ai_redis or rewriting Stage 20 durability.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: security
impact: high
---

# AFFiNE Redis Requirepass Contract

## Problem

Platform Redis is passworded:

```yaml
command: redis-server --requirepass ${REDIS_PASSWORD:-…}
```

`affine_redis` is not:

```yaml
command: redis-server --save "" --appendonly no --tcp-keepalive 60
```

Anything on `ai_network` can talk to `172.20.0.25:6379` with no credential. Stage 23 role networks are not merged yet. Until they are, **auth is the control** that already exists for `ai_redis`.

Stage 20 is durability (named volume + AOF/RDB). Stage 21 is platform Redis durability. Stage 24 is optional ACL users **on top of** `requirepass`. This page is **password parity** for the AFFiNE sidecar.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `ai_redis --requirepass` + `REDIS_PASSWORD` | Pattern to copy |
| `AFFINE_DB_PASSWORD` required in `.env` | AFFiNE already refuses empty DB secrets |
| `REDIS_SERVER_HOST: affine_redis` | AFFiNE connection (add password env) |
| Stage 20 `affine-redis-durability-contract.md` (expected sibling) | Volume / AOF — not auth |
| Stage 24 `redis-acl-users-contract.md` (expected sibling) | ACL file after requirepass |
| Stage 8 secret rotation | `generate-secrets` lane |

Out of scope:

- Pointing AFFiNE at platform Redis (Stage 20 forbids sharing)
- Implementing ACL files on this page
- Changing `--save ""` (durability stays Stage 20)
- Exposing Redis on a host port

## Proposal

Give `affine_redis` the same `--requirepass` shape and a dedicated env key.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `affine_redis` | `command` | `--requirepass ${AFFINE_REDIS_PASSWORD:?…}` |
| Compose `affine` / `affine_migration` | environment | Official AFFiNE Redis password env (verify current image docs; commonly `REDIS_SERVER_PASSWORD`) |
| `env.example` | new key | `AFFINE_REDIS_PASSWORD=CHANGE_ME_SECURE_PASSWORD` |
| `tu-vm.sh generate-secrets` | generator | Emit the new key like `AFFINE_DB_PASSWORD` |
| Healthcheck | `affine_redis` | `redis-cli -a "$AFFINE_REDIS_PASSWORD" ping` (match platform Redis) |

### Rules

1. **Do not reuse `REDIS_PASSWORD`.** A leak of the platform cache must not unlock AFFiNE’s cache.
2. **Do not share `ai_redis`.** Auth is not a license to collapse instances.
3. **Fail closed.** Use `${AFFINE_REDIS_PASSWORD:?Set AFFINE_REDIS_PASSWORD in .env}` like `AFFINE_DB_PASSWORD`.
4. **Confirm the AFFiNE env name** against the pinned image before merging. If the image uses a different key, document it on this page and in `env.example`.
5. **GitHub remains intake.** Requests for “Redis over TLS inside the LAN bridge” stay Issues until Stage 23 networks land.

### Suggested contributor checklist

```text
1. Add AFFINE_REDIS_PASSWORD to env.example and generate-secrets
2. Add --requirepass to affine_redis command
3. Wire AFFiNE + migration to the documented password env
4. Update affine_redis healthcheck to authenticated ping
5. Confirm docker compose config still renders
6. Confirm affine still reaches Redis after start-service affine
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Redis auth | `--requirepass` + env | Open Redis on `ai_network` |
| Secret lifecycle | Existing `generate-secrets` | Hardcoded default in Compose |
| Durability | Stage 20 contract | Mixing AOF work into this PR |
| ACL later | Stage 24 on top of this password | ACL instead of a password |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: env + command + AFFiNE wiring in one PR.
3. Existing AFFiNE Redis data has no password; first start after the change just uses the new command (no dump migration).

## Acceptance criteria

- [ ] `affine_redis` requires a password.
- [ ] The password is a dedicated env key, required, not `REDIS_PASSWORD`.
- [ ] `affine` and `affine_migration` pass that password using the image’s documented env.
- [ ] Healthcheck uses an authenticated ping.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] Platform Redis and AFFiNE Redis remain separate instances.

## Rollback

Remove `--requirepass` and the AFFiNE password env. Volume data remains; then tighten again with a new password.

## Success metrics

- Unauthenticated `redis-cli ping` to `ai_affine_redis` fails.
- `generate-secrets` emits `AFFINE_REDIS_PASSWORD`.
- Stage 20/24 PRs treat this password as a prerequisite, not a competing Redis design.
