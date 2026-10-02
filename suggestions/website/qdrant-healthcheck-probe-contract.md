---
title: Qdrant Healthcheck Probe Contract
description: Constructional contract so the Tier 1 Qdrant healthcheck uses a program that the pinned image already contains.
last_updated: 2026-10-02
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Qdrant Healthcheck Probe Contract

## Problem

Qdrant is Tier 1. `docker-compose.yml` healthchecks it with `curl`:

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -sf http://localhost:6333/healthz || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 20s
```

The running image is pinned:

`qdrant/qdrant@sha256:75eab8c4ba42096724fdcfde8b4de0b5713d529dde32f285a1f86fdcb2c9e50c`

The registry config blob for the linux/amd64 manifest (`sha256:da65a06bc75e42702f80c992b99c5144b0fbd675ae7a96d2991de0bf957b7071`, image created 2026-06-03) records this install and nothing else:

```text
apt-get install -y --no-install-recommends ca-certificates tzdata libunwind8
```

`curl` is not in that list. `CMD-SHELL` runs `/bin/sh -c`. The probe exits 127. Docker ignores failures during `start_period` (20s) and then counts `retries` (5) at `interval` (30s). The container becomes `unhealthy` and stays up, because `restart: unless-stopped` does not restart an unhealthy container.

Open WebUI depends on Qdrant with `condition: service_started`, so Compose still starts the UI. The landing page reports Qdrant by opening a TCP connection to `ai_qdrant:6333` (`/status/qdrant`). That check can say "running" while Docker health is `unhealthy`.

`wait_for_services` treats `unhealthy` as failure. The startup-gate page in this stage describes what that skips. Fixing the waiter without fixing this probe leaves every `./tu-vm.sh start` on the failure path once Qdrant has finished its retries.

Qdrant's own HTTP health route is `GET /healthz` on port 6333. The route is fine. The client binary is the defect.

Checked on 2026-10-02 against the pinned digest's image history. The Docker daemon was not running in this environment, so this was not a live `docker inspect` of a container. The apt line is the image config history from the registry.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `healthcheck` on `qdrant` | The probe to replace |
| Pinned digest | The image the probe must run inside. Do not float the tag to "get curl" |
| `GET /healthz` | The endpoint Open WebUI and Qdrant already use |
| Debian base (`debian.sh` trixie in the same history) | Provides `bash`. `/bin/sh` on Debian is dash and does not implement `/dev/tcp` |
| MinIO healthcheck | Uses `curl` because that is MinIO's upstream check. Leave it alone |
| `check_service_health` | Will report `healthy` once this probe can succeed |

Out of scope:

- A derived `qdrant` image whose only change is `apt-get install curl`
- Changing `QDRANT_URI` or moving Qdrant back to Tier 2
- Vector schema, embeddings, or the offline-embedding contract (Stage 33, open PR #59)
- The 180 second intervals on other services (startup-gate page)

## Proposal

One healthcheck, one pinned image, a client that is already installed.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Probe | `qdrant.healthcheck.test` | Replace `curl` with `bash -c 'echo >/dev/tcp/127.0.0.1/6333'` (or an equivalent bash TCP open). Bash is on the Debian rootfs. Curl is not |
| Timing | Same block | Keep a short `start_interval` if the Compose version supports it, and a `start_period` long enough for Qdrant to bind 6333. The current 30s interval can stay for the steady state |
| Dependency | `open-webui.depends_on.qdrant` | Switch to `condition: service_healthy` after the probe succeeds inside the pinned image. `service_started` is what lets the UI come up against a dead healthcheck |
| Image | digest pin | Do not change the digest in the probe PR unless the pin is already wrong for another reason |

### Rules

1. **The probe must succeed inside the pinned image.** Before merging, run a one-shot container from that digest and confirm `command -v curl` fails and `command -v bash` succeeds. Then run the exact healthcheck shell against a Qdrant that is listening.
2. **Call bash by name.** `CMD-SHELL` is `/bin/sh`. A bare `/dev/tcp` redirect under dash does not work.
3. **Do not install curl.** A fork or an `apt-get` sidecar recreates the image we pinned to avoid.
4. **Do not copy the MinIO check.** MinIO's published image contains `curl`. This Qdrant image does not. Same pattern, different rootfs.
5. **TCP-open is enough.** `/healthz` is the right route when a client exists. A successful TCP connect to 6333 matches what the helper already uses for `/status/qdrant`. Prefer that over adding an HTTP client package.
6. **Unhealthy must mean the port is down.** After this change, a stopped listener becomes `unhealthy`. A running listener becomes `healthy` during `start_period`.

### Suggested contributor checklist

```text
1. docker run --rm --entrypoint bash the pinned digest and print OK
2. Confirm curl is absent in that same one-shot
3. Replace the healthcheck test with the bash TCP probe
4. Recreate ai_qdrant and show docker inspect .State.Health.Status is healthy
5. Point open-webui depends_on qdrant at service_healthy
6. Do not edit the image digest or publish a new Qdrant Dockerfile
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Process check | Compose `healthcheck` | A cron that curls Qdrant from the host |
| Client | `bash` already in the Debian rootfs | `apt-get install curl` in a child image |
| UI gate | `depends_on.condition: service_healthy` | A sleep in `tu-vm.sh` |
| Operator signal | Existing `docker inspect` health status | A new Qdrant exporter |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in the `qdrant` service of `docker-compose.yml` only, plus the `open-webui` `depends_on` condition once the probe is proven.
3. `ai_qdrant` must report `healthy` on the pinned digest before this page is marked implemented.

## Acceptance criteria

- The healthcheck command does not call `curl`.
- On the pinned digest, a listening Qdrant reaches `healthy` without a custom image.
- A Qdrant that is not listening becomes `unhealthy`.
- Open WebUI waits for that healthy status.
- The MinIO healthcheck is unchanged.
