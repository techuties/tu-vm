---
title: Community Suggestions Website
description: Publishable Stage 8 community website markdown for lifecycle, update, knowledge, and contributor day-to-day contracts that extend Stages 1–7 without reinventing frameworks or community intake.
last_updated: 2026-08-01
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, MCP gateway, LangGraph supervisor, n8n, MinIO, Qdrant, monitoring, update/rollback). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 8** (this run) adds **lifecycle and knowledge-plane contracts** that remained open after Stage 1–7 drafts and consolidation PRs (#23–#33):

- Smart startup optimization (CHANGELOG planned feature still without a website contract)
- Secret rotation and credential hygiene for day-to-day operators
- Compose override contribution contract (safe local customization)
- Image update channel policy (`update-check` / `update` / `update-rollback`)
- RAG / knowledge contribution contract (MinIO → Tika → Qdrant → Open WebUI)
- Release canary community program (pre-release validation without a custom QA platform)
- Cross-service end-to-end scenario catalog (reuse `chain-smoke` and playbooks)

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–7 website pages (open PRs #27–#33) | Contracts and living artifacts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 8)

| Page | Purpose |
|---|---|
| [Smart startup optimization](./smart-startup-optimization.md) | Tier-aware quick-start planner without a new orchestrator |
| [Secret rotation and credential hygiene](./secret-rotation-credential-hygiene.md) | Day-to-day secret lifecycle using `generate-secrets` and playbooks |
| [Compose override contribution contract](./compose-override-contribution-contract.md) | Safe community path for local Compose customizations |
| [Image update channel policy](./image-update-channel-policy.md) | Pin, check, update, and roll back with clear operator channels |
| [RAG knowledge contribution contract](./rag-knowledge-contribution-contract.md) | Community docs and corpora via MinIO/Tika/Qdrant/Open WebUI |
| [Release canary community program](./release-canary-community-program.md) | Lightweight pre-release testing using GitHub + existing smoke tools |
| [Cross-service e2e scenario catalog](./cross-service-e2e-scenario-catalog.md) | Named scenarios that wrap `chain-smoke`, helper checks, and playbooks |

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
| `ai-pipeline-contribution-contract.md` | Community path for MCP gateway and LangGraph supervisor changes |

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Startup behavior | Tier 1 portable mode + Stage 2/4 profiles + dependency map | Kubernetes-style control planes for a single host |
| Secrets | `generate-secrets`, `.env` hygiene, SECURITY.md | Checking secrets into suggestion markdown or CI logs |
| Updates | `update-check` / `update` / `update-rollback` + weekly cron | Unattended registry pulls with no rollback story |
| Knowledge / RAG | MinIO buckets, Tika processor, Qdrant, Open WebUI | Cloud-only document SaaS for private corpora |
| Pre-release QA | GitHub Issues + smoke/doctor/chain-smoke | Custom canary control plane |
| E2E proof | Named scenario catalog wrapping existing scripts | Parallel test frameworks that ignore Compose health |
| Suggestion history | Corpus registry + website pages | Another parallel roadmap file each automation run |

## Suggested site navigation (after docs framework adoption)

Map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Lifecycle → smart startup + update channel + secret hygiene
- Community → Customize → Compose override contract (+ Stage 3/4 extension pilot)
- Community → Knowledge → RAG contribution contract (+ Stage 6 air-gap docs mirror)
- Community → Validate → release canary program + e2e scenario catalog
- Community → Operate daily → Stage 5 task runner + Dev Container + health digest
- Community → Quality → Stage 3–7 quality/supply-chain/helper/AI contracts
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- Smart startup guidance reuses Tier 1 / profile / dependency contracts instead of inventing a scheduler
- Operators rotate credentials with documented commands and never paste secrets into Issues
- Local Compose overrides follow a contribution contract that preserves upstream `docker-compose.yml`
- Update channel policy is visible next to playbook safe-update and weekly cron behavior
- Community knowledge packs land through MinIO/Tika/Qdrant paths with privacy notes
- At least one canary checklist runs before risky releases using existing smoke tools
- Cross-service scenarios are named, discoverable, and mapped to scripts already in the repo

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md). Merge Stage hubs using the Stage 4 `stage-merge-playbook.md` (expected sibling)—extend that playbook’s merge order to include Stages 5–8 before treating any single stage `index.md` as final.
