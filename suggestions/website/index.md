---
title: Community Suggestions Website
description: Publishable Stage 40 community website markdown for Open WebUI chunk env names, the local-only OpenAI toggle, fetch-url length, active-user privacy, JWT expiry, n8n SSRF with a Compose mesh allow, and n8n runner payload size.
last_updated: 2026-09-24
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

**Stage 40** (this run) adds **community-hardening official-product-key contracts** that remained open after Stage 1–39 drafts and consolidation PRs (#23–#65). Each key was checked against the images pinned in `docker-compose.yml` on 2026-09-24:

- Open WebUI `ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e` (created 2026-06-02, revision `02dc3e689ceac915a870b373318b99c029ddf603`)
- n8n `n8nio/n8n@sha256:761374d4eb841b0a22771d6bd68f0e8d827b4979ae4e490045517b13fc1259dd` (image version `2.25.7`, created 2026-06-10)

The contracts:

- Replace dead Compose keys `RAG_CHUNK_SIZE` and `RAG_CHUNK_OVERLAP` with official `CHUNK_SIZE` and `CHUNK_OVERLAP` (the intended overlap of 200 is ignored today; the image default is 100)
- Pin official `ENABLE_OPENAI_API=false` so an empty base URL does not become `https://api.openai.com/v1` on model refresh (distinct from Stage 39 passthrough)
- Set official `WEB_FETCH_MAX_CONTENT_LENGTH=50000` for the built-in fetch-url tool, which otherwise has no character cap
- Pin official `ENABLE_PUBLIC_ACTIVE_USERS_COUNT=false` so the user menu and `/api/usage` stay admin-only
- Pin official `JWT_EXPIRES_IN=4w` and forbid `0` and `-1`, both of which disable expiry in this revision
- Enable official `N8N_SSRF_PROTECTION_ENABLED` with `N8N_SSRF_BLOCKED_IP_RANGES=default` and an allow for the Compose subnet `172.20.0.0/16`
- Cap official `N8N_RUNNERS_MAX_PAYLOAD` at 64 MiB (the image default is 1 GiB)

These are **constructional**: they tell contributors how to extend official Open WebUI and n8n keys without inventing a chunker, an OpenAI proxy, a fetch truncator, a presence service, a session store, an SSRF firewall, or a runner sandbox.

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
| Stage 23–39 website pages (open PRs #49–#65) | Compose, data-plane, and product-key contracts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 container log retention or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 timezone, Stage 30 `N8N_SECURE_COOKIE`, Stage 32 `ENABLE_SIGNUP` or unofficial `WEBUI_*` honesty, Stage 33 community-sharing or embedding cache volume, Stage 34 file jail / execution timeout, Stage 35 Scarf / version notifications, Stage 36 PersistentConfig / session cookies, Stage 37 code execution / direct connections, Stage 38 avatar forwarding / iframe CSP / `N8N_PAYLOAD_SIZE_MAX`, or Stage 39 RAG upload limits / passthrough / redirects / `N8N_FORMDATA_FILE_SIZE_MAX` / `NODES_EXCLUDE`.

`SAFE_MODE` is a recovery lever, not a standing default. `ENABLE_PLUGINS=false` hides Tools entirely — leave it alone unless an Issue asks for Tools off. Do not write `BYPASS_ADMIN_ACCESS_CONTROL`; official text says it is not a security boundary. Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials.

Stage 8 `rag-knowledge-contribution-contract.md` remains the knowledge-pack catalog. Stage 9 `nginx-edge-routing-contract.md` remains `client_max_body_size`. Stage 33 offline-embeddings remains the Hugging Face cache volume. Stage 34 execution timeout remains `EXECUTIONS_TIMEOUT`. Stage 36 `openwebui-persistent-config-honesty-contract.md` remains the ConfigVar persistence rule. Stage 39 passthrough remains `ENABLE_OPENAI_API_PASSTHROUGH`. Do not fold those into a new product.

## Page map (Stage 40)

| Page | Purpose |
|---|---|
| [Chunk env names](./openwebui-chunk-env-names-contract.md) | Official `CHUNK_SIZE` and `CHUNK_OVERLAP` |
| [OpenAI API toggle](./openwebui-openai-api-disabled-contract.md) | Official `ENABLE_OPENAI_API=false` |
| [Fetch URL length](./openwebui-web-fetch-length-contract.md) | Official `WEB_FETCH_MAX_CONTENT_LENGTH=50000` |
| [Active user count](./openwebui-public-active-users-contract.md) | Official `ENABLE_PUBLIC_ACTIVE_USERS_COUNT=false` |
| [JWT expiry](./openwebui-jwt-expiry-contract.md) | Official `JWT_EXPIRES_IN=4w`; never `0` or `-1` |
| [n8n SSRF mesh allow](./n8n-ssrf-mesh-allow-contract.md) | Official SSRF protection plus `172.20.0.0/16` |
| [n8n runner payload](./n8n-runners-max-payload-contract.md) | Official `N8N_RUNNERS_MAX_PAYLOAD` at 64 MiB |

## Expected sibling Stage 1–39 pages

When merged from open PRs #27–#65, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

| Stages | Representative contracts (filenames only) |
|---|---|
| 1–4 | `how-to-submit.md`, `status-board.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md` |
| 5–8 | Devcontainer, labels/board, secret rotation, `rag-knowledge-contribution-contract.md` |
| 9–12 | Nginx edge routing, helper/status contribution, host-port binding |
| 13–16 | Healthchecks, safe-update, Open WebUI init/Tika patch, backup drill |
| 17–20 | Hardening baseline (`no-new-privileges` **code**), IPv6 policy |
| 21–22 | Helper modules, journald (do not republish as a product) |
| 23–29 | Timezone, Tika DNS, n8n binary volume, Postgres shm |
| 30–32 | Proxy hops/cookies, `ENABLE_SIGNUP`, unofficial `WEBUI_*` honesty |
| 33–35 | Embedding cache volume, file jail, execution timeout, Scarf |
| 36–37 | PersistentConfig, session cookies, code execution, direct connections |
| 38–39 | Avatar forwarding, `N8N_PAYLOAD_SIZE_MAX`, RAG upload limits, OpenAI passthrough, `NODES_EXCLUDE` |

Extend `stage-merge-playbook.md` through **Stage 40** when reconciling hubs so sibling pages from PRs #27–#65 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| RAG chunking | Official `CHUNK_SIZE` / `CHUNK_OVERLAP` | A custom splitter sidecar |
| Local inference | Existing `OLLAMA_BASE_URL` | An OpenAI-compatible proxy |
| Fetch-url size | Official `WEB_FETCH_MAX_CONTENT_LENGTH` | A second truncating proxy |
| Presence | Official active-user flag left admin-only | A presence websocket service |
| Session lifetime | Official `JWT_EXPIRES_IN` | A custom session table |
| Workflow SSRF | Official n8n SSRF keys plus the Compose subnet | A filtering sidecar |
| Runner payloads | Official `N8N_RUNNERS_MAX_PAYLOAD` | A custom code-node sandbox |
| ConfigVar stickiness | Stage 36 PersistentConfig **code** | A settings-sync sidecar |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Document day-to-day → chunk names the image actually reads
3. Privacy surfaces → OpenAI toggle, active-user count, JWT expiry
4. Fetch budget → built-in URL tool character cap
5. n8n day-to-day limits → SSRF mesh allow, runner payload
6. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
