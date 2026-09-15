---
title: Env Example Dead Keys Contract
description: Constructional contract to mark or remove env.example keys that no Compose service or script consumes, so community operators stop tuning ghosts.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Env Example Dead Keys Contract

## Problem

`env.example` documents operator knobs that **nothing reads**. A scan of Compose, `tu-vm.sh`, helper, and scripts (this run) found no consumers for:

| Key | Section today | Why it looks real |
|---|---|---|
| `OLLAMA_GPU_MEMORY` | Resource limits | Sounds like Ollama VRAM |
| `POSTGRES_MEMORY` / `REDIS_MEMORY` / `MINIO_MEMORY` | Resource limits | Sounds like `deploy.resources` |
| `ENABLE_METRICS` / `ENABLE_TRACING` | Monitoring | Sounds like Prometheus/OTLP |
| `BACKUP_RETENTION_DAYS` / `BACKUP_COMPRESSION` / `BACKUP_ENCRYPTION` | Backup | README talks about backups; script flags are separate |
| `ENABLE_RATE_LIMITING` / `ENABLE_CORS` / `ENABLE_CSRF_PROTECTION` / `SESSION_TIMEOUT` | Security | Sounds like Nginx/Open WebUI |
| `TIKA_SERVER_PORT` / `TIKA_LOG_LEVEL` | Service-specific | Tika uses `JAVA_TOOL_OPTIONS` + image defaults |

Memory limits in Compose are hardcoded `deploy.resources`, not these keys. Nginx rate limits live in `nginx/conf.d`. Backup retention is implemented in `tu-vm.sh` with its own arguments, not these names. Stage 24 already owns unused `NGINX_WORKER_*` and `HEALTH_CHECK_*` — do not rewrite those pages.

This is distinct from Stage 31 `dead-postgres-env-honesty-contract.md` (ignored official-image env on the `postgres` service).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env.example` | Advertises the keys |
| `docker-compose.yml` | Does not interpolate them |
| `tu-vm.sh` | No references (this run) |
| Stage 4 supply-chain / Stage 19 observability (expected siblings) | Real metrics path when adopted |
| Stage 24 nginx-worker + healthcheck-interval (expected siblings) | Same honesty pattern |
| Stage 24 backup-archive-encryption (expected sibling) | Real backup wrap; not `BACKUP_ENCRYPTION=true` |
| Stage 12 env-schema (expected sibling) | How new keys must name a consumer |

Out of scope:

- Implementing a full metrics stack because `ENABLE_METRICS=true` exists
- Wiring these keys into Compose just to “make the example true”
- Deleting live keys (`CONTROL_TOKEN`, `POSTGRES_PASSWORD`, `DOMAIN`, …)

## Proposal

### Path A (preferred): delete or comment as unimplemented

Move the dead block behind a short comment:

```text
# Not consumed by Compose or tu-vm.sh. Do not set expecting runtime changes.
# Resource limits: docker-compose.yml deploy.resources
# Backups: ./tu-vm.sh backup (see playbooks)
# Metrics: Stage 19 observability contribution contract
```

Or delete the keys. Community clones that copied them keep harmless unused lines.

### Path B: wire only with an owner

A key may stay if the **same PR** connects it to an existing surface (for example `BACKUP_RETENTION_DAYS` → `tu-vm.sh backup` default). One owner per key. Do not batch-wire twelve flags.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Env schema | `env.example` | Path A comment/delete |
| Optional code | `tu-vm.sh backup` | Only if Path B for retention |
| Docs | README | Resource table points at Compose, not these keys |
| CI | Optional | Grep job that fails new `env.example` keys without a Compose/script hit |

### Rules

1. **Every `env.example` key names a consumer** (Compose, script, or helper) or is marked unimplemented.
2. **Do not invent products** to justify `ENABLE_TRACING=false`.
3. **Stage 24 keys stay on Stage 24 pages.** `HEALTH_CHECK_*` and `NGINX_WORKER_*` are not this contract.
4. **Postgres GUC-shaped keys** are Stage 31 dead-postgres honesty / Stage 23 `-c`.
5. **GitHub remains intake.** A metrics platform is Stage 19, not this cleanup.

### Suggested contributor checklist

```text
1. For each key in the table, rg across repo excluding env.example and this page
2. Delete or comment with a pointer to the real knob
3. Do not add Compose interpolation without deploy.resources / script ownership
4. Leave generate-secrets keys and CONTROL_TOKEN intact
5. check-config still passes
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Resource caps | Existing Compose `deploy.resources` | Parallel `*_MEMORY` env |
| Backups | Existing `tu-vm.sh backup` | A second backup.yml driven by unused flags |
| Rate limits | Existing Nginx config | Flask CORS middleware “because ENABLE_CORS” |
| Schema discipline | Stage 12 + optional CI grep | Growing env.example as a wishlist |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Path A edit to `env.example` (and README if it cites the keys).
3. Optional follow-up: CI grep for orphan keys.

## Acceptance criteria

- [ ] Listed keys are removed, commented as unimplemented, or wired with a named consumer in the same PR.
- [ ] `HEALTH_CHECK_*` / `NGINX_WORKER_*` are not re-litigated (Stage 24).
- [ ] Live secrets and `DOMAIN` remain documented.
- [ ] No new observability or backup product is introduced to justify the flags.

## Rollback

Restore the previous `env.example` section. Runtime is unchanged for Path A.

## Success metrics

- Fewer issues titled “I set POSTGRES_MEMORY=4G and the container is still 512M”.
- New env keys in PRs cite a consumer in the Stage 12 sense.
- `env.example` shrinks toward keys that `compose config` or scripts actually use.
