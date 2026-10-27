---
title: n8n Postgres Schema Contract
description: Constructional contract so schema n8n exists in the shared Postgres database before n8n 2.25.7 runs migrations.
last_updated: 2026-10-27
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# n8n Postgres Schema Contract

## Problem

n8n is pointed at a schema this repository never creates.

`docker-compose.yml` shares one Postgres database between Open WebUI and n8n:

```text
DB_TYPE: postgresdb
DB_POSTGRESDB_HOST: 172.20.0.10
DB_POSTGRESDB_DATABASE: ${POSTGRES_DB:-ai_platform}
DB_POSTGRESDB_SCHEMA: n8n
```

Open WebUI uses `public` in that same database. The `n8n` schema is how the two apps stay apart. A search of this tree finds `DB_POSTGRESDB_SCHEMA` only in that Compose block. There is no `docker-entrypoint-initdb.d` script, no `CREATE SCHEMA` in `tu-vm.sh`, and no SQL file.

The pinned n8n image `n8nio/n8n@sha256:761374d4eb841b0a22771d6bd68f0e8d827b4979ae4e490045517b13fc1259dd` is version **2.25.7** (image created 2026-06-10). Its database config reads `DB_POSTGRESDB_SCHEMA` and defaults the value to `public` when unset. `DbConnection.migrate()` calls `dataSource.runMigrations()`. It does not issue `CREATE SCHEMA`.

TypeORM 0.3.20, which n8n 2.25.7 builds on, checks for the migrations table with:

```text
SELECT * FROM "information_schema"."tables"
WHERE "table_schema" = 'n8n' AND "table_name" = 'migrations'
```

That query returns no row when the schema is absent. The executor then `createTable`s `"n8n"."migrations"`. PostgreSQL rejects `CREATE TABLE` in a schema that does not exist. n8n stops before workflows can be saved. The official `public` schema would have avoided the error and mixed n8n tables with Open WebUI tables. The Compose choice of `n8n` is the right split. The missing `CREATE SCHEMA` is the defect.

`PGSSLMODE: disable` on the same service is unread. n8n 2.25.7 uses `DB_POSTGRESDB_SSL_ENABLED`, which defaults to false. SSL is already off. This page does not turn that dead key into a second project.

Checked on 2026-10-27 by reading Compose, searching the repo for schema creation, and reading n8n 2.25.7 `packages/@n8n/config/src/configs/database.config.ts`, `packages/@n8n/db/src/connection/db-connection.ts`, and TypeORM 0.3.20 `MigrationExecutor` / `PostgresQueryRunner.hasTable`. The n8n TypeORM fork tag `v0.3.20-10` still only creates a schema inside `createSchema()`, which migrations do not call. No n8n container was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `postgres` service | Official image, database `ai_platform`, user from `POSTGRES_USER` |
| `n8n` service `DB_POSTGRESDB_SCHEMA: n8n` | The schema name to keep |
| n8n 2.25.7 `runMigrations()` | Assumes the schema already exists |
| `tu-vm.sh` `start_services` / `start_single_service` | Host-side place to repair volumes that already exist |
| Stage 28–30 service DNS (open PRs #54–#56) | Host naming. Unchanged here |
| Stage 50 AFFiNE start (open PR #76) | A different database. Unchanged here |

Out of scope:

- A second Postgres container or database just for n8n
- Moving n8n back to schema `public`
- Rewriting n8n migrations
- Treating `PGSSLMODE` as the SSL switch

## Proposal

Create schema `n8n` with the database user this stack already uses, once for new volumes and again, idempotently, for volumes created before this change.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| First boot | `postgres/initdb/01-n8n-schema.sh` mounted at `/docker-entrypoint-initdb.d` | `CREATE SCHEMA IF NOT EXISTS n8n AUTHORIZATION` the `POSTGRES_USER` |
| Existing volume | `tu-vm.sh` before n8n is expected to run | `docker exec` the running `ai_postgres` with `psql -c 'CREATE SCHEMA IF NOT EXISTS n8n ...'` |
| Compose | `n8n` environment | Keep `DB_POSTGRESDB_SCHEMA: n8n` |
| Docs | playbook one-liner | Say what the operator should see in `docker logs ai_n8n` if the schema is still missing |

The official Postgres image runs `*.sh` in `docker-entrypoint-initdb.d` only when the data directory is empty. A volume that already has Open WebUI tables will skip that script. The `tu-vm.sh` step covers that volume. Both steps use `IF NOT EXISTS`. Neither prints the database password.

### Rules

1. **Keep one Postgres.** Open WebUI stays in `public`. n8n stays in `n8n`.
2. **Use the official image's `psql`.** Do not add a migration sidecar image.
3. **Authorize the same role n8n uses.** `POSTGRES_USER` is that role (`ai_admin` by default).
4. **Make both paths idempotent.** A second start must succeed when the schema is already there.
5. **Leave `DB_POSTGRESDB_*` names alone.** They match n8n 2.25.7. Do not invent a TU-VM schema variable.
6. **Leave `PGSSLMODE` for a separate cleanup.** n8n ignores it. SSL remains off through `DB_POSTGRESDB_SSL_ENABLED` default false.

### Suggested contributor checklist

```text
1. Confirm DB_POSTGRESDB_SCHEMA is still n8n
2. On an empty data directory, confirm schema n8n exists after postgres first start
3. On a data directory that already has Open WebUI tables, confirm tu-vm.sh creates schema n8n
4. Confirm a second start does not error
5. Confirm n8n migrations create n8n.migrations rather than public.migrations
6. Confirm the database password is not written to the log
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Schema split | Official `DB_POSTGRESDB_SCHEMA` | A private n8n database service |
| Creation | Postgres `CREATE SCHEMA IF NOT EXISTS` | A custom migrator |
| Existing volumes | `docker exec` `psql` in `ai_postgres` | Recreating the volume |
| SSL | n8n `DB_POSTGRESDB_SSL_ENABLED` default | `PGSSLMODE` as if n8n read it |
| Intake | GitHub Issue | A forked n8n image |
