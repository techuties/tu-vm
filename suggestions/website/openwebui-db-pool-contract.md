---
title: Open WebUI Database Pool Contract
description: Constructional contract to pin official DATABASE_POOL_SIZE and DATABASE_POOL_MAX_OVERFLOW so the SQLAlchemy pool stops using hidden defaults.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Database Pool Contract

## Problem

The pinned Open WebUI revision reads pool settings in `backend/open_webui/env.py`:

- `DATABASE_POOL_SIZE` with no default. Unset or invalid becomes `None`.
- `DATABASE_POOL_MAX_OVERFLOW` default string `0`.
- `DATABASE_POOL_TIMEOUT` default `30`.
- `DATABASE_POOL_RECYCLE` default `3600`.

`backend/open_webui/internal/db.py` passes those values into SQLAlchemy only when `DATABASE_POOL_SIZE` is an `int` greater than `0`. When the size is `None`, both the sync engine and the async engine call `create_engine` / `create_async_engine` with `pool_pre_ping=True` and no pool size. SQLAlchemy 2.0.48 (pinned in this image's `requirements.txt`) then uses `QueuePool` defaults: `pool_size` 5 and `max_overflow` 10.

The configured overflow of `0` is ignored on that branch. Each engine can open 15 connections. Two engines can open 30. The Postgres service limit in Compose is 512M of memory, and Stage 23 already notes that `POSTGRES_MAX_CONNECTIONS` in the environment is ignored until it is a real server GUC.

An integer size of `0` or below selects `NullPool` in this revision (a connection per checkout). That is a different mode, not the overflow of `0`.

The chat completion route in this revision says it avoids holding a database session for the whole LLM call so the pool is not exhausted. The pool size is still unset, so that care sits on top of the hidden 5+10 default.

n8n's official `DB_POSTGRESDB_POOL_SIZE` defaults to 2 in image 2.25.7. Compose already sets `DB_POSTGRESDB_CONNECTION_TIMEOUT: 30000`, which overrides that image's 20000 ms connect timeout. Leave the n8n pool on its default in this change.

Stage 23 owns server GUCs and optional PgBouncer. This page owns the Open WebUI client pool.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Size unset → `None`; overflow default `0` |
| Pinned `internal/db.py` | Applies size and overflow only when size is a positive int |
| SQLAlchemy 2.0.48 | QueuePool defaults 5 and 10 when size is omitted |
| Chat route comment | Do not hold a connection across the LLM call |
| n8n `DB_POSTGRESDB_POOL_SIZE` | Official default 2; not set in Compose |
| Stage 23 contract (expected sibling) | `postgres -c` GUCs and opt-in PgBouncer |
| Stage 31 dead Postgres env (expected sibling) | `POSTGRES_*` keys the image ignores |

Out of scope:

- PgBouncer or any new pooler
- Changing `POSTGRES_MAX_CONNECTIONS` (Stage 23, as a real GUC)
- Setting pool size `0` (NullPool)
- Retuning the n8n pool in the same change

## Proposal

Pin a positive official pool on the `open-webui` service so overflow is honored:

```text
DATABASE_POOL_SIZE: "5"
DATABASE_POOL_MAX_OVERFLOW: "2"
DATABASE_POOL_TIMEOUT: "30"
DATABASE_POOL_RECYCLE: "3600"
```

Both engines read the same variables. If both pools fill, the ceiling is `2 * (5 + 2) = 14` connections from Open WebUI, plus n8n's default pool of 2. That is smaller than the hidden `2 * (5 + 10)` ceiling.

The sync engine is used for startup, migrations, and config load. Count it anyway, because it keeps its own pool.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | The four `DATABASE_POOL_*` lines |
| Env schema | `env.example` | Comment that unset size ignores overflow and uses SQLAlchemy defaults |
| Docs | Open WebUI playbook | How to read pool timeouts in logs |
| Server | Stage 23 | Real `max_connections` GUC, separate change |

### Rules

1. **Official keys only.** `db.py` already branches on them.
2. **Size must be a positive integer.** `None` hides the overflow. `0` selects NullPool.
3. **Overflow 2 is intentional.** It replaces the ignored `0` and the hidden `10`.
4. **PgBouncer stays on the Stage 23 page** and stays opt-in.
5. **n8n pool size stays at its image default** unless a later Issue budgets it.

### Suggested contributor checklist

```text
1. Confirm db.py still skips pool args when DATABASE_POOL_SIZE is None
2. Set the four DATABASE_POOL_* values on the open-webui service
3. Recreate Open WebUI
4. Confirm startup still migrates and /health/db succeeds
5. Confirm pool size is not 0
6. Leave PgBouncer and n8n DB_POSTGRESDB_POOL_SIZE unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Client pool | Official `DATABASE_POOL_*` | A custom pool |
| Server cap | Stage 23 GUCs | Another ignored `POSTGRES_*` env |
| Extra clients | An Issue that raises these integers | NullPool via `0` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: four Compose lines, an `env.example` comment, and an Open WebUI recreate.
3. A larger pool needs an Issue after Stage 23 `max_connections` is a real GUC.

## Acceptance criteria

- [ ] `open-webui` sets `DATABASE_POOL_SIZE=5` and `DATABASE_POOL_MAX_OVERFLOW=2`.
- [ ] Timeout 30 and recycle 3600 are set explicitly.
- [ ] Pool size is not `0` or empty.
- [ ] No PgBouncer service is added in this change.

## Rollback

Remove the four keys to restore SQLAlchemy defaults (size 5, overflow 10 per engine). Do not roll back by setting size `0`.

## Success metrics

- Open WebUI's maximum checkout is the documented 5+2 per engine.
- Startup and `/health/db` still succeed.
