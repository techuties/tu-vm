---
title: Nginx Worker Env Wiring Contract
description: Constructional contract for making advertised NGINX_WORKER_* and keepalive env keys match nginx.conf, or removing them, without introducing a config templating language.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Nginx Worker Env Wiring Contract

## Problem

`env.example` advertises `NGINX_WORKER_PROCESSES`, `NGINX_WORKER_CONNECTIONS`, and `NGINX_KEEPALIVE_TIMEOUT`. Operators copy them into `.env` and expect a restart to change concurrency.

`nginx/nginx.conf` ignores those keys. It hardcodes `worker_processes auto`, `worker_connections 2048`, and `keepalive_timeout 65`. Compose does not interpolate them. `scripts/check-config.sh` does not warn that they are unused.

The result is a silent documentation lie: a laptop operator can set `NGINX_WORKER_PROCESSES=1` for energy savings and still run `auto` workers.

Stage 12 covers **what** a vhost may proxy. Stage 23 covers **how** TLS/header snippets are shared. This page is only **how advertised Nginx worker env keys become real config or are deleted**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env.example` | Advertises the three unused Nginx keys |
| `nginx/nginx.conf` | Source of truth for workers, connections, keepalive |
| `docker-compose.yml` `nginx` service | Bind-mounts `nginx.conf` read-only; no envsubst |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost and proxy contribution rules |
| Stage 17 `check-config-contribution-contract.md` (expected sibling) | Secret-safe preflight; natural home for unused-key warnings |
| Stage 19 `nginx-login-rate-limit-contract.md` (expected sibling) | Separate unused **rate-limit zone** honesty |
| Stage 23 `nginx-compose-configs-contract.md` (expected sibling) | Shared TLS/header includes; not worker wiring |

Out of scope:

- Replacing Nginx or adding Caddy/Traefik
- `envsubst` or Jinja across vhosts (Stage 23 forbids a templating language for routing)
- Changing allowlists, TLS ciphers, or `proxy_pass` targets
- Raising `worker_connections` as a performance product

## Proposal

Pick one honest path. Do not leave advertised keys that Compose and Nginx ignore.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default (prefer) | `env.example` + `check-config.sh` | Delete unused keys; warn if they reappear |
| Opt-in wiring | `nginx/snippets/workers.conf` + `include` | Only if operators need `.env` tuning |
| Values | `nginx/nginx.conf` | Remains the clone-path source of truth |

### Rules

1. **Honesty first.** Either wire a key or remove it from `env.example`. Do not keep decorative knobs.
2. **No vhost templating.** If wiring is accepted, generate or include **only** worker/events settings. `server` blocks stay static.
3. **Energy-safe defaults stay in git.** `auto` workers and today's keepalive are the laptop default. `.env` may only **narrow** concurrency, not silently raise it past documented ulimits.
4. **check-config owns drift.** If a contributor re-adds `NGINX_WORKER_*` without a consumer, `--strict` fails.
5. **GitHub remains intake.** Requests for an Nginx control plane or live-reload UI stay Issues.

### Suggested contributor checklist

```text
1. Grep env.example and .env for NGINX_WORKER_ and NGINX_KEEPALIVE_
2. Grep nginx/ and docker-compose.yml for the same names
3. Prefer deleting unused keys and documenting real values in nginx.conf
4. If wiring is required, add nginx/snippets/workers.conf and one include
5. Do not envsubst default.conf
6. Add a check-config unused-key assertion
7. Confirm nginx -t still gates the container healthcheck
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Worker tuning | Edit `nginx/nginx.conf` or one include | A renderer, Helm chart, or live API |
| Env honesty | `check-config.sh` unused-key scan | New helper endpoints for Nginx knobs |
| Snippet delivery | Stage 23 `include` + bind-mount | Baking generated files into the image |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: drop unused keys from `env.example`, document the live `nginx.conf` values, add a check-config guard.
3. Optional later: one include file if a real operator needs `.env` worker overrides.

## Acceptance criteria

- [ ] Advertised `NGINX_*` keys are consumed by Nginx/Compose or absent from `env.example`.
- [ ] `check-config --strict` fails on unused `NGINX_WORKER_*` keys.
- [ ] `nginx -t` still gates health.
- [ ] No templating language is added for vhosts.
- [ ] Energy defaults in `nginx.conf` remain the clone path.

## Rollback

Restore the three keys in `env.example` and remove any include. Runtime Nginx behavior is unchanged if `nginx.conf` was not edited.

## Success metrics

- Operators stop believing `.env` changes Nginx workers when it does not.
- New contributor PRs do not reintroduce decorative Nginx env keys.
- Worker/keepalive edits remain a one-file change.
