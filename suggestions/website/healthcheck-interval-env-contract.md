---
title: Healthcheck Interval Env Contract
description: Constructional contract for unused HEALTH_CHECK_* env.example keys versus energy-tuned Compose intervals, without a monitoring SaaS or dishonest probes.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Healthcheck Interval Env Contract

## Problem

`env.example` advertises:

- `HEALTH_CHECK_INTERVAL=30`
- `HEALTH_CHECK_TIMEOUT=10`
- `HEALTH_CHECK_RETRIES=3`

No service interpolates them. Compose hardcodes `180s` on energy-sensitive Tier 1 probes (postgres, redis, open-webui, nginx, helper-adjacent) and `30s`/`60s` on others (qdrant, minio, tika). Changelog 2.2.0 / 2.0.0 treated longer intervals as a battery feature.

An operator who sets `HEALTH_CHECK_INTERVAL=300` to save more CPU, or `30` to match the example, changes nothing. The example value `30` also **disagrees** with the 180s energy default, so it teaches the wrong number.

Stage 13 covers **what a probe command may be**. Stage 16 covers **daily checkup**. This page is only **how interval/timeout/retry knobs are advertised and consumed**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env.example` | Unused `HEALTH_CHECK_*` keys with 30/10/3 |
| `docker-compose.yml` `healthcheck` | Hardcoded `interval` / `timeout` / `retries` / `start_period` |
| Changelog 2.2.0 | Open WebUI interval 60s → 180s for energy |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Honest probe design |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling) | Scheduled host/script checks, not Compose probes |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | CPU/memory limits; not probe timers |

Out of scope:

- Prometheus/Grafana (Stage 19 exporters stay opt-in)
- Dummy `exit 0` probes
- Changing probe **commands** in the same PR
- A helper API that rewrites Compose intervals at runtime

## Proposal

Pick one honest path, matching the Nginx worker contract: **wire or delete**.

Prefer **delete-plus-document** unless a real operator needs one global energy slider. If wiring is accepted, interpolate with **energy-safe defaults** (`180s` / `10s` / `2`), not the current example `30`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default (prefer) | `env.example` + compose comments | Remove unused keys; comment why 180s exists |
| Opt-in global | `${HEALTH_CHECK_INTERVAL:-180s}` on Tier 1 energy probes only | Same default as today |
| Per-service overrides | keep hardcoded 30s/60s on qdrant/minio/tika | Fast start vs energy |
| Guard | `check-config.sh` | Fail `--strict` if unused `HEALTH_CHECK_*` reappear |

### Rules

1. **Do not advertise 30s if the live default is 180s.** Example values must match Compose after interpolation.
2. **Energy probes share one default.** Postgres, redis, open-webui, and nginx already chose 180s together. Do not give each a unique unused env key.
3. **Fast-start services may keep local intervals.** Qdrant/MinIO/Tika `30s`/`60s` exist so dependents become healthy; do not force them onto 180s through a global env.
4. **Timeouts and retries stay boring.** `10s` / `2` are enough. Do not add `HEALTH_CHECK_START_PERIOD` unless a service actually needs a new start_period.
5. **Stage 13 still owns the command.** This contract does not replace `pg_isready` / `nginx -t`.
6. **GitHub remains intake.** Requests for a health SaaS stay Issues.

### Suggested contributor checklist

```text
1. Grep HEALTH_CHECK_ in env.example, compose, scripts, and docs
2. Prefer deleting unused keys and documenting 180s in compose comments
3. If wiring, default interpolation to 180s/10s/2 and update env.example to match
4. Leave qdrant/minio/tika intervals local unless a measured start race says otherwise
5. Add check-config unused-key coverage
6. Do not change probe commands in the same PR
7. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Interval honesty | Compose literals or interpolated env | Decorative `env.example` keys |
| Probe command | Stage 13 contract | Helper-driven health rewriting |
| Drift detection | `check-config.sh` | A new linter product |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: remove unused keys (or interpolate with 180s defaults) and align `env.example`.
3. Keep energy comments next to the 180s probes.

## Acceptance criteria

- [ ] `HEALTH_CHECK_*` keys are consumed by Compose or absent from `env.example`.
- [ ] Documented defaults match live energy intervals (180s class).
- [ ] Qdrant/MinIO/Tika may keep faster local intervals.
- [ ] Probe commands are unchanged.
- [ ] `check-config --strict` fails on unused `HEALTH_CHECK_*` keys.

## Rollback

Restore the three keys in `env.example` and hardcoded compose intervals. Runtime probes are unchanged if compose literals were not edited.

## Success metrics

- Operators who want longer probes edit a value that Compose actually reads — or they edit compose directly, with docs that say so.
- The example file no longer teaches a 30s interval that production Compose abandoned.
- Energy regressions from accidental 30s interpolation are avoided by defaulting to 180s.
