---
title: Open WebUI PDF Engine Keys Contract
description: Constructional contract so the PDF loader switch writes the config paths the pinned Open WebUI reads, and the init script stops searching for a loader snippet that revision does not contain.
last_updated: 2026-10-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI PDF Engine Keys Contract

## Problem

The day-to-day PDF switch edits a config shape this Open WebUI build does not load.

`docker-compose.yml` pins:

```text
ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e
```

That image is git revision `02dc3e689ceac915a870b373318b99c029ddf603`. In that revision, `ConfigVar` paths for documents are:

| Env already set in Compose | Config path the process reads |
|---|---|
| `CONTENT_EXTRACTION_ENGINE` | `rag.CONTENT_EXTRACTION_ENGINE` |
| `TIKA_SERVER_URL` | `rag.tika_server_url` |
| `PDF_EXTRACT_IMAGES` | `rag.pdf_extract_images` |

`Loader._get_loader` selects Tika only when `self.engine == 'tika'` and `TIKA_SERVER_URL` is set. The `else` branch for a PDF constructs `PyPDFLoader` with `PDF_EXTRACT_IMAGES` and `PDF_LOADER_MODE`. A search of `retrieval/loaders/main.py` at that revision finds `PyPDFLoader` and no `PyMuPDFLoader`.

`scripts/switch-pdf-loader.sh` does something else. Both branches `UPDATE` `config` where `id = 1`:

| Script value | JSON path it writes |
|---|---|
| `tika` | `rag.file.pdf_loader` = `TikaLoader`, `rag.file.pdf_extract_images` = `true`, top-level `TIKA_SERVER_URL` |
| `pymupdf` | `rag.file.pdf_loader` = `PyMuPDFLoader`, `rag.file.pdf_extract_images` = `false` |

The `SELECT` prints `rag.file.pdf_loader`. None of those paths are in the table above. A successful run stores keys the process never reads, and the `tika` branch tries to turn image extraction on. Compose sets `PDF_EXTRACT_IMAGES: "false"` because image extraction caused reshape errors.

`scripts/init-openwebui.sh` looks for this exact snippet before it will patch the file:

```text
loader = PyPDFLoader(
    file_path, extract_images=self.kwargs.get("PDF_EXTRACT_IMAGES")
)
```

Checked on 2026-10-25 against `main.py` at revision `02dc3e689`: that snippet is absent (`old_snippet_present` false). The PDF branch there also passes `mode=self.kwargs.get('PDF_LOADER_MODE', 'page')`. The script then prints that it could not find the section and exits 0. Wiring the script as an entrypoint, which Stage 49 owns, still would not change loader behavior.

Compose already sets `CONTENT_EXTRACTION_ENGINE: "tika"` and `TIKA_SERVER_URL: "http://ai_tika:9998"`. That is the switch the pinned loader implements. The community does not need a second PDF stack or a fork of Open WebUI.

Checked by reading Compose, both scripts, and the loader and `config.py` at the pinned revision. No container was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `CONTENT_EXTRACTION_ENGINE` / `TIKA_SERVER_URL` / `PDF_EXTRACT_IMAGES` | Compose values the pinned process already accepts |
| `scripts/switch-pdf-loader.sh` | Operator command to keep. Change the keys it writes |
| `scripts/init-openwebui.sh` | Wrapper Stage 49 may exec. Remove the source search |
| Stage 14 loader playbook (open PR #40) | When an operator runs the switch. Leave that sequence in place |
| Stage 49 entrypoint (open PR #75) | How the init script is invoked. This page does not add `entrypoint:` |
| Stage 36 persistent config (open PR #62) | Whether a saved DB value overrides env. This page does not set that flag |

Out of scope:

- A PyMuPDF package, a custom loader image, or a hosted OCR API
- Rewriting `tika-config.xml` (Stage 19 and Stage 58)
- Adding `entrypoint:` on the Open WebUI service (Stage 49)
- Setting `ENABLE_PERSISTENT_CONFIG` (Stage 36)
- Teaching this script the Postgres password (Stage 53)

## Proposal

Make `tika` and `pymupdf` set the engine string this revision branches on. Stop editing `loaders/main.py`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Engine | `.env` and Compose | Interpolate `CONTENT_EXTRACTION_ENGINE: ${CONTENT_EXTRACTION_ENGINE:-tika}` |
| Switch | `switch-pdf-loader.sh` | `tika` writes `tika`. `pymupdf` writes an empty string. Keep those two CLI words so the Stage 14 playbook still runs |
| Images | Same script | Leave `PDF_EXTRACT_IMAGES` false. The `tika` branch must not set extraction to true |
| URL | Compose | Keep `TIKA_SERVER_URL=http://ai_tika:9998`. Do not add a top-level `TIKA_SERVER_URL` key in the JSON blob |
| Init script | `init-openwebui.sh` | Delete the `PyPDFLoader` search and the replacement block. Keep `exec "$@"` so Stage 49's entrypoint still starts `bash start.sh` |
| Apply | Switch script | Restart `open-webui` after the env change, which the script already does |

If Stage 36 has not landed and a saved row already overrides env, one SQL write is enough, at the paths the process reads:

```text
rag.CONTENT_EXTRACTION_ENGINE = tika | ""
rag.pdf_extract_images = false
```

Use the row `ConfigState.load` uses (highest `id`), not a hard-coded `id = 1`, and only when that override is still required. The durable writer is the environment variable.

The script's echo text should say the non-Tika path is `PyPDFLoader` in this revision. The CLI word can stay `pymupdf` so existing playbook steps do not change.

### Rules

1. **Write `rag.CONTENT_EXTRACTION_ENGINE`.** `TikaLoader` and `PyMuPDFLoader` are not values this loader compares.
2. **Keep image extraction false.** Compose already documents the reshape failure.
3. **Leave the loader file unmodified.** The snippet the init script searches for is not in revision `02dc3e689`.
4. **Keep the Stage 14 command names.** `./scripts/switch-pdf-loader.sh tika|pymupdf` stays the operator entry.
5. **Leave entrypoint wiring on Stage 49.** This change only removes the patch body.

### Suggested contributor checklist

```text
1. Confirm switch-pdf-loader.sh no longer writes rag.file.pdf_loader
2. Confirm tika sets CONTENT_EXTRACTION_ENGINE=tika and pymupdf sets it empty
3. Confirm PDF_EXTRACT_IMAGES stays false for both branches
4. Confirm init-openwebui.sh has no PyPDFLoader search and still execs "$@"
5. After restart, a PDF upload uses Tika when the engine is tika
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Engine choice | `CONTENT_EXTRACTION_ENGINE` | A patched `loaders/main.py` |
| Tika URL | Compose `TIKA_SERVER_URL` | A new top-level JSON key |
| Light PDF path | Empty engine, which selects `PyPDFLoader` | A PyMuPDF install |
| Operator steps | Stage 14 playbook | A second switch command |
| Intake | GitHub Issue | A document-engine sidecar |
