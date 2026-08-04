---
title: Community Suggestions Website
description: Publishable Stage 11 community website markdown for network-bridge, host-ops, and autonomous-ops day-to-day contracts that extend Stages 1–10 without reinventing frameworks or community intake.
last_updated: 2026-08-04
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, Open WebUI, MCP gateway, LangGraph supervisor, n8n, browserless, Pi-hole + Tailscale DNS sync, host cron maintenance, sudoers examples). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 11** (this run) adds **network-bridge, host-ops, and autonomous-ops community contracts** that remained open after Stage 1–10 drafts and consolidation PRs (#23–#36):

- Tailscale LAN bridge contract (dual-stack `*.tu.lan`, not Pi-hole blocklist hygiene)
- Host cron maintenance contract (checkup / weekly update / MinIO sync)
- Browserless automation contribution contract
- Workflow Operator contribution contract
- Autonomous write-guard policy (operator-facing confirm / circuit-breaker day-to-day)
- Container log retention contract
- Privileged host-ops contract (sudoers, disk extend, host-level safety)

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–10 website pages (open PRs #27–#36) | Contracts and living artifacts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 11)

| Page | Purpose |
|---|---|
| [Tailscale LAN bridge contract](./tailscale-lan-bridge-contract.md) | Optional Tailscale dual-stack access using existing `sync-dns` |
| [Host cron maintenance contract](./host-cron-maintenance-contract.md) | Safe community path for checkup / update / MinIO sync crons |
| [Browserless automation contribution](./browserless-automation-contribution-contract.md) | Browserless + Playwright MCP contribution and ops rules |
| [Workflow Operator contribution](./workflow-operator-contribution-contract.md) | Open WebUI Workflow Operator / autonomous n8n engineering lane |
| [Autonomous write-guard policy](./autonomous-write-guard-policy.md) | Day-to-day confirm, rate-limit, and circuit-breaker operator policy |
| [Container log retention contract](./container-log-retention-contract.md) | Local log growth hygiene without a logging SaaS |
| [Privileged host-ops contract](./privileged-host-ops-contract.md) | Sudoers, disk extend, and host privilege contribution rules |

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

## Expected sibling Stage 5 pages

| Page | Purpose |
|---|---|
| `devcontainer-contributor-environment.md` | Repeatable Codespaces/Dev Containers setup |
| `compose-ci-live-profile.md` | Minimal Compose profile for live `/status/full` |
| `playbook-version-matrix.md` | Release-aware notes for operator playbooks |
| `community-label-and-board-contract.md` | GitHub labels + Projects as the OS |
| `community-health-digest.md` | Privacy-safe metrics as static markdown |
| `task-runner-wrapper.md` | `just`/`make` thin facade over existing scripts |
| `control-plane-contribution-contract.md` | Safe nginx allowlist and control-plane rules |

## Expected sibling Stage 6 pages

| Page | Purpose |
|---|---|
| `suggestion-corpus-registry.md` | YAML registry + CI for historical suggestions |
| `website-frontmatter-ci-contract.md` | Schema and link checks for publishable pages |
| `n8n-workflow-catalog.md` | Community contribution path for n8n recipes |
| `observability-contribution-contract.md` | Grafana/Prometheus dashboard and alert contribution rules |
| `backup-restore-community-drill.md` | Recurring reliability drill using existing backup/restore commands |
| `airgap-docs-mirror.md` | Offline/static docs pack for LAN and disconnected operators |
| `deprecation-notice-framework.md` | Breaking-change and deprecation communication pattern |

## Expected sibling Stage 7 pages

| Page | Purpose |
|---|---|
| `helper-api-contribution-contract.md` | Evolve helper/`/status/full` without breaking the dashboard |
| `tier2-idle-autostop-policy.md` | Opt-in idle timeout for heavy on-demand services |
| `battery-power-operator-signals.md` | Laptop battery widgets and energy-aware recommendations |
| `local-resource-history.md` | Local-only CPU/memory trend snapshots for operators |
| `service-dependency-map.md` | Declared dependencies for safe Tier 2 start ordering |
| `dashboard-accessibility-mobile.md` | A11y and touch-first acceptance baseline for the control plane |
| `ai-pipeline-contribution-contract.md` | Community path for MCP gateway and LangGraph supervisor **code** changes |

## Expected sibling Stage 8 pages

| Page | Purpose |
|---|---|
| `smart-startup-optimization.md` | Tier-aware quick-start planner without a new orchestrator |
| `secret-rotation-credential-hygiene.md` | Day-to-day secret lifecycle using `generate-secrets` and playbooks |
| `compose-override-contribution-contract.md` | Safe community path for local Compose customizations |
| `image-update-channel-policy.md` | Pin, check, update, and roll back with clear operator channels |
| `rag-knowledge-contribution-contract.md` | Community docs and corpora via MinIO/Tika/Qdrant/Open WebUI |
| `release-canary-community-program.md` | Lightweight pre-release testing using GitHub + existing smoke tools |
| `cross-service-e2e-scenario-catalog.md` | Named scenarios that wrap `chain-smoke`, helper checks, and playbooks |

## Expected sibling Stage 9 pages

| Page | Purpose |
|---|---|
| `privacy-preserving-usage-analytics.md` | Local-only usage patterns and recommendations |
| `ollama-model-catalog-contribution.md` | Community path for recommending local models |
| `affine-collaboration-contribution-contract.md` | Safe community recipes around AFFiNE |
| `pihole-dns-hygiene-contribution.md` | LAN DNS / blocklist hygiene (distinct from Tailscale bridge) |
| `offsite-backup-rclone-contract.md` | Optional remote backup lane over existing `backup` |
| `dashboard-feature-flag-experiments.md` | Env-driven UI experiments |
| `dashboard-release-highlights-contract.md` | Optional “What is new” bullets on the LAN dashboard |

## Expected sibling Stage 10 pages

| Page | Purpose |
|---|---|
| `open-webui-contribution-contract.md` | Safe community path for Open WebUI config, init, and tool wiring |
| `document-pipeline-contribution-contract.md` | Tika + MinIO + `tika_minio_processor` contribution and ops rules |
| `data-plane-hygiene-contract.md` | Day-to-day Postgres / Redis / Qdrant hygiene |
| `tls-certificate-lifecycle-contract.md` | Self-signed and CA-ready cert lifecycle |
| `disk-pressure-volume-ops-contract.md` | Host disk pressure, LVM extend, and volume cleanup recipes |
| `gpu-acceleration-contribution-contract.md` | Optional GPU enablement tied to the hardware matrix |
| `qm-llm-bridge-contribution-contract.md` | Community contract for the queue-manager LLM bridge service |

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Remote access | Optional Tailscale + existing `sync-dns` | Mandatory public inbound exposure or a second VPN product by default |
| Host maintenance | Existing `install-cron` / checkup / weekly update | Unsupervised fleet agents rewriting Compose |
| Browser automation | Compose `browserless` + MCP Playwright | Host Chrome with unbounded network as default |
| Autonomous n8n | Workflow Operator + LangGraph write guards | Unguarded LLM writes straight to production n8n |
| Logs | Docker/json-file limits + local rotate guidance | Shipping private logs to third-party SaaS by default |
| Privileged ops | Narrow sudoers example + documented disk helpers | Broad passwordless root for the whole repo |

## Navigation (future docs site)

Map this folder into a single content root later (for example `docs/community/`) after Stage 3 docs-framework gates pass. Until then, `suggestions/website/` is the publishable staging root; historical planning markdown stays beside it under `suggestions/`.

When reconciling Stage 1–11 hubs, extend `stage-merge-playbook.md` (Stage 4) so the union `index.md` lists every sibling once.

## Related planning sources

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary (when present on branch)
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
