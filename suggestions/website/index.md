---
title: Community Suggestions Website
description: Publishable Stage 4 community website markdown for implementation contracts that turn Stage 1–3 frameworks into day-to-day executable work.
last_updated: 2026-07-27
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, MCP gateway). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 4** (this run) adds **implementation contracts** that were still open after Stage 1–3 website drafts and consolidation PRs (#23–#29):

- Machine-readable MCP catalog + CI validation (builds on Stage 1 catalog page)
- Thin `tu-vm.sh profile` CLI over Stage 2 operator profiles
- First extension scaffold + validator (builds on Stage 3 pilot contract)
- Supply-chain image CVE / SBOM community gates
- Dashboard modularization + Playwright smoke for contributors
- Playbook to merge Stage 1–3 `suggestions/website/` trees safely

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–3 website pages (open PRs) | Contracts and living artifacts—implement, do not rewrite |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 4)

| Page | Purpose |
|---|---|
| [MCP catalog CI contract](./mcp-catalog-ci-contract.md) | `mcp-tools/catalog.yaml` schema + CI validation without a marketplace |
| [Operator profile CLI](./operator-profile-cli.md) | `tu-vm.sh profile` list/show/apply `--plan` thin wrapper |
| [Extension pilot scaffold](./extension-pilot-scaffold.md) | First `extensions/<id>/` package + `validate-extension.sh` |
| [Supply-chain community gates](./supply-chain-community-gates.md) | Image CVE scans, severity gates, optional SBOM on release |
| [Dashboard modularization and smoke](./dashboard-modularization-smoke.md) | Extract Nginx assets + Playwright Tier-1 smoke |
| [Stage merge playbook](./stage-merge-playbook.md) | Reconcile Stage 1–3 `website/` hubs without losing siblings |

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

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Integrations | Compose + MCP Gateway allowlists + extension pilot | Unreviewed privileged plugin hosts |
| Decisions / shipped work | Decision log + Releases / CHANGELOG | Shadow wikis or private status spreadsheets |
| Supply chain | Trivy/Grype + Dependabot + optional CycloneDX | Custom inventory databases |
| Browser proof | Playwright against nginx fixture | Manual-only forever for Tier-1 UI |

## Suggested site navigation (after docs framework adoption)

Map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Implement → Stage 4 contracts (MCP CI, profile CLI, extension scaffold)
- Community → Quality → quality gates + supply-chain gates + browser smoke
- Community → Extend → MCP catalog (Stage 1) + extension pilot (Stage 3/4)
- Operate → Compatibility → hardware matrix + hardware-class intake
- Operate → Profiles → operator service profiles + profile CLI
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- `mcp-tools/catalog.yaml` validates in CI and matches Compose MCP services
- Contributors apply named profiles with `--plan` before changing running sets
- One reference extension validates and documents enable/disable without privileged installers
- Image CVE workflow reports actionable findings with severity thresholds
- Dashboard CSS/JS extracts without UX regressions; Playwright covers Tier-1 flows
- Stage 1–3 pages land under one `website/index.md` without duplicate hubs

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md).
