---
title: Postgres Runtime GUC Contract
description: Constructional contract so Postgres shared_buffers and the other planner settings on the primary database are server parameters the official image actually applies.
last_updated: 2026-10-17
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Postgres Runtime GUC Contract

## Problem

The primary Postgres service publishes tuning as environment variables:

```text
POSTGRES_SHARED_BUFFERS: ${POSTGRES_SHARED_BUFFERS:-256MB}
POSTGRES_EFFECTIVE_CACHE_SIZE: ${POSTGRES_EFFECTIVE_CACHE_SIZE:-1GB}
POSTGRES_WORK_MEM: 4MB
POSTGRES_MAINTENANCE_WORK_MEM: 64MB
POSTGRES_MAX_CONNECTIONS: ${POSTGRES_MAX_CONNECTIONS:-100}
```

The service has no `command:` and no `entrypoint:`. It uses the official image (`postgres@sha256:df7bca0066e6…`, the Postgres 15 line). That image's `docker-entrypoint.sh` reads `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_INITDB_ARGS`, `POSTGRES_INITDB_WALDIR`, and `POSTGRES_HOST_AUTH_METHOD`. It does not read the five tuning names above.

Before `exec`, the same script runs `unset` on every variable whose name starts with `POSTGRES_`. The server process therefore never sees `POSTGRES_SHARED_BUFFERS`. PostgreSQL itself reads `shared_buffers` from its configuration, not from an environment variable with that prefix.

Checked on 2026-10-17 against `docker-library/postgres` `docker-entrypoint.sh` on the `master` branch (the file the 15 image template copies) and against the compose service, which sets memory limit `512M`.

| Compose value | What the official entrypoint does | Server result today |
|---|---|---|
| `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB` | `file_env` and `initdb` | Applied |
| `POSTGRES_INITDB_ARGS` | Passed to `initdb` | Applied on first init |
| `POSTGRES_SHARED_BUFFERS=256MB` | Not read, then unset | Default `shared_buffers` (128MB) |
| `POSTGRES_EFFECTIVE_CACHE_SIZE=1GB` | Not read, then unset | Default `effective_cache_size` (4GB) |
| `POSTGRES_WORK_MEM=4MB` | Not read, then unset | Default `work_mem` (4MB), same number by coincidence |
| `POSTGRES_MAINTENANCE_WORK_MEM=64MB` | Not read, then unset | Default (64MB), same number by coincidence |
| `POSTGRES_MAX_CONNECTIONS=100` | Not read, then unset | Default (100), same number by coincidence |

`shared_buffers=256MB` inside a 512M container limit is also a large share of the cgroup. Applying the env text blindly can make the postmaster fail to start. The contract is to apply a GUC the memory limit can hold, not to copy `256MB` into `postgresql.conf` unchanged.

`effective_cache_size` is a planner hint. It does not allocate RAM. It still has to be set as a GUC if operators want 1GB instead of the server default.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `postgres` service in `docker-compose.yml` | Image, env, 512M limit, healthcheck. No custom command |
| Official `docker-entrypoint.sh` | Already applies user, password, database, and initdb args |
| `postgres -c name=value` | Documented way to set a GUC on every start, including an existing volume |
| A read-only file under `docker-entrypoint-initdb.d` | Runs once, on an empty data directory. It does not change GUCs on later boots |
| AFFiNE's separate `affine_postgres` service | Its own data volume. Do not point this page at that instance |

Out of scope:

- A custom Postgres image or a config-management product
- Changing `POSTGRES_PASSWORD` generation (Stage 54, open PR #80)
- Backup and restore of `database.sql` (Stage 47, open PR #73)
- Volume name prefixes (Stage 46, open PR #72)
- Raising the 512M limit in the same change as the first GUC fix

## Proposal

Keep the official image. Set the GUCs the server understands, and size `shared_buffers` for the existing 512M limit.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Runtime | `postgres` `command` | `postgres -c shared_buffers=128MB -c effective_cache_size=1GB -c work_mem=4MB -c maintenance_work_mem=64MB -c max_connections=100`, or a mounted `postgresql.conf` plus `-c config_file=...` |
| Memory | Same command | Keep `shared_buffers` at or below 128MB while the limit is 512M. Raise it only together with the limit |
| Env | Compose `environment` | Remove the five tuning variables, or stop documenting them as live settings. Keep `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`, and `POSTGRES_INITDB_ARGS` |
| Proof | `SHOW` | After the container is healthy, `SHOW shared_buffers` and `SHOW effective_cache_size` match the command |

### Rules

1. **Use a GUC name the server documents.** `shared_buffers`, not `POSTGRES_SHARED_BUFFERS`.
2. **Apply the setting on every start.** `command: postgres -c ...` covers an existing volume. An init script under `docker-entrypoint-initdb.d` does not.
3. **Fit `shared_buffers` in the cgroup.** With a 512M limit, 128MB is the value that matches the current server default and leaves room for connections. Do not apply the unused `256MB` env default in this change.
4. **Leave credentials on the entrypoint path.** `POSTGRES_PASSWORD` and `POSTGRES_USER` stay environment variables.
5. **Do not retune AFFiNE's Postgres here.** That service has its own volume and its own user.

### Suggested contributor checklist

```text
1. Render the compose service and confirm the postgres command contains shared_buffers
2. Confirm POSTGRES_SHARED_BUFFERS is no longer described as a live setting
3. On a running container, SHOW shared_buffers returns the configured value
4. Confirm the container still becomes healthy under the 512M limit
5. Confirm an existing postgres_data volume keeps its data after recreate
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Server settings | Official image `command` / `postgresql.conf` | A rebuilt Postgres image |
| First-boot credentials | The entrypoint's existing `POSTGRES_USER` path | A second init container |
| Memory ceiling | The `deploy.resources.limits.memory` value already on the service | A host-level memory manager |
