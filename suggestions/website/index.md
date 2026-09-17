---
title: Community Suggestions Website
description: Publishable Stage 33 community website markdown for n8n env-block in Code nodes, n8n Git bare-repo disable, opt-in debug loopback ports, Open WebUI offline embeddings, n8n execution prune, Ollama keep-alive unload, and Open WebUI community-sharing off—extending Stages 1–32 without reinventing frameworks or community intake.
last_updated: 2026-09-17
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

**Stage 33** (this run) adds **official-product-key and host-debug-port constructional contracts** that remained open after Stage 1–32 drafts and consolidation PRs (#23–#58):

- Block n8n Code nodes from reading process environment (DB password, encryption key)
- Disable n8n Git-node bare repositories (official security switch)
- Make localhost debug publishes (8080 / 9000 / 9001 / 8081) opt-in so they do not silently bypass Nginx
- Keep Open WebUI sentence-transformer embeddings on a named volume and allow true offline mode
- Prune n8n execution history with official keys so `n8n_data` does not grow forever
- Unload idle Ollama models with official keep-alive / max-loaded keys (container stays up)
- Turn off official Open WebUI community sharing so private chats are not offered to a public catalog

These are **constructional**: they tell contributors how to extend official n8n / Open WebUI / Ollama / Compose keys without inventing a workflow sandbox VM, a Git-proxy sidecar, a second Traefik debug router, a HuggingFace download daemon, a custom execution janitor, an Ollama operator chart, or a community-share CMS.

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
| Stage 32 website pages (open PR #58) | Nginx DOMAIN server_name, ENABLE_SIGNUP, n8n settings-file permissions, Qdrant API key, n8n runners, unofficial WEBUI_* env, Browserless TOKEN |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 `container-log-retention-contract.md` or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 GUC/`-c` or host timezone, Stage 24 `HEALTH_CHECK_*` / `NGINX_WORKER_*`, Stage 26 Chromium shm / MCP restart honesty, Stage 29 Tika DNS / shm / REDISCLI_AUTH / n8n binary volume, Stage 30 FTLCONF / `MINIO_ROOT_USER` / leftover MCP DNS / n8n hops / probe binaries / Compose `name:` / n8n auth honesty, Stage 31 encryption-key / dead Postgres env / `WEBUI_URL` / DOMAIN public origin / dead env.example keys / helper DOMAIN / check-config coverage, or Stage 32 nginx `server_name` / `ENABLE_SIGNUP` / n8n settings-file permissions / Qdrant API key / n8n runners / unofficial `WEBUI_*` / Browserless `TOKEN`.

Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials. Do not add a helper-MinIO page.

Stage 12 `host-port-binding-contract.md` remains the 53/80/443 conflict lane. Stage 19 `compose-native-profiles-contract.md` remains the Tier-array `profiles:` sync. Stage 6 `airgap-docs-mirror.md` remains the docs/image mirror. Stage 7 `tier2-idle-autostop-policy.md` remains container stop, not model unload. Do not rewrite those as debug-port, HuggingFace, or Ollama-unload products.

## Page map (Stage 33)

| Page | Purpose |
|---|---|
| [n8n block env in Code nodes](./n8n-block-env-access-in-node-contract.md) | Official `N8N_BLOCK_ENV_ACCESS_IN_NODE` |
| [n8n Git bare-repo disable](./n8n-git-node-bare-repos-contract.md) | Official `N8N_GIT_NODE_DISABLE_BARE_REPOS` |
| [Debug loopback publish opt-in](./debug-loopback-publish-opt-in-contract.md) | Optional 127.0.0.1:8080/9000/9001/8081 |
| [Open WebUI offline embeddings](./openwebui-offline-embeddings-contract.md) | HF cache volume + official offline flags |
| [n8n executions prune](./n8n-executions-data-prune-contract.md) | Official `EXECUTIONS_DATA_PRUNE*` keys |
| [Ollama keep-alive unload](./ollama-keep-alive-unload-contract.md) | Official `OLLAMA_KEEP_ALIVE` / max loaded |
| [Open WebUI community sharing](./openwebui-community-sharing-contract.md) | Official `ENABLE_COMMUNITY_SHARING=false` |

## Expected sibling Stage 1–32 pages

When merged from open PRs #27–#58, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

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
| 28–29 | n8n Postgres DNS, start_interval, Tika service DNS, postgres shm, REDISCLI_AUTH, n8n binary volume |
| 30 | `pihole-v6-ftlconf-env-contract.md`, `minio-root-user-env-contract.md`, `n8n-auth-env-honesty-contract.md` |
| 31 | `n8n-encryption-key-honesty-contract.md`, `public-origin-domain-contract.md`, `check-config-secret-coverage-contract.md` |
| 32 | `nginx-server-name-domain-contract.md`, `openwebui-signup-first-user-contract.md`, `qdrant-api-key-contract.md` |

Extend `stage-merge-playbook.md` through **Stage 33** when reconciling hubs so sibling pages from PRs #27–#58 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| n8n secret leak via Code | Official `N8N_BLOCK_ENV_ACCESS_IN_NODE` | A workflow VM or env-redacting proxy |
| n8n Git node risk | Official `N8N_GIT_NODE_DISABLE_BARE_REPOS` | A Git-proxy sidecar |
| Host debug ports | Compose profile / empty-port interpolation | A second reverse-proxy product |
| Offline embeddings | Official HF/Transformers offline flags + volume | A HuggingFace download daemon |
| n8n disk growth | Official `EXECUTIONS_DATA_PRUNE*` | A custom execution janitor cron |
| Idle GPU/RAM | Official Ollama keep-alive keys | An Ollama operator / second autostop |
| Chat privacy | Official `ENABLE_COMMUNITY_SHARING` | A share-catalog microservice |
| Privilege drop | Stage 18 `no-new-privileges` **code** | Another hardening essay |
| Public app origins | Stage 31 `DOMAIN` + `WEBUI_URL` **code** | Rewriting those pages |
| Image CVEs / pins | Stage 4 Trivy + Stage 15 safe-update | Treating labels as supply-chain |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Day-to-day tools → n8n env-block / Git bare-repo / execution prune
3. Debug loopback ports → Stage 12 host-port 53/80/443
4. Offline embeddings + community-sharing off → Stage 6 airgap docs
5. Ollama keep-alive → Stage 7 idle container autostop
6. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
