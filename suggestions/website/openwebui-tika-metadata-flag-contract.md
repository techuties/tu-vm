---
title: Open WebUI Tika Metadata Flag Contract
description: Constructional contract to remove the unread TIKA_METADATA_EXTRACTION Compose flag and keep document metadata on the processor, without patching the pinned Open WebUI loader.
last_updated: 2026-10-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Tika Metadata Flag Contract

## Problem

Open WebUI Compose tells operators that metadata extraction is switched on:

```text
CONTENT_EXTRACTION_ENGINE: "tika"
TIKA_SERVER_URL: "http://ai_tika:9998"
PDF_EXTRACT_IMAGES: "false"
TIKA_METADATA_EXTRACTION: "true"
```

The comment above the last key is "Enable Tika metadata extraction". The pinned image does not read that name.

`docker-compose.yml` pins:

```text
ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e
```

That image is git revision `02dc3e689ceac915a870b373318b99c029ddf603`. A search of that revision finds `CONTENT_EXTRACTION_ENGINE`, `TIKA_SERVER_URL`, and `PDF_EXTRACT_IMAGES`. It finds no `TIKA_METADATA_EXTRACTION`.

`TikaLoader.load` in `backend/open_webui/retrieval/loaders/main.py` at that revision does this:

```text
endpoint += 'tika/text'
r = requests.put(endpoint, data=data, headers=headers)
raw_metadata = r.json()
text = raw_metadata.get('X-TIKA:content', '<No text content found>').strip()
if 'Content-Type' in raw_metadata:
    headers['Content-Type'] = raw_metadata['Content-Type']
return [Document(page_content=text, metadata=headers)]
```

`headers` starts empty unless `mime_type` was passed. The call site that builds `TikaLoader` passes `url`, `file_path`, and `extract_images`. It does not pass `mime_type`. The `Document` therefore keeps page text and, at most, `Content-Type`. Title, creator, and page count are in the JSON body and are dropped.

Apache Tika 3.3.1 `TikaResource` maps `PUT /tika/{handler}` with `@Produces("application/json")` onto metadata that includes `X-TIKA:content`. `/tika/text` is that JSON method. The loader is right to call it for text. The Compose flag does not change the call.

Checked on 2026-10-26 by reading Compose, `TikaLoader`, and `git grep` of revision `02dc3e689`. No container was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `CONTENT_EXTRACTION_ENGINE` and `TIKA_SERVER_URL` | The engine switch this revision actually branches on |
| `TikaLoader.load` | Text extraction to keep. Do not edit it in this repo |
| `tika-minio-processor` `/meta` call | The metadata path this stack owns |
| Stage 59 PDF engine keys (open PR #85) | Which config paths the loader reads. This page does not write `rag.file.pdf_loader` |
| Stage 59 init script (same PR) | Deletes the `PyPDFLoader` search. This page does not add a metadata patch there |
| Stage 58 OCR runtime (open PR #84) | Tika image and `tika-config.xml`. Unchanged here |
| Processor meta Accept (this stage) | How `/meta` becomes a JSON object |

Out of scope:

- A fork or bind-mount of `loaders/main.py`
- A metadata database, search index, or second Tika container
- Changing `PDF_EXTRACT_IMAGES` (Stage 59 keeps it false)
- Rewriting `tika-config.xml` (Stage 58)
- Teaching Compose a new `TU_VM_TIKA_METADATA` name

## Proposal

Remove the flag that this image ignores. Keep chat-upload text on the pinned loader. Keep author, title, and similar fields on the processor, which already calls `/meta`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Delete `TIKA_METADATA_EXTRACTION` and the comment that says it enables metadata |
| Docs | Operator note beside the Tika env block | Say this revision stores `X-TIKA:content` in the Open WebUI document and does not keep the rest of the Tika JSON |
| Processor | `universal_processor.py` | Metadata work stays on the `/meta` call covered by the Accept contract in this stage |
| Init script | `scripts/init-openwebui.sh` | Do not add a metadata patch. Stage 59 already removes the loader search |

### Rules

1. **Delete `TIKA_METADATA_EXTRACTION`.** Revision `02dc3e689` has no reader for it.
2. **Do not patch `TikaLoader`.** Stage 59 leaves `loaders/main.py` unmodified. A local patch would drift on the next image bump.
3. **Text stays on `/tika/text`.** That path is the JSON handler Tika 3.3.1 uses for `X-TIKA:content`.
4. **Metadata stays on the processor.** The community-owned code is `universal_processor.py`, not the upstream loader.
5. **Leave OCR and the PDF engine keys on Stages 58 and 59.**

### Suggested contributor checklist

```text
1. Confirm TIKA_METADATA_EXTRACTION is absent from open-webui environment
2. Confirm init-openwebui.sh does not write a metadata patch into loaders/main.py
3. Confirm CONTENT_EXTRACTION_ENGINE and TIKA_SERVER_URL are unchanged
4. Confirm PDF_EXTRACT_IMAGES stays false
5. Confirm a PDF upload still uses Tika for text after the flag is removed
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| PDF and office text | Pinned `TikaLoader` and `CONTENT_EXTRACTION_ENGINE` | A custom loader image |
| Document metadata | Existing processor `/meta` call | A new metadata service |
| Config honesty | Delete the unread key | A second flag with a TU-VM name |
| Upstream drift | The digest pin | A bind-mounted `main.py` |
| Intake | GitHub Issue | A forked Open WebUI |
