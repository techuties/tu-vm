---
title: Backup Volume Image Pin Contract
description: Constructional contract so create_backup packs Docker volumes with the pinned Postgres image instead of pulling floating alpine.
last_updated: 2026-10-29
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Backup Volume Image Pin Contract

## Problem

`create_backup` in `tu-vm.sh` packs each Docker volume by starting a helper container:

```text
docker run --rm -v "$volume":/data -v "$(pwd)/$backup_path":/backup \
    alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || warn "$volume backup failed"
```

The image name is `alpine` with no tag. Docker Engine uses the tag `latest` when the reference omits one, so this pull tracks `alpine:latest`. That tag moves whenever the registry publishes it. The container's only job is `tar`.

Compose already pins the database image that this backup exists to protect:

```text
postgres@sha256:df7bca0066e6f60cc3dd32faa70caddec20e2c22b58932f79498e5704b23854a
```

The Compose comment identifies that digest as the 15-alpine build. Alpine includes `tar`. A backup host that can dump Postgres already has this image, or will pull it for the database service itself.

Stage 60 (open PR #86) says `alpine:latest` is the empty-directory probe in `scripts/sync-openwebui-minio.sh`, and it tells that probe to use the pinned Open WebUI digest. Stage 62 (open PR #88) says the same tag in `scripts/seed-chat-context.sh` must use that Open WebUI digest or `docker cp`. A search of shell scripts on 2026-10-29 still finds a bare `alpine` image in `create_backup` only. The privileged `alpine` inside `recover_openwebui_container` is Stage 62's recovery page, and that function should stop using a helper image entirely.

Stage 46 (open PR #72) already tells the implementation to pin `minio/mc` for the bucket listing in this same function. This page does not choose that digest and does not edit those lines.

Checked on 2026-10-29 by reading the volume loop in `create_backup` and the `postgres` `image:` line in `docker-compose.yml`. The script was not executed and no image was pulled.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup` volume loop | The `docker run` to change |
| Postgres digest in Compose | Image that already contains `tar` |
| `pg_dump` earlier in the same function | Database dump, unchanged here |
| Stage 46 MinIO client (open PR #72) | `minio/mc` pin and network. Unchanged here |
| Stage 46 volume prefix (open PR #72) | Which volume names are archived. Unchanged here |
| Stage 60 sync client pin (open PR #86) | `alpine:latest` in the sync script only |
| Stage 62 seed image pin (open PR #88) | `alpine:latest` in the seed script only |
| Stage 62 recovery command (open PR #88) | The privileged `alpine` kill helper |

Out of scope:

- A new archiver, restic server, or volume plugin
- Pinning `minio/mc` again
- Renaming `docker_*` volumes
- Editing the sync script, the seed script, or `recover_openwebui_container`
- Changing keep-latest rotation (the sibling page on this branch)

## Proposal

Pack every volume tarball with the Postgres digest Compose already pins.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Image | `create_backup` | Replace `alpine` with the `postgres` digest from `docker-compose.yml` |
| Entrypoint | Same `docker run` | `--entrypoint tar` so the Postgres entrypoint does not try to start a database |
| Mounts | Same `docker run` | Keep the volume at `/data` and the backup directory at `/backup` |
| Failure | Same loop | Keep the per-volume warning. The sibling page decides whether that warning may delete older archives |
| Log | Same function | Print the image id used for the volume loop once, not the archive contents |

### Rules

1. **No floating `alpine` in `create_backup`.** The volume loop names the Postgres digest, or reads that digest from the `postgres` service in Compose.
2. **Do not float the tag.** If the digest is copied into the script, it matches `docker-compose.yml` in the same PR. A later Postgres bump updates both.
3. **Do not start Postgres in the helper.** `--entrypoint tar` and `--rm` only. No port publish, no `--network host`, no environment from `.env`.
4. **Leave Stage 60 and Stage 62 files alone.** `scripts/sync-openwebui-minio.sh`, `scripts/seed-chat-context.sh`, and `recover_openwebui_container` stay on those pages.
5. **Leave the MinIO listing alone.** Stage 46 still owns `minio/mc` in this function.
6. **Confirm `tar` is on PATH** in the implementation PR before merging. If that digest ever drops `tar`, use another digest already pinned in this Compose file. Do not add an image that exists only for backups.

### Suggested contributor checklist

```text
1. Confirm create_backup contains no alpine image name
2. Confirm the volume loop uses the postgres digest from docker-compose.yml with --entrypoint tar
3. Confirm a volume tarball still extracts to the volume root
4. Confirm scripts/sync-openwebui-minio.sh and scripts/seed-chat-context.sh are not edited
5. Confirm the MinIO mc lines in create_backup are not edited
6. Confirm the helper container is removed when tar exits
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| `tar` | Pinned Postgres image | `alpine` / `alpine:latest` |
| Digest | `docker-compose.yml` | A second pin table |
| Volume bytes | Existing `docker run -v` mount | A volume backup plugin |
| Intake | GitHub Issue | A parallel backup script |
