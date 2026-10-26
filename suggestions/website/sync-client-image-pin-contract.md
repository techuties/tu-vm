---
title: Sync Client Image Pin Contract
description: Constructional contract so the Open WebUI upload sync lists files with the pinned Open WebUI image and runs a digest-pinned MinIO client, instead of alpine:latest and untagged minio/mc.
last_updated: 2026-10-26
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Sync Client Image Pin Contract

## Problem

The daily upload sync pulls images that Compose does not pin.

`scripts/sync-openwebui-minio.sh` does four `docker run` calls:

| Line of work | Image reference | Docker tag |
|---|---|---|
| List the upload volume | `alpine:latest` | `latest` |
| `mb`, forward `mirror`, reverse `mirror` | `minio/mc` | `latest` (no tag was written) |

Compose pins `minio/minio` to `sha256:14cea493d9a34af32f524e538b8346cf79f3321eff8e708c1e2960462bd8936e` and pins Open WebUI to `sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e`. Neither digest is an `mc` or `alpine` image. The sync script never reads those pins. A cron run can fetch whatever `alpine:latest` and `minio/mc:latest` point at that day.

`alpine:latest` is only used for:

```text
docker run --rm -v "$SRC_VOL":/src:ro alpine:latest sh -c 'ls -A /src ...'
```

The same files are already mounted in `ai_openwebui` at `/app/backend/data/uploads`. The volume name is taken from that container's inspect when the container exists. A second image is not required to list it.

`minio/mc` is the client the script should keep. It should be pinned the same way the server image is pinned: a digest recorded in the script, reviewed in a PR, and not `:latest`.

Checked on 2026-10-26 by reading the sync script and the Compose `image:` lines. No image was pulled.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/sync-openwebui-minio.sh` | The cron sync to keep |
| `ai_openwebui` volume mount `/app/backend/data/uploads` | The directory `alpine:latest` is listing |
| Compose `open-webui` digest | Image to reuse for a one-shot `ls` when the container is stopped |
| Compose `minio` digest | Proof the server is pinned. Not a substitute digest for `mc` |
| Stage 46 mc transport (open PR #72) | `MC_HOST_local` and `--network host`. This page does not change either |
| Stage 44 image compare (open PR #70) | Compose `image:` lines, including `python:3-alpine` and `n8n-mcp:latest`. It does not see `docker run` images in this script |
| Stage 26 n8n-mcp pin (open PR #52) | Floating-tag policy for a different image |

Out of scope:

- Replacing `mc` with a Python MinIO SDK or a new sync container
- Changing `--network host`, the bucket name, or the password lookup
- Putting `minio/mc` into `docker-compose.yml` as a long-running service
- Claiming the MinIO server digest is a valid `mc` digest
- A Watchtower or pull-always policy

## Proposal

List the volume with an image this repo already pins. Pin the client the three `mc` commands share.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Empty check | `sync-openwebui-minio.sh` | Delete `alpine:latest`. If `ai_openwebui` is running, `docker exec` it and `ls` the uploads directory. If it is stopped, `docker run --rm --entrypoint` the same Open WebUI digest Compose pins, with the volume mounted read-only |
| Client | The three `minio/mc` runs | One variable, `minio/mc@sha256:…`, used by `mb` and both `mirror` calls |
| Digest | The PR that pins `mc` | Record the digest from the registry manifest the same way Compose records `minio/minio`. Do not copy the server digest |
| Compare | Optional follow-up on Stage 44 | The checkup can learn script image references later. This page does not edit `daily-checkup.sh` |

The Open WebUI image is large for an `ls`, and that is acceptable: the alternative is an unpinned Alpine pull. `docker exec` avoids the extra run whenever the chat container is up, which is the normal Tier 1 case.

### Rules

1. **No `alpine:latest`.** The uploads directory is already on a pinned container.
2. **No untagged `minio/mc`.** Untagged means `:latest`.
3. **One digest for all three client runs.** `mb` and both `mirror` calls share it.
4. **Leave the transport on Stage 46.** Do not rewrite `MC_HOST_local` or `--network host` here.
5. **Do not add a sync service.** Cron plus `mc` stays the tool.

### Suggested contributor checklist

```text
1. Confirm alpine:latest is absent from sync-openwebui-minio.sh
2. Confirm minio/mc is referenced with @sha256 and not as a floating tag
3. Confirm mb and both mirror calls use that same reference
4. Confirm an empty volume still exits 0 without pulling Alpine
5. Confirm --network host and MC_HOST_local are unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Listing uploads | `docker exec` on `ai_openwebui`, or that image's digest | `alpine:latest` |
| Object sync | Pinned official `minio/mc` | A custom sync binary |
| Server image | The existing Compose digest | Reusing that digest as if it were `mc` |
| Update visibility | Stage 44's Compose compare, extended later | A second scanner in this PR |
| Intake | GitHub Issue | An always-on sync container |
