---
title: Community Suggestions Website
description: Publishable Stage 38 community website markdown for Open WebUI avatar redirects, artifact iframe CSP, pending user role, admin export, admin chat access, n8n metrics, and n8n payload size—extending Stages 1–37 without reinventing frameworks or community intake.
last_updated: 2026-09-22
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

**Stage 38** (this run) adds **community-hardening official-product-key contracts** that remained open after Stage 1–37 drafts and consolidation PRs (#23–#63):

- Stop Open WebUI profile-image endpoints from redirecting browsers to external avatar origins with official `ENABLE_PROFILE_IMAGE_URL_FORWARDING=false`
- Inject the official artifact iframe policy with `IFRAME_CSP` so generated HTML cannot open network connections
- Pin official `DEFAULT_USER_ROLE=pending` so new accounts wait for admin approval (Stage 32 still owns `ENABLE_SIGNUP`)
- Close the admin-panel bulk export surface with official `ENABLE_ADMIN_EXPORT=false`
- Close in-panel access to other users' chats with official `ENABLE_ADMIN_CHAT_ACCESS=false`
- Pin official `N8N_METRICS=false` so `/metrics` stays off the `n8n.tu.lan` vhost
- Pin official `N8N_PAYLOAD_SIZE_MAX=16` (MiB) so JSON bodies stay at the documented laptop-safe default

These are **constructional**: they tell contributors how to extend official Open WebUI and n8n keys without inventing an avatar proxy, an HTML sanitizer, an invitation service, an export portal, a moderation queue, a Prometheus stack, or a webhook buffering gateway.

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
| Stage 34 website pages (open PR #60) | n8n templates, file jail, community packages, execution timeout, Open WebUI CORS, API-key endpoints, n8n personal-space sharing |
| Stage 35 website pages (open PR #61) | Pi-hole published-password honesty, n8n MFA, concurrency, Scarf, version notifications, Open WebUI version-check, n8n Swagger UI |
| Stage 36 website pages (open PR #62) | n8n hiring / personalization / SameSite / usage page, Open WebUI Analytics / session cookies / PersistentConfig |
| Stage 37 website pages (open PR #63) | n8n onboarding tips, n8n Assistant module, Open WebUI code execution / interpreter / direct connections / password validation / pip frontmatter |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 `container-log-retention-contract.md` or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 timezone, Stage 30 `N8N_SECURE_COOKIE`, Stage 32 `ENABLE_SIGNUP`, Stage 33 community-sharing, Stage 34 CORS, Stage 35 Scarf / version notifications, Stage 36 Analytics / session cookies / PersistentConfig / n8n personalization, or Stage 37 onboarding / Assistant / code execution / interpreter / direct connections / password validation / pip frontmatter.

`SAFE_MODE` is a recovery lever, not a standing default. `ENABLE_PLUGINS=false` hides Tools entirely — leave it alone unless an Issue asks for Tools off. Helper `MINIO_*` leftovers were re-scanned on Stage 31: `helper/` has no MinIO credentials. Do not add a helper-MinIO page.

Stage 19 `prometheus-exporter-opt-in-contract.md` remains the platform scrape decision. Stage 9 `nginx-edge-routing-contract.md` remains `client_max_body_size`. Stage 29 binary-data volume remains large n8n files. Do not rewrite those as metrics or payload products.

## Page map (Stage 38)

| Page | Purpose |
|---|---|
| [Profile image forwarding](./openwebui-profile-image-url-forwarding-contract.md) | Official `ENABLE_PROFILE_IMAGE_URL_FORWARDING=false` |
| [Artifact iframe CSP](./openwebui-iframe-csp-contract.md) | Official `IFRAME_CSP` example policy |
| [Default user role](./openwebui-default-user-role-contract.md) | Official `DEFAULT_USER_ROLE=pending` |
| [Admin export](./openwebui-admin-export-contract.md) | Official `ENABLE_ADMIN_EXPORT=false` |
| [Admin chat access](./openwebui-admin-chat-access-contract.md) | Official `ENABLE_ADMIN_CHAT_ACCESS=false` |
| [n8n metrics](./n8n-metrics-disabled-contract.md) | Official `N8N_METRICS=false` |
| [n8n payload size](./n8n-payload-size-max-contract.md) | Official `N8N_PAYLOAD_SIZE_MAX=16` |

## Expected sibling Stage 1–37 pages

When merged from open PRs #27–#63, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

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
| 30 | `pihole-v6-ftlconf-env-contract.md`, `n8n-proxy-hops-cookie-contract.md`, `n8n-auth-env-honesty-contract.md` |
| 31 | `n8n-encryption-key-honesty-contract.md`, `public-origin-domain-contract.md`, `check-config-secret-coverage-contract.md` |
| 32 | `nginx-server-name-domain-contract.md`, `openwebui-signup-first-user-contract.md`, `qdrant-api-key-contract.md` |
| 33 | `n8n-block-env-access-in-node-contract.md`, `n8n-executions-data-prune-contract.md`, `openwebui-community-sharing-contract.md` |
| 34 | `n8n-templates-disabled-contract.md`, `n8n-restrict-file-access-contract.md`, `n8n-execution-timeout-contract.md`, `n8n-personal-space-sharing-contract.md` |
| 35 | `pihole-published-password-honesty-contract.md`, `n8n-mfa-enforced-contract.md`, `openwebui-scarf-analytics-contract.md`, `n8n-public-api-swagger-disabled-contract.md` |
| 36 | `n8n-hiring-banner-contract.md`, `n8n-personalization-contract.md`, `n8n-samesite-cookie-contract.md`, `openwebui-persistent-config-honesty-contract.md` |
| 37 | `n8n-onboarding-flow-disabled-contract.md`, `n8n-instance-ai-disabled-contract.md`, `openwebui-code-execution-contract.md`, `openwebui-password-validation-contract.md` |

Extend `stage-merge-playbook.md` through **Stage 38** when reconciling hubs so sibling pages from PRs #27–#63 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| External avatars | Official `ENABLE_PROFILE_IMAGE_URL_FORWARDING` | An avatar proxy |
| Artifact network | Official `IFRAME_CSP` | A sanitizer sidecar |
| New accounts | Official `DEFAULT_USER_ROLE=pending` plus Stage 32 signup | An invitation service |
| Admin export | Official `ENABLE_ADMIN_EXPORT` | A download portal |
| Admin chat browse | Official `ENABLE_ADMIN_CHAT_ACCESS` | A moderation queue |
| n8n `/metrics` | Official `N8N_METRICS=false` | A public scrape on `n8n.tu.lan` |
| JSON body cap | Official `N8N_PAYLOAD_SIZE_MAX=16` | A webhook buffering proxy |
| Env vs Admin UI | Stage 36 PersistentConfig **code** for ConfigVar keys | A settings-sync sidecar |
| Privilege drop | Stage 18 `no-new-privileges` **code** | Another hardening essay |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Account gate → pending role, with signup owned by Stage 32
3. Privacy surfaces → avatar redirects, admin export, admin chat access
4. Artifact previews → iframe CSP
5. n8n day-to-day limits → metrics off, 16 MiB JSON cap
6. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
