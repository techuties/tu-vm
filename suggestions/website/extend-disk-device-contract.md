---
title: Disk Extend Device Discovery Contract
description: Constructional contract so scripts/extend-disk.sh grows the logical volume that holds slash, and exits when the root disk is not that Ubuntu LVM layout.
last_updated: 2026-10-28
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Disk Extend Device Discovery Contract

## Problem

`scripts/extend-disk.sh` grows one fixed set of device names:

```text
pvresize /dev/sda3
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv
```

Those names match an Ubuntu desktop installer that put the root filesystem on LVM, with the third partition of `/dev/sda` as the physical volume. They are not discovered from the machine. `set -e` is on, so a missing path aborts the script. A machine that does have `/dev/sda3` and `/dev/ubuntu-vg/ubuntu-lv`, but whose root filesystem is somewhere else, would grow that other volume and then run `resize2fs` on it.

Checked on 2026-10-28 on this host:

| Check | Result |
|---|---|
| `findmnt -n -o SOURCE /` | `/dev/vdc` |
| `/dev/sda3` | absent |
| `/dev/ubuntu-vg/ubuntu-lv` | absent |
| `lsblk` types | three virtio disks, no LVM volumes |

The root filesystem here is a whole virtio disk. `pvresize /dev/sda3` cannot succeed. `resize2fs` would also be the wrong tool for an XFS root even when the LV names were right, because the script never reads the filesystem type.

Stage 10 (open PR #36) already tells operators to run this script as step 2 of the disk-pressure ladder, and it leaves non-LVM detection out of that page. This page is that detection. It does not add a partition editor, an auto-prune job, or a second backup format.

The script was not executed. It needs root and it would call `pvresize`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/extend-disk.sh` | The three hardcoded commands to replace with a lookup |
| `findmnt` | Reports the source mounted at `/` |
| `lsblk`, `pvs`, `vgs`, `lvs` | Already printed by the script before it resizes |
| `resize2fs` | Correct grow tool when the filesystem is ext |
| Stage 10 disk-pressure ladder (open PR #36) | When an operator should grow the disk. Unchanged here |
| Stage 11 privileged host ops (open PR #37) | Who may run sudo. Unchanged here |
| `./tu-vm.sh doctor` | Already prints `df` for `/`. It does not resize |

Out of scope:

- Creating partitions, expanding a partition table, or installing `cloud-guest-utils`
- `docker system prune`, volume deletes, or a new backup tool
- Running `pvresize` against a device that does not back `/`
- Supporting every hypervisor's disk name by listing them in the script

## Proposal

Resolve the root mount, grow that logical volume when it is LVM, and exit with a clear message when it is not.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Root source | `scripts/extend-disk.sh` | `findmnt -n -o SOURCE,FSTYPE /` before any resize |
| LVM path | Same script | If the source is a device-mapper LV, `lvextend -l +100%FREE` that LV and `pvresize` only a PV that `pvs` shows for its VG |
| Filesystem | Same script | `resize2fs` for ext2/ext3/ext4. `xfs_growfs /` for xfs. Anything else prints the type and exits without resizing |
| Plain disk | Same script | If `/` is `/dev/vdc` or any non-mapper device, print that source and exit 0. Do not call `pvresize` |
| Ladder | Stage 10 page, when hubs merge | One sentence pointing here for device discovery. Do not copy that page onto this branch |

### Rules

1. **Root is the target.** The LV or filesystem that is grown is the one mounted at `/`.
2. **Missing `/dev/sda3` is a normal result.** The script must not require that path, `/dev/ubuntu-vg`, or the name `ubuntu-lv`.
3. **No resize on a guess.** If the root source is not an LV, the script exits before `pvresize`, `lvextend`, and `resize2fs`.
4. **Match the filesystem.** `resize2fs` runs only for ext filesystems. XFS uses `xfs_growfs` on the mount point.
5. **Stay a script.** Do not add a Nginx control, a Compose service, or a partition editor.
6. **Keep the sudo check.** The script already refuses to run without root. Keep that gate in front of the lookup.

### Suggested contributor checklist

```text
1. On a host whose root is /dev/vdc, the script prints that source and exits 0
2. The script does not invoke pvresize, lvextend, or resize2fs on that host
3. On an LVM root, lvextend receives the mapper device findmnt reported
4. An ext4 root uses resize2fs and an xfs root uses xfs_growfs
5. /dev/sda3 appears in the script only as an example in a comment, not as the command target
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Find `/` | `findmnt` | Hardcoded `/dev/sda3` |
| Grow an LV | `lvextend` and `pvresize` on the VG `pvs` reports | A fixed `ubuntu-vg` name |
| Grow the filesystem | `resize2fs` or `xfs_growfs` from `findmnt` FSTYPE | `resize2fs` for every root |
| When to grow | Stage 10 ladder | A new storage service |
