---
title: Processor Metadata Header Contract
description: Constructional contract so the document processor stores extracted text when Tika metadata does not fit in the S3 user-metadata limit.
last_updated: 2026-10-10
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Processor Metadata Header Contract

## Problem

`store_processed_content` in `tika-minio-processor/universal_processor.py` attaches Tika's metadata JSON to the processed object. The size check runs before percent-encoding. The encoded value is what S3 counts, and it can be larger than the 2 KiB user-metadata limit even when the check passed.

The function does this:

```python
metadata_json = json.dumps(metadata, ensure_ascii=True)
max_len = 1500
if len(metadata_json) > max_len:
    metadata_json = metadata_json[:max_len] + "...(truncated)"
s3_metadata['extracted-metadata'] = quote(metadata_json, safe='')
```

`quote(..., safe='')` encodes every character that is not a letter, digit, or `_.-`. A quote becomes `%22`. A space becomes `%20`. A backslash becomes `%5C`. `json.dumps` writes quotes, colons, and spaces throughout, and `ensure_ascii=True` writes non-ASCII as `\uXXXX`, which then encodes the backslash as well.

Replayed on 2026-10-10 with the same `json.dumps` and `quote` calls. No object was uploaded.

| Payload | JSON length | After the 1500 cut | `quote()` length |
|---|---|---|---|
| One value of 350 quote characters | 709 | not cut | 2125 |
| `dc:title`, `dc:creator`, and 40 `pdf:docinfo:custom:field_N` values of `value N "quoted" and spaced` | 2640 | 1514 | 2406 |

2125 and 2406 are both past 2048 before the other user-metadata headers. The put also sends `processed-by`, `original-filename`, `processing-timestamp`, `processing-date`, `processing-method`, and `original-content-type`. On the second object those headers bring the block to about 2791 bytes.

`put_object` then fails. `process_file_from_minio` returns false. The watcher records a retry. Compose sets `PROCESSOR_MAX_FILE_ATTEMPTS=0`, and the watcher treats `0` as unlimited. The same file is attempted on every `CHECK_INTERVAL` (10 seconds) for as long as the processor runs. The extracted text never lands, so the pipeline looks busy and produces no `.txt`.

The 1500 comment says the cut is conservative enough to survive quoting. The table is the opposite: a body under 1500 can encode past 2048, and a body over 1500 is still past 2048 after the cut.

Stage 41 (open PR #67) owns how many bytes of the object body are read and how many archive members are expanded. Stage 52 (open PR #78) owns `.tar.gz` identity and the output stem. This page is the user-metadata header on a successful extract.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `store_processed_content` | Builds `Metadata` and calls `put_object` |
| `quote` from `urllib.parse` | The encoder the size check ignores |
| `process_file_from_minio` | Treats a failed store as a failed file |
| `UniversalMinIOWatcher` | Retries forever when `PROCESSOR_MAX_FILE_ATTEMPTS` is `0` |
| Tika `/meta` response | The dict stored under `extracted-metadata` |
| Stage 41 `processor-object-byte-budget-contract.md` (expected sibling, open PR #67) | Body size and archive expansion |
| Stage 52 `processor-archive-identity-contract.md` (expected sibling, open PR #78) | Archive suffix and output stem |

Out of scope:

- A side database or a second bucket for metadata
- Raising MinIO's metadata limit
- Changing archive detection or the object-body cap
- Dropping extracted text to make the header fit

## Proposal

Measure the encoded header. Keep the text object when metadata does not fit.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Budget | `store_processed_content` | Percent-encode first, then shorten until `extracted-metadata` plus the other `x-amz-meta-*` headers is at most 2048 bytes |
| Cut | the same function | Shorten on a JSON boundary, or drop `extracted-metadata` and set `metadata-omitted=too-large` |
| Store | `put_object` | Upload the extracted text either way. A metadata failure is a log line, not a failed file |
| Retry | watcher | Leave `PROCESSOR_MAX_FILE_ATTEMPTS` alone. This path should not be a retry |

### Rules

1. **The encoded size is the size that counts.** A JSON string under 1500 characters still fails the budget when `quote()` makes it longer than the remaining header room.
2. **Text is the product.** The `.txt` object is written when Tika returned text, including when metadata is omitted.
3. **Omission is visible.** The object metadata says the Tika dict was left off, so an operator can tell a short header from a failed extract.
4. **Retries stay for real failures.** Download errors and Tika errors still use the existing backoff.

### Suggested contributor checklist

```text
1. Replay quote(json.dumps({"k": '"' * 350}, ensure_ascii=True), safe='') and confirm the encoded length is 2125
2. A store call with that dict still puts the text body
3. The resulting user-metadata block is at most 2048 bytes
4. A store call whose metadata fits unchanged still sends extracted-metadata
5. The watcher does not schedule another attempt solely because metadata was omitted
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Header limit | The 2 KiB S3 user-metadata budget `put_object` already has to satisfy | A custom metadata service |
| Encoding | `urllib.parse.quote`, already imported | A second encoder |
| Object body | The current `put_object` of the extracted text | A new bucket layout |
