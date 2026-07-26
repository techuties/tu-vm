---
title: Community Suggestions Website
description: Publishable Stage 3 community website markdown for decision transparency, quality gates, docs adoption, and extension pilots.
last_updated: 2026-07-26
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living artifacts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, MCP gateway). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 3** (this run) adds constructional pages that were still missing after Stage 1/2 and open consolidation PRs:

- Decision log and implemented showcase (close the lifecycle loop)
- Docs-framework adoption runbook (Starlight-first, gates before migration)
- Community quality gates catalog (day-to-day evidence without new CLIs)
- Extension pilot contract (Compose fragments, not a plugin marketplace)
- Hardware-class intake field (links Issues to the Stage 2 matrix)

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 3)

| Page | Purpose |
|---|---|
| [Decision log](./decision-log.md) | Accepted / deferred / declined rationale without a second tracker |
| [Implemented showcase](./implemented-showcase.md) | Changelog-adjacent proof that community ideas shipped |
| [Docs framework adoption](./docs-framework-adoption.md) | Constructional runbook to adopt a static docs framework safely |
| [Community quality gates](./community-quality-gates.md) | Day-to-day evidence map for contributors and maintainers |
| [Extension pilot contract](./extension-pilot-contract.md) | First community extension package shape using Compose reuse |
| [Hardware-class intake](./hardware-class-intake.md) | Optional Issue-form `class_id` tied to the hardware matrix |

## Expected sibling Stage 1 pages

When merged from the Stage 1 website proposal, keep these as siblings (same folder, one content root later):

| Page | Purpose |
|---|---|
| `how-to-submit.md` | High-signal suggestion writing and dedupe checks |
| `status-board.md` | Curated projection of suggestion lifecycle |
| `day-to-day-community-tools.md` | Frameworks and commands that ease daily work |
| `mcp-tools-catalog.md` | Contribution contract for optional MCP tool images |

## Expected sibling Stage 2 pages

When merged from the Stage 2 website proposal:

| Page | Purpose |
|---|---|
| `hardware-compatibility-matrix.md` | Living host/RAM/GPU/storage fit artifact |
| `persona-entry-paths.md` | First-hour routes for operators and contributors |
| `operator-service-profiles.md` | Named Tier 1/Tier 2 profiles for resource control |

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Integrations | Compose + MCP Gateway allowlists + extension pilot contract | Unreviewed privileged plugin hosts |
| Decisions / shipped work | Decision log + Releases / CHANGELOG | Shadow wikis or private status spreadsheets |
| Knowledge / notes | AFFiNE (Tier 2) + git-reviewed Markdown | Drift from the repository of record |

## Suggested site navigation (after docs framework adoption)

Map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Decisions → decision log + implemented showcase
- Community → Quality → quality gates
- Community → Extend → MCP catalog (Stage 1) + extension pilot
- Operate → Compatibility → hardware matrix + hardware-class intake
- Operate → Profiles → operator service profiles (Stage 2)
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- Contributors can find accept/defer/decline rationale without pinging maintainers
- Docs migration happens only after published adoption gates pass
- PRs cite the quality-gates page instead of inventing ad-hoc check lists
- Extension ideas follow one Compose-backed contract instead of privileged installers
- Hardware Issues increasingly include a `class_id` from the matrix

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md).
