---
title: Platform Postgres WAL and PITR Policy Contract
description: Constructional contract for naming platform PostgreSQL durability as pg_dump plus volume tar, or an explicit WAL/PITR lane, without introducing a second database product or sharing affine_postgres.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Platform Postgres WAL and PITR Policy Contract

## Problem

Platform Postgres (`postgres` / `ai_postgres`) already has `postgres_data` and is dumped by `create_backup()`:

```text
docker compose exec -T -e PGPASSWORD=… postgres \
  pg_dump -U ai_admin ai_platform > "$backup_path/database.sql"
```

There is no `wal_level`, `archive_mode`, or `pg_basebackup` policy. A crash between daily tarballs can lose Open WebUI / n8n rows that `pg_dump` never saw. Community PRs that notice “restore is dump-only” tend to propose Timescale, Patroni, a hosted Postgres, or pointing AFFiNE at `ai_postgres`.

Stage 21 covers **platform Redis** AOF. Stage 18 covers **tar archive format**. This page is **platform Postgres write-ahead and restore granularity** only.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `postgres` | Digest-pinned 15-alpine; `postgres_data`; `pg_isready` healthcheck |
| `create_backup()` | `pg_dump` to `database.sql` plus `docker_postgres_data` tarball |
| `safe-update.sh` | Also calls `pg_dump` before image moves |
| `POSTGRES_*` in `env.example` | Shared buffers / connections; no WAL knobs |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Day-to-day vacuum / hygiene, not PITR |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Archive layout and rotation |
| Stage 21 `platform-redis-durability-contract.md` (expected sibling) | Redis AOF only |

Out of scope:

- Merging AFFiNE onto `ai_postgres` (AFFiNE has `affine_postgres`)
- Patroni / CloudNativePG / a hosted database
- Changing Postgres major without the existing 15-volume warning
- Replacing `pg_dump` as the default operator restore path

## Proposal

Name the durability choice: keep dump-plus-volume as the documented default, or add an **opt-in** WAL archive lane behind existing `tu-vm.sh backup` / `restore` without a second CLI.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Policy | Compose `command:` / `POSTGRES_*` | Document dump-only vs `wal_level=replica` |
| Backup | `create_backup()` | Keep `database.sql` + volume tar as default |
| Optional PITR | `TU_VM_POSTGRES_WAL=0/1` | WAL files next to the existing backup dir |
| Isolation | Service name | Never point AFFiNE at `postgres` / `ai_postgres` |
| Energy | Archive cadence | Laptop-friendly; no continuous shipping by default |

### Rules

1. **Keep a dedicated platform Postgres.** Open WebUI / n8n / platform data must not share `affine_postgres`.
2. **Name the choice.** Either (a) dump + volume tar is enough and say so, or (b) opt in to WAL archive / `pg_basebackup` **behind** `tu-vm.sh backup`. A silent `wal_level` change without restore docs is worse than dump-only.
3. **Default recommendation.** Keep `pg_dump` + `docker_postgres_data` for LAN operators. PITR is opt-in for hosts that already keep `BACKUP_DIR` on durable disk.
4. **Do not invent a backup product.** No Barman, pgBackRest, or WAL-G service unless an Issue proves dump+volume insufficient **and** the new tool is wrapped by `tu-vm.sh backup`.
5. **Healthcheck stays `pg_isready`.** Durability must not break `service_healthy`.
6. **Major version stays 15** until a documented `pg_upgrade` path exists (compose comment already warns).
7. **GitHub remains intake.** Requests for RDS or Patroni stay Issues.

### Suggested contributor checklist

```text
1. Read the postgres service and create_backup() pg_dump block
2. Leave postgres_data and database.sql in place
3. If adding WAL, gate it with an explicit env flag defaulting off
4. Document restore: dump-only vs dump+WAL
5. Do not touch affine_postgres
6. Keep pg_isready and scram-sha-256 initdb args
7. Note disk cost of archive_mode on laptops
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Default backup | Existing `pg_dump` + volume tar | A new database dump CLI |
| Optional PITR | Official Postgres WAL + `tu-vm.sh` | Barman / WAL-G as a required service |
| Isolation | Current `postgres` vs `affine_postgres` | Sharing one cluster |
| Restore | Existing `restore` + `psql` | A second recovery UI |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: comment the dump-only policy on the `postgres` service, or add opt-in `wal_level=replica` + archive directory documented in `create_backup()`.
3. Optional: `tu-vm.sh doctor` check that `database.sql` exists in the latest archive when Postgres is up.

## Acceptance criteria

- [ ] Dump-plus-volume is an explicit default policy.
- [ ] WAL/PITR, if added, is opt-in and wrapped by `tu-vm.sh`.
- [ ] AFFiNE Postgres is out of scope.
- [ ] `pg_isready` and Postgres 15 volume warning remain.
- [ ] No required extra backup product.

## Rollback

Remove WAL env/command flags. `pg_dump` and `postgres_data` stay. Redis and AFFiNE databases are unaffected.

## Success metrics

- Operators can state whether restore is dump-only or PITR-capable.
- Default backups still produce `database.sql` without a new tool.
- No PR merges AFFiNE onto platform Postgres.
