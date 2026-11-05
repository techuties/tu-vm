---
title: Source Text File Contract
description: Constructional contract so a source .txt upload reaches the text decoder the processor already has.
last_updated: 2026-11-05
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Source Text File Contract

## Problem

`tika-minio-processor/universal_processor.py` documents text extraction and implements it:

```python
'.txt': 'text',
'.md': 'text',
'.csv': 'text',
```

`_process_text_file` decodes UTF-8 and falls back to Latin-1. `process_file` calls it when `_get_file_type` returns `text`.

`.txt` is also in `SKIP_EXTENSIONS`, and `_get_file_type` returns `skip` as soon as `Path.suffix` is in that set. The supported map is never consulted. The watcher in `universal_auto_processor.py` returns before `_get_file_type` when the key ends with `.txt`.

The output name uses `Path.stem` plus `.txt`. For a source that is already `.txt`, that name is the source key.

Replayed on 2026-11-05 with Python 3.12.3. The sets and the two functions were read from `universal_processor.py`. MinIO was not contacted. The processor container was not started.

| Source key | `_get_file_type` | Output key | Output key equals source |
|---|---|---|---|
| `notes.txt` | `skip` | `notes.txt` | yes |
| `folder/notes.txt` | `skip` | `folder/notes.txt` | yes |
| `notes.md` | `text` | `notes.txt` | no |
| `notes.csv` | `text` | `notes.txt` | no |
| `notes.pdf` | `tika` | `notes.txt` | no |

`notes.md` and `notes.csv` can reach `_process_text_file`. `notes.txt` cannot. The watcher drops it first. If that `continue` is removed, `_get_file_type` still returns `skip`. If that set no longer contains `.txt`, `process_file_from_minio` still `head_object`s `notes.txt`, finds the source, and returns success without calling `process_file`.

`store_processed_content` already writes user metadata `processed-by: universal-processor` on outputs. The head check does not read it. A source `.txt` has no such header. An output does, once this path stores one.

Stage 52 (open PR #78) is the collision where `notes.pdf` and `notes.md` share `notes.txt`. That table stays. This page is the source whose suffix is already `.txt`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `SUPPORTED_EXTENSIONS['.txt']` | Already says `text` |
| `_process_text_file` | UTF-8 decode with a Latin-1 fallback |
| `SKIP_EXTENSIONS` | Drops `.txt` before the supported map |
| Watcher `endswith('.txt')` | Drops the key before `_get_file_type` |
| `process_file_from_minio` head check | Treats an existing output key as done |
| `processed-by` metadata | Header `store_processed_content` already sets |
| Stage 52 `processor-archive-identity-contract.md` (open PR #78) | Shared output key for different source suffixes |

Out of scope:

- Renaming `notes.pdf` → `notes.txt` (Stage 52)
- A new parser for Markdown or CSV
- OCR for text files
- Pagination of `list_objects_v2` (Stage 41, open PR #67)

## Proposal

Let a source `.txt` through to `_process_text_file`. Keep skipping objects that this processor already wrote, using the metadata header it already stores. When the output key would be the source key, do not treat "object exists" as "already processed".

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Watcher | `endswith('.txt')` in `check_for_new_files` | Do not drop every `.txt`. Skip outputs, not sources |
| Classifier | `.txt` inside `SKIP_EXTENSIONS` | Leave `.lock`, `.tmp`, `.swp`, and `.processed`. A source `.txt` returns `text` |
| Done check | `head_object` in `process_file_from_minio` | If the output key is the source key, skip only when `processed-by` is `universal-processor` |
| Decode | `_process_text_file` | Call it for that source. Leave the function as it is |

### Rules

1. **`notes.txt` is text.** `_get_file_type("notes.txt")` returns `text`, and the watcher does not `continue` solely because the key ends in `.txt`.
2. **The decoder is the one already written.** `_process_text_file` stays the UTF-8 / Latin-1 reader.
3. **Outputs stay outputs.** An object whose metadata `processed-by` is `universal-processor` is not decoded again.
4. **Existence of the source is not success.** `head_object` on `notes.txt` before any processing must not return true from `process_file_from_minio`.
5. **Stage 52 still owns `notes.pdf` and `notes.md`.** Their output key remains whatever that page sets. This page does not edit that table.
6. **No second pipeline.** The watcher, the classifier, and `_process_text_file` are the path.

### Suggested contributor checklist

```text
1. Classify notes.txt and folder/notes.txt as text
2. Classify notes.md as text and notes.pdf as tika, unchanged
3. Run the watcher selection on notes.txt with no processed-by metadata and confirm it is queued
4. Run it on a .txt whose metadata processed-by is universal-processor and confirm it is skipped
5. Confirm head_object of the source key alone does not count as already processed
6. Confirm the notes.pdf / notes.md output-key table from Stage 52 is unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Decode | `_process_text_file` | A new text service |
| Output marker | `processed-by` from `store_processed_content` | A sidecar database of filenames |
| Other suffixes | Stage 52's key rule | A second naming scheme in this page |
| Intake | GitHub Issue | An upload portal |

### Acceptance check

- [ ] `_get_file_type("notes.txt")` is `text`, not `skip`.
- [ ] The watcher queues a `.txt` key that has no `processed-by: universal-processor` metadata.
- [ ] The watcher skips a `.txt` key that has that metadata.
- [ ] `process_file_from_minio("notes.txt")` calls `_process_text_file` when the object is only a source.
- [ ] `notes.md` still classifies as `text` and `notes.pdf` still classifies as `tika`.
- [ ] The Stage 52 output key for `notes.pdf` and `notes.md` is unchanged.
- [ ] MinIO was not required to prove the classification, and `.env` was not created.

### Rollback

Put `.txt` back in `SKIP_EXTENSIONS` and restore the watcher's `endswith('.txt')` continue. Source `.txt` uploads are ignored again. `notes.md` still reaches `_process_text_file`.
