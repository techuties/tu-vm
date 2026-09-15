---
title: Dead Postgres Env Honesty Contract
description: Constructional contract to stop advertising POSTGRES_SHARED_BUFFERS and sibling keys as live Compose environment, because the official image ignores them. Stage 23 already owns the real GUC path.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Dead Postgres Env Honesty Contract

## Problem

The `postgres` service sets several “performance” keys as container environment:

```text
POSTGRES_SHARED_BUFFERS
POSTGRES_EFFECTIVE_CACHE_SIZE
POSTGRES_WORK_MEM
POSTGRES_MAINTENANCE_WORK_MEM
POSTGRES_MAX_CONNECTIONS
```

The official `postgres` image only honors a small set (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_INITDB_ARGS`, `POSTGRES_HOST_AUTH_METHOD`, `PGDATA`, and related init keys). The keys above are **not** read as GUCs. They sit in `docker inspect` and `env.example` as if operators can tune RAM and connections from `.env`.

`env.example` also documents `POSTGRES_SHARED_BUFFERS=256MB` and `POSTGRES_EFFECTIVE_CACHE_SIZE=1GB`. Changing those values does nothing until someone implements Stage 23 `postgres-statement-timeout-pooling-contract.md` (expected sibling) via `command: postgres -c …`.

This page is **honesty**, not another GUC essay. Do not re-specify `-c shared_buffers`, statement_timeout, or PgBouncer here.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official postgres image | Ignores unknown `POSTGRES_*` env as GUCs |
| Compose `postgres.environment` | Advertises dead keys |
| `env.example` Advanced section | Documents the same dead keys |
| Stage 23 postgres GUC / pooling (expected sibling) | The **code** path: `postgres -c` and optional PgBouncer |
| Stage 29 `postgres-shm-size-contract.md` (expected sibling) | `/dev/shm` sized for a **real** `shared_buffers` |
| Stage 24 unused `HEALTH_CHECK_*` / `NGINX_WORKER_*` (expected siblings) | Same honesty pattern for other dead keys |
| Stage 31 `env-example-dead-keys-contract.md` | Broader unused `.env` catalog (memory limits, flags) |

Out of scope:

- Rewriting Stage 23 GUC flags or pooling
- Rewriting Stage 29 `shm_size`
- A custom postgres wrapper image just to map env → GUC
- Changing `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_INITDB_ARGS` (those **are** live)

## Proposal

Pick **one** honesty path:

### Path A (preferred): delete the dead keys

Remove the five ignored keys from Compose `postgres.environment` and from `env.example`. Point a one-line comment at Stage 23 for real tuning.

### Path B: keep names only after Stage 23 lands

If a contributor is implementing Stage 23 in the same change, **move** the values onto `command: ["postgres", "-c", "shared_buffers=…", …]`. Do not leave them in `environment:` and also on `-c` without a comment that env is unused.

Do not invent `POSTGRES_SHARED_BUFFERS` → entrypoint mapping. Official image + Compose `command` is enough.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `postgres` | Path A delete, or Path B `-c` (Stage 23) |
| Env schema | `env.example` | Remove or relocate under a “Stage 23 command flags” comment |
| Docs | README resource table | Do not list these as live env |

### Rules

1. **Do not write another GUC design.** Stage 23 is the implementation page.
2. **Do not claim `.env` tunes shared_buffers** until `-c` (or a conf file mount) exists.
3. **Keep live init keys.** `POSTGRES_PASSWORD` and friends stay.
4. **Affine postgres is separate.** `affine_postgres` does not currently advertise these dead keys; do not add them there.
5. **GitHub remains intake.** Requests for “a postgres.conf generator” are a different product.

### Suggested contributor checklist

```text
1. Grep POSTGRES_SHARED_BUFFERS and POSTGRES_EFFECTIVE_CACHE_SIZE
2. Confirm official image docs do not list them as env
3. Delete from Compose + env.example (Path A) or wire -c (Path B + Stage 23)
4. Leave POSTGRES_DB / USER / PASSWORD / INITDB_ARGS intact
5. docker compose config still renders
6. Do not add a custom entrypoint
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Real GUCs | Stage 23 `postgres -c` | Env-to-GUC sidecar |
| Honesty | Delete unused keys | Comments that say “optimization” on dead env |
| shm vs buffers | Stage 29 `shm_size` after real `-c` | Another shared_buffers essay |
| Other dead keys | Stage 24 + Stage 31 dead-keys catalog | One mega “delete all unused env” PR without owners |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Path A is a small docs/Compose cleanup. Path B only when Stage 23 is implemented.
3. If operators already set these in `.env`, Path A is a no-op at runtime (the image never read them).

## Acceptance criteria

- [ ] Compose `postgres.environment` no longer lists ignored GUC-shaped keys **or** those values appear only as `postgres -c` (Stage 23).
- [ ] `env.example` does not present the keys as live container environment.
- [ ] This page does not introduce a new GUC table that duplicates Stage 23.
- [ ] Live init keys remain.

## Rollback

Restore the previous environment block. Runtime behavior is unchanged for Path A because the image ignored the keys.

## Success metrics

- Contributors stop opening “I raised POSTGRES_SHARED_BUFFERS and nothing changed” issues.
- Stage 23 implementers do not have to fight a second env-mapping design.
- `env.example` Advanced section only documents keys that Compose or scripts actually consume.
