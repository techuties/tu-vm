---
title: Community Decision Log
description: Publishable decision records for accepted, deferred, and declined TU-VM community suggestions without a second tracker.
last_updated: 2026-07-26
owner: maintainers
status: proposed
theme: community
impact: high
---

# Community Decision Log

## Problem

Historical suggestion branches and open Issues accumulate **outcomes** (accepted, deferred, declined) that live only in scattered PR comments. Contributors cannot see why a popular-sounding idea was declined, so the same portal, voting database, or custom tracker proposals keep returning.

[`website-community-pages.md`](../website-community-pages.md) already recommended a `decisions.md` page. Stage 1 delivered a status board; Stage 3 closes the loop with an explicit decision log.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| GitHub Issues / PRs | Authoritative discussion and links |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Labels, security path, RFC expectations |
| Stage 1 `status-board.md` | Curated lifecycle projection |
| [`../implementation-backlog.md`](../implementation-backlog.md) | Current execution priorities |
| [`../historical-suggestions.md`](../historical-suggestions.md) | Older product ideas still open |
| Release Drafter + [`CHANGELOG.md`](../../CHANGELOG.md) | Shipped evidence after accept → implement |

Do **not** invent a decision database, ADR microservice, or dashboard voting UI. Publish short Markdown decision entries that link to GitHub.

## Proposal

Maintain a **Decision Log** page (this file, later rendered by the static docs site) with one row or section per meaningful community decision.

### Entry contract

Every entry must include:

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Stable id, e.g. `DEC-2026-014` |
| `title` | yes | Human-readable decision title |
| `status` | yes | `accepted`, `accepted-with-changes`, `deferred`, `declined` |
| `date` | yes | ISO date of decision |
| `related` | yes | Issue/PR URLs or suggestion ids |
| `summary` | yes | One or two sentences |
| `rationale` | yes | Why this outcome |
| `reuse` | yes | What existing framework/tool was preferred |
| `reopen_when` | for deferred | Concrete conditions to reopen |
| `alternative` | for declined | What to do instead |
| `owner` | yes | Maintainer or subsystem |

### Seed decisions (constructional, 2026-07-26)

#### DEC-2026-001 — GitHub remains sole suggestion intake

- **Status:** `accepted`
- **Summary:** Community proposals enter through the Idea / suggestion Issue form only.
- **Rationale:** Identity, moderation, reactions, search, and audit already exist on GitHub.
- **Reuse:** Issue templates, Discussions link, stale workflow, CONTRIBUTING labels.
- **Alternative rejected:** Local suggestion queue, dashboard auth, voting DB.

#### DEC-2026-002 — Nginx dashboard stays an operator control plane

- **Status:** `accepted`
- **Summary:** The landing dashboard must not become a CMS, social portal, or docs site.
- **Rationale:** LAN-first reliability and allowlist security matter more than public community UX on the control plane.
- **Reuse:** Static docs framework (future) for community content; dashboard for local ops.
- **Related:** [`docs-framework-adoption.md`](./docs-framework-adoption.md)

#### DEC-2026-003 — Prefer mature docs frameworks over custom site engines

- **Status:** `accepted-with-changes`
- **Summary:** Adopt a static docs framework only after navigation/search/versioning gates; default Astro Starlight.
- **Rationale:** Custom site generators and SSR stacks add maintenance without unique product value for curated Markdown.
- **Reuse:** Astro Starlight (default); Docusaurus or MkDocs Material when their strengths match requirements.
- **Related:** [`../website-and-docs-framework.md`](../website-and-docs-framework.md)

#### DEC-2026-004 — MCP tools extend via catalog + gateway, not a marketplace

- **Status:** `accepted`
- **Summary:** Optional MCP images follow a catalog/contribution contract gated by `mcp_gateway`.
- **Rationale:** Allowlists, write approval, and kill switch already exist; dynamic installers bypass them.
- **Reuse:** `mcp-tools/*`, Compose, `./tu-vm.sh chain-smoke`.
- **Related:** Stage 1 MCP tools catalog page (expected sibling `mcp-tools-catalog.md`)

#### DEC-2026-005 — Named operator profiles before new orchestrators

- **Status:** `accepted`
- **Summary:** Document Work / AI / Energy-style profiles as Markdown contracts first; CLI wrappers only after membership stabilizes.
- **Rationale:** Avoid a custom scheduler while operators still lack shared vocabulary.
- **Reuse:** Tier 1/Tier 2 Compose split + existing `start-service` / `stop-service`.
- **Related:** Stage 2 operator service profiles page (expected sibling `operator-service-profiles.md`)

#### DEC-2026-006 — Decline local voting / reputation systems

- **Status:** `declined`
- **Summary:** Do not add vote weights, badges, or reputation on the LAN dashboard.
- **Rationale:** Duplicates GitHub reactions; adds personal-data and moderation burden on a private control plane.
- **Alternative:** Use Issue reactions and maintainer triage; publish decisions here.

## Maintainer workflow

1. When a suggestion reaches a clear outcome, add a Decision Log entry the same week.
2. Link the Issue/PR with `DEC-YYYY-NNN` in a comment.
3. Update Stage 1 status-board row to `accepted`, `deferred`, or `declined` with the decision id.
4. If accepted work ships, move a short card to [Implemented showcase](./implemented-showcase.md) and link the release.

## Automation (optional, reuse-first)

Only after the manual log is useful for two release cycles:

- CI warning if a status-board terminal state lacks a Decision Log id
- Generated index from YAML frontmatter (still edited in git)
- Do **not** auto-close Issues from the website build

## Success criteria

- New “build a community portal with voting” Issues can be closed with a link to `DEC-2026-001` / `DEC-2026-006`
- Deferred items include reopen conditions that contributors can meet with evidence
- Decision entries stay short; deep design stays in Issues/PRs
