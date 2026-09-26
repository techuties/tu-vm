---
title: Processor Archive Expansion Budget Contract
description: Constructional contract to cap zip and tar expansion in the existing watcher using member counts, uncompressed sizes, and a compression ratio, without extracting archives to disk.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Processor Archive Expansion Budget Contract

## Problem

`_process_archive` in `tika-minio-processor/universal_processor.py` opens a zip or tar that is already fully in memory and then reads **every** member:

- Zip: `zip_ref.read(member)` for each name that does not end in `/`
- Tar: `tar_ref.extractfile(member).read()` for each `member.isfile()`

The later display trim (`extracted_files[:20]` and metadata `[:50]`) happens **after** those reads. A small compressed archive can expand far past the 64 MiB object cap proposed on the object-budget page, and past the 512M watcher limit.

The function does **not** write members to disk. This is not a zip-slip path bug. It is an in-memory expansion bug. Python `tarfile` data filters are the wrong tool here because nothing is extracted to the filesystem. The right tool is the size metadata already on `ZipInfo` (`file_size`, `compress_size`) and `TarInfo.size`, read **before** the member body.

Text is decoded only for `.txt`, `.md`, `.csv`, `.json`, and `.xml`. Other members are still fully read so their sizes can be listed. That read is the cost to remove.

This is distinct from the object-byte budget (compressed object size on the wire) and from Stage 41 paging and attempt caps.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `_process_archive` | Unbounded member reads; display trim after the read |
| `zipfile.ZipInfo.file_size` / `compress_size` | Uncompressed and compressed sizes available before `read` |
| `tarfile.TarInfo.size` | Uncompressed size available before `extractfile` |
| Object byte budget (this stage) | Cap on the archive blob itself |
| Stage 41 attempt cap (expected sibling) | Counts a `False` / failed process |
| Watcher memory limit | 512M in Compose |

Out of scope:

- Extracting archives onto a volume or into a sandbox container
- ClamAV, a zip-bomb appliance, or a new file-type service
- Changing which extensions count as archives
- Deleting the source object

## Proposal

Fail the archive (return `None`) before reading member bodies when any of these env caps is exceeded. Proposed defaults:

| Env | Default | Meaning |
|---|---|---|
| `PROCESSOR_ARCHIVE_MAX_MEMBERS` | `100` | Count of file members considered |
| `PROCESSOR_ARCHIVE_MAX_UNCOMPRESSED_BYTES` | `33554432` | Sum of uncompressed sizes (32 MiB) |
| `PROCESSOR_ARCHIVE_MAX_RATIO` | `100` | Skip-and-fail if `file_size / max(compress_size, 1)` exceeds this for a zip member |

1. For zip, use `infolist()` and decide from `file_size` and `compress_size`. Call `read` only for text extensions that are inside the budget, and only up to the remaining byte budget.
2. For tar, use `getmembers()` / `member.size` the same way. Do not call `extractfile` until the member is inside the budget. Do not use `extract` or `extractall`.
3. If the archive exceeds the budget, log the object key and which cap fired, return `None`, and let the attempt cap count the failure.
4. Keep the human listing short. The cap, not the `[:20]` slice, is what bounds memory.
5. Pass the three env values from Compose and document them in `env.example`.

A zip member with `compress_size == 0` and a large `file_size` fails the ratio check. That is intentional.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Zip | `_process_archive` | Budget check before `ZipFile.read` |
| Tar | `_process_archive` | Budget check before `extractfile` |
| Env | Compose + `env.example` | The three keys above |

### Rules

1. **Metadata before bytes.** `file_size` and `TarInfo.size` are the decision. The body read is optional.
2. **No disk extract.** Do not switch to `extractall` to "simplify" the cap.
3. **Fail closed.** A partial text dump of a hostile archive is not success.
4. **Object cap stays separate.** A 1 MiB zip can still be over the uncompressed budget.
5. **GitHub remains intake.** Raising the defaults is an Issue, not a silent Compose edit during an incident.

### Suggested contributor checklist

```text
1. Read _process_archive zip and tar loops
2. Add the three PROCESSOR_ARCHIVE_* env defaults
3. Reject using ZipInfo / TarInfo sizes before read or extractfile
4. Return None when a cap fires; do not write members to disk
5. Document the env keys next to PROCESSOR_MAX_OBJECT_BYTES
6. Do not add ClamAV or a sandbox container
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Expansion limit | Stdlib size fields plus env ints | A decompression appliance |
| On-disk safety | Today's in-memory-only reads | `extractall` plus a path filter |
| Failure accounting | Stage 41 attempt cap | Deleting the archive object |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in the same change as the object byte budget, or immediately after it. Either order is safe. The archive cap still matters if the blob itself is small.
3. Restart the watcher to load the env.

## Acceptance criteria

- [ ] A zip whose `file_size` sum exceeds `33554432` does not have every member read into RAM.
- [ ] A zip member with a ratio above `100` fails the archive before `read`.
- [ ] Tar members are not `extractfile`'d once the uncompressed sum exceeds the cap.
- [ ] No archive member is written to the container filesystem.
- [ ] Defaults are in code, Compose, and `env.example`.
- [ ] The object-budget page and Stage 41 pages are not rewritten.

## Rollback

Remove the three checks. Archive handling returns to a full in-memory read.

## Success metrics

- A tiny high-ratio zip does not restart the watcher via the OOM killer.
- Normal zip and tar files under the caps still produce a `.txt` summary.
- The processor image does not gain an antivirus or sandbox dependency.
