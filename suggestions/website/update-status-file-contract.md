---
title: Update Status File Contract
description: Constructional contract so the helper does not overwrite a timezone-aware checkup file, and so host scripts and the dashboard share one status directory.
last_updated: 2026-09-28
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Update Status File Contract

## Problem

The landing page shows update and processor state from JSON files. Three writers share host `/tmp`, and they do not agree about the update file.

`scripts/daily-checkup.sh` and `tu-vm.sh` `write_update_notification_entry` set `last_check` with `date -Iseconds`. On GNU date that string includes a numeric UTC offset, for example `2026-09-28T08:01:45+00:00`.

`helper/uploader.py` `check_updates()` does this when the file exists:

```text
last_check = datetime.fromisoformat(last_check_str)
if datetime.now() - last_check < 24 hours:
    return the file
on any exception:
    pass
then write a new file with updates_available false
```

Checked with the interpreter on 2026-09-28: `datetime.now()` (naive) minus an offset-aware timestamp raises `TypeError: can't subtract offset-naive and offset-aware datetimes`. The bare `except` treats that as a bad file. The handler then writes:

```text
updates_available: false
message: Awaiting daily update check (scheduled)
last_check: a naive local timestamp
```

The next dashboard poll is inside 24 hours of that naive timestamp, so it shows “no updates” until the next host write. A host write with an offset throws again on the following poll, and the helper overwrites the file again. The landing page cannot show a real checkup result for long.

There is a second split. If `/tmp/tu-vm-update-status.json` exists and is not writable by the user running the checkup, both host writers switch to `/tmp/tu-vm-update-status-${USER}.json`. The helper only reads the unsuffixed path. The helper container runs as root and mounts host `/tmp`, so the placeholder it creates is root-owned. A user cron then cannot update the file the dashboard reads.

Processor status is a different file, `/tmp/tika-processing-status.json`, written with a naive `datetime.now().isoformat()`. That compare works. It is still a world-writable host path: any local user can replace the JSON the dashboard trusts. Stage 43 owns rendering those strings as text. This page owns the directory and the write rules.

Stage 12 owns announcement categories and the `/announcements` JSON shape. Do not change those keys here.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` `check_updates()` | Reads and, today, rewrites `/tmp/tu-vm-update-status.json` |
| `helper/uploader.py` `status_pdf_processing()` | Reads `/tmp/tika-processing-status.json` and does not create it |
| `scripts/daily-checkup.sh` | Writes the update file and `/tmp/tu-vm-log-status.json` |
| `tu-vm.sh` `write_update_notification_entry` | Same update path and the same `${USER}` fallback |
| `tika-minio-processor/universal_processor.py` | Writes the processor status file with `os.replace` |
| `nginx/html/index.html` `refreshUpdates()` | Already uses `textContent` for the update title and message |
| Stage 12 dashboard announcements (expected sibling) | Announcement taxonomy |
| Stage 43 dashboard untrusted text (expected sibling, open PR #69) | `textContent` for log samples and filenames |

Out of scope:

- A new “what’s new” service or a call to the GitHub API from the LAN dashboard
- Changing announcement `type` / `priority` values
- HTML sanitizer libraries
- Rewriting the apt and registry logic inside the checkup (that compare is the image-update contract)

## Proposal

One directory, one update filename, and a helper that is read-only for that file.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Path | `TU_VM_STATUS_DIR` | Default `/var/lib/tu-vm/status` on a named volume or a `./run/status` directory created by `tu-vm.sh` with mode `0750`. Not host `/tmp`. |
| Helper update route | `check_updates()` | Parse `last_check` in UTC. On parse failure or a missing file, return the placeholder JSON and do not write. |
| Host writers | `daily-checkup.sh`, `tu-vm.sh` | Write only `TU_VM_STATUS_DIR/tu-vm-update-status.json`. If that path is not writable, log an error and exit non-zero. Delete the `${USER}` fallback. |
| Processor | `universal_processor.py` | Write `TU_VM_STATUS_DIR/tika-processing-status.json` with the same atomic replace it uses now. |
| Mounts | helper and `tika_minio_processor` | Mount the status directory. Remove `/tmp:/tmp` once those three filenames have moved. |
| Log status | `daily-checkup.sh` | Move `tu-vm-log-status.json` to the same directory so announcements and updates share the rule. |

### Rules

1. **The helper never creates or truncates the update file.** A missing checkup is an HTTP body, not a new source of truth.
2. **Compare instants in UTC.** Accept both naive ISO strings and offset strings. Do not subtract a naive `datetime.now()` from an aware value.
3. **One filename.** Host tools must not invent `tu-vm-update-status-${USER}.json`. The dashboard will not look for it.
4. **The directory is not world-writable.** Mode `0750` owned by the user that runs checkup and the container writer. Do not use host `/tmp` (`1777`).
5. **Keep the JSON keys** `updates_available`, `last_check`, `message`, `details`, `os_updates`, `docker_updates`, and `docker_outdated`. The landing page already reads them.
6. **Processor status stays a sibling file** in that directory. Do not merge it into the update document.
7. **Do not change announcement HTML.** Stage 43 covers insertion. Stage 12 covers categories.

### Suggested contributor checklist

```text
1. Reproduce the TypeError with an offset last_check and datetime.now()
2. Make check_updates return the existing file for both naive and offset timestamps
3. Remove the write of the placeholder file
4. Point checkup, tu-vm.sh, the processor, and the helper at TU_VM_STATUS_DIR
5. Delete the per-user fallback path
6. Confirm /announcements keys are unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Clock compare | `datetime` with a UTC normalization in the helper that already parses the field | A new scheduler |
| Atomic processor write | The existing `os.replace` in `_update_status` | A message bus |
| Directory setup | `tu-vm.sh` creating `TU_VM_STATUS_DIR` the way it already prepares other host paths | A status sidecar container |
| Dashboard copy | Existing `refreshUpdates()` `textContent` path | A new update panel |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Ship the helper read-only fix first. That stops the clobber even while files still live on `/tmp`.
3. Move the directory and drop `/tmp:/tmp` in a follow-up once checkup and the processor use the same path. Doing the move without the read-only fix still loses checkup results.

## Acceptance criteria

- [ ] A file whose `last_check` is `2026-09-28T08:01:45+00:00` is returned as-is and left unmodified by `GET /updates`.
- [ ] A missing update file yields the placeholder body and does not create a file.
- [ ] `daily-checkup.sh` and `write_update_notification_entry` do not write a `${USER}` sibling path.
- [ ] Helper, processor, and checkup share `TU_VM_STATUS_DIR`.
- [ ] After the move, `helper_index` does not mount host `/tmp`.
- [ ] Announcement JSON keys and dashboard `textContent` behavior are unchanged.

## Rollback

Restore the `/tmp` paths and the helper write. Docs-only publication needs no runtime rollback. Prefer rolling back the directory move and the read-only fix together if a host cron still points at `/tmp`.

## Success metrics

- A checkup that finds updates is still visible on the landing page an hour later.
- A failed JSON parse does not erase the last good checkup.
- Operators have one directory to back up or inspect, instead of root-owned files in `/tmp` plus a per-user copy the UI ignores.
