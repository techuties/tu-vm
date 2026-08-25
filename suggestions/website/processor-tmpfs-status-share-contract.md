---
title: Processor Tmpfs and Status Share Contract
description: Constructional contract for processor scratch tmpfs that preserves the helper dashboard status file share, without overlaying /tmp blindly.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Processor Tmpfs and Status Share Contract

## Problem

`tika_minio_processor` and `helper_index` both bind **`/tmp:/tmp`** so the dashboard can read `/tmp/tika-processing-status.json`. That works, and it is also an energy and hygiene leak:

- Processor scratch (downloads, OCR temp) lands on the **host** `/tmp`
- Helper writes other files there (`tu-vm-update-status.json`, `tu-vm-log-status.json`)
- A naive `tmpfs: /tmp` on the processor **hides** the bind mount and **breaks** PDF progress notifications

Stage 10 covers **document pipeline** behavior. Stage 20 covers **processor Python** changes. Stage 23 covers **read-only rootfs + tmpfs for Nginx**. This page is **scratch isolation without breaking the status share**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` | Reads `/tmp/tika-processing-status.json` |
| `tika-minio-processor/universal_processor.py` | `STATUS_FILE = '/tmp/tika-processing-status.json'` |
| Compose binds | `/tmp:/tmp` on helper and processor |
| Compose `tmpfs` | Engine-supported scratch (already proposed for Nginx in Stage 23) |
| Stage 20 `tika-minio-processor-python-contribution-contract.md` (expected sibling) | Watch/retry/status code |
| Stage 23 `read-only-rootfs-proxy-contract.md` (expected sibling) | Nginx tmpfs, not processor |

Out of scope:

- Deleting dashboard PDF progress
- A Redis/NATS status bus (Stage 25 already rejected an ingest bus for `CHECK_INTERVAL`)
- Making the processor `read_only` in the same PR unless the status path is already split
- Changing helper docker.sock or CONTROL_TOKEN

## Proposal

Split **status** from **scratch**. Then give the processor a tmpfs `/tmp`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Shared status | Named volume `processor_status` (or a dedicated host dir) mounted on **both** helper and processor | e.g. `/var/lib/tu-vm/status` |
| Code paths | `STATUS_FILE` in processor + helper | Same new path on both; one constant |
| Scratch | Processor `tmpfs: /tmp` **after** the status path is no longer under `/tmp` | Host `/tmp` bind removed from processor |
| Helper host `/tmp` | Keep helper's `/tmp:/tmp` for update/log JSON until those move | Do not break `tu-vm.sh` status files in the same step |

### Rules

1. **Do not overlay `/tmp` with tmpfs while `STATUS_FILE` is still `/tmp/…`.** That is a user-visible dashboard regression.
2. **Do not invent a status API.** A named volume or bind plus the existing JSON file is enough.
3. **Move the path once, on both sides.** Helper and processor must agree before the processor bind is removed.
4. **Scratch is tmpfs.** After the split, processor `/tmp` is memory-backed and discarded on stop (fits Stage 25 stop-grace).
5. **Helper update/log files are a later split.** This page does not require moving `tu-vm-update-status.json`.
6. **GitHub remains intake.** Requests for a "processing event stream" stay Issues.

### Suggested contributor checklist

```text
1. Introduce a shared mount (named volume or /var/lib/tu-vm/status)
2. Point processor STATUS_FILE and helper reader at that mount
3. Confirm dashboard PDF progress still updates
4. Remove processor /tmp:/tmp bind
5. Add tmpfs: /tmp on the processor only
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Status share | Named volume / dedicated bind + existing JSON | Redis/NATS status bus |
| Scratch | Compose `tmpfs` | Host `/tmp` as a scratch disk |
| Nginx tmpfs | Stage 23 | Copying Nginx `read_only` onto the processor here |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in two commits if needed: (a) relocate `STATUS_FILE`, (b) tmpfs + drop processor `/tmp` bind.
3. Do not merge (b) without a dashboard check of PDF progress.

## Acceptance criteria

- [ ] Processor scratch is tmpfs (or the PR explains why the bind remains).
- [ ] Helper still reads processor progress without a new API.
- [ ] Processor no longer uses host `/tmp` as unbounded scratch.
- [ ] `STATUS_FILE` is not left on `/tmp` underneath a processor tmpfs overlay.
- [ ] `docker compose config` still renders.
- [ ] A test PDF shows progress on the landing page.

## Rollback

Restore `/tmp:/tmp` on the processor and the original `STATUS_FILE` path. Named volume can be removed.

## Success metrics

- Host `/tmp` no longer fills during OCR.
- Dashboard PDF notifications keep working after the split.
- Contributors add tmpfs instead of proposing a processing message bus.
