---
title: Processor Archive Identity Contract
description: Constructional contract so a .tar.gz archive is actually extracted, and so two different source files do not share one processed object key.
last_updated: 2026-10-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Processor Archive Identity Contract

## Problem

The document watcher classifies files by their full suffix, then the archive reader and the object key throw that suffix away. Two day-to-day failures follow.

### `.tar.gz` is stored as an empty extract

`SUPPORTED_EXTENSIONS` maps `.tar.gz` to `archive`. `_get_file_type` checks longer suffixes first with `filename.lower().endswith(ext)`, so `bundle.tar.gz` is an archive.

`_process_archive` then branches on `Path.suffix` only:

```python
path = Path(filename.lower())
if path.suffix == '.zip':
    ...
elif path.suffix in ['.tar', '.tar.gz', '.tgz']:
    mode = 'r:gz' if path.suffix in ['.tar.gz', '.tgz'] else 'r'
    ...
```

`Path("bundle.tar.gz").suffix` is `.gz`, and `.suffixes` is `['.tar', '.gz']`. The zip branch does not run. The tar branch does not run. `extracted_files` stays empty. The function still returns success:

```text
Archive: bundle.tar.gz
Extracted 0 files
```

with `archive_type` set to `.gz` and `processing_method` `archive`. `process_file_from_minio` stores that body and returns true. The watcher adds the object to `processed_files` and will not open it again until the processed object is removed.

`.tgz` and `.tar` do enter the branch, because their `Path.suffix` is `.tgz` or `.tar`. `.zip` enters the zip branch. The common `.tar.gz` name is the one that skips both.

Checked with the interpreter on 2026-10-06:

| Name | `Path.suffix` | Tar branch (`suffix in {'.tar', '.tar.gz', '.tgz'}`) |
|---|---|---|
| `bundle.tar.gz` | `.gz` | no |
| `bundle.tgz` | `.tgz` | yes |
| `bundle.tar` | `.tar` | yes |
| `bundle.zip` | `.zip` | no (zip branch matches) |

The gzip mode line has the same hole. Even inside the tar branch, `path.suffix in ['.tar.gz', '.tgz']` is false for a `.gz` suffix, so a `.tar.gz` opened the wrong way would use mode `r` instead of `r:gz`.

### Distinct sources share one `.txt` key

The skip check and the writer both name the output from `Path.stem`, which drops only the last suffix:

```python
p = Path(object_key)
parent = str(p.parent).strip('.')
output_key = f"{p.stem}.txt" if parent == '' else f"{parent}/{p.stem}.txt"
```

The same expression is repeated in `store_processed_content`. Interpreter results on 2026-10-06:

| Source key | Processed key |
|---|---|
| `notes.pdf` | `notes.txt` |
| `notes.docx` | `notes.txt` |
| `notes.md` | `notes.txt` |
| `quarterly/report.pdf` | `quarterly/report.txt` |
| `quarterly/report.xlsx` | `quarterly/report.txt` |
| `bundle.tar.gz` | `bundle.tar.txt` |

`process_file_from_minio` treats an existing key as success and returns true without reading the new source. The second file is marked processed. The bucket keeps whichever text was stored first. A `.tar.gz` that took the empty-extract path occupies `bundle.tar.txt`, which is also the key `bundle.tar.pdf` would use.

Stage 41 (open PR #67) owns archive expansion budgets and object-list pagination. Those caps stay. This page owns which branch runs, and what the stored object is called. Stage 48 owns the dashboard card for the worker. The status file path is unchanged.

Checked on 2026-10-06 in `tika-minio-processor/universal_processor.py` (`_get_file_type`, `_process_archive`, `process_file_from_minio`, `store_processed_content`) and `universal_auto_processor.py` (the watcher treats a true return as done). MinIO was not running.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `_get_file_type` | Longest-suffix match, including `.tar.gz` |
| `tarfile` and `zipfile` | Already imported. They can read the bytes once the branch runs |
| `process_file_from_minio` head-object skip | Right idea: do not extract again when this source's output exists |
| `store_processed_content` | The only writer of processed text |
| Watcher `processed_files` | In-memory "already handled" set for this process |
| Stage 41 `processor-archive-expansion-budget-contract.md` (expected sibling, open PR #67) | Byte and member caps. Do not raise them here |
| Stage 41 object-list pagination (expected sibling, open PR #67) | `list_objects_v2` continuation. Not the object key |
| Stage 46 MinIO client transport (expected sibling, open PR #72) | How the processor reaches MinIO. Not key names |

Out of scope:

- A new document service, queue, or OCR engine
- Raising archive size caps
- Changing Tika's task timeout (Stage 50)
- A database of processed keys
- Reprocessing every historical object automatically

## Proposal

Decide the archive type from the suffix `_get_file_type` already matched, and build the processed key from the full source name.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Archive type | `_process_archive` | Take the extension `_get_file_type` returns (`ext`), or test `endswith` in the same longest-first order. `.zip` uses `zipfile`. `.tar.gz` and `.tgz` use `tarfile` mode `r:gz`. `.tar` uses mode `r` |
| Empty open | Same function | If the matching branch does not run, return `None` so the watcher records a failure and retries. A real archive that contains no files may still return success |
| Object key | One function used by the head-object check and by `store_processed_content` | Key is the source key plus `.txt` (`notes.pdf.txt`, `quarterly/report.xlsx.txt`, `bundle.tar.gz.txt`). Parent directories stay. Do not use `Path.stem` alone |
| Skip | Watcher | It already ignores keys that end with `.txt`. The new key still ends with `.txt`, so extracts are not fed back in |
| Repair | Operator note in the module docstring or the existing playbook | Objects already stored under the stem key, including an empty `bundle.tar.txt`, are not rewritten by a process restart. Delete that object, or remove the source from the watcher's in-memory set by restarting after the delete, before the corrected extractor will run |

### Rules

1. **The classified extension is the one that is opened.** `_get_file_type` says `.tar.gz`; the reader must not look at `Path.suffix` alone.
2. **Gzip tar uses `r:gz`.** A `.tar.gz` file opened with mode `r` is not a successful extract.
3. **One source, one key.** `notes.pdf` and `notes.docx` store `notes.pdf.txt` and `notes.docx.txt`.
4. **An existing key for that same source still skips.** The head-object check uses the new function, so a second pass does not call Tika again for the same object.
5. **Budgets stay.** Member count and byte caps from Stage 41 are not increased to make this work.
6. **Do not add a lock service.** The in-memory set and the MinIO head-object check remain the two "already done" signals.

### Suggested contributor checklist

```text
1. Pass a .tar.gz that contains one hello.txt through _process_archive and confirm the text includes hello
2. Confirm archive metadata names .tar.gz, not .gz
3. Confirm notes.pdf and notes.docx produce two object keys
4. Confirm a second process_file_from_minio of notes.pdf skips when notes.pdf.txt exists
5. Confirm a .txt upload is still skipped by the watcher
6. Confirm a .tar.gz that does not open returns failure rather than "Extracted 0 files"
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Zip and tar | `zipfile` and `tarfile` already imported | A new unpack service |
| Suffix choice | `_get_file_type` longest-match | A MIME database |
| Idempotence | `head_object` on the processed key | A processed-file database |
| Operator retry | Delete the old stem object, then let the existing watcher loop | A migration framework |
| Community report | GitHub issue with the source key and the stored key | A custom pipeline console |

## Acceptance criteria

- A `.tar.gz` containing a small text file produces that text in the result body.
- The tar branch is not selected by comparing `Path.suffix` to the string `.tar.gz`.
- `notes.pdf` and `notes.docx` in the same folder store different keys, and the second is extracted.
- `head_object` skip and `store_processed_content` call the same key function.
- Keys that end with `.txt` are still ignored by the watcher.
- Archive expansion limits are unchanged.

## Verification notes

Interpreter check on 2026-10-06: `Path("bundle.tar.gz").suffix == ".gz"` and that value is not in `{".tar", ".tar.gz", ".tgz"}`. `Path("notes.pdf").stem` and `Path("notes.docx").stem` are both `notes`. The watcher and MinIO were not run. Stage 41 still owns pagination and expansion budgets.

## Rollback

Restore the `Path.suffix` branch and the `Path.stem` key. New extracts go back to colliding names, and `.tar.gz` again stores an empty success body.
