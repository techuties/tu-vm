---
title: Community Suggestions Website
description: Publishable Stage 7 community website markdown for product and day-to-day operator contracts that extend Stages 1–6 without reinventing frameworks or community intake.
last_updated: 2026-07-31
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, MCP gateway, LangGraph supervisor, n8n, monitoring). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 7** (this run) turns long-standing **CHANGELOG / historical product directions** into constructional website contracts that remained open after Stage 1–6 drafts and consolidation PRs (#23–#32):

- Helper API contribution contract (safe dashboard/`/status/full` evolution)
- Tier 2 idle auto-stop policy (opt-in energy and resource control)
- Battery and power operator signals (laptop-aware recommendations)
- Local resource usage history (privacy-preserving trends)
- Service dependency map (auto-start rules without a new orchestrator)
- Dashboard accessibility and mobile baseline
- AI pipeline contribution contract (MCP gateway + LangGraph reuse)

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–6 website pages (open PRs #27–#32) | Contracts and living artifacts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 7)

| Page | Purpose |
|---|---|
| [Helper API contribution contract](./helper-api-contribution-contract.md) | Evolve `helper/uploader.py` and `/status/full` without breaking the dashboard |
| [Tier 2 idle auto-stop policy](./tier2-idle-autostop-policy.md) | Opt-in idle timeout for heavy on-demand services |
| [Battery and power operator signals](./battery-power-operator-signals.md) | Laptop battery widgets and energy-aware recommendations |
| [Local resource usage history](./local-resource-history.md) | Local-only CPU/memory trend snapshots for operators |
| [Service dependency map](./service-dependency-map.md) | Declared dependencies for safe Tier 2 start ordering |
| [Dashboard accessibility and mobile](./dashboard-accessibility-mobile.md) | A11y and touch-first acceptance baseline for the control plane |
| [AI pipeline contribution contract](./ai-pipeline-contribution-contract.md) | Community path for MCP gateway and LangGraph supervisor changes |

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
| `observability-contribution-contract.md` | Grafana/Prometheus contribution rules |
| `backup-restore-community-drill.md` | Recurring reliability drill |
| `airgap-docs-mirror.md` | Offline/static docs pack |
| `deprecation-notice-framework.md` | Breaking-change communication pattern |

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, helper API, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Product analytics | Local snapshots + Prometheus/Grafana | Mandatory cloud telemetry |
| AI orchestration | Existing `mcp-gateway` + `langgraph-supervisor` | Second agent runtime as a default |

## Merge guidance

When Stages 1–7 land on the same branch, reconcile hubs with the Stage 4 `stage-merge-playbook.md` (extend the merge order through Stage 7). Keep one `suggestions/website/index.md` that unions page maps and lists expected siblings; do not maintain seven competing hubs after merge.

After static-framework adoption, map this folder into `docs/community/` (or the configured content root) without two editable copies.
