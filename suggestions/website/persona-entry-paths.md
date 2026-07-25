---
title: Persona Entry Paths
description: First-hour community website routes for operators, docs contributors, and integration authors that only link existing TU-VM commands and docs.
last_updated: 2026-07-25
owner: maintainers
status: proposed
theme: community
impact: high
---

# Persona Entry Paths

## Problem

New contributors land on a large repository (Compose stack, `tu-vm.sh`, helper API, nginx dashboard, MCP tools, many overlapping `suggestions/*` drafts) and do not know which **first hour** path applies to them. Historical branches proposed portals, dashboards, and custom onboarding apps. Those reinvent GitHub and the existing control plane.

## Existing scan (reuse first)

| Persona need | Already available |
|---|---|
| Run the stack | `./tu-vm.sh start`, `status`, `secure`, [`QUICK_REFERENCE.md`](../../QUICK_REFERENCE.md) |
| Diagnose | `./tu-vm.sh doctor`, `check-config`, `smoke-test`, `diagnose` |
| Operator recipes | [`docs/playbooks/`](../../docs/playbooks/README.md) |
| Suggest / contribute | [`CONTRIBUTING.md`](../../CONTRIBUTING.md), Idea/suggestion Issue form |
| Security reports | [`SECURITY.md`](../../SECURITY.md) |
| Avoid duplicate ideas | [`../implementation-backlog.md`](../implementation-backlog.md), historical suggestion files |
| MCP / automation smoke | `./tu-vm.sh chain-smoke`, playbook `playbook-mcp-smoke` |
| Pre-push confidence | [`scripts/pre-push-check.sh`](../../scripts/pre-push-check.sh) |

Do **not** build a persona quiz app, authenticated community portal, or second documentation tree. Publish thin persona pages that **only link** existing commands and docs.

## Proposal

Add website markdown entry paths for three personas. Each page (or section) has one job: get that person to a safe first success and the correct intake channel.

### Persona A — LAN operator (day-to-day)

**Goal:** Healthy Tier 1 stack on the LAN without drowning in optional services.

| Step | Action | Link / command |
|---|---|---|
| 1 | Pick a host class | [Hardware matrix](./hardware-compatibility-matrix.md) |
| 2 | Start Tier 1 | `./tu-vm.sh start` |
| 3 | Lock to secure LAN posture | `sudo ./tu-vm.sh secure` |
| 4 | Verify | `./tu-vm.sh status` then `./tu-vm.sh doctor` |
| 5 | Use recipes | [Playbooks](../../docs/playbooks/README.md) |
| 6 | Choose a service profile when enabling Tier 2 | [Operator service profiles](./operator-service-profiles.md) |

**When something breaks:** playbook recovery → `doctor` / `check-config --strict` → bug Issue with redacted evidence. Never paste `.env`.

### Persona B — Docs / suggestions contributor

**Goal:** Improve docs or propose an idea without spinning a full AI stack when unnecessary.

| Step | Action | Link / command |
|---|---|---|
| 1 | Read contribution path | [`CONTRIBUTING.md`](../../CONTRIBUTING.md) |
| 2 | Dedupe against backlog and history | [`../implementation-backlog.md`](../implementation-backlog.md), [`../historical-suggestions.md`](../historical-suggestions.md) |
| 3 | Prefer editing canonical pages | [`../README.md`](../README.md) canonical reading path |
| 4 | Validate docs-only changes | `git diff --check`, relative links; `./scripts/pre-push-check.sh` with `env.example` interpolated when needed |
| 5 | Submit | GitHub Idea/suggestion or docs PR |

**Boundary:** Website pages in this folder are curated publishing views. New ideas still enter through GitHub Issues, not by inventing a local queue.

### Persona C — Integration / MCP / automation contributor

**Goal:** Extend optional tools without weakening MCP Gateway controls or Tier 1 reliability.

| Step | Action | Link / command |
|---|---|---|
| 1 | Confirm Tier 1 healthy | `./tu-vm.sh status` |
| 2 | Enable only required Tier 2 services | `./tu-vm.sh start-service <name>` |
| 3 | Respect gateway allowlists | `MCP_ALLOWED_SERVERS` and mcp-gateway docs/env comments |
| 4 | Exercise the chain | `./tu-vm.sh chain-smoke` / playbook MCP smoke |
| 5 | Follow catalog contract when adding tools | Stage 1 `mcp-tools-catalog.md` (sibling page) + `mcp-tools/` Dockerfiles |
| 6 | Propose larger integration shape | Issue + optional extension notes in [`../extensions-and-integration-framework.md`](../extensions-and-integration-framework.md) |

**Boundary:** No privileged plugin host, no bypass of write approval / kill switch patterns already in the gateway.

## Suggested website IA

Under the future static docs site:

```text
Community/
  Start here/          ← this page (persona switchboard)
  Suggestions/         ← Stage 1 submit + status board
  Compatibility/       ← hardware matrix
Operate/
  Profiles/            ← service profiles
  Playbooks/           ← existing docs/playbooks
```

The Nginx landing page should only deep-link to playbooks and GitHub community entry points it already exposes—not host persona apps.

## Copy rules (keep pages thin)

1. One short paragraph per persona, then a table of steps.
2. Every step names an existing path or command.
3. No cards, quizzes, or progress trackers in the control-plane dashboard.
4. If a command does not exist yet (for example change-aware `contribute-check`), link the proposal doc and keep the persona path on today’s commands.

## Rollout

1. Publish this page in `suggestions/website/`.
2. Link it from [`index.md`](./index.md) and the suggestions hub README.
3. After Stage 1 submit/status pages land, add cross-links in both directions.
4. Optional later: one sentence in root `README.md` Contributing section pointing here.

## Rollback

Delete or archive the page. Contributors continue using `CONTRIBUTING.md` and `QUICK_REFERENCE.md` alone.

## Acceptance criteria

- Three personas documented with ordered first-hour steps.
- Zero steps depend on a not-yet-built portal, auth system, or voting feature.
- Hardware matrix and service profiles are linked, not duplicated.
- Security reports are routed to `SECURITY.md` only.

## Success metrics

- New Issues from first-time contributors reference the persona they followed.
- Docs-only contributors report lower setup friction (no full stack required for Markdown PRs).
- Integration PRs include chain-smoke or gateway allowlist evidence more often.
