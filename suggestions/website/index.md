---
title: Community Suggestions Website
description: Publishable Stage 6 community website markdown for content integrity, operator reliability drills, and non-MCP community catalogs that extend Stages 1–5 without reinventing them.
last_updated: 2026-07-29
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, MCP gateway, n8n, monitoring). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 6** (this run) adds **content integrity and operator reliability contracts** that remain open after Stage 1–5 website drafts and consolidation PRs (#23–#31):

- Machine-readable suggestion corpus registry (stop duplicate reinvention)
- Website frontmatter / link CI contract for publishable pages
- n8n workflow catalog (community automation recipes, parallel to MCP catalog)
- Observability contribution contract (Grafana/Prometheus reuse)
- Backup/restore community drill using existing `tu-vm.sh` backup surfaces
- Air-gapped docs mirror for LAN-first / offline operators
- Deprecation and breaking-change notice framework for website + operators

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–5 website pages (open PRs #27–#31) | Contracts and living artifacts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 6)

| Page | Purpose |
|---|---|
| [Suggestion corpus registry](./suggestion-corpus-registry.md) | YAML registry + CI so historical suggestions are discoverable, not rewritten |
| [Website frontmatter CI contract](./website-frontmatter-ci-contract.md) | Schema and link checks for publishable website markdown |
| [n8n workflow catalog](./n8n-workflow-catalog.md) | Community contribution path for reusable n8n recipes |
| [Observability contribution contract](./observability-contribution-contract.md) | Grafana/Prometheus dashboard and alert contribution rules |
| [Backup/restore community drill](./backup-restore-community-drill.md) | Recurring reliability drill using existing backup/restore commands |
| [Air-gapped docs mirror](./airgap-docs-mirror.md) | Offline/static docs pack for LAN and disconnected operators |
| [Deprecation notice framework](./deprecation-notice-framework.md) | Breaking-change and deprecation communication pattern |

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

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Suggestion history | Corpus registry + website pages | Another parallel roadmap file each automation run |
| Automation recipes | n8n export catalog + MinIO workflow buckets | Custom workflow engines beside n8n |
| Observability | Existing Prometheus/Grafana stack | SaaS APM that phones home from the LAN |
| Reliability proof | Scheduled backup/restore drills | Untested “we have backups” folklore |
| Offline operators | Static site export / docs tarball | Cloud-only documentation portals |
| Deprecations | CHANGELOG + website notice + playbook notes | Silent breaking changes |
| Supply chain | Trivy/Grype + Dependabot + optional CycloneDX | Custom inventory databases |

## Suggested site navigation (after docs framework adoption)

Map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Integrity → corpus registry + frontmatter CI + deprecation notices
- Community → Automate → n8n workflow catalog (+ MCP catalog from Stage 1/4)
- Community → Observe → observability contribution contract
- Community → Reliability → backup/restore drill + air-gapped docs mirror
- Community → Operate daily → Stage 5 task runner + Dev Container + health digest
- Community → Quality → Stage 3–5 quality/supply-chain/CI contracts
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- New suggestion automation runs extend the corpus registry instead of inventing parallel framework files
- Publishable website pages fail CI when frontmatter or relative links drift
- Community n8n recipes land through a catalog with security review, not ad-hoc Compose forks
- Grafana/Prometheus contributions follow a documented path and stay LAN-local
- At least one backup/restore drill is documented per release train
- Air-gapped operators can obtain a static docs pack without public CDN dependency
- Breaking changes appear in CHANGELOG, website notices, and playbook version notes together

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md). Merge Stage hubs using the Stage 4 `stage-merge-playbook.md` (expected sibling)—extend that playbook’s merge order to include Stage 5 and Stage 6 before treating any single stage `index.md` as final.
