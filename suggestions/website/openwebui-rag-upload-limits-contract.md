---
title: Open WebUI RAG Upload Limits Contract
description: Constructional contract to set official RAG_FILE_MAX_SIZE, RAG_FILE_MAX_COUNT, and RAG_ALLOWED_FILE_EXTENSIONS on the pinned Open WebUI image, which otherwise leaves chat uploads unlimited.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI RAG Upload Limits Contract

## Problem

The pinned Open WebUI image (revision `02dc3e689ceac915a870b373318b99c029ddf603`, created 2026-06-02) defines three document-upload keys as `ConfigVar`s in `backend/open_webui/config.py`:

| Key | Unset behavior in that revision |
|---|---|
| `RAG_FILE_MAX_SIZE` | `None` |
| `RAG_FILE_MAX_COUNT` | `None` |
| `RAG_ALLOWED_FILE_EXTENSIONS` | empty list |

Compose does not set them. The chat composer in that revision (`src/lib/components/chat/MessageInput.svelte`) treats a null `file.max_size` as no size cap and a null `file.max_count` as no count cap. Size, when set, is megabytes: the composer compares `file.size` with `max_size * 1024 * 1024`. An empty extension list skips the server check in `upload_file_handler`, so every extension is accepted.

Open WebUI is limited to 2G RAM. Tika's heap is 1536m. Nginx on `oweb.tu.lan` `location /` already sets `client_max_body_size 20m`. An unlimited application cap lets the UI accept work the proxy or the container cannot finish.

Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) is the knowledge-pack catalog. It does not set these keys. Stage 9 `nginx-edge-routing-contract.md` (expected sibling) owns the proxy body size. This page does not edit Nginx.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `config.py` | `RAG_FILE_MAX_*` and `RAG_ALLOWED_FILE_EXTENSIONS` are `ConfigVar`s; unset size and count are `None` |
| Pinned chat composer | Enforces size (MiB) and count when the config values are not null |
| Pinned `upload_file_handler` | Rejects an extension only when the allowlist is non-empty |
| `tika-minio-processor/universal_processor.py` `SUPPORTED_EXTENSIONS` | Document and image types the pipeline already extracts |
| Nginx `oweb.tu.lan` `location /` | `client_max_body_size 20m` already present |
| Stage 36 PersistentConfig (expected sibling) | Stored admin values override env after first boot unless that contract is implemented in code |
| GitHub Issues | Place to widen a cap |

Out of scope:

- Changing Nginx `client_max_body_size`
- A new upload service, virus scanner, or document CMS
- Replacing the MinIO / Tika / Qdrant pipeline (Stage 8)
- Treating knowledge-base screens as count-capped. In this revision, `KnowledgeBase/Files.svelte` does not read `file.max_count` or `file.max_size`

## Proposal

Set the official keys on the `open-webui` service:

```text
RAG_FILE_MAX_SIZE: "20"
RAG_FILE_MAX_COUNT: "10"
RAG_ALLOWED_FILE_EXTENSIONS: "pdf,doc,docx,xls,xlsx,ppt,pptx,odt,ods,odp,rtf,epub,mobi,txt,md,csv,json,xml,html,htm,log,jpg,jpeg,png,gif,bmp,tiff,tif,webp"
```

`20` matches the existing `oweb.tu.lan` proxy cap so the composer and Nginx agree. It is megabytes in this image, not bytes. `10` is a laptop starting count for one chat attachment batch, not an upstream default. The extension string is the processor's document and image list without `.zip`, `.tar`, `.tar.gz`, or `.tgz`. Those archives stay on the MinIO processor for operators who already use them; they are not chat-upload types.

The extension value is comma-separated with no dots. That matches `os.getenv('RAG_ALLOWED_FILE_EXTENSIONS', '').split(',')` in the pinned `config.py`.

These three keys are `ConfigVar`s. After the first successful start, Admin → Documents values stored in Postgres win over a later Compose edit unless Stage 36 `ENABLE_PERSISTENT_CONFIG=false` is implemented in **code**. Do not add a settings-sync sidecar on this page.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | The three official keys above |
| Env schema | `env.example` | Comment the units and the archive exclusion |
| Docs | Open WebUI playbook | Point oversized corpora at MinIO, not a higher chat cap |
| Nginx | `client_max_body_size` | Leave it on the Stage 9 edge contract |
| Persistence | Stage 36 | Implement in code so the env pin survives Admin saves |

### Rules

1. **Official keys only.** Do not invent `TU_VM_UPLOAD_MAX`.
2. **Size unit is megabytes** in this image revision. `20` means 20 MiB.
3. **Do not chase a larger proxy.** Raising Nginx above `20m` is a Stage 9 change with a memory note.
4. **Archives stay off the chat allowlist.** Zip and tar remain a MinIO-processor concern.
5. **Empty allowlist means all types.** Do not "clear" the key to disable the check.
6. **Count is the chat composer.** Do not document knowledge-base uploads as count-limited unless a later image revision shows that check.
7. **GitHub remains intake.** A higher size or count names the workflow and the 2G container budget.

### Suggested contributor checklist

```text
1. Confirm the pinned image still treats unset RAG_FILE_MAX_SIZE and RAG_FILE_MAX_COUNT as None
2. Set the three keys on the open-webui service
3. Recreate Open WebUI
4. Confirm a chat file over 20 MiB is rejected in the composer
5. Confirm an extension outside the list is rejected by upload_file_handler
6. Leave Nginx client_max_body_size unchanged
7. If Admin → Documents already stored values, apply Stage 36 PersistentConfig in code or update the stored config on purpose
8. Do not add an upload gateway
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Size, count, extensions | Official RAG file keys | A custom upload filter |
| Edge body cap | Existing Nginx `20m` | Editing `client_max_body_size` here |
| Bulk documents | Existing MinIO + Tika processor | Stuffing archives through chat upload |
| Stored admin overrides | Stage 36 PersistentConfig code | A settings-sync service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: three Compose lines, an `env.example` comment, and an Open WebUI recreate.
3. Wider caps need an Issue before the numbers change.

## Acceptance criteria

- [ ] `open-webui` sets `RAG_FILE_MAX_SIZE=20`, `RAG_FILE_MAX_COUNT=10`, and a non-empty `RAG_ALLOWED_FILE_EXTENSIONS` list that excludes zip and tar.
- [ ] Nginx `client_max_body_size` on `oweb.tu.lan` is unchanged.
- [ ] No upload gateway or second ingest daemon is added.
- [ ] The page does not claim the knowledge-base screen enforces `RAG_FILE_MAX_COUNT` on this image revision.

## Rollback

Remove the three keys to restore unlimited size, unlimited count, and all extensions. That rollback is a reviewed Issue on a 2G container, not a silent default.

## Success metrics

- Chat upload rejects files above 20 MiB and extensions outside the list.
- The Open WebUI memory limit stays 2G.
