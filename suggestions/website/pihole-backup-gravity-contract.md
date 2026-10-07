---
title: Pi-hole Backup Gravity Contract
description: Constructional contract so create_backup copies Pi-hole state instead of downloading blocklists into the live resolver.
last_updated: 2026-10-07
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Pi-hole Backup Gravity Contract

## Problem

`create_backup` in `tu-vm.sh` treats two Pi-hole CLI commands as a backup:

```text
docker exec ai_pihole pihole -a -t > "$backup_path/pihole-config.txt"
docker exec ai_pihole pihole -g > "$backup_path/pihole-gravity.txt"
```

Both stdout streams are stored as text files. Failures are warnings. The backup archive is still built.

Pi-hole's command documentation uses `pihole -g` as the example for Gravity. That script reads the adlist table, downloads each list, merges the domains into `/etc/pihole/gravity.db`, and reloads DNS. Running it from `create_backup` changes the live resolver and writes the progress log to `pihole-gravity.txt`. The file is not a copy of `gravity.db`.

`pihole -a -t` is the v5 admin teleporter flag. Current Pi-hole release notes document the export as `pihole-FTL --teleporter`. The command reference no longer lists `pihole -a`. On the pinned v6 image, the flag is the wrong invocation, and a text redirect would still not be the teleporter archive even if the flag worked.

Stage 30 (open PR #56) already says this image is a v6 digest and maps `FTLCONF_*` environment keys. It does not mention these two `docker exec` lines. Stage 46 (open PR #72) is the volume-name fix so `pihole_data` is one of the tarballs. That tarball is the copy of `/etc/pihole`, including `gravity.db`. This page only stops the backup from downloading lists while that copy is taken.

Checked on 2026-10-07 against `create_backup` and the Pi-hole command docs. The container was not started here.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup` | The function that runs `pihole -g` |
| `pihole_data` volume mounted at `/etc/pihole` | Where `gravity.db` and lists already live |
| Stage 46 volume prefix (expected sibling, open PR #72) | How that volume gets into the archive under the real project name |
| Stage 30 `pihole-v6-ftlconf-env-contract.md` (expected sibling, open PR #56) | v6 environment keys. Leave them on that page |
| `pihole-FTL --teleporter` | The export Pi-hole documents for a portable config archive |
| `pihole/01-custom.conf` in the repo | dnsmasq snippet `create_backup` already copies with the `pihole/` directory |

Out of scope:

- Replacing Pi-hole
- Remapping `WEBPASSWORD` and the other v5 keys (Stage 30)
- Choosing the volume name prefix (Stage 46)
- Scheduling a weekly gravity update. Gravity may still run on Pi-hole's own timer. It must not run because a backup started

## Proposal

`create_backup` stops invoking the Pi-hole CLI for backup content.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Gravity | `create_backup` | Delete the `pihole -g` exec. Do not replace it with `pihole updateGravity` |
| Teleporter flag | `create_backup` | Delete `pihole -a -t`. Do not keep writing `pihole-config.txt` from that stdout |
| Data copy | Volume loop | Keep relying on the `pihole_data` tarball Stage 46 names correctly |
| Optional export | Only if operators still want a single config file | `docker exec ai_pihole pihole-FTL --teleporter`, and store the archive file that command writes, not its log |

### Rules

1. **Backup does not download lists.** `gravity.db` on disk after a backup matches `gravity.db` from before the backup, aside from Pi-hole's own scheduler.
2. **The volume is the backup.** A `.txt` log of Gravity is not a second copy.
3. **Teleporter is the FTL flag** if a portable export is added. It is not `pihole -a`.
4. **Repo dnsmasq stays a file copy.** `pihole/01-custom.conf` is already in the `pihole/` directory `create_backup` copies. Do not regenerate it from the CLI.

### Suggested contributor checklist

```text
1. create_backup no longer contains pihole -g or pihole -a
2. A backup run does not change the mtime of gravity.db inside the Pi-hole container except for Pi-hole's own scheduler
3. The archive still gains the pihole_data tarball once the Stage 46 name match is in place
4. pihole/01-custom.conf is still present under the copied pihole directory
5. If teleporter is wired, the stored object is the archive pihole-FTL writes, and pihole-gravity.txt is gone
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Full Pi-hole state | The existing volume tarball | A new backup container |
| Portable settings | `pihole-FTL --teleporter` | `pihole -a -t` |
| List refresh | Pi-hole's own gravity schedule | A refresh hidden inside `create_backup` |
