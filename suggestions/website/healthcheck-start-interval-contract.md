---
title: Healthcheck Start Interval Contract
description: Constructional contract for Compose-native healthcheck start_interval so first-boot probes are fast without changing energy-aware steady-state intervals.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Healthcheck Start Interval Contract

## Problem

Tier 1 healthchecks trade energy for honesty: `interval: 180s` on `postgres`, `redis`, `open-webui`, `nginx`, and `pihole`. That is the right **steady-state** poll. It is the wrong **first-boot** poll.

Compose already has `start_period` (Open WebUI 180s, Qdrant/MinIO 20s). After `start_period` ends, the engine still waits a full `interval` before the first success can mark the container healthy. Dependents that use Stage 24 `condition: service_healthy` then sit idle for up to three minutes even when Postgres answered `pg_isready` at second 12.

Stage 13 is the general healthcheck contribution contract. Stage 24 is unused `HEALTH_CHECK_*` **environment keys**. Stage 25 is Tika `/tika`. Stage 27 is helper `/health`. Stage 28 is the commented n8n `/healthz`. This page is the leftover Compose Specification key: `start_interval`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `healthcheck.interval` | Energy-aware steady-state (180s / 60s / 30s) |
| Compose `healthcheck.start_period` | Ignore failures during boot |
| Compose Specification `start_interval` (Compose 2.20+ / Engine 25+) | Faster probes **only during** `start_period` |
| `depends_on: service_healthy` on `open-webui` → `postgres` | First-boot waiter |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Honest probe rules |
| Stage 24 `healthcheck-interval-env-contract.md` (expected sibling) | Wire or delete unused env keys — not this native field |
| Stage 24 `compose-depends-on-health-contract.md` (expected sibling) | Who waits |

Out of scope:

- Changing the 180s steady-state interval (energy work in CHANGELOG 2.0)
- Inventing a helper `/status/ready` scrape
- A startup sidecar that `sleep`s then curls
- Enabling probes on services with no official route

## Proposal

Add `start_interval` beside existing `start_period` on services that already have a real probe. Keep `interval` as the energy-aware value.

Suggested first wave (already probed, already waited on, or already slow):

| Service | Keep `interval` | Add `start_period` if missing | Suggested `start_interval` |
|---|---|---|---|
| `postgres` | 180s | 20s | 5s |
| `redis` | 180s | 10s | 5s |
| `open-webui` | 180s | 180s (exists) | 15s |
| `nginx` | 180s | 10s | 5s |
| `pihole` | 180s | 20s | 10s |
| `minio` | 30s | 20s (exists) | 5s |
| `qdrant` | 30s | 20s (exists) | 5s |
| `affine_postgres` | 60s | 20s | 5s |

Do not add `start_interval` to services with no `healthcheck`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose probes | services that already have `healthcheck` | `start_interval` + `start_period` |
| Dependents | no new API | Existing `service_healthy` becomes honest sooner |
| Docs | this page + Stage 24 | `HEALTH_CHECK_*` env is not a substitute for the native key |
| CI | `docker compose config` | Confirm the field survives interpolation |

### Rules

1. **Use the Compose key.** Do not encode start cadence in `tu-vm.sh` or the helper.
2. **`interval` stays energy-aware.** `start_interval` is only for the start window.
3. **`start_period` is required** for `start_interval` to matter. Add a short one if missing.
4. **Do not lower retries to hide a bad probe.** Fix the `test` (Stages 13/25/27/28).
5. **GitHub remains intake.** Requests for “poll every 2s forever” are energy regressions, not this page.

### Suggested contributor checklist

```text
1. Confirm Docker Engine / Compose versions support start_interval
2. Add start_period where a probe exists but the field is missing
3. Set start_interval to 5s–15s (Open WebUI may need 15s)
4. Leave interval at 180s / 60s / 30s
5. Confirm docker compose config still renders
6. Time postgres → open-webui first healthy after a cold start
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fast first ready | Compose `start_interval` | Sleep loops in `tu-vm.sh` |
| Steady-state energy | Existing 180s `interval` | 5s polls for the life of the container |
| Env documentation | Stage 24 `HEALTH_CHECK_*` wire-or-delete | A second interval schema in `.env` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add `start_period` / `start_interval` on the first-wave table in one PR.
3. If an older engine rejects the key, gate on Compose version in `./tu-vm.sh doctor` rather than inventing a wrapper.

## Acceptance criteria

- [ ] No service changes its energy-aware `interval`.
- [ ] Every service with `start_interval` also has `start_period` and a real `test`.
- [ ] `postgres` and `redis` become `healthy` well under one steady-state interval on a cold start.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] Stage 24 reviews do not treat `HEALTH_CHECK_INTERVAL` as a replacement for this key.

## Rollback

Delete `start_interval` (and any `start_period` added only for this page). Probes fall back to `interval`. Data volumes are unchanged.

## Success metrics

- Open WebUI no longer waits a full 180s after Postgres is actually ready.
- Contributors stop proposing helper readiness endpoints for first-boot races.
- Energy-idle CPU stays at the CHANGELOG 2.0/2.2 baseline.
