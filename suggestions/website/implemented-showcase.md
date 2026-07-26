---
title: Implemented Community Suggestions Showcase
description: Changelog-adjacent website page that shows which community suggestions shipped and how to verify them.
last_updated: 2026-07-26
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Implemented Community Suggestions Showcase

## Problem

Operators and contributors cannot quickly see which community ideas already shipped, so they re-propose GitHub templates, stale bots, playbook hubs, doctor/smoke tooling, and “what is new” panels that already exist. Historical branches treated “implemented” as a status word; the website still lacks a **showcase** page that links evidence.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`CHANGELOG.md`](../../CHANGELOG.md) | Authoritative narrative of releases |
| GitHub Releases / Release Drafter | Grouped notes by PR labels |
| [`../implementation-backlog.md`](../implementation-backlog.md) | Completed / superseded baseline |
| Landing dashboard community + operator hubs | Local discoverability of playbooks and Releases |
| Decision log | Why something was accepted before it shipped |

Do **not** parse production databases or invent a separate “wins” CMS. Curate short Markdown cards that point at Releases, changelog anchors, and verification commands.

## Proposal

Publish an **Implemented Showcase** with cards that answer four questions:

1. What community pain was addressed?
2. What shipped (paths / commands)?
3. How does an operator or contributor verify it today?
4. Which Decision / Issue / PR closed the loop?

### Card contract

| Field | Required | Notes |
|---|---|---|
| `id` | yes | e.g. `SHIP-2026-004` |
| `title` | yes | Outcome-focused title |
| `shipped_in` | yes | Release tag or changelog date |
| `surfaces` | yes | Files/commands users touch |
| `verify` | yes | Concrete commands or UI checks |
| `decision` | optional | `DEC-…` id |
| `links` | yes | Issue/PR/Release URLs when public |

### Seed showcase (already in repository baseline)

These cards document **already shipped** community foundations so Stage 3 does not reinvent them:

#### SHIP-BASE-001 — GitHub-native suggestion intake

- **Pain:** No shared place to propose ideas.
- **Shipped:** Idea / suggestion Issue form, PR template, CONTRIBUTING labels.
- **Verify:** Open the Issue chooser; confirm suggestion + security paths.
- **Decision:** `DEC-2026-001`

#### SHIP-BASE-002 — Contributor diagnostics and CI gates

- **Pain:** Unclear how to prove a change is safe.
- **Shipped:** `./tu-vm.sh doctor`, `check-config`, `smoke-test`, `helper-contract-check`, `scripts/pre-push-check.sh`, CI compose/smoke/contract jobs.
- **Verify:** `./tu-vm.sh doctor` and `./scripts/pre-push-check.sh` (with `env.example` interpolated in docs-only cloud agents).
- **Related quality map:** [Community quality gates](./community-quality-gates.md)

#### SHIP-BASE-003 — Operator playbooks + dashboard deep links

- **Pain:** Recipes buried in a long README.
- **Shipped:** [`docs/playbooks/README.md`](../../docs/playbooks/README.md) with stable anchors; landing page operator hub shortcuts.
- **Verify:** Open playbook anchors from the dashboard Community / Operate strips.

#### SHIP-BASE-004 — Release Drafter + stale hygiene

- **Pain:** Hard to see what merged; idle Issues clutter triage.
- **Shipped:** Release Drafter workflow, stale workflow, documented labels.
- **Verify:** Inspect latest draft Release grouping; confirm stale labels on idle Issues.

### How maintainers add a new card

1. After a suggestion-linked PR ships in a Release, add a card within one week.
2. Prefer three verification bullets over long narrative.
3. Link the Decision Log entry and mark the status-board row `shipped`.
4. Keep the dashboard “What is new” links pointed at Releases/CHANGELOG; optional inline bullets remain backlog polish only.

## Website experience

Under the future static docs site:

```text
Community/
  Suggestions/
    Status board
    Decision log
    Implemented showcase  ← this page
```

Filter or tag cards by theme (`ops`, `docs`, `security`, `mcp`) once there are more than ~15 entries. Until then, a single chronological list is enough.

## Success criteria

- Duplicate “add GitHub templates / doctor / playbooks” suggestions can be closed with a showcase link
- Every new community-facing feature that ships gets a card or an explicit “too small for a card” note in the Release
- Cards never embed secrets, support bundles, or live tokens
