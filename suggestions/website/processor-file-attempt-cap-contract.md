---
title: Document Watcher Attempt Cap Contract
description: Constructional contract to set PROCESSOR_MAX_FILE_ATTEMPTS to a finite value and to honor that cap when processing raises.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Document Watcher Attempt Cap Contract

## Problem

`UniversalMinIOWatcher` reads `PROCESSOR_MAX_FILE_ATTEMPTS`. The code comment and the branch are explicit: `0` means unlimited attempts. Compose sets `PROCESSOR_MAX_FILE_ATTEMPTS=0`.

On a failed `process_file_from_minio` result, the watcher increments a counter and, when the cap is a positive integer and the counter has reached it, adds the key to the in-memory `processed_files` set so the hot loop stops.

On an exception, the watcher increments the same counter and sets the backoff, then continues. That branch never compares the counter to the cap. A poison file that raises (timeouts, Tika errors that escape as exceptions) retries forever even after the cap is a positive number.

A negative cap also fails the `> 0` check, so it is unlimited too.

`PROCESSOR_MAX_RETRIES` (Compose `2`) is the inner retry inside one `process_file_from_minio` call. It is not this watcher cap. `CHECK_INTERVAL` is how long the loop sleeps (Stage 25). `PROCESSOR_RETRY_BACKOFF_SECONDS` (Compose `30`) is the delay between watcher attempts.

The cap is in-memory. After a process restart the counter starts over. Finished files still skip via the `.txt` head check inside `process_file_from_minio`. A file that never produced a `.txt` gets another budget of attempts after restart. That is the current design. A durable poison marker is a follow-up Issue, not a new store in this contract.

Keys past the first list page are invisible until the [page-size contract](./processor-object-list-pagination-contract.md) lands. The cap cannot apply to keys the watcher never sees.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `PROCESSOR_MAX_FILE_ATTEMPTS=0` | Compose today; code treats `0` as unlimited |
| Failure branch | Honors a positive cap by skipping for this process |
| Exception branch | Counts and backs off, then ignores the cap |
| `PROCESSOR_MAX_RETRIES=2` | Inner retries of one processing call |
| `PROCESSOR_RETRY_BACKOFF_SECONDS=30` | Delay between watcher attempts |
| `.txt` head check | Skips finished files across restarts |
| Stage 25 interval contract (expected sibling) | Sleep between scans |
| [Page size](./processor-object-list-pagination-contract.md) | Which keys are visible |

Out of scope:

- Deleting or quarantining the source object in a new bucket
- A failure database or ticket system
- Changing the inner `PROCESSOR_MAX_RETRIES`
- Changing `CHECK_INTERVAL`

## Proposal

Set a finite cap in Compose:

```text
PROCESSOR_MAX_FILE_ATTEMPTS=5
```

Apply the same positive-cap check on the exception path that already exists on the failure path: once the count reaches the cap, add the key to `processed_files`, drop it from `failed_files`, and log that the cap was reached.

Five watcher rounds, with the existing 30 second backoff and the inner retry of 2, is enough for a Tika blip. It stops a file that raises every scan from occupying the processor until restart.

Treat `0` and any negative value as misconfiguration in `env.example` comments. The code may keep `0` as the unlimited sentinel so an operator can opt in, but the shipped Compose value is `5`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `tika_minio_processor` environment | `PROCESSOR_MAX_FILE_ATTEMPTS=5` |
| Watcher | exception branch in `universal_auto_processor.py` | Same cap check as the failure branch |
| Env schema | `env.example` | Comment that `0` and negatives are unlimited |
| Docs | document playbook | Restart gives a failed file a fresh in-memory budget |

### Rules

1. **Reuse the existing counter.** Do not add a second retry framework.
2. **Both branches honor a positive cap.** Exceptions and `False` returns.
3. **Shipped value is 5.** `0` remains the unlimited opt-in, not the default.
4. **Do not delete the source object.** Operators may still want the file.
5. **Inner retries and the scan interval stay as they are.**

### Suggested contributor checklist

```text
1. Set PROCESSOR_MAX_FILE_ATTEMPTS=5 on tika_minio_processor
2. On the exception path, apply the same max_file_attempts check as the False path
3. Add a test where process raises and the sixth cycle does not call process again
4. Confirm a successful .txt output is still skipped after restart
5. Leave PROCESSOR_MAX_RETRIES and CHECK_INTERVAL unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop a hot loop | Existing attempt counter | A new job runner |
| Survive a blip | Existing backoff and inner retries | Unlimited Compose `0` |
| Skip finished work | Existing `.txt` head check | A processed-files service |
| Durable poison list | A later Issue | Inventing a queue here |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Compose `5`, the exception-path check, and a unit test.
3. Restart `tika_minio_processor`. In-flight memory counters reset, which matches the current design.

## Acceptance criteria

- [ ] Compose sets `PROCESSOR_MAX_FILE_ATTEMPTS=5`.
- [ ] The exception path stops retrying when the count reaches the cap.
- [ ] The failure path still stops at the same cap.
- [ ] Source objects are not deleted.
- [ ] No queue or failure database is added.

## Rollback

Set `PROCESSOR_MAX_FILE_ATTEMPTS=0` to restore unlimited retries. Keep the exception-path check so a future positive cap works.

## Success metrics

- A file that raises on every pass is skipped after 5 attempts until the process restarts.
- Tika blips still retry inside the backoff window.
