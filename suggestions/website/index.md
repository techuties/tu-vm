---
title: Community Suggestions Website
description: Publishable community hub for TU-VM suggestions, tooling, and MCP catalog pages.
last_updated: 2026-07-24
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **Stage 1 website markdown**: curated, read-only pages that a future static docs site can publish without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, how to avoid reinventing historical ideas, and which frameworks and day-to-day tools to reuse.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

This hub turns those themes into publishable pages and one distinct next focus: a **community MCP tools catalog** that builds on `mcp-tools/` and `mcp-gateway`.

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

## Page map

| Page | Purpose |
|---|---|
| [How to submit](./how-to-submit.md) | High-signal suggestion writing and dedupe checks |
| [Status board](./status-board.md) | Curated projection of suggestion lifecycle |
| [Day-to-day community tools](./day-to-day-community-tools.md) | Frameworks and commands that ease daily work |
| [MCP tools community catalog](./mcp-tools-catalog.md) | Contribution contract for optional MCP tool images |

Canonical vocabulary and lifecycle states live in [`../website-community-pages.md`](../website-community-pages.md). Active backlog priority is tracked in [`../implementation-backlog.md`](../implementation-backlog.md).

## Suggested site navigation (after docs framework adoption)

When a static docs framework is adopted (reuse-first default: Astro Starlight; see [`../website-and-docs-framework.md`](../website-and-docs-framework.md)), map this folder to `docs/community/` (or the configured content root) **without** maintaining two editable copies:

- Community → Suggestions → this index
- Community → Tools → day-to-day + MCP catalog
- Operate → Playbooks (existing `docs/playbooks/`)

## Success signals

- A new contributor finds submit + dedupe guidance in two clicks or fewer
- Duplicate suggestion rate trends down because historical pages are linked from intake
- MCP tool contributions follow one reviewed contract instead of ad-hoc Compose edits
- Operators keep using `tu-vm.sh` and playbooks as the day-to-day path of record
