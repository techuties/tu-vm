---
title: Community Suggestions Website
description: Publishable Stage 59 website markdown for the Open WebUI PDF engine keys, a checkup that rewrites RAG config, and a Tika update track that follows 4.1.0 latest.
last_updated: 2026-10-25
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#84 already specify the docs framework, governance, and most product contracts.

**Stage 59** (this run) records three defects checked on 2026-10-25 against the tree on `dev` and against the pinned Open WebUI and Tika sources. They are not restatements of Stages 1–58.

- `scripts/switch-pdf-loader.sh` writes `rag.file.pdf_loader`, `rag.file.pdf_extract_images`, and a top-level `TIKA_SERVER_URL`. The Open WebUI revision in the pinned image reads `rag.CONTENT_EXTRACTION_ENGINE`, `rag.pdf_extract_images`, and `rag.tika_server_url`. Its non-Tika PDF path constructs `PyPDFLoader`. The file contains no `PyMuPDFLoader`. `scripts/init-openwebui.sh` searches for a `PyPDFLoader` snippet that is not in that revision.
- `scripts/daily-checkup.sh` `check_pipeline_integrity` runs an `UPDATE` on `config` when `rag.embedding_engine` is `"ollama"`, forcing the empty engine and `sentence-transformers/all-MiniLM-L6-v2`. That path is a real Open WebUI config key. Compose already sets those two values.
- `tu-vm.sh` `OFFICIAL_UPDATE_IMAGE_PAIRS` tracks `apache/tika:latest` for the `tika` service. On 2026-10-25 that tag is Tika 4.1.0 (index `sha256:fe2c6e3fca77b986ff3368107a20fa5060a3eefd03d14c12b45c0334626335d2`, created 2026-10-21). Its linux/amd64 history installs a JRE and `ca-certificates`. It does not install `tesseract-ocr`. The Compose pin is still the 3.3.1 index.

The contracts:

- Point the PDF switch at `CONTENT_EXTRACTION_ENGINE`. Keep image extraction off. Stop patching `loaders/main.py`.
- Delete the checkup `UPDATE` of the Open WebUI `config` row. Leave embedding choice on the Compose environment.
- Track `apache/tika:3.3.1.0-full` from the updater. Leave `apache/tika:latest` off the pair list.

No new PDF product, database migrator, or Tika fork.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–58 website pages (open PRs #27–#84) | Implement those contracts in code; do not rewrite them here |
| Compose `CONTENT_EXTRACTION_ENGINE: "tika"` and `TIKA_SERVER_URL` | The engine switch the pinned loader already honors |
| Compose `RAG_EMBEDDING_ENGINE` and `RAG_EMBEDDING_MODEL` | The embedding choice the checkup should leave alone |
| Stage 58 full-image pin (open PR #84) | The 3.3.1 line the updater should follow |

Do **not** republish Stage 58's Tika OCR property, Redis `maxmemory`, or the Google Fonts import. Stage 49 (open PR #75) owns wiring `init-openwebui.sh` as the entrypoint. This stage does not change that wiring. Stage 14 (open PR #40) owns the operator sequence for when to switch loaders. Stage 36 (open PR #62) owns `ENABLE_PERSISTENT_CONFIG`. Stage 53 (open PR #79) owns probe credentials. Stage 44 (open PR #70) owns digest comparison. This stage does not restate those.

## Page map (Stage 59)

| Page | Purpose |
|---|---|
| [Open WebUI PDF engine keys](./openwebui-pdf-engine-keys-contract.md) | The loader switch writes the config paths this image reads |
| [Checkup RAG config write](./checkup-rag-config-write-contract.md) | The daily checkup does not `UPDATE` the Open WebUI config row |
| [Tika update track](./tika-update-track-contract.md) | `./tu-vm.sh update` follows the 3.3.1 full tag, not Tika 4.1.0 `latest` |

## Expected sibling pages

Stages 1–58 live on open PRs #27–#84 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `openwebui-init-hook-unwired-contract.md`, `pdf-loader-switch-day2-contract.md`, `openwebui-persistent-config-honesty-contract.md`, `service-probe-credentials-contract.md`, `image-update-compare-contract.md`, `tika-ocr-runtime-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 59** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| PDF engine | `CONTENT_EXTRACTION_ENGINE` on the pinned Open WebUI | A source patch of `loaders/main.py` |
| Embeddings | Compose `RAG_EMBEDDING_*` | A nightly SQL rewrite of `config` |
| Tika upgrades | The 3.3.1 full tag named by Stage 58 | `apache/tika:latest` inside `tu-vm.sh update` |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: PDF extraction uses the engine key the running Open WebUI reads
3. Operator day-to-day: embedding settings survive the daily checkup
4. Maintainer day-to-day: Tika updates stay on the reviewed 3.3.1 line

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
