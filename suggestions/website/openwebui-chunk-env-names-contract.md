---
title: Open WebUI Chunk Env Names Contract
description: Constructional contract to replace dead RAG_CHUNK_SIZE and RAG_CHUNK_OVERLAP Compose keys with official CHUNK_SIZE and CHUNK_OVERLAP on the pinned Open WebUI image.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Chunk Env Names Contract

## Problem

`open-webui` Compose sets:

```text
RAG_CHUNK_SIZE: "1000"
RAG_CHUNK_OVERLAP: "200"
```

The pinned image (revision `02dc3e689ceac915a870b373318b99c029ddf603`) does not read those names. `backend/open_webui/config.py` defines:

| Official key | Unset behavior in that revision |
|---|---|
| `CHUNK_SIZE` | `1000` |
| `CHUNK_OVERLAP` | `100` |

A search of `backend/` in that revision finds no `RAG_CHUNK_SIZE` or `RAG_CHUNK_OVERLAP`. Size happens to match the image default, so the dead key looks harmless. Overlap does not: Compose asks for 200 and the process uses 100.

Both official keys are `ConfigVar`s. After the first successful start, Admin → Documents values stored in Postgres win over a later Compose edit unless Stage 36 `ENABLE_PERSISTENT_CONFIG=false` is implemented in **code**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `config.py` | `CHUNK_SIZE` default 1000, `CHUNK_OVERLAP` default 100 |
| `open-webui` environment | Dead `RAG_CHUNK_*` keys only |
| Stage 32 unofficial `WEBUI_*` honesty (expected sibling) | Different dead keys (`WEBUI_JWT_SECRET_KEY`, rate-limit names) |
| Stage 8 knowledge packs (expected sibling) | Catalog of what is ingested, not chunk arithmetic |
| Stage 36 PersistentConfig (expected sibling) | Stored admin values override env |
| GitHub Issues | Place to change 1000 / 200 |

Out of scope:

- A custom text splitter, embedding worker, or chunk database
- Changing `RAG_EMBEDDING_MODEL` or the Hugging Face cache volume (Stage 33)
- Stage 39 `RAG_FILE_MAX_SIZE` / count / extensions

## Proposal

On the `open-webui` service, remove `RAG_CHUNK_SIZE` and `RAG_CHUNK_OVERLAP`. Set the official keys to the numbers Compose already intended:

```text
CHUNK_SIZE: "1000"
CHUNK_OVERLAP: "200"
```

`1000` matches both the dead key and the image default. `200` is the overlap operators already wrote down; today it is ignored.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official keys; delete the `RAG_CHUNK_*` pair |
| Env schema | `env.example` | Comment that the image reads `CHUNK_*`, not `RAG_CHUNK_*` |
| Docs | Open WebUI playbook | One line: overlap is characters of neighboring chunks, not a second upload cap |
| Persistence | Stage 36 | Implement in code so the env pin survives Admin saves |

### Rules

1. **Official names only.** Do not keep `RAG_CHUNK_*` as aliases.
2. **Do not invent `TU_VM_CHUNK_SIZE`.**
3. **Overlap 200 is the existing intent**, not a new tuning project.
4. **ConfigVars stick.** A later Compose edit does nothing if Admin → Documents already saved chunk settings, until Stage 36 is in code.
5. **GitHub remains intake** for a different size or overlap.

### Suggested contributor checklist

```text
1. Confirm the pinned image still has no RAG_CHUNK_SIZE or RAG_CHUNK_OVERLAP reads under backend/
2. Replace the two Compose keys with CHUNK_SIZE=1000 and CHUNK_OVERLAP=200
3. Recreate Open WebUI
4. Confirm Admin → Documents shows size 1000 and overlap 200 on a database that has not stored older values
5. If those fields were already saved, apply Stage 36 in code or update the stored config on purpose
6. Do not add a splitter service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Chunk size and overlap | Official `CHUNK_*` ConfigVars | A preprocessing sidecar |
| Dead-key cleanup | Same pattern as Stage 32 `WEBUI_*` honesty | A new env linter product |
| Stored admin overrides | Stage 36 PersistentConfig code | A settings-sync service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: two Compose renames, an `env.example` comment, and an Open WebUI recreate.
3. Different numbers need an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `CHUNK_SIZE=1000` and `CHUNK_OVERLAP=200`.
- [ ] `RAG_CHUNK_SIZE` and `RAG_CHUNK_OVERLAP` are gone from Compose and `env.example`.
- [ ] No splitter sidecar is added.
- [ ] The page does not claim the dead keys were already applied.

## Rollback

Restore `RAG_CHUNK_*` only if a future image revision documents those names. On this revision, removing `CHUNK_*` returns overlap to 100.

## Success metrics

- A fresh Open WebUI config reports overlap 200.
- Contributors stop debugging `RAG_CHUNK_OVERLAP` as if the container honored it.
