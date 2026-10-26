---
title: Community Suggestions Website
description: Publishable Stage 60 website markdown for a dead Open WebUI metadata flag, a Tika /meta call that receives CSV, and unpinned images in the upload sync.
last_updated: 2026-10-26
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#85 already specify the docs framework, governance, and most product contracts.

**Stage 60** (this run) records three defects checked on 2026-10-26 against the tree on `dev`, the pinned Open WebUI revision, and Apache Tika 3.3.1. They are not restatements of Stages 1–59.

- `docker-compose.yml` sets `TIKA_METADATA_EXTRACTION: "true"` on `open-webui`. A search of Open WebUI revision `02dc3e689ceac915a870b373318b99c029ddf603` finds no such name. `TikaLoader.load` reads `X-TIKA:content` from the `/tika/text` JSON body and returns a `Document` whose metadata is only the request headers plus `Content-Type`.
- `tika-minio-processor/universal_processor.py` `PUT`s the file to `/meta` with `Content-Type` and no `Accept`. `requests` 2.32.5 then sends `Accept: */*`. Tika 3.3.1 `MetadataResource` produces `text/csv` and `application/json`, and the 3.3.1 server README shows `curl -T file http://localhost:9998/meta` as CSV. `response.json()` fails, the exception is swallowed, and the stored object has no `extracted-metadata`.
- `scripts/sync-openwebui-minio.sh` lists the upload volume with `alpine:latest` and runs untagged `minio/mc` (Docker tag `latest`) three times. Compose pins service images by digest. Those two references are outside that pin list.

The contracts:

- Delete the unread metadata flag. Leave the Open WebUI loader file alone. Keep document metadata on the processor path.
- Send `Accept: application/json` on the processor `/meta` call. Do not put that JSON on the object until the Stage 54 header budget is in the same change.
- Stop pulling `alpine:latest`. List the volume with the pinned Open WebUI image. Pin `minio/mc` the same way Compose pins `minio/minio`.

No metadata database, Tika fork, or second sync service.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–59 website pages (open PRs #27–#85) | Implement those contracts in code; do not rewrite them here |
| `TikaLoader` in the pinned Open WebUI image | Text extraction the community already selected |
| `universal_processor.py` `/meta` call | The metadata store this stack owns |
| `scripts/sync-openwebui-minio.sh` | The cron sync to keep |

Do **not** republish Stage 59's PDF engine keys, checkup `UPDATE`, or Tika `:latest` update pair. Stage 58 (open PR #84) owns `tika-config.xml` and the full Tika image. Stage 54 (open PR #80) owns the encoded S3 user-metadata length. Stage 46 (open PR #72) owns `MC_HOST_local` and `--network host`. Stage 44 (open PR #70) owns digest comparison for Compose `image:` lines. This stage does not restate those.

## Page map (Stage 60)

| Page | Purpose |
|---|---|
| [Open WebUI Tika metadata flag](./openwebui-tika-metadata-flag-contract.md) | The Compose flag is unread; the loader keeps text, not a metadata record |
| [Processor meta Accept](./processor-meta-accept-contract.md) | `/meta` is asked for JSON, so the CSV default is not parsed as an object |
| [Sync client image pin](./sync-client-image-pin-contract.md) | The upload sync does not pull `alpine:latest` or untagged `minio/mc` |

## Expected sibling pages

Stages 1–59 live on open PRs #27–#85 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `openwebui-pdf-engine-keys-contract.md`, `tika-ocr-runtime-contract.md`, `processor-metadata-header-contract.md`, `minio-mc-client-transport-contract.md`, `image-update-compare-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 60** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Chat-upload text | Pinned Open WebUI `TikaLoader` | A patched `loaders/main.py` |
| Document metadata | Processor `/meta` with `Accept: application/json` | A metadata sidecar |
| Upload sync images | The pinned Open WebUI image and a pinned `minio/mc` | `alpine:latest` and untagged `minio/mc` |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: Open WebUI metadata claims match the keys the pinned image reads
3. Operator day-to-day: processed objects can carry Tika metadata that was actually JSON
4. Maintainer day-to-day: the sync cron uses images this repo already pins

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
