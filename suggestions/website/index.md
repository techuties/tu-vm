---
title: Community Suggestions Website
description: Publishable Stage 42 community website markdown for the helper control allowlist, Nginx header inheritance, document byte budgets, and MCP build and listener honesty.
last_updated: 2026-09-26
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

**Stage 42** (this run) adds **community-hardening contracts** that remained open after Stage 1–41 drafts and consolidation PRs (#23–#67). Each fact was checked on 2026-09-26 against the tree on `dev`:

- `helper/uploader.py` `control_service` sends unknown service names to the Docker Engine API
- `nginx/nginx.conf` and `nginx/conf.d/default.conf` rely on `add_header`, which does not inherit once a child block sets its own header
- `tika-minio-processor/universal_processor.py` reads whole objects and whole archive members into memory
- `mcp-tools/*/Dockerfile` and `mcp-gateway/Dockerfile` install floating package tags
- `mcp-gateway/app.py` falls back to `npx` plus a package name that is not the npm bin
- supergateway `4.0.0` README documents `--oauth2Bearer` for outbound calls, not as an inbound listener lock

The contracts:

- Reject helper control names that are not in the existing service map, after the existing token check
- Repeat the headers a server block already declares inside locations that set their own `add_header`
- Cap watcher downloads with `PROCESSOR_MAX_OBJECT_BYTES` (proposed default `67108864`) before `Body.read()`
- Cap archive expansion with member, byte, and ratio limits before `ZipFile.read` / `extractfile`
- Pin MCP build inputs to the registry versions recorded on 2026-09-26
- Keep MCP tool listeners off host ports, and do not treat supergateway's outbound bearer flag as inbound auth
- Align the AFFiNE MCP command fallback with the package bin `affine-mcp`

These are **constructional**: they tell contributors how to finish checks and pins that already exist in TU-VM, without inventing an orchestrator, a WAF, a malware sandbox, or a second MCP gateway.

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
| Stage 23–41 website pages (open PRs #49–#67) | Compose, data-plane, and product-key contracts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 container log retention or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 18 helper token auth, Stage 18 MCP sandbox shape, Stage 26 MCP `restart:` honesty, Stage 32 Qdrant API key, Stage 36 PersistentConfig, or Stage 41 tool-call, HTTP timeout, SQLAlchemy pool, n8n save mode, watcher pagination, attempt cap, or `KB_PUBLIC_READ_ENABLED`.

`SAFE_MODE` is a recovery lever, not a standing default. `ENABLE_PLUGINS=false` hides Tools entirely. Do not write `BYPASS_ADMIN_ACCESS_CONTROL`. Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials.

Stage 18 `helper-control-auth-contract.md` remains the token and 401 behavior. This stage only closes the **name fallthrough**. Stage 12 `nginx-edge-routing-contract.md` remains "keep Nginx." This stage only fixes **header inheritance**. Stage 41 owns watcher paging and attempt caps. This stage only bounds **bytes**.

## Page map (Stage 42)

| Page | Purpose |
|---|---|
| [Helper control allowlist](./helper-control-service-allowlist-contract.md) | Unknown names never reach the Docker API |
| [Nginx header inheritance](./nginx-add-header-inheritance-contract.md) | Locations keep the headers their server block already sets |
| [Watcher object budget](./processor-object-byte-budget-contract.md) | Stop `Body.read()` before the 512M limit |
| [Archive expansion budget](./processor-archive-expansion-budget-contract.md) | Cap members, uncompressed bytes, and ratio |
| [MCP build pins](./mcp-tool-build-pin-contract.md) | Replace `@latest` with recorded versions |
| [MCP listener honesty](./mcp-tool-listener-auth-contract.md) | No host ports, no fake inbound bearer |
| [AFFiNE MCP command fallback](./affine-mcp-command-fallback-contract.md) | Code default matches bin `affine-mcp` |

## Expected sibling Stage 1–41 pages

When merged from open PRs #27–#67, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

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
| 38–41 | Avatar forwarding, payload size, RAG limits, chunk names, JWT, SSRF, tool-call cap, pool, save mode, public KB read |

Extend `stage-merge-playbook.md` through **Stage 42** when reconciling hubs so sibling pages from PRs #27–#67 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | A second orchestrator or SSO |
| Control names | Existing `name_map` in `uploader.py` | Passing the URL segment to Docker |
| Edge headers | Nginx `include` of the headers already in the server block | `headers-more`, a WAF, or a new proxy |
| Document size | Env cap before `Body.read()` | A queue or ClamAV sidecar |
| Archive safety | `ZipInfo.file_size` / tar `member.size` before read | Extract-to-disk sandbox |
| MCP installs | Pinned npm/pip in the existing Dockerfiles | Runtime `npx -y` |
| MCP reachability | Existing `MCP_GATEWAY_TOKEN` on the gateway | A fake supergateway inbound flag |
| AFFiNE MCP | Preinstalled bin `affine-mcp` | A second AFFiNE image |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Control day-to-day → token (Stage 18) then service allowlist
3. Edge day-to-day → header inheritance beside the existing Nginx vhosts
4. Document day-to-day → object budget and archive budget beside Stage 41 paging
5. Tool day-to-day → build pins, listener honesty, AFFiNE command fallback
6. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
