---
title: Helper Host Tmp Isolation Contract
description: Constructional contract for moving host cron JSON (update and log status) off /tmp so helper_index can drop the host /tmp bind, distinct from the Stage 26 Tika STATUS_FILE relocation.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Helper Host Tmp Isolation Contract

## Problem

`helper_index` bind-mounts the **host** `/tmp`:

```yaml
- /tmp:/tmp  # Share status file with tika-minio-processor
```

Two different JSON families live there:

| File | Writer | Reader | Stage that owns it |
|---|---|---|---|
| `/tmp/tika-processing-status.json` | processor | helper | Stage 26 (relocate, then processor tmpfs) |
| `/tmp/tu-vm-update-status.json` | `daily-checkup.sh` / `tu-vm.sh` **on the host** | helper `/updates` | **this page** |
| `/tmp/tu-vm-log-status.json` | `daily-checkup.sh` on the host | helper `/announcements` | **this page** |

Host `/tmp` is world-writable, tmpfs-cleared on reboot, and shared with every other container or user that uses `/tmp`. The helper does not need that blast radius to show "updates available" on the dashboard. Stage 26 relocates the **Tika** status file; it does not move the **host cron** files. Overlaying `/tmp` as tmpfs on the helper **before** those paths move would hide updates and log warnings from the dashboard.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/daily-checkup.sh` | Writes update + log JSON under `/tmp` |
| `tu-vm.sh` `UPDATE_STATUS_FILE` | Same update JSON path |
| `helper/uploader.py` `/updates`, `/announcements` | Reads those two files |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling) | How the cron job evolves |
| Stage 26 `processor-tmpfs-status-share-contract.md` (expected sibling) | Tika `STATUS_FILE` only |

Out of scope:

- A Redis/NATS status bus, helper-owned write API for cron, or MinIO put of these files
- Changing announcement JSON shape
- Processor OCR scratch (Stage 26)
- Weekly-update lock file (`/tmp/tu-vm-weekly-update.lock`) unless a follow-up Issue wants it

## Proposal

Give the host cron files a dedicated directory that both the host scripts and the helper already understand, then drop `/tmp:/tmp` from the helper.

### Contribution lanes

| Lane | Where | Suggested path |
|---|---|---|
| Host scripts | `daily-checkup.sh`, `tu-vm.sh` | `state/tu-vm-update-status.json` and `state/tu-vm-log-status.json` (repo-local) **or** `/var/lib/tu-vm/` |
| Helper | `uploader.py` constants | Same two paths via env (`TU_VM_STATUS_DIR`) with that default |
| Compose | `helper_index.volumes` | Bind `./state:/var/lib/tu-vm:ro` (helper reads only) |
| Cron | existing daily checkup | Create the directory; keep writing JSON, not a new format |
| Tika file | Stage 26 | Separate bind or env; do not reuse host `/tmp` |

Prefer a **repo-local `state/`** directory (gitignored) so cloud agents and laptops do not need `/var/lib`. Document `/var/lib/tu-vm` as the packaged-host alternative, not a second product.

### Rules

1. **Move cron JSON first, then drop the bind.** Never remove `/tmp:/tmp` while helper still reads `/tmp/tu-vm-*.json`.
2. **Do not reuse the Tika filename.** Stage 26 owns `tika-processing-status.json`.
3. **Do not invent a bus.** Files plus a bind remain the community contract.
4. **Helper should be read-only on that bind.** Host cron writes; helper reads. Helper may still write a placeholder only if the env dir is writable — prefer host cron creating the files.
5. **Keep the JSON keys.** `updates_available`, `last_check`, `os_updates`, `docker_updates`, `critical_errors` stay stable.
6. **GitHub remains intake.** "Push status to AFFiNE / MinIO" stays an Issue.

### Suggested contributor checklist

```text
1. Add a gitignored state/ directory (or TU_VM_STATUS_DIR)
2. Point daily-checkup.sh and tu-vm.sh UPDATE_STATUS_FILE at that dir
3. Point helper /updates and /announcements at the same dir via env
4. Bind-mount the dir read-only into helper_index
5. Remove /tmp:/tmp from helper only after both cron files and Stage 26 Tika file are off /tmp
6. Confirm dashboard updates/announcements still render on a test stack
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Cron → dashboard | Shared JSON files on a dedicated bind | Host `/tmp` or a message bus |
| Tika progress | Stage 26 `STATUS_FILE` | Mixing Tika JSON into cron JSON |
| Helper scratch | After both families move, no host `/tmp` | Overlay tmpfs first |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: env + paths + bind, then delete `/tmp:/tmp` from helper.
3. Coordinate with Stage 26 so the helper loses host `/tmp` once, not twice.

## Acceptance criteria

- [ ] Update and log status files are not under host `/tmp`.
- [ ] Helper reads them from a dedicated bind or `TU_VM_STATUS_DIR`.
- [ ] JSON keys used by `/updates` and `/announcements` are unchanged.
- [ ] Helper `/tmp:/tmp` is gone only after Tika status is also off `/tmp`.
- [ ] `state/` is gitignored if the repo-local option is chosen.
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Restore the `/tmp` paths and the `/tmp:/tmp` bind. Dashboard routes stay the same.

## Success metrics

- Host `/tmp` cleanup no longer wipes "updates available".
- Helper no longer mounts the host temporary directory.
- Contributors extend checkup JSON in `state/` instead of proposing a status service.
