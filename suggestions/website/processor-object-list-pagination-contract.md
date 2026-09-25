---
title: Document Watcher Page Size Contract
description: Constructional contract to page MinIO listings in the document watcher by reusing the ContinuationToken loop already used for stats.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Document Watcher Page Size Contract

## Problem

`tika-minio-processor/universal_auto_processor.py` `check_for_new_files` calls `list_objects_v2` once per watched bucket and reads `Contents`. It does not pass `ContinuationToken`, and it ignores `IsTruncated`.

ListObjectsV2 returns at most 1000 keys when `MaxKeys` is omitted. Objects after that page are never handed to `process_file_from_minio`. A community folder that grows past one page silently stops processing new files that sort after the first page.

`tika-minio-processor/universal_processor.py` `get_processing_stats` already loops:

- call `list_objects_v2`
- read `Contents`
- if `IsTruncated`, continue with `NextContinuationToken`
- stop when the page is complete

`process_file_from_minio` already calls `head_object` on the sibling `.txt` output and returns success when that output exists. A full listing therefore does not re-OCR finished documents. The in-memory `processed_files` set only avoids repeat `head_object` calls inside one process. After a restart the head check still skips finished work.

Raising `MaxKeys` once, without following the token, still drops every later page.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `UniversalMinIOWatcher.check_for_new_files` | Single-page list |
| `UniversalMinIOProcessor.get_processing_stats` | Working ContinuationToken loop |
| `process_file_from_minio` | Skips when the `.txt` output already exists |
| `WATCH_BUCKETS` | Comma-separated buckets the watcher already honors |
| Stage 25 check-interval contract (expected sibling) | How often the loop wakes, not how many keys it sees |
| [Attempt cap](./processor-file-attempt-cap-contract.md) | How many times one key is retried |

Out of scope:

- A queue, database, or search index of object keys
- Changing `CHECK_INTERVAL`
- Deleting source objects after success
- A new MinIO bucket layout

## Proposal

Use the same ContinuationToken loop inside `check_for_new_files` for every watched bucket. Keep the existing filters (skip `.txt`, `.lock`, `.tmp`, `.swp`, `.processed`, and unsupported types). Keep the existing per-key backoff map.

Do not replace the loop with a higher `MaxKeys` only. A higher page size is optional after the token loop exists; it is not the fix.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Watcher | `universal_auto_processor.py` | Page `list_objects_v2` like `get_processing_stats` |
| Tests | processor unit test or a small fixture | Two pages of keys, second page must be returned |
| Docs | document playbook | Note that buckets over 1000 keys are in the contract |
| Interval | Stage 25 | Leave the sleep interval alone |

### Rules

1. **Reuse the stats loop.** Same `IsTruncated` / `NextContinuationToken` fields.
2. **Keep output skipping.** The `.txt` head check is the idempotency the processor already has.
3. **Page every watched bucket.** `WATCH_BUCKETS` can list more than one.
4. **Do not add a queue.** The watcher is already the scheduler.
5. **Attempt caps stay on the sibling page.** Pagination must not mark unseen keys as failed.

### Suggested contributor checklist

```text
1. Extract or copy the continuation loop from get_processing_stats
2. Use it in check_for_new_files for each bucket
3. Add a test with a truncated first page and a second page
4. Confirm an existing .txt output is still skipped via head_object
5. Leave CHECK_INTERVAL and bucket names unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Full listing | Existing token loop in stats | A custom indexer |
| Skip finished files | Existing `.txt` head check | A processed-files database |
| Wakeups | Existing `CHECK_INTERVAL` | A new scheduler |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: the watcher loop plus a two-page test.
3. Restart `tika_minio_processor` after the change. No Compose env is required for the loop itself.

## Acceptance criteria

- [ ] `check_for_new_files` follows `NextContinuationToken` until `IsTruncated` is false.
- [ ] A key that appears only on page two is offered for processing.
- [ ] Existing `.txt` outputs are still skipped.
- [ ] No queue service is added.

## Rollback

Restore the single `list_objects_v2` call. Buckets under 1000 keys behave as they do today.

## Success metrics

- A bucket with more than 1000 source keys still yields new files to the processor.
- Stats and the watcher use the same paging fields.
