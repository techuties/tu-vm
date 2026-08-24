---
title: Processor Check Interval Energy Contract
description: Constructional contract for tika_minio_processor CHECK_INTERVAL versus energy-tuned 180s health probes, without a second watcher product or MinIO event bus.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Processor Check Interval Energy Contract

## Problem

`tika_minio_processor` polls MinIO every **10 seconds**:

```yaml
- CHECK_INTERVAL=10  # Check for new files every 10 seconds
```

`universal_auto_processor.py` reads `CHECK_INTERVAL` (default `10`) and sleeps in a tight loop. Health checks inside the same loop run every 60 iterations (about 10 minutes). Meanwhile Tier 1 **Compose healthchecks** were moved to **180s** for battery (changelog 2.2.0). The processor is labeled Tier 1 always-on, but its poll rate is a 2010s-era busy loop.

Stage 24 covers unused **`HEALTH_CHECK_*`** keys (Compose probes). Stage 20 covers **watcher/retry Python**. Stage 7 covers **battery widgets**. This page is only **the MinIO poll period versus the energy budget**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `CHECK_INTERVAL` in Compose + processor | Already a real env knob (unlike `HEALTH_CHECK_*`) |
| `WATCH_BUCKETS` | Which buckets to list |
| MinIO `mc` / bucket notifications | Optional event path; not wired |
| Stage 7 `battery-power-operator-signals.md` (expected sibling) | Host battery UI, not poll timers |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Pipeline contribution rules |
| Stage 20 `tika-minio-processor-python-contribution-contract.md` (expected sibling) | Retry/status code |
| Stage 24 `healthcheck-interval-env-contract.md` (expected sibling) | Compose probe env honesty |

Out of scope:

- Replacing the poller with Kafka, Redis streams, or a new "ingest bus"
- Making MinIO bucket notifications **required** (nice opt-in later; poll stays the clone path)
- Changing Tika OCR timeouts (XML contract)
- Tightening Compose healthcheck intervals in the same PR

## Proposal

Treat `CHECK_INTERVAL` as an **energy knob** with a laptop-safe default. Keep polling as the zero-dependency path. Optionally document MinIO event notifications as an opt-in accelerator, not a rewrite.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | Compose `CHECK_INTERVAL` | Raise default from `10` to `30` or `60` (document in env.example) |
| Operator override | `.env` / Compose interpolation | `${CHECK_INTERVAL:-60}` so power users can set `10` |
| Honesty | `env.example` | Add the key (it exists in Compose but not in the example file) |
| Events (optional) | MinIO notification → processor | Only if poll remains the fallback; no new broker |

### Rules

1. **Do not delete the poller.** LAN clones must work without webhook wiring.
2. **Default must match energy policy.** A 10s list on two buckets is busier than the 180s health probes on the same host.
3. **Advertise the key.** If Compose interpolates `CHECK_INTERVAL`, `env.example` must list it (the inverse of Stage 24's unused-key rule).
4. **No message bus.** Redis/NATS/Kafka "to save energy" is out of scope.
5. **OCR timeouts stay separate.** A longer poll does not change Tika's 15-minute job ceiling.
6. **GitHub remains intake.** Requests for a streaming ingest product stay Issues.

### Suggested contributor checklist

```text
1. Add CHECK_INTERVAL to env.example with the new default
2. Interpolate Compose: CHECK_INTERVAL=${CHECK_INTERVAL:-60}
3. Keep Python default in sync or document that Compose always sets it
4. Do not add Kafka/Redis-streams
5. Optional: document mc event setup as opt-in, poll remains fallback
6. Confirm a 2 MB upload is still picked up within 2x the interval
7. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Watch cadence | Existing `CHECK_INTERVAL` env | New watcher daemon |
| Push (optional) | MinIO bucket notifications | Kafka / Redis streams |
| Probe timers | Stage 24 `HEALTH_CHECK_*` | Mixing probe env with poll env |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: interpolate `${CHECK_INTERVAL:-60}`, document in `env.example`.
3. Leave OCR and retry settings unchanged.

## Acceptance criteria

- [ ] Default poll is ≥ 30s unless an operator overrides it.
- [ ] `env.example` documents `CHECK_INTERVAL`.
- [ ] No new message bus or second watcher is added.
- [ ] A new object is still processed within two poll intervals in a local test.
- [ ] `docker compose config` still renders.

## Rollback

Restore `CHECK_INTERVAL=10` and drop the env.example key. Python is unchanged if it still reads the variable.

## Success metrics

- Processor CPU at idle drops versus a 10s list loop.
- Operators can set `10` for "ingest now" without a code change.
- Contributors extend the existing env key instead of proposing an ingest platform.
