---
title: Community Suggestions Website
description: Publishable Stage 39 community website markdown for Open WebUI upload limits, inline avatar size, outbound identity headers, OpenAI passthrough, redirect following, n8n form-data size, and the n8n node exclude list—extending Stages 1–38 without reinventing frameworks or community intake.
last_updated: 2026-09-23
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

**Stage 39** (this run) adds **community-hardening official-product-key contracts** that remained open after Stage 1–38 drafts and consolidation PRs (#23–#64). Each key was checked against the images pinned in `docker-compose.yml` on 2026-09-23:

- Open WebUI `ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e` (created 2026-06-02, revision `02dc3e689ceac915a870b373318b99c029ddf603`)
- n8n `n8nio/n8n@sha256:761374d4eb841b0a22771d6bd68f0e8d827b4979ae4e490045517b13fc1259dd` (image version `2.25.7`, created 2026-06-10)

The contracts:

- Set official `RAG_FILE_MAX_SIZE`, `RAG_FILE_MAX_COUNT`, and `RAG_ALLOWED_FILE_EXTENSIONS`, which that Open WebUI revision leaves unlimited
- Cap inline avatars with official `PROFILE_IMAGE_MAX_DATA_URI_SIZE` (distinct from Stage 38 URL forwarding)
- Pin official `ENABLE_FORWARD_USER_INFO_HEADERS=false`, `ENABLE_OPENAI_API_PASSTHROUGH=false`, and `AIOHTTP_CLIENT_ALLOW_REDIRECTS=false` (all already the code default in the pinned image)
- Pin official `N8N_FORMDATA_FILE_SIZE_MAX=200` (distinct from Stage 38 JSON payload)
- Pin the n8n `2.25.7` `NODES_EXCLUDE` array so Execute Command and Local File Trigger stay unloaded

These are **constructional**: they tell contributors how to extend official Open WebUI and n8n keys without inventing an upload gateway, an avatar store, a header filter, an API proxy, a redirect firewall, a webhook buffer, or a custom node blocklist service.

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
| Stage 23–38 website pages (open PRs #49–#64) | Compose, data-plane, and product-key contracts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 container log retention or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 timezone, Stage 30 `N8N_SECURE_COOKIE`, Stage 32 `ENABLE_SIGNUP`, Stage 33 community-sharing, Stage 34 file jail / execution timeout, Stage 35 Scarf / version notifications, Stage 36 PersistentConfig / Analytics / session cookies, Stage 37 code execution / interpreter / direct connections, or Stage 38 avatar forwarding / iframe CSP / pending role / admin export / admin chat access / `N8N_METRICS` / `N8N_PAYLOAD_SIZE_MAX`.

`SAFE_MODE` is a recovery lever, not a standing default. `ENABLE_PLUGINS=false` hides Tools entirely — leave it alone unless an Issue asks for Tools off. Do not write `BYPASS_ADMIN_ACCESS_CONTROL`; official text says it is not a security boundary. Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials.

Stage 8 `rag-knowledge-contribution-contract.md` remains the knowledge-pack catalog. Stage 9 `nginx-edge-routing-contract.md` remains `client_max_body_size`. Stage 29 binary-data volume remains large n8n files. Stage 36 `openwebui-persistent-config-honesty-contract.md` remains the ConfigVar persistence rule. Do not fold those into a new product.

## Page map (Stage 39)

| Page | Purpose |
|---|---|
| [RAG upload limits](./openwebui-rag-upload-limits-contract.md) | Official size, count, and extension keys |
| [Profile image data URI size](./openwebui-profile-image-data-uri-size-contract.md) | Official `PROFILE_IMAGE_MAX_DATA_URI_SIZE` |
| [Forward user info headers](./openwebui-forward-user-info-headers-contract.md) | Official `ENABLE_FORWARD_USER_INFO_HEADERS=false` |
| [OpenAI API passthrough](./openwebui-openai-api-passthrough-contract.md) | Official `ENABLE_OPENAI_API_PASSTHROUGH=false` |
| [Outbound redirect following](./openwebui-aiohttp-redirects-contract.md) | Official `AIOHTTP_CLIENT_ALLOW_REDIRECTS=false` |
| [n8n form-data file size](./n8n-formdata-file-size-contract.md) | Official `N8N_FORMDATA_FILE_SIZE_MAX=200` |
| [n8n node exclude list](./n8n-nodes-exclude-contract.md) | Official `NODES_EXCLUDE` default array |

## Expected sibling Stage 1–38 pages

When merged from open PRs #27–#64, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

| Stages | Representative contracts (filenames only) |
|---|---|
| 1–4 | `how-to-submit.md`, `status-board.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md` |
| 5–8 | Devcontainer, labels/board, secret rotation, `rag-knowledge-contribution-contract.md` |
| 9–12 | Nginx edge routing, helper/status contribution, host-port binding |
| 13–16 | Healthchecks, safe-update, Open WebUI init/Tika patch, backup drill |
| 17–20 | Hardening baseline (`no-new-privileges` **code**), IPv6 policy |
| 21–22 | Helper modules, journald (do not republish as a product) |
| 23–29 | Timezone, Tika DNS, n8n binary volume, Postgres shm |
| 30–32 | Proxy hops/cookies, `ENABLE_SIGNUP`, Qdrant API key |
| 33–35 | Community sharing, file jail, execution timeout, Scarf, Swagger UI |
| 36–37 | PersistentConfig, session cookies, code execution, direct connections |
| 38 | `openwebui-profile-image-url-forwarding-contract.md`, `openwebui-iframe-csp-contract.md`, `n8n-payload-size-max-contract.md`, `n8n-metrics-disabled-contract.md` |

Extend `stage-merge-playbook.md` through **Stage 39** when reconciling hubs so sibling pages from PRs #27–#64 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| Upload caps | Official RAG file keys + existing Nginx `20m` | A new upload gateway |
| Inline avatars | Official `PROFILE_IMAGE_MAX_DATA_URI_SIZE` | An avatar object store |
| External avatar URLs | Stage 38 forwarding flag | A second avatar page |
| User identity on tools | Official forward-headers flag left `false` | A header-stripping proxy |
| OpenAI catch-all | Official passthrough flag left `false` | A custom API gateway |
| Redirect SSRF | Official aiohttp flag left `false` | A redirect firewall |
| Form-data files | Official `N8N_FORMDATA_FILE_SIZE_MAX=200` | Raising Stage 38 JSON payload |
| Dangerous nodes | Official `NODES_EXCLUDE` JSON array | A node-policy microservice |
| ConfigVar stickiness | Stage 36 PersistentConfig **code** | A settings-sync sidecar |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Document day-to-day → RAG size, count, and extensions
3. Privacy surfaces → inline avatar bytes, forwarded identity headers
4. Outbound safety → passthrough off, redirects off
5. n8n day-to-day limits → form-data size, excluded nodes
6. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
