---
title: Community Suggestions Website
description: Publishable Stage 32 community website markdown for Nginx DOMAIN server_name, Open WebUI signup honesty, n8n settings-file permissions, Qdrant API key, n8n official task runners, unofficial Open WebUI Compose env, and Browserless token requirement—extending Stages 1–31 without reinventing frameworks or community intake.
last_updated: 2026-09-16
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

**Stage 32** (this run) adds **edge-hostname and official-product-key constructional contracts** that remained open after Stage 1–31 drafts and consolidation PRs (#23–#57):

- Rewrite Nginx `server_name` when operators change existing `DOMAIN` (Stage 31 deferred this)
- Set official Open WebUI `ENABLE_SIGNUP` after first-admin bootstrap (distinct from the Tika init patch)
- Turn on official n8n `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS`
- Give Qdrant an API key and pass the same key to Open WebUI
- Enable official n8n task runners (`N8N_RUNNERS_ENABLED`) instead of a custom worker fleet
- Stop advertising unofficial Open WebUI Compose keys that the image may ignore
- Require `BROWSERLESS_TOKEN` so the Chromium sidecar is not anonymous on the compose network

These are **constructional**: they tell contributors how to extend official Nginx / Open WebUI / n8n / Qdrant / Browserless keys and the existing `tu-vm.sh` cert/DNS helpers without inventing a Traefik control plane, an SSO portal, a Vault sidecar, a Qdrant operator chart, a Justfile-shaped n8n runner, a Flask rate-limiter, or a host Chrome farm.

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
| Stage 23 website pages (open PR #49) | Snippets, ILM, read-only rootfs, GUCs, Qdrant memory, timezone, role networks |
| Stage 24 website pages (open PR #50) | Nginx worker env, Redis ACL, MinIO SSE, host sysctl, depends_on health, backup wrap, HEALTH_CHECK_* |
| Stage 25 website pages (open PR #51) | Stop grace, tini, non-root user, CHECK_INTERVAL, pids_limit, mem_swappiness, Tika /tika probe |
| Stage 26 website pages (open PR #52) | Chromium shm, n8n-mcp pin, MCP restart honesty, Tika/MinIO limits, processor tmpfs, datastore nofile, OOM order |
| Stage 27 website pages (open PR #53) | Helper pin, helper `/health`, CPU/IO shares, host `/tmp` isolation, docker GID, helper limits, socket-proxy |
| Stage 28 website pages (open PR #54) | pull_policy, leftover Tier 2 budgets, n8n healthz, x-* DRY, AFFiNE Redis auth, n8n Postgres DNS, include |
| Stage 29 website pages (open PR #55) | start_interval, Nginx tmpfs, n8n binary prune, labels, Open WebUI Tika DNS, Postgres shm, REDISCLI_AUTH |
| Stage 30 website pages (open PR #56) | Pi-hole FTLCONF, MinIO root user, leftover MCP DNS, n8n hops/cookies, healthcheck binaries, Compose `name:`, n8n auth honesty |
| Stage 31 website pages (open PR #57) | n8n encryption-key honesty, dead Postgres env, WEBUI_URL, DOMAIN public origins, dead env.example keys, helper DOMAIN, check-config coverage |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 `container-log-retention-contract.md` or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 GUC/`-c` or host timezone, Stage 24 `HEALTH_CHECK_*` / `NGINX_WORKER_*`, Stage 26 Chromium shm / MCP restart honesty, Stage 29 Tika DNS / shm / REDISCLI_AUTH, Stage 30 FTLCONF / `MINIO_ROOT_USER` / leftover MCP DNS / n8n hops / probe binaries / Compose `name:` / n8n auth honesty, or Stage 31 encryption-key / dead Postgres env / `WEBUI_URL` / DOMAIN public origin / dead env.example keys / helper DOMAIN / check-config coverage.

Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials. Do not add a helper-MinIO page.

Stage 12 `host-port-binding-contract.md` remains the 53/80/443 conflict lane. Stage 5 `task-runner-wrapper.md` remains the optional Justfile/`make` facade. Do not rewrite those as n8n runners or debug-port products.

## Page map (Stage 32)

| Page | Purpose |
|---|---|
| [Nginx DOMAIN server_name](./nginx-server-name-domain-contract.md) | Rewrite static `*.tu.lan` vhosts when `DOMAIN` changes |
| [Open WebUI signup / first user](./openwebui-signup-first-user-contract.md) | Official `ENABLE_SIGNUP` after first admin |
| [n8n settings-file permissions](./n8n-settings-file-permissions-contract.md) | Official `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` |
| [Qdrant API key](./qdrant-api-key-contract.md) | Official Qdrant + Open WebUI API key pair |
| [n8n official task runners](./n8n-runners-enabled-contract.md) | `N8N_RUNNERS_ENABLED` — not a Justfile control plane |
| [Open WebUI Compose env honesty](./openwebui-compose-env-honesty-contract.md) | Drop unofficial `WEBUI_*` keys the image may ignore |
| [Browserless token required](./browserless-token-required-contract.md) | Empty `TOKEN` must not leave Chromium anonymous |

## Expected sibling Stage 1–31 pages

When merged from open PRs #27–#57, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

| Stages | Representative contracts (filenames only) |
|---|---|
| 1–4 | `how-to-submit.md`, `status-board.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, supply-chain / dashboard smoke |
| 5–8 | Devcontainer, labels/board, Justfile wrapper, secret rotation, env schema |
| 9–12 | Playbooks, helper/status contribution, host-port binding, Nginx edge routing |
| 13–16 | Healthchecks, safe-update, Open WebUI init/Tika patch, backup drill |
| 17–20 | Hardening baseline (`no-new-privileges` **code**), IPv6 policy, nginx zones |
| 21–22 | Helper modules, journald (do not republish as a product), helper image bake |
| 23 | `postgres-statement-timeout-pooling-contract.md` (real GUCs), timezone, read-only, ILM |
| 24 | `nginx-worker-env-wiring-contract.md`, `healthcheck-interval-env-contract.md`, backup wrap |
| 25–27 | tini, Tika probe, helper pin/health/socket-proxy |
| 28–29 | n8n Postgres DNS, start_interval, Tika service DNS, postgres shm, REDISCLI_AUTH |
| 30 | `pihole-v6-ftlconf-env-contract.md`, `minio-root-user-env-contract.md`, `n8n-auth-env-honesty-contract.md` |
| 31 | `n8n-encryption-key-honesty-contract.md`, `public-origin-domain-contract.md`, `check-config-secret-coverage-contract.md` |

Extend `stage-merge-playbook.md` through **Stage 32** when reconciling hubs so sibling pages from PRs #27–#57 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| Custom hostname suffix | Existing `DOMAIN` + `tu-vm.sh` cert/DNS helpers | Traefik/Caddy or a `render-vhosts` daemon |
| First Open WebUI admin | Official `ENABLE_SIGNUP` / first-user docs | Baking users into a forked image |
| n8n config file mode | Official `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | A custom chmod sidecar |
| Qdrant auth | Official `QDRANT__SERVICE__API_KEY` + `QDRANT_API_KEY` | An extra auth proxy in front of 6333 |
| n8n isolated JS | Official n8n task runners | A second `just`/`make` worker product |
| Open WebUI secrets | Official `WEBUI_SECRET_KEY` | Unofficial `WEBUI_JWT_*` / rate-limit env |
| Headless browser auth | Existing `BROWSERLESS_TOKEN` required interpolation | Host Chrome or an open TOKEN |
| Privilege drop | Stage 18 `no-new-privileges` **code** | Another hardening essay |
| Public app origins | Stage 31 `DOMAIN` + `WEBUI_URL` **code** | Rewriting those pages |
| Image CVEs / pins | Stage 4 Trivy + Stage 15 safe-update | Treating labels as supply-chain |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Day-to-day tools → signup honesty / Browserless token / n8n permissions
3. Public hostname (`DOMAIN` + Nginx `server_name`) → Stage 31 app-origin interpolation
4. Qdrant API key → Open WebUI vector settings
5. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
