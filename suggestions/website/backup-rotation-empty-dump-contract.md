---
title: Backup Rotation Empty Dump Contract
description: Constructional contract so keep-latest rotation does not replace the last backup with a zero-byte database dump.
last_updated: 2026-10-29
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Backup Rotation Empty Dump Contract

## Problem

`create_backup` keeps one archive. After it writes `${backup_path}.tar.gz` it deletes every older `backups/*.tar.gz`. Stage 18 (open PR #44) documents that single slot as intentional. This page does not ask to keep a history.

The database dump is allowed to fail without stopping the function:

```text
docker compose exec -T -e PGPASSWORD="$pg_password" postgres pg_dump -U ai_admin ai_platform > "$backup_path/database.sql" 2>/dev/null || warn "Database backup failed"
```

The shell opens `database.sql` for writing before `pg_dump` runs. A non-zero status is swallowed by `|| warn`, so `set -euo pipefail` at the top of `tu-vm.sh` does not abort. The file is left in place at zero bytes when the producer writes nothing. The outer `tar czf` then succeeds, the directory is removed, and rotation treats that archive as the one to keep.

Replayed on 2026-10-29 under `set -euo pipefail` with the same shape (`false > database.sql || warn`, then the keep-latest `ls -1t | tail -n +2` delete):

| Step | Result |
|---|---|
| Failed producer | Printed the warning and continued |
| `database.sql` | 0 bytes |
| Older archive before rotation | 177 bytes, contained a non-empty `database.sql` |
| After rotation | Only `backup_new.tar.gz` (158 bytes) remained |
| Members of the sole archive | `backup_new/database.sql` at 0 bytes |

The same window deletes a previous good archive when the volume loop warns and skips a tarball. Each volume uses `|| warn`, and the outer tar does not check that `${volume}.tar.gz` exists. A config-only archive is newer, so it becomes the only file under `backups/`.

`./tu-vm.sh update` calls `create_backup` before it pulls images. A failed dump during that call removes the last restorable archive and then continues into the upgrade.

Checked on 2026-10-29 by reading `create_backup` and replaying the redirect-plus-rotation sequence in a temporary directory. `tu-vm.sh` was not executed. No Docker volume was read.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup` | Writes `database.sql`, the outer tar, and the rotation |
| `set -euo pipefail` | Already aborts when `tar czf` itself returns non-zero, because that line has no `||` |
| Stage 18 keep-latest (open PR #44) | One archive remains the policy |
| Stage 46 volume prefix (open PR #72) | Which volume names are candidates. Unchanged here |
| Stage 47 restore (open PR #73) | How a good archive is applied. Unchanged here |
| Sibling image-pin page | Which image runs `tar`. Unchanged here |
| Sibling archive-mode page | Who can read the tarball. Unchanged here |

Out of scope:

- Keeping every historical tar, or adding a retention count above one
- A second backup scheduler
- Restoring volumes (Stage 47)
- The `local backup_count=$(ls … | wc -l)` form. An assignment on `local` is what lets `cleanup` continue when no tar exists. Leave that form as it is
- Pi-hole CLI backup lines (Stage 53, open PR #79)

## Proposal

Rotation runs only after the new archive contains a usable database dump and the volume tarballs for volumes that were present.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Dump | `pg_dump` redirection | On failure, remove `database.sql` if its size is 0. Do not archive a zero-byte dump |
| Volumes | Volume loop | If `docker volume inspect` succeeded and the tarball is missing or empty, record a failure |
| Outer tar | `tar czf` | Write to a temporary name in `backups/`. On non-zero status the previous archives are still in place because `set -e` already stops the function |
| Rotation | Keep-latest block | Delete older archives only when the new archive lists a non-empty `database.sql` and a non-empty tarball for each volume that inspect found |
| First backup | Same block | When `backups/` has no older tar, still publish a good archive. When the new archive is not good, leave the directory without deleting anything and return a warning |
| Update | `update_system` | No new flag. It already calls `create_backup`. A failed dump there must not remove `pre_update_*.tar.gz` from an earlier successful run |

### Rules

1. **Keep one archive.** After a good backup, older `backups/*.tar.gz` files are still removed.
2. **A zero-byte `database.sql` is not a dump.** It is not a member of the archive that rotation is allowed to promote.
3. **A skipped volume tarball is not success.** The warning can stay. Rotation waits.
4. **Do not delete the previous archive on the way to a failed one.** Check the new archive first, then delete.
5. **Leave Stage 18's product decision in place.** Operators still do not get a stack of daily tars from this change.
6. **Leave restore behavior in Stage 47.** This page only decides which file is allowed to be the sole survivor.

### Suggested contributor checklist

```text
1. Force pg_dump to fail and confirm database.sql is absent or absent from the new archive
2. Confirm the previous backups/*.tar.gz is still present after that failure
3. Run a backup where pg_dump writes a non-empty database.sql and confirm older tars are removed
4. Confirm a missing volume tarball also preserves the previous archive
5. Confirm update_system still calls create_backup and does not grow a second retention policy
6. Confirm the local backup_count assignment in cleanup is unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| One slot | Existing keep-latest delete | A backup server or a numbered retention scheme |
| Failure signal | File size and `tar tzf` before `rm` | Treating `|| warn` as a successful dump |
| Database bytes | `pg_dump` already in `create_backup` | A second dump tool |
| Intake | GitHub Issue | A wrapper script around `tu-vm.sh` |
