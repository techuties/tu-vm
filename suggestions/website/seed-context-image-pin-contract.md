---
title: Seed Context Image Pin Contract
description: Constructional contract so scripts/seed-chat-context.sh copies the assistant pack with the pinned Open WebUI image instead of pulling alpine:latest.
last_updated: 2026-10-28
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Seed Context Image Pin Contract

## Problem

`scripts/seed-chat-context.sh` publishes the assistant context pack into the Open WebUI uploads volume by pulling a floating image:

```text
docker run --rm \
  -v "$DEST_VOL":/dest \
  -v "$SRC_DIR":/src:ro \
  alpine:latest sh -c "mkdir -p ... && cp -f /src/* ..."
```

`alpine:latest` moves whenever the registry updates that tag. The script's only job is `mkdir` and `cp`. The Open WebUI image already in Compose can do both, and that image is pinned:

```text
ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e
```

Stage 60 (open PR #86) says `alpine:latest` is only the empty-directory probe in `scripts/sync-openwebui-minio.sh`, and it tells that probe to use this same Open WebUI digest. That scope is correct for the sync script. It does not cover this file. A search of shell scripts on 2026-10-28 still finds `alpine:latest` in `scripts/seed-chat-context.sh`.

The destination volume name `docker_openwebui_files` is a separate bug. Stage 46 (open PR #72) already says to resolve `openwebui_files` from the running container's mount, the way the sync script inspects `ai_openwebui`. This page does not choose a new prefix.

The pack itself is three files under `helper/chat-context/` (`assistant_context_affine_deep_dive.txt`, `assistant_context_affine_n8n.txt`, `n8n_workflow_examples.json`). The script copies them to `/context-pack` on the uploads volume. Keep that destination path.

Checked on 2026-10-28 by reading `scripts/seed-chat-context.sh`, listing `helper/chat-context/`, and reading the Open WebUI `image:` line in `docker-compose.yml`. The script was not executed and no image was pulled.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/seed-chat-context.sh` | The copy to change |
| `helper/chat-context/` | The three source files |
| Open WebUI digest in Compose | Image that already contains a shell and `cp` |
| `ai_openwebui` mount `/app/backend/data/uploads` | The directory the files must land in |
| Stage 14 seed contribution (open PR #40) | What the pack is for. Unchanged here |
| Stage 46 volume prefix (open PR #72) | How to name the volume. Unchanged here |
| Stage 60 sync client pin (open PR #86) | `alpine:latest` and untagged `minio/mc` in the sync script only |

Out of scope:

- A prompt store, CMS, or second uploader
- Editing the three context documents
- Changing `/context-pack`
- Pinning `minio/mc` again
- Rewriting the sync script's probe

## Proposal

Copy the pack with the pinned Open WebUI image, into the uploads directory that container already mounts.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Running UI | `scripts/seed-chat-context.sh` | If `ai_openwebui` is running, `docker cp` each file to `/app/backend/data/uploads/context-pack/` inside that container |
| Stopped UI | Same script | `docker run --rm --entrypoint` the Compose digest, mount the resolved uploads volume, and `cp` there |
| Image id | Same script | Read the digest from the `open-webui` service. Do not write `alpine:latest` |
| Volume | Same script | Keep the Stage 46 inspect of the uploads mount. Do not add another hardcoded prefix in this change |
| Log | Same script | Print the destination path and the image id that performed the copy |

### Rules

1. **No `alpine:latest` in this script.** The copy uses the Open WebUI digest Compose already pins, or `docker cp` into the running container built from that digest.
2. **Do not float the tag.** If the digest is copied into the script, it matches `docker-compose.yml` in the same PR. A later Open WebUI bump updates both.
3. **Leave Stage 60's file alone.** `scripts/sync-openwebui-minio.sh` stays on that page.
4. **Leave the volume-prefix rule alone.** Stage 46 still owns `docker_openwebui_files` versus the project prefix.
5. **Keep the pack path.** Files land in `context-pack/` on the uploads volume, which is `/app/backend/data/uploads/context-pack` inside Open WebUI.
6. **Do not start Tier 2.** Seeding context does not start Ollama, n8n, or the processor.

### Suggested contributor checklist

```text
1. Confirm scripts/seed-chat-context.sh contains no alpine image name
2. Confirm the copy uses the open-webui digest from docker-compose.yml or docker cp into ai_openwebui
3. Confirm the three helper/chat-context files arrive under context-pack
4. Confirm scripts/sync-openwebui-minio.sh is not edited by this change
5. Confirm the script does not pull an image when ai_openwebui is already running
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| File copy | `docker cp` or the pinned Open WebUI image | `alpine:latest` |
| Destination | The existing uploads mount | A new volume |
| Pack contents | `helper/chat-context/` | A context service |
| Intake | GitHub Issue | A second seed implementation |
