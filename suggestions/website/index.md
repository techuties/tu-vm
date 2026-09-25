---
title: Community Suggestions Website
description: Publishable Stage 41 community website markdown for Open WebUI tool-call and HTTP-client limits, the SQLAlchemy pool, n8n execution save mode, the document watcher page size and attempt cap, and anonymous knowledge-base reads.
last_updated: 2026-09-25
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, smoke/pre-push gates, Compose IPAM, local tar backup, and digest-pinned images). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 41** (this run) adds **community-hardening contracts** that remained open after Stage 1–40 drafts and consolidation PRs (#23–#66). Each fact was checked on 2026-09-25 against the tree on `dev` and the images pinned in `docker-compose.yml`:

- Open WebUI `ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e` (created 2026-06-02, revision `02dc3e689ceac915a870b373318b99c029ddf603`, `sqlalchemy==2.0.48`, `aiohttp==3.13.5`)
- n8n `n8nio/n8n@sha256:761374d4eb841b0a22771d6bd68f0e8d827b4979ae4e490045517b13fc1259dd` (image version `2.25.7`)
- `tika-minio-processor/universal_auto_processor.py` and `mcp-gateway/app.py` in this repository

The contracts:

- Pin official `CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS=8` (this revision defaults to 256; `-1` removes the cap)
- Pin official `AIOHTTP_CLIENT_TIMEOUT=600` (unset becomes `None`, which is no total timeout on Ollama and OpenAI routes)
- Pin official `DATABASE_POOL_SIZE=5` and `DATABASE_POOL_MAX_OVERFLOW=2` so the overflow value is actually applied (today the size is unset, so SQLAlchemy defaults apply and the overflow of `0` is ignored)
- Pin official n8n execution save keys and keep `EXECUTIONS_DATA_SAVE_ON_PROGRESS=false`
- Teach the MinIO watcher to follow `ContinuationToken`, reusing the loop already in `get_processing_stats`
- Set `PROCESSOR_MAX_FILE_ATTEMPTS=5` and apply that cap on the exception path (Compose `0` means unlimited, and exceptions ignore a finite cap)
- Default `KB_PUBLIC_READ_ENABLED=false` so `https://oweb.tu.lan/api/mcp/` requires `MCP_GATEWAY_TOKEN` for knowledge-base reads

These are **constructional**: they tell contributors how to extend official Open WebUI and n8n keys, and how to finish two loops that already exist in TU-VM code, without inventing a tool-call watchdog, an HTTP proxy, a connection pooler, an execution archive, a queue, or a second knowledge-base auth system.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting path |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–22 website pages (open PRs #27–#48) | Contracts and living artifacts—implement, do not rewrite |
| Stage 23–40 website pages (open PRs #49–#66) | Compose, data-plane, and product-key contracts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 container log retention or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 timezone or server-side Postgres GUCs / PgBouncer, Stage 29 n8n binary volume, Stage 30 `N8N_SECURE_COOKIE`, Stage 32 `ENABLE_SIGNUP`, Stage 33 execution **prune** or embedding cache, Stage 34 `EXECUTIONS_TIMEOUT`, Stage 36 PersistentConfig, Stage 38 `N8N_PAYLOAD_SIZE_MAX`, Stage 39 OpenAI passthrough / aiohttp **redirects** / RAG upload limits, or Stage 40 chunk names / `ENABLE_OPENAI_API` / fetch length / active-user count / `JWT_EXPIRES_IN` / SSRF mesh allow / runner payload.

`SAFE_MODE` is a recovery lever, not a standing default. `ENABLE_PLUGINS=false` hides Tools entirely — leave it alone unless an Issue asks for Tools off. Do not write `BYPASS_ADMIN_ACCESS_CONTROL`; official text says it is not a security boundary. Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials.

Stage 33 `n8n-executions-data-prune-contract.md` remains retention (`EXECUTIONS_DATA_PRUNE*`). This stage only decides **what is saved**. Stage 39 `openwebui-aiohttp-redirects-contract.md` remains `AIOHTTP_CLIENT_ALLOW_REDIRECTS`. This stage only sets the **total timeout**. Stage 23 pooling remains optional PgBouncer. This stage only sets the Open WebUI SQLAlchemy pool.

## Page map (Stage 41)

| Page | Purpose |
|---|---|
| [Tool-call iterations](./openwebui-tool-call-iteration-contract.md) | Official cap of 8; never `-1` |
| [HTTP client timeout](./openwebui-aiohttp-client-timeout-contract.md) | Official `AIOHTTP_CLIENT_TIMEOUT=600` |
| [Database pool](./openwebui-db-pool-contract.md) | Official SQLAlchemy pool size and overflow |
| [n8n execution save mode](./n8n-execution-save-mode-contract.md) | Official save keys; progress stays false |
| [Watcher page size](./processor-object-list-pagination-contract.md) | Reuse the existing ContinuationToken loop |
| [Watcher attempt cap](./processor-file-attempt-cap-contract.md) | Finite attempts, including exceptions |
| [Knowledge-base public read](./kb-public-read-default-contract.md) | Anonymous reads off unless opted in |

## Expected sibling Stage 1–40 pages

When merged from open PRs #27–#66, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

| Stages | Representative contracts (filenames only) |
|---|---|
| 1–4 | `how-to-submit.md`, `status-board.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md` |
| 5–8 | Devcontainer, labels/board, secret rotation, `rag-knowledge-contribution-contract.md` |
| 9–12 | Nginx edge routing, helper/status contribution, host-port binding |
| 13–16 | Healthchecks, safe-update, Open WebUI init/Tika patch, backup drill |
| 17–20 | Hardening baseline (`no-new-privileges` **code**), IPv6 policy |
| 21–22 | Helper modules, journald (do not republish as a product) |
| 23–29 | Timezone, Tika DNS, n8n binary volume, Postgres shm, PgBouncer opt-in |
| 30–32 | Proxy hops/cookies, `ENABLE_SIGNUP`, unofficial `WEBUI_*` honesty |
| 33–35 | Embedding cache volume, execution prune, execution timeout, Scarf |
| 36–37 | PersistentConfig, session cookies, code execution, direct connections |
| 38–40 | Avatar forwarding, payload size, RAG limits, chunk names, JWT, SSRF, runner payload |

Extend `stage-merge-playbook.md` through **Stage 41** when reconciling hubs so sibling pages from PRs #27–#66 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| Tool-call loops | Official `CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS` | A custom loop watchdog |
| Upstream HTTP time | Official `AIOHTTP_CLIENT_TIMEOUT` | A timing proxy in front of Ollama |
| DB connections | Official `DATABASE_POOL_*` | A new pooler (Stage 23 PgBouncer stays opt-in) |
| Execution history | Official `EXECUTIONS_DATA_SAVE_*` plus Stage 33 prune | A custom archive service |
| Bucket listing | Existing `get_processing_stats` token loop | A queue or search index |
| Failed documents | Existing `PROCESSOR_MAX_FILE_ATTEMPTS` | Deleting source objects |
| Knowledge reads | Existing `MCP_GATEWAY_TOKEN` | A second auth gateway |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Chat day-to-day → tool-call cap and HTTP client timeout
3. Database day-to-day → Open WebUI pool budget
4. Workflow day-to-day → what n8n saves, beside Stage 33 prune
5. Document day-to-day → full bucket pages and a finite retry cap
6. Community knowledge → public-read opt-in
7. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
