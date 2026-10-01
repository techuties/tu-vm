---
title: Backup Restore Apply Contract
description: Constructional contract so restore applies the archive create_backup already writes, replaces config trees, and starts Tier 1 with the existing service list.
last_updated: 2026-10-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Backup Restore Apply Contract

## Problem

`create_backup` in `tu-vm.sh` writes an archive that `restore_backup` does not apply.

The create path copies `.env`, `nginx/`, `ssl/`, `helper/`, `pihole/`, and `tika-minio-processor/`. It writes `database.sql` when `pg_isready` succeeds. It writes one `<volume>.tar.gz` per volume it inspects. It then packs that directory.

`restore_backup` extracts the outer tar, then:

```bash
cp "$extract_dir"/*/.env .
cp -r "$extract_dir"/*/nginx .
cp -r "$extract_dir"/*/ssl .
$compose_cmd up -d
sleep 10
docker compose exec -T postgres psql -U ai_admin -d ai_platform < "$extract_dir"/*/database.sql
```

Checked on 2026-10-01:

| Archive member `create_backup` writes | What `restore_backup` does with it |
|---|---|
| `.env` | Copies the file into the working directory |
| `nginx/`, `ssl/` | `cp -r` onto the live directories |
| `helper/`, `pihole/`, `tika-minio-processor/` | Not referenced. The words do not appear in `restore_backup` |
| `database.sql` | `psql` after `sleep 10`, as user `ai_admin` into database `ai_platform` |
| `<volume>.tar.gz` | Not unpacked. The function extracts only the outer archive |

GNU cp 9.4, which is the `cp` on this host, merges a source directory into an existing destination. A file that exists in both trees is overwritten. A file that exists only in the live tree is left in place. A restored `nginx/` therefore keeps local files the archive does not contain. Replacing the tree means remove-or-swap, not merge.

`tu-vm.sh` sets `set -euo pipefail`. `restore_backup` prompts with `read -p`. On EOF, `read` returns 1 and the script exits before the y/N test. A non-interactive run never reaches `error "Restore cancelled"`. Replayed on 2026-10-01: `read` under `set -e` with stdin closed exited 1.

`restore_backup` then runs `up -d` with no service list. This compose file has no `profiles:` key. A bare `up -d` starts every service. `start_services` already avoids that in portable mode: `up -d` on `TIER1_SERVICES`, then `up -d --no-start` on `TIER2_SERVICES`. Restore does not use those arrays. Calling the whole `start_services` function from restore would also run MinIO bucket setup and cron installation. Those side effects stay out of the restore change. Stage 46 owns the cron secret.

Postgres is backed up twice: a logical dump and a volume tarball. Applying both onto one data directory is how a restore corrupts a cluster. The dump is the one `pg_isready` already gates. The volume tarball for that same data directory should be skipped when `database.sql` is present.

`create_backup` still hardcodes `ai_admin` and `ai_platform` while it reads `POSTGRES_PASSWORD` from `.env`. Restore repeats the user and database literals and does not wait on `pg_isready`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup` / `restore_backup` | The only local archive path |
| `TIER1_SERVICES` and `TIER2_SERVICES` | Service lists portable start already passes to Compose |
| `pg_isready` in `create_backup` | Readiness check restore should use before `psql` |
| `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_PASSWORD` | Values both sides should read after `.env` is restored |
| `wait_for_services` | Existing wait helper, if the Tier 1 start is reused in part |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling, open PR #44) | Archive format and keep-latest rotation. Do not change keep-latest here |
| Stage 19 `compose-native-profiles-contract.md` (expected sibling, open PR #45) | Compose profiles. This page uses the existing arrays instead |
| Stage 46 `backup-volume-prefix-contract.md` (expected sibling, open PR #72) | Which volume names are written. Restore should unpack the members that are actually in the archive |
| Stage 6 backup drill and Stage 9 rclone (expected siblings) | Proof and offsite copy of this same tar |

Out of scope:

- A second backup tool, restic, borg, or encryption (Stage 24)
- Changing keep-latest rotation (Stage 18)
- Changing which volume names `create_backup` discovers (Stage 46)
- Adding Compose `profiles:` in this change (Stage 19)
- Installing cron or rewriting the MinIO client (Stage 46)

## Proposal

`restore_backup` becomes the inverse of the archive that is already on disk.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Confirm | `restore_backup` | Keep the prompt on a terminal. If stdin is not a terminal, call the existing `error` helper unless the operator passed an explicit confirm flag that defaults off |
| Config trees | After extract | Replace `nginx`, `ssl`, `helper`, `pihole`, and `tika-minio-processor` with the archive copies. Do not `cp -r` onto the live tree |
| Volumes | Before containers start | For each `*.tar.gz` whose stem `docker volume inspect` accepts, extract into that volume while the containers that mount it are stopped |
| Postgres | After Tier 1 postgres is ready | Apply `database.sql` only. Skip the postgres data-directory tarball when the dump is present. Wait on `pg_isready`, not `sleep 10` |
| Identity | Dump and restore | Read user, database, and password from the restored `.env`, with the same fallbacks Compose uses |
| Start | After volumes are loaded | `up -d` on `TIER1_SERVICES`, then `up -d --no-start` on `TIER2_SERVICES`. Do not call `start_services` |

### Rules

1. **One archive format.** Extend `restore_backup`. Do not add `scripts/restore2.sh`.
2. **Replace config trees.** A file that is absent from the archive is removed from that tree. A merge that keeps live-only files is not a restore.
3. **Unpack volume members that exist.** The stem of the tarball is the volume name. Do not keep a second hardcoded `docker_` list in restore. Stage 46 changes which stems `create_backup` writes; restore follows the archive.
4. **One Postgres restore path.** Prefer `database.sql`. Do not load the postgres volume tarball in the same run as the dump.
5. **Tier 1 only.** Use the arrays at the top of `tu-vm.sh`. A bare `up -d` starts Tier 2 because this file has no profiles.
6. **Do not start cron, bucket setup, or rclone from restore.** Those run inside `start_services` and are out of scope.
7. **Non-interactive restore must fail closed.** EOF is an error string from `error`, not a `set -e` abort with no message. An explicit confirm flag may skip the prompt. The default remains to ask on a terminal.
8. **Archives contain secrets.** Do not print `.env` or the SQL dump. That rule is already Stage 18.

### Suggested contributor checklist

```text
1. Replace nginx, ssl, helper, pihole, and tika-minio-processor from the archive instead of merging
2. Unpack non-postgres volume tarballs into the inspected volume before containers start
3. Apply database.sql after pg_isready, using POSTGRES_USER and POSTGRES_DB from the restored .env
4. Skip the postgres data volume tarball when database.sql is present
5. Start TIER1_SERVICES and create TIER2_SERVICES with --no-start
6. EOF on the prompt exits through the error helper; a confirm flag is required to skip the prompt
7. Do not change backup rotation or the Stage 46 volume discovery list in this PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Archive | `create_backup` members | A new layout |
| Service list | `TIER1_SERVICES` and `TIER2_SERVICES` | Bare `compose up -d` |
| Postgres ready | `pg_isready` already in `create_backup` | `sleep 10` |
| Volume bytes | `docker run` plus `tar`, the same shape as create | restic or borg |
| Confirm | Existing `error` helper | A `set -e` exit with no message |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in `restore_backup` only, plus a shared user/database lookup if `create_backup` must stop hardcoding `ai_admin` for the dump to match.
3. Prove it on a disposable directory: a live-only file under `nginx/` is gone after restore, a non-postgres volume tarball is loaded, and Tier 2 containers are created stopped.

## Acceptance criteria

- `helper/`, `pihole/`, and `tika-minio-processor/` from the archive are the trees on disk after restore.
- A file that exists only in the live `nginx/` tree is not still there after restore.
- Volume tarballs other than the postgres data directory are extracted into the matching volume.
- `database.sql` is applied after `pg_isready`, and the postgres data tarball is not applied in that run.
- Tier 2 services are not started.
- A non-interactive invoke without an explicit confirm flag exits with an error message.
