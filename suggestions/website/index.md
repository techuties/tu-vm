---
title: Community Suggestions Website
description: Publishable Stage 13 community website markdown for operator feature day-2 surfaces and contributor quality contracts that extend Stages 1–12 without reinventing frameworks or community intake.
last_updated: 2026-08-06
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, Open WebUI audio/web-search helpers, PDF operator commands, IP whitelist helpers, Compose healthchecks, fixtures, and `cleanup`). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 13** (this run) adds **operator feature day-2 and contributor quality contracts** that remained open after Stage 1–12 drafts and consolidation PRs (#23–#38):

- Open WebUI audio / STT contract (`check-openwebui-audio` / `fix-openwebui-audio`)
- Open WebUI web-search contract (`check-openwebui-websearch`)
- PDF operator day-2 contract (`pdf-status` / `pdf-test` / `pdf-logs` / `pdf-reset`)
- IP allowlist day-2 contract (`whitelist-list` / `add` / `remove`)
- Fixture and contract-test contribution contract
- Compose healthcheck contribution contract
- Host cleanup and prune contract (`cleanup` and safe Docker prune hygiene)

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–12 website pages (open PRs #27–#38) | Contracts and living artifacts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 13)

| Page | Purpose |
|---|---|
| [Open WebUI audio / STT contract](./open-webui-audio-stt-contract.md) | Safe community path for speech-to-text config and repair helpers |
| [Open WebUI web-search contract](./open-webui-websearch-contract.md) | Loader and privacy rules for optional web-search features |
| [PDF operator day-2 contract](./pdf-operator-day2-contract.md) | Operator toolkit for PDF pipeline status, test, logs, and reset |
| [IP allowlist day-2 contract](./ip-allowlist-day2-contract.md) | Day-to-day whitelist ops distinct from control-plane PR security |
| [Fixture and contract-test contribution](./fixture-and-contract-test-contribution.md) | How community evolves fixtures and schema validators |
| [Compose healthcheck contribution contract](./compose-healthcheck-contribution-contract.md) | Healthcheck design rules that keep `docker compose ps` honest |
| [Host cleanup and prune contract](./host-cleanup-and-prune-contract.md) | Safe backup/log/image cleanup without surprise data loss |

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

## Expected sibling Stage 11 pages

| Page | Purpose |
|---|---|
| `tailscale-lan-bridge-contract.md` | Optional Tailscale dual-stack access using existing `sync-dns` |
| `host-cron-maintenance-contract.md` | Safe community path for checkup / update / MinIO sync crons |
| `browserless-automation-contribution-contract.md` | Browserless + Playwright MCP contribution and ops rules |
| `workflow-operator-contribution-contract.md` | Open WebUI Workflow Operator / autonomous n8n engineering lane |
| `autonomous-write-guard-policy.md` | Day-to-day confirm, rate-limit, and circuit-breaker operator policy |
| `container-log-retention-contract.md` | Local log growth hygiene without a logging SaaS |
| `privileged-host-ops-contract.md` | Sudoers, disk extend, and host privilege contribution rules |

## Expected sibling Stage 12 pages

| Page | Purpose |
|---|---|
| `access-mode-and-firewall-contract.md` | Safe community path for `secure` / `public` / `locked` and UFW |
| `nginx-edge-routing-contract.md` | Vhost, proxy, and conf contribution rules at the edge |
| `env-schema-contribution-contract.md` | Evolving `env.example` without secret leakage |
| `diagnostics-and-triage-contract.md` | `doctor` / `diagnose` / smoke as day-to-day triage tools |
| `dashboard-announcements-contract.md` | Priority taxonomy for helper-driven operator alerts |
| `lan-dns-client-onboarding-contract.md` | Router and client first-hour DNS recipes |
| `host-port-binding-contract.md` | Port 53 / 80 / 443 conflict detection and recovery |

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Speech / STT | Existing Open WebUI audio check/fix helpers | Mandatory cloud STT SaaS as default |
| Web search | Existing Open WebUI web-search checker + privacy-first loaders | Shipping operator search queries to public Issues |
| PDF day-2 | `pdf-status` / `pdf-test` / `pdf-logs` / `pdf-reset` | Replacing the pipeline with a second OCR product for triage |
| Allowlist ops | `whitelist-*` + Stage 5 control-plane PR rules | Embedding production WAN IPs in git |
| Contract tests | `fixtures/` + existing Python validators | Screenshot-only proof for JSON shape changes |
| Healthchecks | Compose `healthcheck` with honest probes | Always-green checks that hide failures |
| Cleanup | `tu-vm.sh cleanup` + documented prune lanes | Unattended `docker system prune -a --volumes` |
