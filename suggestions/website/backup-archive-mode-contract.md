---
title: Backup Archive Mode Contract
description: Constructional contract so create_backup writes owner-only archives, matching the mode generate_secrets already sets on .env.
last_updated: 2026-10-29
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Backup Archive Mode Contract

## Problem

`generate_secrets` ends with `chmod 600` on `.env` and tells the operator to keep that file private. `create_backup` then copies that file, the `ssl/` directory (certificate and private key), and the service config into an archive:

```text
cp "$ENV_FILE" "$backup_path/"
cp -r ssl "$backup_path/"
tar czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$(basename "$backup_path")"
```

Nothing in `create_backup` changes the mode of the tarball or of `backups/`. With the process umask at `0022`, `tar czf` creates the archive as mode `644` and `mkdir -p` creates `backups/` as mode `755`.

Replayed on 2026-10-29 with umask `0022`:

| Object | Mode | What a reader gets |
|---|---|---|
| `.env` member inside the tar | `600` (`-rw-------`) | The mode bit does not hide the member |
| Archive file | `644` (`-rw-r--r--`) | `tar xzf` printed the `.env` body (`secret-marker` in the fixture) |

Any local account that can read the archive can extract `.env` and `ssl/nginx.key`. `validate_security` flags `.env` when its mode is not `600`, then a later `./tu-vm.sh backup` or `./tu-vm.sh update` publishes those bytes in a world-readable file. `update_system` calls `create_backup` as root (`check_root "update"`), so the resulting tar is often root-owned and still mode `644`.

Checked on 2026-10-29 by reading `create_backup` and `generate_secrets`, and by creating a temporary archive under umask `0022`. The repository `backups/` directory was not used. No real `.env` was read.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `chmod 600 "$ENV_FILE"` in `generate_secrets` | The mode to copy |
| `create_backup` | The `tar czf` that needs the same mode |
| `validate_security` | Already treats non-`600` `.env` as a finding |
| `update_system` | Root caller that writes `pre_update_*.tar.gz` |
| Sibling empty-dump page | Whether rotation may delete the previous archive |
| Stage 54 secret writer (open PR #80) | Which values land in `.env`. Unchanged here |
| Stage 46 crontab secret (open PR #72) | The password that must not be written into cron. Unchanged here |

Out of scope:

- A new encryption tool, age recipient, or KMS
- Redacting `.env` out of the archive. Operators restore from that copy. The file has to be present and unreadable to other accounts
- Log redaction in `tu-vm.log`
- Changing who may run `backup`

## Proposal

Create `backups/` and the archive with owner-only permissions, using the `chmod` the script already uses for `.env`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Directory | `create_backup`, before the first write | `mkdir -p "$BACKUP_DIR"` and `chmod 700 "$BACKUP_DIR"` |
| Archive | Immediately after `tar czf` succeeds | `chmod 600` on `${backup_path}.tar.gz` |
| Umask | The `tar` invocation | `umask 077` around `mkdir` and `tar` so a crash between `tar` and `chmod` does not leave a `644` file |
| Existing files | Same function, one pass | `chmod 600` any `backups/*.tar.gz` already present before rotation, so an old world-readable archive is closed on the next successful backup |
| Check | `validate_security` | When `backups/*.tar.gz` exists and any mode is other than `600`, report it next to the `.env` mode finding |

### Rules

1. **The archive mode is `600`.** Group and other have no read bit.
2. **The directory mode is `700`.** Other accounts cannot list backup names.
3. **Use `chmod`, which is already a dependency of `generate_secrets`.** Do not add `gpg`, `age`, or `openssl enc` for this.
4. **Keep the secrets in the archive.** Restore still needs `.env` and `ssl/`. Privacy is the file mode, not a second copy with the secrets removed.
5. **Leave rotation policy on the sibling page.** This change applies `chmod` to whatever archive that page decides to keep.
6. **Do not print file bodies.** Success lines already print the archive path. They stay path-only.

### Suggested contributor checklist

```text
1. With umask 022, a new backups/*.tar.gz is mode 600 and backups/ is mode 700
2. A second local user cannot read the archive (open fails)
3. The owner can still extract .env and ssl/nginx.key
4. validate_security reports a 644 archive when one is planted
5. generate_secrets is otherwise unchanged
6. No encryption binary is added to the script
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Private file | `chmod 600`, already used for `.env` | A backup encryption product |
| Private directory | `chmod 700` on `backups/` | Moving archives to another host path |
| Detection | `validate_security` mode check | A new scanner |
| Intake | GitHub Issue | A second backup command |
