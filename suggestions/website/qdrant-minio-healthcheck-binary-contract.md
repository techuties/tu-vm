---
title: Qdrant and MinIO Healthcheck Binary Contract
description: Constructional contract for image-honest Qdrant and MinIO probes so healthchecks use binaries the pinned images actually ship.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Qdrant and MinIO Healthcheck Binary Contract

## Problem

Two Tier 1 probes assume `curl` is on `$PATH`:

```yaml
# qdrant
test: ["CMD-SHELL", "curl -sf http://localhost:6333/healthz || exit 1"]

# minio
test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
```

Official `qdrant/qdrant` and recent `minio/minio` images are minimal. `curl` is often missing. Docker then marks the container `unhealthy` even when the process is serving. Stage 24 `depends_on: service_healthy` would then block Open WebUI or the processor forever.

Stage 13 is the general healthcheck contribution contract. Stage 25 is Tika `/tika`. Stage 27 is helper `/health`. Stage 28 is n8n `/healthz`. Stage 29 is `start_interval`. This page is leftover **binary honesty** for the two probes that still call `curl`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Qdrant HTTP `/readyz` or `/healthz` | Official readiness |
| MinIO `/minio/health/live` | Official liveness |
| MinIO `mc ready` / `mc ready local` | Official CLI in many MinIO images |
| BusyBox `wget` | Present in some Qdrant images; verify on the digest |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Honest `test` rules |
| Stage 25 `tika-healthcheck-honesty-contract.md` (expected sibling) | Same idea, Tika route |
| Pi-hole probe | Already uses `dig` (image-honest) — copy this pattern |

Out of scope:

- Installing `curl` via a custom derived image
- A helper sidecar that probes peers
- Changing energy-aware `interval` values (Stage 29 owns `start_interval`)
- Enabling probes on services with no official route

## Proposal

Verify the binary on the **pinned digest**, then pick the first option that exists:

| Service | Preferred `test` | Fallback if the binary is absent |
|---|---|---|
| `qdrant` | `wget -qO- http://127.0.0.1:6333/readyz` (or `/healthz` if that is what the digest documents) | Distroless: use the Qdrant grpc/http health documented for that tag; do not `apk add curl` |
| `minio` | `["CMD", "mc", "ready", "local"]` **or** the image's documented `curl` path if `curl` is actually present | Keep HTTP live check only with a binary that `docker run --rm <digest> sh -c 'command -v …'` finds |

Do this as a one-time digest inspection in the PR description (`docker run --rm --entrypoint sh <image> -c 'command -v curl wget mc'`).

Keep `interval` / `timeout` / `retries` / `start_period` as they are (or as Stage 29 specifies). This page only changes `test`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose probes | `qdrant`, `minio` | Image-honest `test` |
| Docs | this page + Stage 13 | Cite the digest check |
| CI | optional | A comment or script note; do not add a curl-install step |

### Rules

1. **Probe with what the image ships.** Do not add packages to official images.
2. **Prefer official routes** (`/readyz`, `/minio/health/live`, `mc ready`).
3. **Do not wrap the probe in `tu-vm.sh`.** Compose `healthcheck` is the contract.
4. **CMD vs CMD-SHELL.** Use `CMD` when no shell features are needed.
5. **GitHub remains intake.** Requests for "just install curl in a FROM qdrant Dockerfile" are rejected unless the vendor image is truly distroless with no probe tool.

### Suggested contributor checklist

```text
1. docker run --rm --entrypoint sh <qdrant digest> -c 'command -v curl wget'
2. docker run --rm --entrypoint sh <minio digest> -c 'command -v curl mc'
3. Pick the first existing binary + official route
4. Keep interval / start_period (apply Stage 29 start_interval separately)
5. Recreate the service; docker inspect Health.Status becomes healthy
6. docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Qdrant ready | Official `/readyz` + image binary | Custom Qdrant Dockerfile |
| MinIO live | `mc ready` or image `curl` | A helper that curls MinIO |
| General probe rules | Stage 13 | A new healthcheck framework |
| First-boot cadence | Stage 29 `start_interval` | Tightening `interval` to hide a missing binary |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose PR after digest inspection.
3. If Stage 24 `service_healthy` is enabled for these services, land this **before** that waiter.

## Acceptance criteria

- [ ] `qdrant` and `minio` `healthcheck.test` use a binary proven present on the pinned digest.
- [ ] No custom image is introduced just to add `curl`.
- [ ] Energy-aware `interval` values are unchanged by this page.
- [ ] `docker compose config` still renders.
- [ ] Stage 13/25/27/28/29 reviews do not treat this as a rewrite of those pages.

## Rollback

Restore the previous `curl` tests. Data volumes are unchanged.

## Success metrics

- Qdrant and MinIO report `healthy` on a cold start without a derived image.
- Stage 24 `service_healthy` can wait on them without a false negative.
- Contributors stop proposing `FROM qdrant` just to apk-add curl.
