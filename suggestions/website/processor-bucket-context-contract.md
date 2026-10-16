---
title: Processor Bucket Context Contract
description: Constructional contract so a failed MinIO watch-bucket file restores uploads_bucket and processed_bucket. Stats must keep listing tika-pipe.
last_updated: 2026-10-16
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Processor Bucket Context Contract

## Problem

The watcher handles more than one bucket by rewriting the processor's bucket fields for the duration of one file:

```text
original_uploads = uploads_bucket
original_processed = processed_bucket
uploads_bucket = bucket
processed_bucket = bucket
success = process_file_from_minio(object_key)
uploads_bucket = original_uploads
processed_bucket = original_processed
```

Those two assignments back to the originals sit after the call, still inside the `try`. The `except` logs the error, updates `failed_files`, and does not restore the pointers.

Checked on 2026-10-16 by constructing `UniversalMinIOWatcher` with a processor whose `process_file_from_minio` raises. Starting buckets were `tika-pipe`. The queued key was `n8n-workflows/inputs/.gitkeep`. After `process_new_files` returned, both pointers were `n8n-workflows`.

`get_processing_stats` lists `self.processed_bucket`. The next stats print, which the main loop runs every 60 checks, therefore counts `.txt` objects in the failed watch bucket instead of the processed prefix the operator expects (`tika-pipe`, from `PROCESSED_BUCKET`).

The next file in a later cycle assigns the pointers again at the top of its own `try`, so that later file is downloaded from the right bucket. The window is everything between the exception and that next assignment, including the `CHECK_INTERVAL` sleep when the failed key was the last one in the batch.

Open PR #67 describes this `except` only as the branch that does not apply `PROCESSOR_MAX_FILE_ATTEMPTS`. It does not mention the bucket fields. Do not restate the cap.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `UniversalMinIOWatcher.process_new_files` | The `try` that swaps the two bucket fields |
| `UniversalMinIOProcessor.processed_bucket` | What `get_processing_stats` lists |
| Compose `UPLOADS_BUCKET` / `PROCESSED_BUCKET` | Both default to `tika-pipe` |
| Compose `WATCH_BUCKETS` | `tika-pipe,n8n-workflows`, which is why the swap exists |
| Open PR #67 attempt-cap page (expected sibling) | The counter in this `except`. Leave the cap rules there |
| `processor-object-list-pagination-contract.md` on open PR #67 (expected sibling) | Listing more than one page of keys. Not the pointer restore |

Out of scope:

- A per-bucket processor instance or a new worker pool
- Changing which buckets are watched
- Durable failure state on disk
- The placeholder skip rules (the sibling page on this branch)

## Proposal

Restore the two fields on every exit from the attempt.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Restore | `process_new_files` | Save the originals, assign the watch bucket, and put the originals back in `finally` |
| Success path | Same function | Keep the current success and failure counter updates after the call, so they still see the result |
| Stats | `get_processing_stats` | No new bucket argument. It stays correct once the pointer is restored |
| Tests | A unit test next to the processor, or a short `python3` snippet in the PR | One raising call on `n8n-workflows` leaves both fields on `tika-pipe` |

### Rules

1. **`finally` runs on success and on exception.** A `False` return still restores. An exception still restores.
2. **The originals are the Compose defaults for that process.** Do not hardcode `tika-pipe` inside the watcher. Read whatever the processor had when the attempt started.
3. **Do not split the processor into one object per bucket.** The swap is the feature. The leak is the missing `finally`.
4. **The attempt cap stays on its page.** This change does not decide when a key is abandoned.
5. **Stats list `processed_bucket` after the attempt.** After a failed `n8n-workflows` key, a stats call lists `tika-pipe` when that was the original.

### Suggested contributor checklist

```text
1. Queue one n8n-workflows key whose process_file_from_minio raises
2. After process_new_files, uploads_bucket and processed_bucket equal the values from before the call
3. Repeat with a False return and confirm the same restore
4. Confirm a following tika-pipe key is still downloaded from tika-pipe
5. Do not add a bucket argument to get_processing_stats
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Multi-bucket watch | The existing field swap | One thread per bucket |
| Cleanup | `try` / `finally` | A new context-manager helper module |
| Stats | `get_processing_stats` as it is | A second status API |
