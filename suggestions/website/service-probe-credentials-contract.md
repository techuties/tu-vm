---
title: Service Probe Credentials Contract
description: Constructional contract so retention, the daily checkup, and the PDF loader switch authenticate to Postgres and Redis the way the audio tools already do.
last_updated: 2026-10-07
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Service Probe Credentials Contract

## Problem

Three day-to-day probes open Postgres and Redis without the password those services require. One function in the same script already does it correctly.

Postgres is initialized with:

```text
POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256 --auth-local=scram-sha-256"
```

A local `psql` session needs a password. Redis is started with `--requirepass`. The Compose healthcheck only succeeds when `redis-cli` prints `PONG`.

`check_openwebui_audio_config` already resolves the four values and passes them in:

```text
pg_user="$(resolve_env_value POSTGRES_USER ai_admin)"
pg_db="$(resolve_env_value POSTGRES_DB ai_platform)"
pg_pass="$(resolve_env_value POSTGRES_PASSWORD ai_password_2024)"
redis_pass="$(resolve_env_value REDIS_PASSWORD redis_password_2024)"
docker exec -e PGPASSWORD="$pg_pass" ai_postgres psql -U "$pg_user" -d "$pg_db" ...
docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli ...
```

An empty Postgres row is a failure there (`Could not read Open WebUI config row`). The other call sites do not follow that pattern.

| Caller | Command | Password env | Empty result |
|---|---|---|---|
| `verify_data_retention` | `psql -U ai_admin -d ai_platform` | none | Appends "PostgreSQL database not accessible" |
| `verify_data_retention` | `redis-cli ping` | none | Uses the exit status. Stdout is discarded, so `PONG` is never required |
| `scripts/daily-checkup.sh` `check_pipeline_integrity` | four `psql -U ai_admin -d ai_platform` queries, stderr discarded | none | An empty string is not the ollama marker, so the check continues as if the row were fine |
| `scripts/switch-pdf-loader.sh` | `psql -U ai_admin -d ai_platform` under `set -e` | none | The UPDATE never runs |

`verify_data_retention` runs at the end of `./tu-vm.sh update`. A failed probe sets `update_healthy` false. `perform_docker_cleanup` is then skipped and the update is recorded as completed with warnings. That happens even when the containers are up, because the probe never authenticated.

The user and database names are the Compose defaults (`ai_admin`, `ai_platform`). They are still wrong once an operator changes `POSTGRES_USER` or `POSTGRES_DB`. The password gap is present on a stock install too, because scram and `requirepass` do not accept a passwordless client.

Stage 47 (open PR #73) already owns the hardcoded user and database inside `create_backup` and `restore_backup`. This page does not move those two functions. Stage 29 (open PR #55) owns moving the Compose Redis healthcheck from `redis-cli -a` to `REDISCLI_AUTH`. This page uses that same environment variable on the shell probes.

Checked on 2026-10-07 by reading the call sites. Postgres and Redis were not started in this environment.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `resolve_env_value` | Reads the process environment, then `.env`, then the Compose default |
| `check_openwebui_audio_config` / `fix_openwebui_audio_config` | Working `PGPASSWORD` and `REDISCLI_AUTH` usage |
| `verify_data_retention` | Post-update gate that currently password-fails |
| `scripts/daily-checkup.sh` `check_pipeline_integrity` | Scheduled reader that treats a failed login like an empty config |
| `scripts/switch-pdf-loader.sh` | Operator toggle that aborts before the UPDATE |
| Redis Compose healthcheck | The `PONG` test the retention probe should match |
| Stage 13 audio contract (expected sibling, open PR #39) | What the audio query means. Not how the other scripts log in |
| Stage 47 backup identity (expected sibling, open PR #73) | `create_backup` / `restore_backup` only |

Out of scope:

- Changing `POSTGRES_INITDB_ARGS` or turning `requirepass` off
- Putting the Redis password on `redis-cli -a` (Stage 29)
- The dump and restore literals (Stage 47)
- A new database role or a connection pooler

## Proposal

Every remaining probe uses the four `resolve_env_value` lines the audio check already has.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Retention, Postgres | `verify_data_retention` | `docker exec -e PGPASSWORD=... psql -U "$pg_user" -d "$pg_db" -c "SELECT 1;"` |
| Retention, Redis | `verify_data_retention` | `docker exec -e REDISCLI_AUTH=... redis-cli ping` and require the output to contain `PONG`, as the Compose healthcheck does |
| Checkup | `check_pipeline_integrity` | Same Postgres env. If `psql` fails, log a warning and skip the rewrite. Do not treat empty stdout as a healthy row |
| Loader switch | `switch-pdf-loader.sh` | Same Postgres env on the SELECT and both UPDATE statements |
| Wrapper | `scripts/safe-update.sh` | Do not patch its copies. Stage 53's wrapper page deletes them |

### Rules

1. **One helper.** Call `resolve_env_value` or source the same four keys. Do not add a fifth password file.
2. **Redis success is `PONG`.** Exit status alone is not the check. `NOAUTH` must not count as accessible.
3. **Empty is not healthy** on the checkup. A failed login stays a failed login.
4. **Defaults stay the Compose defaults.** `ai_admin`, `ai_platform`, and the published passwords remain the fallbacks `resolve_env_value` already uses. They are fallbacks, not the only accepted values.

### Suggested contributor checklist

```text
1. With POSTGRES_PASSWORD set and the stock user, verify_data_retention no longer reports Postgres or Redis down while both healthchecks are healthy
2. With POSTGRES_USER changed in .env, the probe uses that user
3. redis-cli in verify_data_retention is invoked with REDISCLI_AUTH and the script checks for PONG
4. daily-checkup logs a database warning when psql cannot log in, and it does not run the RAG rewrite
5. switch-pdf-loader.sh tika|pymupdf reaches the UPDATE when the password in .env is the one Postgres has
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Read `.env` | `resolve_env_value` | A new parser |
| Postgres auth | `PGPASSWORD` on `docker exec` | A trust line in `pg_hba.conf` |
| Redis auth | `REDISCLI_AUTH` | `redis-cli -a` on these probes |
