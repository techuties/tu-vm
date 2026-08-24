---
title: Compose Init Tini Contract
description: Constructional contract for Compose init: true (tini) on helper and processor, without a custom PID-1 image or a process supervisor product.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Compose Init Tini Contract

## Problem

`helper_index` and `tika_minio_processor` run Python as PID 1:

- Helper command is `sh -c "apk add … && pip install … && python … /app/uploader.py"`.
- Processor `command` is `["python", "universal_auto_processor.py"]` on a `python:3-alpine` image with no `ENTRYPOINT` tini.

PID 1 in Linux does not reap zombies the way a real init does. Flask and the MinIO watcher can leave defunct `curl` / `docker` / child Python processes after a failed probe. `docker compose stop` then hits the shell wrapper, not the Flask process, so SIGTERM is delayed until the Stage 25 grace period expires (or the 10s default).

Official images for Nginx, Postgres, Redis, MinIO, and Pi-hole already ship a proper entrypoint. This gap is the **two custom Python services**.

Stage 18 covers **cap_drop / no-new-privileges**. Stage 22 covers **baking helper apk/pip** so the `sh -c` wrapper can shrink. This page is only **who is PID 1**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `init: true` | Docker injects tini; no image rebuild required |
| `helper/uploader.py` | Flask app; not an init |
| `tika-minio-processor/Dockerfile` | `CMD` python; no tini |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | Capabilities, not PID 1 |
| Stage 20 `tika-minio-processor-python-contribution-contract.md` (expected sibling) | Watcher/retry code, not init |
| Stage 22 `helper-index-image-bake-contract.md` (expected sibling) | Bake deps; still needs an init |

Out of scope:

- systemd, supervisord, s6, or a "process manager" sidecar
- Rewriting helper as a multi-process app
- Changing `restart:` or healthchecks in the same PR
- Adding tini to vendor images that already have an entrypoint

## Proposal

Set `init: true` on `helper_index` and `tika_minio_processor` (and any future first-party Python/Node service that starts without an official entrypoint). Prefer Compose's built-in tini over copying `tini` into Dockerfiles.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| First-party Python | `helper_index`, `tika_minio_processor` | `init: true` |
| First-party Node | `mcp_gateway`, `langgraph_supervisor` if they exec children | `init: true` when a child is spawned |
| Vendor images | postgres, nginx, minio, redis | Do **not** double-wrap; leave unset |
| Bake path | Stage 22 helper Dockerfile | Keep `init: true` even after apk/pip move into the image |

### Rules

1. **Compose `init: true` first.** It uses the engine's tini. Do not add a `tini` package to Alpine unless the service must run outside Compose.
2. **Do not add supervisord.** One process per container remains the model.
3. **Vendor images stay untouched.** Double init can confuse signal routing.
4. **Helper `sh -c` is a separate smell.** Stage 22 bake removes apk/pip from start; this page still requires tini so the remaining Python is not PID 1.
5. **GitHub remains intake.** Requests for a cluster process manager stay Issues.

### Suggested contributor checklist

```text
1. Identify first-party services whose PID 1 is python/node/sh
2. Set init: true on those services only
3. Do not add supervisord, s6, or a tini COPY unless off-Compose
4. After bake (Stage 22), keep init: true
5. Confirm docker compose config still renders
6. docker top / inspect shows tini as PID 1 wrapping python
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| PID 1 / zombies | Compose `init: true` | Custom init images, supervisord |
| Helper start time | Stage 22 baked image | Keeping apk+pip in `sh -c` forever |
| Signals + drain | This page + stop-grace contract | Helper pre-stop hooks |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `init: true` on helper and processor in one Compose PR.
3. Optionally add the same flag to mcp_gateway / langgraph_supervisor if they spawn children.

## Acceptance criteria

- [ ] `helper_index` and `tika_minio_processor` set `init: true`.
- [ ] No supervisord/s6/custom PID-1 image is introduced.
- [ ] Vendor images are not double-wrapped.
- [ ] `docker compose config` still renders.
- [ ] `docker inspect` on helper shows an init process wrapping Python.

## Rollback

Remove `init: true`. Images and volumes are unchanged.

## Success metrics

- Zombie `curl`/`docker` processes no longer accumulate in helper.
- `compose stop` delivers SIGTERM to Python within a second (then grace applies).
- Contributors add `init: true` instead of a process-manager product.
