---
title: Postgres SHM Size Contract
description: Constructional contract for Compose shm_size on postgres and affine_postgres so official PostgreSQL shared buffers and parallel query fit, without inventing a custom IPC service.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Postgres SHM Size Contract

## Problem

The official PostgreSQL Docker image documents that `/dev/shm` defaults to **64MB** on Docker. This stack already asks Postgres for more than that:

- `POSTGRES_SHARED_BUFFERS: ${POSTGRES_SHARED_BUFFERS:-256MB}`
- `POSTGRES_EFFECTIVE_CACHE_SIZE` default `1GB`
- `POSTGRES_WORK_MEM: 4MB` with `POSTGRES_MAX_CONNECTIONS` default 100

Those GUCs expect a usable shared-memory device. When `shm` is 64MB, operators see `could not resize shared memory segment`, flaky `pg_isready` under load, or silent parallel-query failures. `affine_postgres` (pgvector) has the same 64MB default and no `shm_size` at all.

Stage 23 is statement_timeout / pooling. Stage 26 `chromium-shm-size-contract.md` is **browser** `/dev/shm` for Playwright. This page is leftover **database** `shm_size` using the same official Compose key.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `postgres` environment GUCs | Already request 256MB shared_buffers |
| Compose `deploy.resources` on `postgres` (512M limit) | Cgroup RAM, not `/dev/shm` |
| Official Postgres Docker docs | Increase `--shm-size` |
| Stage 23 `postgres-statement-timeout-pooling-contract.md` (expected sibling) | `-c` flags / optional PgBouncer |
| Stage 26 `chromium-shm-size-contract.md` (expected sibling) | browserless / mcp-playwright only |
| `affine_postgres` | Second official Postgres, same 64MB trap |

Out of scope:

- Host `kernel.shmmax` sysctl as the default fix (Stage 24 is optional host sysctl)
- Moving Postgres to `ipc: host`
- Raising `shared_buffers` further without a RAM budget change
- A sidecar that `mount`s tmpfs into `/dev/shm`

## Proposal

Set Compose `shm_size` on both Postgres services. Size it for the **already declared** `shared_buffers`, not a new GUC.

```yaml
postgres:
  shm_size: ${POSTGRES_SHM_SIZE:-256mb}

affine_postgres:
  shm_size: ${AFFINE_POSTGRES_SHM_SIZE:-128mb}
```

256mb matches the default `POSTGRES_SHARED_BUFFERS`. 128mb is enough for AFFiNE's smaller companion DB unless operators raise its buffers. Document both keys in `env.example`.

Do **not** set `shm_size` on Redis, Qdrant, or Nginx in this PR.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `postgres` | `shm_size` | Default 256mb |
| Compose `affine_postgres` | `shm_size` | Default 128mb |
| `env.example` | database section | Optional overrides |
| Docs | this page + Stage 23 | shm ≠ statement_timeout ≠ pooling |

### Rules

1. **Use Compose `shm_size`.** Do not `ipc: host` or privileged mounts.
2. **Match existing GUCs.** If someone raises `POSTGRES_SHARED_BUFFERS`, they raise `POSTGRES_SHM_SIZE` in the same change.
3. **Keep cgroup limits.** `deploy.resources.limits.memory: 512M` stays; shm is inside that budget, not extra host RAM advertising.
4. **Distinct from Chromium.** Do not copy the 1G browser value onto Postgres.
5. **GitHub remains intake.** “Give Postgres 8G shm for analytics” is a hardware-class Issue (Stage 3), not this default.

### Suggested contributor checklist

```text
1. Add shm_size: 256mb on postgres
2. Add shm_size: 128mb on affine_postgres
3. Add POSTGRES_SHM_SIZE / AFFINE_POSTGRES_SHM_SIZE to env.example
4. Do not change shared_buffers in this PR
5. Confirm docker compose config still renders
6. docker exec ai_postgres df -h /dev/shm
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Container shm | Compose `shm_size` | `ipc: host` or a shm sidecar |
| Query safety | Stage 23 timeouts / pool | Raising shm to hide runaway queries |
| Browser tabs | Stage 26 1G Chromium shm | One global shm_size YAML anchor for every service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: two `shm_size` keys + `env.example`.
3. Recreate (not just restart) the containers so `/dev/shm` is resized.

## Acceptance criteria

- [ ] `postgres.shm_size` is at least the default `POSTGRES_SHARED_BUFFERS` (256mb).
- [ ] `affine_postgres` has an explicit `shm_size` (≥ 64mb).
- [ ] No `ipc: host` is added.
- [ ] Chromium/browserless shm is unchanged by this PR.
- [ ] `docker compose config` still renders.

## Rollback

Remove `shm_size`. Docker returns to 64MB `/dev/shm`. Data directories are unchanged; recreate containers to apply the rollback.

## Success metrics

- Shared-memory resize errors disappear from `ai_postgres` logs under normal RAG/n8n load.
- Reviewers stop copying `shm_size: 1G` from the browserless service onto Postgres.
- AFFiNE migration jobs do not fail on pgvector shared-memory errors at default settings.
