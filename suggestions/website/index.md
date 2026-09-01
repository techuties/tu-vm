---
title: Community Suggestions Website
description: Publishable Stage 31 community website markdown for n8n encryption-key honesty, Open WebUI public URL, official Open WebUI env hygiene, MinIO public URL interpolation, helper status-probe DNS, leftover timezone literals, and Qdrant API key—extending Stages 1–30 without reinventing frameworks or community intake.
last_updated: 2026-09-01
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

**Stage 31** (this run) adds **encryption-key, public-URL, official-env, helper-DNS, leftover-timezone, and Qdrant-auth constructional contracts** that remained open after Stage 1–30 drafts and consolidation PRs (#23–#56):

- Official n8n `N8N_ENCRYPTION_KEY` without a public Compose hex default
- Official Open WebUI `WEBUI_URL` matching `https://oweb.tu.lan`
- Wire-or-delete leftover `WEBUI_*` keys the image does not read
- Interpolate `MINIO_SERVER_URL` / `MINIO_BROWSER_REDIRECT_URL` already listed in `env.example`
- Helper TCP probes on Compose service DNS (Stage 28–30 leftover cleanup applied to Python)
- n8n `GENERIC_TIMEZONE` and Pi-hole `TZ` via Stage 23 `TU_VM_TZ` instead of hardcoded Zurich
- Official Qdrant `QDRANT__SERVICE__API_KEY` plus Open WebUI `QDRANT_API_KEY`

These are **constructional**: they tell contributors how to extend official n8n / Open WebUI / MinIO / Qdrant / Compose keys and the GitHub-native community path without inventing a secrets-manager sidecar, an OAuth rewrite proxy, a rate-limit microservice, a MinIO URL rewriter, a service-discovery product, a chrony container, or a second vector database.

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
| Stage 23 website pages (open PR #49) | Snippets, ILM, read-only rootfs, GUCs, Qdrant memory, timezone policy, role networks |
| Stage 24 website pages (open PR #50) | Nginx worker env, Redis ACL, MinIO SSE, host sysctl, depends_on health, backup wrap, HEALTH_CHECK_* |
| Stage 25 website pages (open PR #51) | Stop grace, tini, non-root user, CHECK_INTERVAL, pids_limit, mem_swappiness, Tika /tika probe |
| Stage 26 website pages (open PR #52) | Chromium shm, n8n-mcp pin, MCP restart honesty, Tika/MinIO limits, processor tmpfs, datastore nofile, OOM order |
| Stage 27 website pages (open PR #53) | Helper pin, helper `/health`, CPU/IO shares, host `/tmp` isolation, docker GID, helper limits, socket-proxy |
| Stage 28 website pages (open PR #54) | pull_policy, leftover Tier 2 budgets, n8n healthz, x-* DRY, AFFiNE Redis auth, n8n Postgres DNS, include |
| Stage 29 website pages (open PR #55) | start_interval, Nginx tmpfs, n8n binary prune, labels, Open WebUI Tika DNS, Postgres shm, REDISCLI_AUTH |
| Stage 30 website pages (open PR #56) | Pi-hole FTLCONF, MinIO root user, leftover MCP DNS, n8n hops/cookies, probe binaries, Compose `name:`, n8n auth honesty |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

Do **not** republish Stage 11 `container-log-retention-contract.md` (Compose `logging` max-size) or Stage 22 `logging-driver-journald-contract.md` as a new logging product. Stage 18 `container-hardening-baseline-contract.md` already covers `security_opt: no-new-privileges` — implement that in **code**, do not write another page. Do **not** rewrite Stage 23 read-only policy or GUC essays, Stage 23 timezone **policy** (this stage only wires leftover literals), Stage 24 interval env keys, Stage 26 Chromium shm, Stage 26 MCP restart honesty, Stage 28 n8n Postgres DNS, Stage 29 start_interval / Nginx tmpfs / n8n binary / labels / Open WebUI Tika DNS / Postgres shm / REDISCLI_AUTH, or Stage 30 FTLCONF / MINIO_ROOT_USER / leftover MCP DNS / n8n proxy hops / healthcheck binaries / compose name / n8n auth honesty.

## Page map (Stage 31)

| Page | Purpose |
|---|---|
| [n8n encryption key honesty](./n8n-encryption-key-honesty-contract.md) | No public hex default for `N8N_ENCRYPTION_KEY` |
| [Open WebUI public URL](./openwebui-public-url-contract.md) | Official `WEBUI_URL` for `oweb.tu.lan` |
| [Open WebUI official env honesty](./openwebui-official-env-honesty-contract.md) | Wire or delete unused `WEBUI_*` keys |
| [MinIO public URL env](./minio-public-url-env-contract.md) | Interpolate console URL keys already in `env.example` |
| [Helper status probe DNS](./helper-status-probe-dns-contract.md) | TCP probes use service names; Docker API keeps `container_name` |
| [Leftover timezone literals](./leftover-timezone-literal-contract.md) | `TU_VM_TZ` for n8n and Pi-hole after Stage 23 |
| [Qdrant service API key](./qdrant-service-api-key-contract.md) | Official Qdrant + Open WebUI API key |

## Expected sibling Stage 1 pages

When merged from the Stage 1 website proposal, keep these as siblings (same folder, one content root later):

| Page | Purpose |
|---|---|
| `how-to-submit.md` | High-signal suggestion writing and dedupe checks |
| `status-board.md` | Curated projection of suggestion lifecycle |
| `day-to-day-community-tools.md` | Frameworks and commands that ease daily work |
| `mcp-tools-catalog.md` | Human contribution contract for optional MCP tool images |

## Expected sibling Stage 2 pages

| Page | Purpose |
|---|---|
| `hardware-compatibility-matrix.md` | Living host/RAM/GPU/storage fit artifact |
| `persona-entry-paths.md` | First-hour routes for operators and contributors |
| `operator-service-profiles.md` | Named Tier 1/Tier 2 profiles for resource control |

## Expected sibling Stage 3 pages

| Page | Purpose |
|---|---|
| `decision-log.md` | Accepted / deferred / declined rationale |
| `implemented-showcase.md` | Changelog-adjacent proof that community ideas shipped |
| `docs-framework-adoption.md` | Starlight-first adoption gates |
| `community-quality-gates.md` | Day-to-day evidence map |
| `extension-pilot-contract.md` | Compose-backed extension package shape |
| `hardware-class-intake.md` | Optional Issue-form `class_id` |

## Expected sibling Stage 4 pages

| Page | Purpose |
|---|---|
| `mcp-catalog-ci-contract.md` | `mcp-tools/catalog.yaml` schema + CI validation |
| `operator-profile-cli.md` | `tu-vm.sh profile` list/show/apply `--plan` |
| `extension-pilot-scaffold.md` | First `extensions/<id>/` package + validator |
| `supply-chain-community-gates.md` | Image CVE scans, severity gates, optional SBOM |
| `dashboard-modularization-smoke.md` | Extract Nginx assets + Playwright Tier-1 smoke |
| `stage-merge-playbook.md` | Reconcile Stage hubs without losing siblings |

## Expected sibling Stage 5–30 pages

Stages 5–30 remain on open PRs #31–#56. Treat those filenames as **expected siblings** (do not stub-duplicate them on this branch). The Stage 30 hub lists the full table. When merging, extend `stage-merge-playbook.md` through **Stage 31**.

## Expected sibling Stage 30 pages (PR #56)

| Page | Purpose |
|---|---|
| `pihole-v6-ftlconf-env-contract.md` | Official `FTLCONF_*` instead of v5 names |
| `minio-root-user-env-contract.md` | Interpolate `MINIO_ROOT_USER` |
| `leftover-mcp-service-dns-contract.md` | `n8n` / `affine` / `n8n_mcp` after Stage 28/29 |
| `n8n-proxy-hops-cookie-contract.md` | Official `N8N_PROXY_HOPS` + `N8N_SECURE_COOKIE` |
| `qdrant-minio-healthcheck-binary-contract.md` | Probes that exist in the pinned images |
| `compose-project-name-contract.md` | Top-level `name:` for stable project labels |
| `n8n-auth-env-honesty-contract.md` | `N8N_USER` / `N8N_PASSWORD` are gateway-only |

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| n8n credential crypto | Official `N8N_ENCRYPTION_KEY` + `generate-secrets` | Vault sidecar or a published hex default |
| Open WebUI public origin | Official `WEBUI_URL` | OAuth rewrite proxy |
| Open WebUI env hygiene | Upstream env list; wire or delete | Invented `WEBUI_RATE_LIMIT` |
| MinIO console URLs | Official `MINIO_SERVER_URL` from `.env` | Hardcoded `*.tu.lan` in Compose |
| Helper reachability | Compose service DNS | `ai_*` folklore in new TCP probes |
| Display timezone | Stage 23 `TU_VM_TZ` | A chrony container |
| Qdrant auth | Official API key on Qdrant + Open WebUI | A second vector DB |
| Privilege drop | Stage 18 `no-new-privileges` **code** | Another hardening essay |
| Postgres GUCs | Stage 23 `-c` flags | Another unused-env GUC essay |
| Image CVEs / pins | Stage 4 Trivy + Stage 15 safe-update | Treating labels as supply-chain |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Day-to-day tools → n8n encryption key / Open WebUI URL / official env hygiene
3. MinIO public URLs → helper probe DNS → leftover TZ → Qdrant API key
4. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

Extend `stage-merge-playbook.md` through **Stage 31** when reconciling hubs so sibling pages from PRs #27–#56 are not lost.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
