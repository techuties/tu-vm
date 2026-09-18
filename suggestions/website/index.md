---
title: Community Suggestions Website
description: Publishable Stage 34 community website markdown for n8n cloud templates off, n8n file-node jail, n8n community-package governance, n8n execution timeouts, Open WebUI CORS origin, Open WebUI API-key endpoint limits, and n8n personal-space sharing off—extending Stages 1–33 without reinventing frameworks or community intake.
last_updated: 2026-09-18
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

**Stage 34** (this run) adds **community-governance and day-to-day official-product-key contracts** that remained open after Stage 1–33 drafts and consolidation PRs (#23–#59):

- Turn off n8n's default workflow-template fetch from `api.n8n.io` (LAN-first community catalog later via official host override)
- Jail Read/Write File nodes to a dedicated volume with official `N8N_RESTRICT_FILE_ACCESS_TO`
- Govern community npm nodes with official package flags (disable by default; optional env-managed allowlist)
- Stop hung workflows with official `EXECUTIONS_TIMEOUT` / `EXECUTIONS_TIMEOUT_MAX` (runtime, not prune)
- Pin Open WebUI CORS to the `oweb.${DOMAIN}` origin instead of the implicit `*`
- Enable community API-key integrations with official endpoint restrictions (n8n / MCP day-to-day)
- Lock n8n personal-space publish/share off with official security-policy env keys

These are **constructional**: they tell contributors how to extend official n8n / Open WebUI keys without inventing a template CMS, a file-proxy sidecar, a private npm mirror product, a custom execution watchdog, a CORS microservice, a second API-gateway, or a share-catalog UI.

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
| Stage 33 website pages (open PR #59) | n8n env-block in Code, Git bare-repo, debug loopback ports, offline embeddings, executions prune, Ollama keep-alive, Open WebUI community-sharing |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 `container-log-retention-contract.md` or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 GUC/`-c` or host timezone, Stage 24 `HEALTH_CHECK_*` / `NGINX_WORKER_*`, Stage 26 Chromium shm / MCP restart honesty, Stage 29 Tika DNS / shm / REDISCLI_AUTH / n8n binary volume, Stage 30 FTLCONF / `MINIO_ROOT_USER` / leftover MCP DNS / n8n hops / probe binaries / Compose `name:` / n8n auth honesty, Stage 31 encryption-key / dead Postgres env / `WEBUI_URL` / DOMAIN public origin / dead env.example keys / helper DOMAIN / check-config coverage, Stage 32 nginx `server_name` / `ENABLE_SIGNUP` / n8n settings-file permissions / Qdrant API key / n8n runners / unofficial `WEBUI_*` / Browserless `TOKEN`, or Stage 33 n8n env-block / Git bare-repo / debug loopback ports / offline embeddings / executions prune / Ollama keep-alive / Open WebUI community-sharing.

Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials. Do not add a helper-MinIO page.

Stage 12 `host-port-binding-contract.md` remains the 53/80/443 conflict lane. Stage 19 `compose-native-profiles-contract.md` remains the Tier-array `profiles:` sync. Stage 6 `airgap-docs-mirror.md` remains the docs/image mirror. Stage 7 `tier2-idle-autostop-policy.md` remains container stop, not model unload. Do not rewrite those as template-host, file-jail, or timeout products.

## Page map (Stage 34)

| Page | Purpose |
|---|---|
| [n8n templates disabled](./n8n-templates-disabled-contract.md) | Official `N8N_TEMPLATES_ENABLED=false` (+ optional `N8N_TEMPLATES_HOST`) |
| [n8n restrict file access](./n8n-restrict-file-access-contract.md) | Official `N8N_RESTRICT_FILE_ACCESS_TO` + dedicated volume |
| [n8n community packages](./n8n-community-packages-contract.md) | Official package flags / optional env-managed allowlist |
| [n8n execution timeout](./n8n-execution-timeout-contract.md) | Official `EXECUTIONS_TIMEOUT` / `EXECUTIONS_TIMEOUT_MAX` |
| [Open WebUI CORS origin](./openwebui-cors-origin-contract.md) | Official `CORS_ALLOW_ORIGIN` from `DOMAIN` |
| [Open WebUI API key endpoints](./openwebui-api-keys-endpoint-contract.md) | Official `ENABLE_API_KEYS` + endpoint restrictions |
| [n8n personal-space sharing](./n8n-personal-space-sharing-contract.md) | Official personal-space publish/share off |

## Expected sibling Stage 1–33 pages

When merged from open PRs #27–#59, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

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
| 33 | `n8n-block-env-access-in-node-contract.md`, `n8n-executions-data-prune-contract.md`, `openwebui-community-sharing-contract.md` |

Extend `stage-merge-playbook.md` through **Stage 34** when reconciling hubs so sibling pages from PRs #27–#59 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| Workflow templates | Official `N8N_TEMPLATES_ENABLED` / `N8N_TEMPLATES_HOST` | A template CMS or scraper |
| File node jail | Official `N8N_RESTRICT_FILE_ACCESS_TO` | A file-proxy sidecar |
| Community npm nodes | Official package flags + env-managed allowlist | A private npm product |
| Hung workflows | Official `EXECUTIONS_TIMEOUT*` | A custom watchdog cron |
| Browser origins | Official `CORS_ALLOW_ORIGIN` | A CORS microservice |
| Programmatic chat | Official Open WebUI API keys + endpoint allowlist | A second API gateway |
| n8n share/publish | Official personal-space security-policy keys | A share-catalog UI |
| Chat privacy (Open WebUI) | Stage 33 `ENABLE_COMMUNITY_SHARING` **code** | Rewriting that page |
| Privilege drop | Stage 18 `no-new-privileges` **code** | Another hardening essay |
| Image CVEs / pins | Stage 4 Trivy + Stage 15 safe-update | Treating labels as supply-chain |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Day-to-day tools → n8n templates / file jail / packages / timeouts
3. Open WebUI CORS + API keys → Stage 31 `WEBUI_URL` / Stage 32 signup
4. n8n personal-space sharing → Stage 33 Open WebUI community-sharing
5. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
