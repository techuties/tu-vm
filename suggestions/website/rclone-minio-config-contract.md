---
title: rclone MinIO Config Contract
description: Constructional contract so the host MinIO mount rewrites its rclone secret when MINIO_ROOT_PASSWORD changes.
last_updated: 2026-10-10
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# rclone MinIO Config Contract

## Problem

`mount_minio_storage` writes `/etc/rclone/rclone.conf` once. The next MinIO password does not reach the host mounts.

The writer is guarded like this:

```bash
if ! sudo grep -q "^\[minio\]" "$rclone_conf" 2>/dev/null; then
    sudo tee "$rclone_conf" >/dev/null <<EOF
[minio]
type = s3
provider = Minio
env_auth = false
access_key_id = admin
secret_access_key = ${minio_pass}
endpoint = http://127.0.0.1:9000
region = us-east-1
EOF
    sudo chmod 600 "$rclone_conf"
fi
```

`minio_pass` comes from `resolve_minio_password`, which reads `.env`. The `grep` succeeds as soon as `[minio]` exists, and the function keeps the old `secret_access_key`. `./tu-vm.sh start` as root can run this on every boot and still leave the first password in place.

That sticks in two ordinary cases:

- The first start wrote a password, and the operator later replaced `MINIO_ROOT_PASSWORD` in `.env`.
- The first start wrote the published default because `.env` was not ready, and `generate_secrets` later stored a different MinIO password.

`rclone mount` then runs with the stale file. The mount fails or serves the old credentials. The script logs `Mounting minio:tika-pipe` and, on failure, `Failed to mount tika-pipe`. It does not say the config secret is older than `.env`.

The file mode is already `600`. The gap is freshness, not permissions.

Stage 35 (open PR #35, `offsite-backup-rclone-contract.md`) is the offsite backup profile. Stage 46 (open PR #72) is the `mc` client used for buckets and cron. This page is the host mount config under `/etc/rclone/rclone.conf`.

Checked on 2026-10-10 by reading `mount_minio_storage`. The function was not executed here, and no rclone file was written.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mount_minio_storage` | Installs rclone and writes the MinIO remote |
| `resolve_minio_password` | The current password the config should store |
| `/etc/rclone/rclone.conf` | The file the guard refuses to update |
| `rclone mount` later in the same function | The consumer of that file |
| Stage 35 `offsite-backup-rclone-contract.md` (expected sibling, open PR #35) | Offsite backup, not this host mount |
| Stage 46 `minio-mc-client-transport-contract.md` (expected sibling, open PR #72) | `mc` transport for buckets and the sync cron |

Out of scope:

- A second mount tool
- Offsite backup credentials (Stage 35)
- The sync cron password (Stage 46)
- Logging `secret_access_key`

## Proposal

Rewrite the MinIO secret when it differs from `resolve_minio_password`. Keep the remote name, endpoint, and mount points.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compare | `mount_minio_storage` | Read `secret_access_key` under `[minio]` without printing it |
| Update | the same function | When the stored secret differs from `minio_pass`, rewrite that key and `chmod 600` |
| Create | the same function | Keep the current full write when `[minio]` is absent |
| Mount | `mount_minio_bucket` | If the secret changed and the mount point is already mounted, unmount and mount again so the daemon reloads the file |

### Rules

1. **The config follows `.env`.** After `MINIO_ROOT_PASSWORD` changes, the next root `mount_minio_storage` stores the new secret.
2. **The first write still happens.** A missing `[minio]` section creates the remote, as it does today.
3. **The secret stays out of logs.** The update path does not echo `minio_pass` or the file body.
4. **Other remotes stay.** A rewrite of `[minio]` does not drop a different section an operator added below it.

### Suggested contributor checklist

```text
1. A missing rclone.conf gains a [minio] section and mode 600
2. Changing MINIO_ROOT_PASSWORD and running the function again changes secret_access_key to the new value
3. A second run with the same password does not rewrite the file
4. The function's stdout does not contain the password
5. An existing second remote in the same file is still present after the update
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Mount | rclone, already installed by this function | A new FUSE helper |
| Password | `resolve_minio_password` | A second copy of the `.env` parser |
| File update | Rewrite `secret_access_key` in the existing config | Deleting `/etc/rclone` on every start |
