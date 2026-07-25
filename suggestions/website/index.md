---
title: Community Suggestions Website
description: Publishable community website markdown for TU-VM frameworks, day-to-day tools, and Stage 2 living artifacts.
last_updated: 2026-07-25
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

Stage 1 of this folder (submit guide, status board, day-to-day tools hub, MCP catalog) is proposed in parallel under the same path naming. This run adds **Stage 2 living artifacts** that were still missing as website pages:

- Hardware and host compatibility matrix
- Persona-based entry paths that only link existing commands and docs
- Operator service profiles that formalize historical Work / AI / Energy ideas

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

## Page map (Stage 2)

| Page | Purpose |
|---|---|
| [Hardware compatibility matrix](./hardware-compatibility-matrix.md) | Living community artifact for host/RAM/GPU/storage fit |
| [Persona entry paths](./persona-entry-paths.md) | First-hour routes for operators, docs, and integration contributors |
| [Operator service profiles](./operator-service-profiles.md) | Named Tier 1/Tier 2 profiles for day-to-day resource control |

## Expected sibling Stage 1 pages

When merged from the Stage 1 website proposal, keep these as siblings (same folder, one content root later):

| Page | Purpose |
|---|---|
| `how-to-submit.md` | High-signal suggestion writing and dedupe checks |
| `status-board.md` | Curated projection of suggestion lifecycle |
| `day-to-day-community-tools.md` | Frameworks and commands that ease daily work |
| `mcp-tools-catalog.md` | Contribution contract for optional MCP tool images |

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md).

## Framework reuse policy

| Need | Prefer | Avoid |
|---|---|---|
| Community intake | GitHub Issues / Discussions | Local suggestion DB or dashboard voting |
| Docs website | Static framework after gates (Astro Starlight default; Docusaurus/MkDocs when better fit) | Turning Nginx control plane into a CMS |
| Day-to-day ops | `tu-vm.sh`, playbooks, existing scripts | New parallel CLIs per contributor niche |
| Integrations | Compose + MCP Gateway allowlists | Unreviewed privileged plugin hosts |
| Knowledge / notes | AFFiNE (Tier 2) + git-reviewed Markdown | Shadow wikis that drift from the repo |

## Suggested site navigation (after docs framework adoption)

Map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Start here → persona entry paths
- Operate → Profiles → operator service profiles
- Operate → Compatibility → hardware matrix
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- New contributors reach the right first command or doc in two clicks or fewer
- Hardware-related Issues include matrix evidence instead of vague “it is slow”
- Operators choose named profiles instead of ad-hoc service mixes
- Duplicate “build a community portal” suggestions decline because boundaries are published
