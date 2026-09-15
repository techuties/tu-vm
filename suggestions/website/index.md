---
title: Community Suggestions Website
description: Publishable Stage 31 community website markdown for n8n encryption-key honesty, dead Postgres env keys, Open WebUI WEBUI_URL, DOMAIN public origins, unused env.example knobs, helper DOMAIN wiring, and check-config secret coverage—extending Stages 1–30 without reinventing frameworks or community intake.
last_updated: 2026-09-15
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

**Stage 31** (this run) adds **env-honesty and public-origin constructional contracts** that remained open after Stage 1–30 drafts and consolidation PRs (#23–#56):

- Require a unique `N8N_ENCRYPTION_KEY` instead of the published Compose hex default
- Stop advertising `POSTGRES_SHARED_BUFFERS` and sibling keys as live container env (Stage 23 already owns real `-c` GUCs)
- Set official Open WebUI `WEBUI_URL` to the Nginx vhost
- Interpolate existing `DOMAIN` into n8n / AFFiNE / MinIO public URL env
- Mark or remove `env.example` knobs that no script or Compose service reads
- Pass `DOMAIN` into `helper_index` so `/status` links match the operator hostname
- Extend `check-config.sh --strict` to the same published defaults `generate-secrets` already knows

These are **constructional**: they tell contributors how to extend official n8n / Open WebUI / MinIO / Compose keys and the existing check-config script without inventing a secrets manager, a GUC sidecar, an OAuth proxy, a vhost templating product, a metrics stack, a helper URL microservice, or a second secret scanner.

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
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 `container-log-retention-contract.md` or Stage 22 journald as a new logging product. Stage 18 `no-new-privileges` — implement in **code**, do not write another page. Do **not** rewrite Stage 20 IPv6, Stage 23 GUC/`-c`, Stage 24 `HEALTH_CHECK_*` / `NGINX_WORKER_*`, Stage 29 Tika DNS / shm / REDISCLI_AUTH, or Stage 30 FTLCONF / `MINIO_ROOT_USER` / leftover MCP DNS / n8n hops / probe binaries / Compose `name:` / n8n auth honesty.

Helper `MINIO_*` leftovers were re-scanned this run: `helper/` has no MinIO credentials. Do not add a helper-MinIO page.

## Page map (Stage 31)

| Page | Purpose |
|---|---|
| [n8n encryption key honesty](./n8n-encryption-key-honesty-contract.md) | Require a unique key; drop the published Compose hex default |
| [Dead Postgres env honesty](./dead-postgres-env-honesty-contract.md) | Remove ignored `POSTGRES_*` GUC-shaped env; Stage 23 owns `-c` |
| [Open WebUI public URL](./openwebui-public-url-contract.md) | Official `WEBUI_URL` = Nginx oweb vhost |
| [Public origin DOMAIN](./public-origin-domain-contract.md) | Interpolate `DOMAIN` into n8n / AFFiNE / MinIO public URLs |
| [Env example dead keys](./env-example-dead-keys-contract.md) | Delete or mark knobs nothing consumes |
| [Helper DOMAIN wiring](./helper-domain-env-wiring-contract.md) | Pass `DOMAIN` into `helper_index` |
| [Check-config secret coverage](./check-config-secret-coverage-contract.md) | `--strict` flags published defaults `generate-secrets` already knows |

## Expected sibling Stage 1–30 pages

When merged from open PRs #27–#56, keep prior stage pages as siblings (same folder, one content root later). Do not stub-duplicate them on this branch.

| Stages | Representative contracts (filenames only) |
|---|---|
| 1–4 | `how-to-submit.md`, `status-board.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, supply-chain / dashboard smoke |
| 5–8 | Devcontainer, labels/board, secret rotation, env schema |
| 9–12 | Playbooks, helper/status contribution, env schema |
| 13–16 | Healthchecks, safe-update, backup drill |
| 17–20 | Hardening baseline (`no-new-privileges` **code**), IPv6 policy, nginx zones |
| 21–22 | Helper modules, journald (do not republish as a product), helper image bake |
| 23 | `postgres-statement-timeout-pooling-contract.md` (real GUCs), timezone, read-only, ILM |
| 24 | `nginx-worker-env-wiring-contract.md`, `healthcheck-interval-env-contract.md`, backup wrap |
| 25–27 | tini, Tika probe, helper pin/health/socket-proxy |
| 28–29 | n8n Postgres DNS, start_interval, Tika service DNS, postgres shm, REDISCLI_AUTH |
| 30 | `pihole-v6-ftlconf-env-contract.md`, `minio-root-user-env-contract.md`, `n8n-auth-env-honesty-contract.md` |

Extend `stage-merge-playbook.md` through **Stage 31** when reconciling hubs so sibling pages from PRs #27–#56 are not lost.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| n8n credential encryption | Official `N8N_ENCRYPTION_KEY` + `:?` + generate-secrets | Vault sidecar or a published Compose default |
| Postgres memory/connections | Stage 23 `postgres -c` | Dead `POSTGRES_SHARED_BUFFERS` env |
| Open WebUI origin | Official `WEBUI_URL` | localhost detection or an OAuth proxy |
| Custom hostname suffix | Existing `DOMAIN` | Per-service `*_DOMAIN` keys or Traefik |
| Dashboard service links | Helper `/status` + passed `DOMAIN` | `env_file: .env` on the helper |
| Unused example knobs | Delete or comment | Wiring a metrics stack to justify `ENABLE_METRICS` |
| Secret preflight | Existing `check-config.sh --strict` | A second scanner that prints values |
| Privilege drop | Stage 18 `no-new-privileges` **code** | Another hardening essay |
| Pi-hole / MinIO identity | Stage 30 `FTLCONF_*` / `${MINIO_ROOT_USER}` | Rewriting those pages |
| Image CVEs / pins | Stage 4 Trivy + Stage 15 safe-update | Treating labels as supply-chain |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Day-to-day tools → encryption-key honesty / check-config coverage
3. Public URL (`WEBUI_URL` + `DOMAIN`) → helper DOMAIN wiring
4. Dead env honesty → Stage 23 GUC implementation
5. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
