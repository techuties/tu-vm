---
title: Community Suggestions Website
description: Publishable Stage 5 community website markdown for day-to-day operating contracts that make frameworks and community workflows executable without reinventing Stages 1–4.
last_updated: 2026-07-28
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

**Stage 5** (this run) adds **day-to-day operating contracts** that remain open after Stage 1–4 website drafts and consolidation PRs (#23–#30):

- Dev Container / Codespaces contributor environment (reuse Dev Containers spec)
- Compose CI live profile for `/status/full` against a minimal stack
- Playbook version matrix tied to TU-VM releases
- GitHub-native label taxonomy and project board contract
- Privacy-safe community health digest (Actions → static markdown)
- Thin task-runner wrapper (`just`/`make`) over existing scripts
- Control-plane / allowlist contribution contract for safe LAN changes

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–4 website pages (open PRs #27–#30) | Contracts and living artifacts—implement, do not rewrite |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 5)

| Page | Purpose |
|---|---|
| [Dev Container contributor environment](./devcontainer-contributor-environment.md) | Repeatable Codespaces/Dev Containers setup for contributors |
| [Compose CI live profile](./compose-ci-live-profile.md) | Minimal Compose profile to exercise live `/status/full` |
| [Playbook version matrix](./playbook-version-matrix.md) | Release-aware notes for operator playbooks |
| [Label and board contract](./community-label-and-board-contract.md) | GitHub labels + Projects as the community operating system |
| [Community health digest](./community-health-digest.md) | Privacy-safe metrics published as static markdown |
| [Task runner wrapper](./task-runner-wrapper.md) | `just`/`make` thin facade over `tu-vm.sh` and scripts |
| [Control-plane contribution contract](./control-plane-contribution-contract.md) | Safe nginx allowlist and control-plane change rules |

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
| `stage-merge-playbook.md` | Reconcile Stage 1–4 `website/` hubs without losing siblings |

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Contributor environments | Dev Containers / Codespaces spec | One-off host bootstrap scripts per OS |
| Integrations | Compose + MCP Gateway allowlists + extension pilot | Unreviewed privileged plugin hosts |
| Decisions / shipped work | Decision log + Releases / CHANGELOG | Shadow wikis or private status spreadsheets |
| Community metrics | GitHub Actions → static markdown digest | Third-party analytics on operator traffic |
| Task shortcuts | Thin `just`/`make` wrappers | Replacing `tu-vm.sh` with a second control plane |
| Supply chain | Trivy/Grype + Dependabot + optional CycloneDX | Custom inventory databases |
| Browser proof | Playwright against nginx fixture | Manual-only forever for Tier-1 UI |

## Suggested site navigation (after docs framework adoption)

Map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Operate daily → task runner + Dev Container + health digest
- Community → Quality → quality gates + supply-chain gates + Compose CI profile + browser smoke
- Community → Govern → labels/board contract + decision log + status board
- Operate → Compatibility → hardware matrix + playbook version matrix
- Operate → Control plane → allowlist contribution contract
- Operate → Profiles → operator service profiles + profile CLI
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- Contributors open a Dev Container / Codespaces workspace and run `doctor` + `pre-push-check` without host-specific folklore
- CI can optionally exercise a live helper `/status/full` shape via a documented Compose profile
- Playbooks carry a short version matrix so operators know which release a recipe targets
- Labels and a GitHub Project board make triage visible without a custom tracker
- A weekly community health digest regenerates as static markdown (no PII, no operator telemetry)
- `just check` / `make check` (or equivalent) wraps existing scripts without duplicating logic
- Allowlist and control-plane PRs follow an explicit security checklist

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md). Merge Stage hubs using the Stage 4 `stage-merge-playbook.md` (expected sibling) before treating any single stage `index.md` as final.
