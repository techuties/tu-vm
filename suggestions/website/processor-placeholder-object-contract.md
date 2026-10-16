---
title: Processor Placeholder Object Contract
description: Constructional contract so the MinIO watcher does not send .gitkeep and other unknown keys to Tika. Those placeholders are created by tu-vm.sh bucket setup.
last_updated: 2026-10-16
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Processor Placeholder Object Contract

## Problem

`setup_minio_buckets` in `tu-vm.sh` creates empty objects so the bucket layout exists:

```text
local/tika-pipe/.gitkeep
local/n8n-workflows/inputs/.gitkeep
local/n8n-workflows/outputs/.gitkeep
local/shared-documents/company/.gitkeep
```

Compose watches `tika-pipe` and `n8n-workflows`. The watcher skips keys that end in `.txt`, `.lock`, `.tmp`, `.swp`, or `.processed`. It does not skip `.gitkeep`.

`_get_file_type` returns `skip` only for `SKIP_EXTENSIONS`. Any other unknown name is classified as `tika`. Checked on 2026-10-16 by loading `universal_processor.py` with stubbed `boto3` and `requests` (the processor image was not started):

| Key | Result |
|---|---|
| `notes.pdf` | `tika` |
| `.gitkeep` | `tika` |
| `inputs/.gitkeep` | `tika` |
| `n8n-workflows/outputs/.gitkeep` | `tika` |
| `folder/` | `tika` |
| `README` | `tika` |
| `scan.tmp` | `skip` |
| `done.txt` | `skip` |

Each unknown name logs `Unknown file type ... attempting Tika processing`. With `PROCESSOR_MAX_FILE_ATTEMPTS=0`, a placeholder that never produces a `.txt` stays in the retry loop. The attempt-cap page (open PR #67) owns that cap, including the exception branch that ignores it. This page is the objects that should never be queued. `shared-documents` is not in `WATCH_BUCKETS`, so its `.gitkeep` is out of this loop today. The two watched buckets are not.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `setup_minio_buckets` | Writes the `.gitkeep` objects with `mc cp /dev/null` |
| `SKIP_EXTENSIONS` and `_get_file_type` | The classifier to extend |
| `UniversalMinIOWatcher.check_for_new_files` | The suffix filter beside the classifier |
| `WATCH_BUCKETS=tika-pipe,n8n-workflows` | The buckets that contain the placeholders |
| `SUPPORTED_EXTENSIONS` | The only names that should go to Tika, text, or archive handling |
| Open PR #67 `processor-file-attempt-cap-contract.md` (expected sibling) | How many times a real file may fail. Do not restate that cap |
| Stage 48 Tika readiness (open PR #74) | When the JVM is listening. Do not add a Tika healthcheck here |

Out of scope:

- A new document pipeline or a second extractor
- Deleting operator uploads that happen to have an uncommon extension after this rule ships. Unknown keys are skipped and logged, not deleted
- Object-list pagination (`processor-object-list-pagination-contract.md` on open PR #67). A key on a later page is still subject to this filter once it is listed
- Changing `CHECK_INTERVAL`

## Proposal

Keep the watcher. Teach it to ignore placeholders and names it does not know.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Classifier | `_get_file_type` | Return `skip` when the suffix is not in `SUPPORTED_EXTENSIONS` and not already in `SKIP_EXTENSIONS`. Remove the `return 'tika'` fallback |
| Names | `SKIP_EXTENSIONS` | Add `.gitkeep` |
| Dot keys | `check_for_new_files` | Skip a key whose final path segment starts with `.` |
| Empty objects | `check_for_new_files` | Skip `Size == 0` |
| Layout | `setup_minio_buckets` | Keep creating the prefix objects if the bucket UI needs them. The watcher, not a new layout tool, must ignore them |

### Rules

1. **Known extensions still go to Tika.** `.pdf` and the other keys in `SUPPORTED_EXTENSIONS` stay on their current method.
2. **Unknown means skip, once.** Log the key at info, and do not call Tika. Do not add it to `failed_files`.
3. **Placeholders are not documents.** `.gitkeep`, a trailing-slash folder marker, and a zero-byte object are layout, not OCR input.
4. **Do not raise the attempt cap here.** Open PR #67 still owns poison files that are real documents.
5. **Do not delete the objects from MinIO in the watcher.** Skipping them leaves bucket setup idempotent.

### Suggested contributor checklist

```text
1. Classify inputs/.gitkeep, .gitkeep, and folder/ as skip
2. Classify notes.pdf as tika
3. Run one watcher cycle against a bucket that contains only .gitkeep and confirm Tika is not called
4. Confirm a zero-byte object is skipped even when its suffix is .pdf
5. Confirm a non-empty .pdf is still processed
6. Do not change PROCESSOR_MAX_FILE_ATTEMPTS in this change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| File types | `SUPPORTED_EXTENSIONS` already in the processor | A MIME server or a new classifier package |
| Placeholders | The existing `.gitkeep` objects plus a skip rule | Removing bucket setup |
| Retry budget | The attempt-cap contract on open PR #67 | A second retry store |
