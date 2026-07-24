---
title: Community Suggestions Status Board
description: Curated, read-only projection of suggestion lifecycle for the TU-VM website.
last_updated: 2026-07-24
owner: maintainers
status: proposed
---

# Community Suggestions Status Board

## Purpose

Give operators and contributors a human-readable view of what the community is working on **without** standing up a second tracker.

GitHub Issues and pull requests remain authoritative. This page is a curated projection that a static docs site can render from repository-owned Markdown or generated indexes.

## Lifecycle states

Align with [`../website-community-pages.md`](../website-community-pages.md):

| Status | Meaning |
|---|---|
| `new` | Captured; not yet triaged |
| `triaged` | Scoped, labeled, ownership or next action clear |
| `accepted` | Worth doing; waiting for implementation capacity |
| `in-progress` | Active Issue/PR linked |
| `shipped` | Released with changelog/docs evidence |
| `deferred` | Valuable later; reopen conditions recorded |
| `declined` | Explicit no, with alternative or rationale |

## Seed board (constructional themes, 2026-07-24)

These rows summarize recurring historical themes and the distinct website focus added in this folder. Update links when Issues/PRs exist.

| ID | Theme | Status | Reuse / framework | Next action |
|---|---|---|---|---|
| WEB-IA | Docs site IA + Starlight/MkDocs reuse gates | `accepted` | Static docs framework; keep Nginx dashboard separate | Adopt framework only after navigation/search/versioning gates |
| GOV-GH | GitHub-native suggestion governance | `shipped` (baseline) | Issue/PR templates, stale bot, CONTRIBUTING | Keep website as read-only guide |
| TOOL-DAY | Day-to-day contributor/operator tooling | `in-progress` | `tu-vm.sh`, pre-push, doctor, smoke, CI | See [day-to-day community tools](./day-to-day-community-tools.md) |
| MCP-CAT | Community MCP tools catalog + contribution contract | `triaged` | `mcp-tools/*`, `mcp_gateway`, chain-smoke | Implement catalog metadata + review checklist |
| EXT-PILOT | Extension package contract pilot | `accepted` | Compose fragments + validator script | Pilot one reference extension after catalog shape stabilizes |
| SUPPLY | Image CVE scanning depth | `accepted` | Trivy/Grype on pinned Compose images | Separate from config-only scan; fail on HIGH/CRITICAL after triage |
| DASH-MOD | Dashboard asset modularization + a11y | `accepted` | Extract CSS/JS; declarative card registry later | Keep control plane small; no docs framework inside Nginx |

Historical product ideas (profiles, battery widget, idle Tier-2 stop) remain in [`../historical-suggestions.md`](../historical-suggestions.md) and should not be re-proposed without new evidence.

## Row format for maintainers

When adding or updating a row, include:

```yaml
id: SHORT-ID
title: Human readable title
status: triaged
theme: operations|docs|security|mcp|tooling|ux
impact: high|medium|low
github: https://github.com/techuties/tu-vm/issues/N
updated_at: YYYY-MM-DD
notes: One-line next action or decline rationale
```

## Publishing rules

1. Prefer linking to Issues/PRs over copying discussion prose.
2. Mark duplicates as `declined` with `duplicate-of: <id-or-url>`.
3. Move `shipped` items to a short implemented list (or Releases filter) after one release cycle.
4. Never embed secrets, support-bundle contents, or live control tokens.
5. Show `last_updated` on the rendered page so staleness is obvious.

## Automation (optional, reuse-first)

Only after the manual board is useful:

- Generate a draft table from Issues labeled `kind:community` / `kind:feature` (read-only GitHub API in CI)
- Fail CI if a board row references a closed Issue without status `shipped`, `deferred`, or `declined`
- Do **not** auto-mutate Issue state from the website build

## Related pages

- [How to submit](./how-to-submit.md)
- [MCP tools community catalog](./mcp-tools-catalog.md)
- Active engineering backlog: [`../implementation-backlog.md`](../implementation-backlog.md)
