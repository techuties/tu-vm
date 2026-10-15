---
title: Docker Daemon DNS Merge Contract
description: Constructional contract so configure_docker_dns merges a dns key into daemon.json and restores the file when the update's DNS check fails.
last_updated: 2026-10-15
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Docker Daemon DNS Merge Contract

## Problem

`configure_docker_dns set` replaces `/etc/docker/daemon.json` with a document that has only a `dns` list, then restarts Docker. The matching `restore` action runs later. A failed DNS check never reaches it.

`handle_pihole_dns_replacement stop` calls `configure_docker_dns set` before `update_system` reaches `docker compose down`. Containers are still running when Docker restarts.

The writer is:

```bash
cat > "$docker_daemon_conf" << EOF
{
    "dns": ["1.1.1.1", "1.0.0.1", "9.9.9.9", "8.8.8.8"]
}
EOF
```

On 2026-10-15 `/etc/docker/daemon.json` on this machine was:

```json
{
  "storage-driver": "fuse-overlayfs"
}
```

Applying that `cat` removes `storage-driver`. The same replacement drops any other key that was present (`iptables`, `log-driver`, `log-opts`, `live-restore`). The function was not executed, and Docker was not restarted.

`set` copies the current file to `/etc/docker/daemon.json.tu-backup` only when that backup is absent. `restore` moves the backup back, or, when no backup exists, writes `{}` if the live file contains `"dns"`.

When `verify_dns_connectivity` fails, `stop` calls `error`, and `error` is `exit 1`. Nothing calls `configure_docker_dns restore` on that path. The DNS-only file and the Docker restart remain.

The sibling page in this stage owns when host `resolv.conf` may point at Pi-hole. This page owns `daemon.json` only.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `configure_docker_dns` | The only writer of `/etc/docker/daemon.json` in `tu-vm.sh` |
| `/etc/docker/daemon.json.tu-backup` | The one-shot copy `set` already makes |
| `python3` | Already used in `update_system` to edit JSON-shaped text |
| `handle_pihole_dns_replacement stop` | Calls `set` and can `exit 1` afterward |
| Stage 55 `pihole-dns-restore-order-contract.md` | When `resolv.conf` switches to `127.0.0.1` |
| AGENTS.md note for this cloud environment | Docker here expects the `fuse-overlayfs` storage driver |

Out of scope:

- A new Docker config service or a drop-in directory layout
- Changing which public resolvers are used during image pulls
- `resolv.conf` and `chattr` (the sibling page)
- Restarting Docker while applying an unrelated setting

## Proposal

Merge `dns` into the existing JSON object. Restart Docker only after project containers are stopped. Restore the backup before any exit that follows a failed check.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Merge | `configure_docker_dns set` | Load the current JSON object, or `{}` when the file is missing. Set the `dns` key. Write the object back with a temp file and `mv` |
| Backup | `set` | Keep one backup of the pre-merge file. Refresh it when the live file is not already the DNS override from a crashed run |
| Restart timing | `update_system` | Call `set` after `docker compose down`, before image pulls. Do not restart Docker while `ai_postgres` and the other project containers are running |
| Failure | `handle_pihole_dns_replacement stop` | On a failed `verify_dns_connectivity`, call `restore` and then return non-zero. Do not `exit 1` while the DNS-only file is still installed |
| Restore | `configure_docker_dns restore` | Move the backup back when it exists. When it does not, delete only the `dns` key this function added and leave every other key |

### Rules

1. **Existing keys survive `set`.** A file whose only key is `storage-driver` still has that key after `set`, and also has `dns`.
2. **A failed check puts the backup back.** `storage-driver` is `fuse-overlayfs` again before the function returns, and the process does not leave Docker on the DNS-only file.
3. **Docker restarts after compose down.** Image pulls still see the merged `dns` list. Project containers are not killed by that restart.
4. **The backup is not logged.** Paths may be logged. The file contents stay on disk.

### Suggested contributor checklist

```text
1. Start from a copy of {"storage-driver":"fuse-overlayfs"} and run the merge. The result has both storage-driver and dns
2. A second key such as log-opts is still present after the merge
3. A failed verify path writes the backup back and does not leave the DNS-only document in place
4. update_system calls set only after compose down
5. restore on a file that had no backup removes the dns key and keeps storage-driver
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Edit daemon.json | `python3` json load and dump, already used by the updater | `cat` over the whole file |
| Undo | The `.tu-backup` file this function already copies | A second backup directory |
| When to restart | After `docker compose down`, which `update_system` already runs | Restarting Docker while Postgres is up |
