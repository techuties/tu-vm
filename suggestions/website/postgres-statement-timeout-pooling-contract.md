---
title: Postgres Statement Timeout and Pooling Contract
description: Constructional contract for applying real Postgres runtime settings (statement_timeout, shared_buffers) and optional connection pooling, without changing WAL/PITR policy or sharing AFFiNE's database.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Postgres Statement Timeout and Pooling Contract

## Problem

`ai_postgres` sets `POSTGRES_SHARED_BUFFERS`, `POSTGRES_EFFECTIVE_CACHE_SIZE`, `POSTGRES_WORK_MEM`, and `POSTGRES_MAX_CONNECTIONS` as container environment variables. The official Postgres image only honors `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_INITDB_ARGS`, and a few auth helpers. Those extra `POSTGRES_*` values are ignored unless passed as `postgres -c` flags or a `postgresql.conf` include. There is no `statement_timeout`, so a runaway n8n or helper query can hold the Tier 1 database.

Stage 22 covers **dump-plus-volume versus opt-in WAL/PITR**. This page is only **runtime GUCs and pooling**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `postgres` | Official `postgres` 15 image; unused `POSTGRES_SHARED_BUFFERS` style env |
| `env.example` | Documents `POSTGRES_MAX_CONNECTIONS` / `POSTGRES_SHARED_BUFFERS` |
| `n8n` | Connects to `172.20.0.10` with `DB_POSTGRESDB_CONNECTION_TIMEOUT` |
| Open WebUI / helper | Also depend on platform Postgres |
| `affine_postgres` | Separate pgvector instance — do not share |
| Stage 22 `postgres-wal-pitr-policy-contract.md` (expected sibling) | Backup/WAL, not GUCs |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | Container memory limits |

Out of scope:

- Patroni, CloudNativePG, or a hosted Postgres
- Sharing `affine_postgres` or moving n8n onto AFFiNE's database
- Changing dump/restore format
- Raising container memory as a substitute for timeouts

## Proposal

Pass real server settings with `command: postgres -c ...` (or a bind-mounted `conf.d` file) so `shared_buffers`, `max_connections`, and `statement_timeout` actually apply. Keep pooling optional: prefer PgBouncer in transaction mode only if `max_connections` and laptop memory are proven tight.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Runtime GUCs | `postgres.command` or `postgres.conf` include | `SHOW statement_timeout` inside the container |
| Env | `env.example` | Values that the command line actually interpolates |
| Clients | n8n / Open WebUI | Existing client timeouts stay; server timeout is the backstop |
| Pool | optional `pgbouncer` service | Only after GUC evidence, Compose profile off by default |

### Rules

1. **Settings must be real.** Do not add more `POSTGRES_*` env vars that the official image ignores. If a value is in `env.example`, it must appear on the `postgres` command line or in a mounted conf file.
2. **`statement_timeout` is the first new GUC.** Start conservative (for example 60s) and document that maintenance jobs may need `SET statement_timeout = 0` locally.
3. **Do not touch `affine_postgres`.** Platform and AFFiNE databases stay separate.
4. **Pooling is opt-in.** A PgBouncer service, if added, uses a Compose profile and does not replace the published-to-network `postgres` hostname used today until clients are updated together.
5. **Reuse official images.** Prefer `pgbouncer/pgbouncer` or an equivalent well-known image. Do not write a custom pooler.
6. **Memory math stays honest.** `shared_buffers` must fit inside the Compose `512M` limit (Stage 18). Do not "fix" ignored env vars by raising buffers above the container cap.
7. **GitHub remains intake.** Requests for a clustered Postgres stay Issues.

### Suggested contributor checklist

```text
1. Read the postgres service and env.example ADVANCED CONFIGURATION
2. Confirm ignored POSTGRES_SHARED_BUFFERS via SHOW inside a running container
3. Add command: postgres -c shared_buffers=... -c max_connections=... -c statement_timeout=...
4. Interpolate the same env names so env.example becomes true
5. Keep POSTGRES_DB / USER / PASSWORD / INITDB_ARGS as official image env
6. Leave affine_postgres and backup/WAL paths unchanged
7. Only propose PgBouncer after SHOW max_connections and client counts are documented
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Server settings | Official `postgres -c` or `conf.d` include | Fake `POSTGRES_*` env as configuration |
| Timeouts | Postgres `statement_timeout` | A query killer sidecar |
| Pooling | Optional official PgBouncer | Writing a pooler or using Redis as a DB queue |
| Durability | Stage 22 dump / opt-in WAL | Mixing WAL work into this contract |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: real `-c` flags for the settings already advertised in `env.example`, plus `statement_timeout`.
3. Defer PgBouncer until a laptop profile shows connection saturation.

## Acceptance criteria

- [ ] `SHOW shared_buffers` matches the documented env value.
- [ ] `SHOW statement_timeout` is non-zero on `ai_postgres`.
- [ ] Official image env (`POSTGRES_DB` / user / password / initdb) is unchanged.
- [ ] `affine_postgres` is not modified.
- [ ] No cluster or hosted database product is introduced.

## Rollback

Remove the `command:` override (or mounted conf). Postgres returns to image defaults. Data files are untouched.

## Success metrics

- Advertised buffer and connection settings apply.
- A runaway query dies at `statement_timeout` instead of pinning the laptop.
- Contributors stop treating ignored `POSTGRES_*` env vars as live config.
