---
title: Processor Object Byte Budget Contract
description: Constructional contract to refuse oversized MinIO objects before Body.read(), using a PROCESSOR_MAX_OBJECT_BYTES cap that fits the watcher memory limit.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Processor Object Byte Budget Contract

## Problem

`UniversalMinIOProcessor.process_file_from_minio` downloads an object with:

```text
response = self.s3_client.get_object(...)
file_content = response["Body"].read()
```

There is no `ContentLength` check and no streaming cap. The Compose service `tika_minio_processor` limits memory to **512M**. One large object in `tika-pipe` or `n8n-workflows` can OOM the watcher, which is `restart: unless-stopped`, so it comes back and tries again.

The MCP gateway already has `KB_MAX_OBJECT_BYTES` (default `10485760`) for knowledge-base reads. The watcher does not. OCR PDFs need a higher ceiling than that 10 MiB gateway cap, and they still need a ceiling under 512M. A second in-memory copy during Tika or archive handling means the cap should stay well below the cgroup limit.

Stage 41 `processor-object-list-pagination-contract.md` owns `ContinuationToken`. Stage 41 `processor-file-attempt-cap-contract.md` owns `PROCESSOR_MAX_FILE_ATTEMPTS`, including the exception path. This page only bounds **how many bytes are read**. Do not delete the source object. A failed size check should return failure so the Stage 41 attempt cap can count it.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `universal_processor.py` `process_file_from_minio` | Unbounded `Body.read()` |
| Compose `tika_minio_processor` | `memory: 512M` |
| `KB_MAX_OBJECT_BYTES` | Gateway cap, default 10 MiB, different workload |
| Stage 41 watcher pagination (expected sibling) | Listing pages, not object size |
| Stage 41 attempt cap (expected sibling) | How many failures before skip |
| Stage 25 check-interval energy (expected sibling) | Poll period, not payload size |

Out of scope:

- A job queue, ClamAV, or a second watcher
- Deleting or quarantining the source object
- Lowering `KB_MAX_OBJECT_BYTES` to match this cap
- Changing Tika OCR timeouts
- Raising the 512M limit in the same PR (do that only in a follow-up that also raises the byte cap)

## Proposal

Add `PROCESSOR_MAX_OBJECT_BYTES`. Proposed default: **`67108864`** (64 MiB). That leaves headroom inside 512M for the process, a decoded copy, and a modest archive expansion (see the archive budget page).

1. Read `ContentLength` from `head_object` or from the `get_object` response **before** `Body.read()`.
2. If `ContentLength` is greater than the cap, log the key and the size, return `False`, and do not download the body.
3. If `ContentLength` is missing, read in chunks and stop once the cap is exceeded. Discard the partial buffer and return `False`.
4. Document the key in `env.example` and pass it on `tika_minio_processor`.
5. Keep the sibling `.txt` skip. An oversized object that never produces a `.txt` remains eligible until the attempt cap (Stage 41) marks it skipped. Do not add a new poison-object database here.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Download | `process_file_from_minio` | Length check, then capped read |
| Env | Compose + `env.example` | `PROCESSOR_MAX_OBJECT_BYTES=67108864` |
| Ops note | This page | Raise the cap only together with the memory limit |

### Rules

1. **Check before the full read.** A limit after `Body.read()` does not protect the 512M cgroup.
2. **64 MiB is the default, not a product limit.** Operators override the env value. They do not fork the watcher.
3. **Do not delete the source.** Stage 41 already says a durable poison marker is a later Issue.
4. **Do not reuse the 10 MiB KB cap** as this default. The gateway extracts text for chat. The watcher OCRs documents.
5. **GitHub remains intake.** A higher default is an Issue that names the memory limit in the same change.

### Suggested contributor checklist

```text
1. Confirm Body.read() in process_file_from_minio
2. Add PROCESSOR_MAX_OBJECT_BYTES default 67108864
3. Refuse on ContentLength above the cap before reading the body
4. Stream-and-abort when ContentLength is absent
5. Wire the env into tika_minio_processor and env.example
6. Do not delete the MinIO object and do not add a queue
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Size guard | Env int checked before `Body.read()` | A new ingest service |
| Retry accounting | Stage 41 attempt cap when this returns `False` | A poison-object database |
| KB reads | Existing `KB_MAX_OBJECT_BYTES` | One shared cap that starves OCR |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: the length check and the Compose env.
3. Restart `tika_minio_processor`. In-flight downloads of the old process are unchanged until then.

## Acceptance criteria

- [ ] An object larger than `PROCESSOR_MAX_OBJECT_BYTES` is not fully downloaded.
- [ ] The default in code, Compose, and `env.example` is `67108864` unless an Issue changes both the cap and the memory limit.
- [ ] Missing `ContentLength` cannot grow the buffer past the cap.
- [ ] The source object is not deleted.
- [ ] Stage 41 pagination and attempt-cap pages are not rewritten.

## Rollback

Remove the env and the length check. Downloads are unbounded again, as today.

## Success metrics

- The watcher stays up when a bucket receives a file larger than the cap.
- Logs name the key and the size instead of an OOM restart loop.
- OCR of ordinary documents under 64 MiB continues without a new pipeline.
