---
title: Datastore Nofile Ulimits Contract
description: Constructional contract for Compose ulimits.nofile on postgres and minio, reusing the same knob Nginx already sets.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Datastore Nofile Ulimits Contract

## Problem

Only **nginx** sets `ulimits.nofile` (`65535` / `65535`). Postgres and MinIO — the two services most likely to hold many sockets and file descriptors — inherit the **container default** (often 1024). Under Open WebUI + n8n + processor concurrency that shows up as `too many open files`, hung healthchecks, or MinIO API 500s that look like disk failure.

Stage 18 covers **CPU/memory budget**. Stage 23 covers **Postgres statement timeout / pooling**. This page is only **the `ulimits` key Nginx already proved in-tree**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx.ulimits.nofile` | Existing pattern (`soft`/`hard` 65535) |
| `postgres` / `minio` | No `ulimits` today |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | CPU/RAM, not fds |
| Stage 23 `postgres-statement-timeout-pooling-contract.md` (expected sibling) | Connection count, not fd ceiling |

Out of scope:

- A PAM/systemd `LimitNOFILE` product on the host as the default
- Raising `POSTGRES_MAX_CONNECTIONS` in the same PR (that is Stage 23)
- Applying 65535 to every sidecar (Pi-hole, Redis, MCP fetch do not need it)
- Changing Nginx's existing values

## Proposal

Copy Nginx's `ulimits.nofile` onto postgres (and affine_postgres if present) and minio.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| SQL | `postgres`, `affine_postgres` | Same 65535/65535 block as nginx |
| Object store | `minio` | Same block |
| Proxy | `nginx` | Already set — leave it |
| Skip | redis, pihole, helper, MCP tools | Default fds are enough; do not cargo-cult |

### Rules

1. **Reuse the Nginx block.** Do not invent a second number without evidence (`cat /proc/<pid>/limits` after a failure).
2. **Do not add a ulimit sidecar or entrypoint wrapper.** Compose `ulimits` is the contract.
3. **Do not raise `max_connections` here.** Fds and connection caps are related but Stage 23 owns GUCs.
4. **Do not set `nproc` / `memlock` unless a vendor image requires it.** Scope is `nofile`.
5. **GitHub remains intake.** Requests for "tune the host pam.d" stay Issues (optional operator note, not the default).

### Suggested contributor checklist

```text
1. Copy nginx ulimits.nofile onto postgres
2. Copy the same block onto minio
3. Optionally copy onto affine_postgres
4. Do not change POSTGRES_MAX_CONNECTIONS
5. Confirm docker compose config still renders
6. On a test stack, confirm postgres and minio start and pass healthchecks
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fd ceiling | Compose `ulimits.nofile` | Host PAM / systemd drop-in as default |
| Connection cap | Stage 23 GUCs / optional PgBouncer | Mixing GUCs into this PR |
| Proxy fds | Existing nginx block | A third "fd tuner" script |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add the two (or three) `ulimits` blocks.
3. If a vendor image ignores the key, document that exception — do not wrap the entrypoint.

## Acceptance criteria

- [ ] `postgres` and `minio` set `ulimits.nofile` ≥ 65535.
- [ ] Nginx values are unchanged.
- [ ] No ulimit wrapper or host PAM change is added as the default.
- [ ] `docker compose config` still renders.
- [ ] Postgres and MinIO still become healthy on a test stack.

## Rollback

Remove the new `ulimits` keys. Images and volumes are unchanged.

## Success metrics

- `too many open files` tickets on postgres/minio drop.
- Contributors copy the Nginx block instead of proposing a host tuner.
- Healthchecks stay green under concurrent Open WebUI + processor load.
