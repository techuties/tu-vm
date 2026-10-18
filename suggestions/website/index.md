---
title: Community Suggestions Website
description: Publishable Stage 58 website markdown for Tika OCR that the pinned image cannot run, a Redis memory cap equal to the container limit, and a dashboard font load that leaves the LAN.
last_updated: 2026-10-18
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#83 already specify the docs framework, governance, and most product contracts.

**Stage 58** (this run) records three defects checked on 2026-10-18 against the tree on `dev`. They are not restatements of Stages 1–57.

- The `tika` service pins the Apache image whose config history installs a JRE and not `tesseract-ocr`. `tika-config.xml` puts `900000` under `<ocr><timeout>`. Tika 3.3.1, the version in that image, applies `<server>` only and reads Tesseract's limit as `timeoutSeconds` (default 120). The processor still sends `X-Tika-PDFOcrStrategy: ocr_and_text_extraction`.
- Platform Redis sets `--maxmemory` to `256mb` and the Compose memory limit to `256M`. Redis 8.8.0 treats `mb` as `1024*1024`, which is the same byte count as Docker's `256M`. The default `client-query-buffer-limit` in that Redis release is 1GB.
- The landing page `@import`s `fonts.googleapis.com` for Outfit and JetBrains Mono. The font stacks already name `system-ui` and `monospace`. The HTTP-level Content-Security-Policy is not attached to this vhost, so the browser does request Google.

The contracts:

- Pin the official Tika **full** image for the same 3.3.1 line, and set `timeoutSeconds` on `TesseractOCRParser` inside the task cap that already works.
- Keep Redis `maxmemory` and `client-query-buffer-limit` under the existing 256M cgroup. Keep the password, eviction policy, and disabled persistence.
- Drop the Google Fonts `@import`. Keep the generic families already in the stylesheet.

No new OCR product, cache, or font service.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–57 website pages (open PRs #27–#83) | Implement those contracts in code; do not rewrite them here |
| `tika-config.xml` `<server><params><taskTimeoutMillis>` | The server task cap that Tika 3.3.1 does apply |
| Official `apache/tika:3.3.1.0-full` | The image line that already installs Tesseract |
| Redis `command` on the `redis` service | The process to keep; change two memory arguments |
| `font-family` fallbacks in `nginx/html/index.html` | The type stack to keep after the import is gone |

Do **not** republish Stage 57's Postgres GUCs, processor MinIO address, Pi-hole `DOMAIN` names, or `ufw status` parsing. Stage 50 (open PR #76) owns the processor client budget versus `taskTimeoutMillis`. This stage does not change those client numbers. Stage 19 (open PR #45) owns the rule that Tika changes stay in this XML file and this service. This stage names the property Tika 3.3.1 actually reads.

## Page map (Stage 58)

| Page | Purpose |
|---|---|
| [Tika OCR runtime](./tika-ocr-runtime-contract.md) | OCR uses the official full image and `timeoutSeconds`, not a no-op XML element on the minimal image |
| [Redis memory headroom](./redis-maxmemory-headroom-contract.md) | `maxmemory` and the client query cap sit below the 256M cgroup |
| [Landing font privacy](./landing-font-privacy-contract.md) | The dashboard does not load typefaces from Google |

## Expected sibling pages

Stages 1–57 live on open PRs #27–#83 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `tika-client-server-timeout-contract.md`, `tika-xml-config-contribution-contract.md`, `platform-redis-durability-contract.md`, `nginx-add-header-inheritance-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 58** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| OCR | Official Tika full image + the existing XML file | A second OCR container or a forked Tika image |
| Cache memory | `redis-server` flags already on the command | Redis Sentinel or a memory sidecar |
| Dashboard type | `system-ui` and `monospace` already in the CSS | A font CDN or a webfont build |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: document OCR that the pinned Tika image can actually run
3. Operator day-to-day: Redis eviction that the cgroup allows to run
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
