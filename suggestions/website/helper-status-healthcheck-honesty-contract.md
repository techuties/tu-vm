---
title: Helper Healthcheck Honesty Contract
description: Constructional contract for a Compose healthcheck on helper_index that probes the existing /health route, so Nginx can use service_healthy without a second health API.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Helper Healthcheck Honesty Contract

## Problem

`helper_index` exposes Flask on port 9001 and already has `GET /health` (`ok` / 200). Compose does **not** declare a `healthcheck`. `nginx` uses:

```yaml
depends_on:
  - helper_index
```

Docker marks the helper "started" as soon as the container process exists. The real process is `apk add` + `pip install` + `python …/uploader.py`. For the first 30–90s the dashboard's `/status/full` origin is not listening. Nginx can pass the config test (`nginx -t`) while every landing XHR fails.

Stage 24 says: use `service_healthy` **when a probe exists**. Stage 25 gave Tika a real `/tika` probe for that reason. The helper is the missing probe. Using `/status` as that probe would be **dishonest liveness**: `/status` talks to the Docker socket and can 500 when Docker is slow, flapping Nginx every 180s.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` `GET /health` | Existing liveness body (`ok`) |
| `GET /status` + fixture | Dashboard contract; too heavy for a probe |
| `scripts/helper-contract-check.sh` | Live JSON checks when the helper is up |
| Compose `healthcheck` on postgres/nginx/open-webui | Pattern to copy (interval 180s) |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | How `/status/full` evolves |
| Stage 24 `compose-depends-on-health-contract.md` (expected sibling) | `service_healthy` once a probe exists |
| Stage 25 `tika-healthcheck-honesty-contract.md` (expected sibling) | Same honesty move for Tika |

Out of scope:

- A `/health/ready` product, Docker-socket circuit breaker, or health sidecar
- Changing `/status` JSON or the fixture
- Making Nginx `nginx -t` probe upstreams (config test stays config test)
- Baking the image (Stage 22); the probe must tolerate apk/pip `start_period`

## Proposal

Add a Compose probe that hits the route that already means "Flask accepted a request".

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `helper_index.healthcheck` | `curl -fsS http://127.0.0.1:9001/health` |
| Compose | `nginx.depends_on.helper_index` | `condition: service_healthy` after the probe exists |
| Docs | this page + Stage 24 checklist | Helper is not healthy until `/health` answers |
| Contract script | optional | `helper-contract-check.sh` may assert `/health` == `ok` |

### Rules

1. **Probe `/health`, not `/status`.** Liveness is "Flask is up". Readiness for Docker is a different ticket.
2. **Do not invent a second health API.** `/health` already returns `ok`. Do not add `/readyz` unless a measured flake appears.
3. **Allow first-boot package install.** `start_period` ≥ 90s while the command still runs apk/pip. After Stage 22 bake, that can drop.
4. **Reuse the 180s energy interval** already used by Nginx/Postgres. Do not restore 10s helper polls.
5. **`curl` is already in the startup command.** Do not add `wget` or a Python one-liner as the default probe.
6. **GitHub remains intake.** "Helper should report per-container health on `/health`" stays an Issue.

### Suggested contributor checklist

```text
1. Add helper_index.healthcheck using curl to http://127.0.0.1:9001/health
2. Set start_period to at least 90s (apk+pip)
3. Match nginx/postgres interval 180s, timeout 5–10s, retries 2
4. Change nginx depends_on helper_index to condition: service_healthy
5. Do not point the probe at /status
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Liveness | Existing `/health` | New endpoint or `/status` probe |
| Start order | Stage 24 `service_healthy` | Bare `depends_on` after a probe exists |
| Live JSON proof | `helper-contract-check.sh` | A second contract runner |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: healthcheck first, then Nginx `service_healthy`.
3. After Stage 22 bake, shorten `start_period` in the same PR.

## Acceptance criteria

- [ ] `helper_index` has a Compose `healthcheck` against `/health`.
- [ ] The probe is not `/status` or `/status/full`.
- [ ] `nginx` waits on `service_healthy` for the helper.
- [ ] `start_period` covers apk/pip (or is reduced only after bake).
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Remove `healthcheck` and restore bare `depends_on: helper_index`. Flask routes are unchanged.

## Success metrics

- Dashboard XHR after `compose up` no longer races apk/pip.
- Helper "unhealthy" in `docker ps` means Flask is down, not "Docker list was slow".
- New helper routes do not replace `/health` without an Issue.
