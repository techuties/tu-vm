---
title: Helper API Contribution Contract
description: Constructional contract for evolving helper/uploader.py and /status/full safely so community dashboard work reuses the existing control plane instead of inventing a second API.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Helper API Contribution Contract

## Problem

The landing dashboard and operator tooling depend on `helper/uploader.py` and the `/status/full` contract. Historical suggestions repeatedly propose “new community APIs,” suggestion queues, or ad-hoc endpoints without documenting schema impact. Day-to-day contributors need a **reuse-first contract** so helper changes stay compatible with fixtures, CI, and the Nginx control plane.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` | Flask helper API for status and control |
| `fixtures/status-full-contract.json` | Canonical `/status/full` shape |
| `scripts/validate_status_full_contract.py` | Static contract validation |
| `scripts/helper-contract-check.sh` | Live helper checks when stack is up |
| `.github/workflows/ci.yml` | Compose render + fixture validation |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Frontend extraction + Playwright |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | Live `/status/full` CI profile |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Allowlist / control-plane safety |

Out of scope:

- A public internet-facing community API
- Local voting or suggestion submission through the helper
- Breaking `/status/full` without a fixture + deprecation path
- Replacing Flask with a new framework as a prerequisite for small endpoints

## Proposal

Treat helper changes as **contract-first contributions**.

### Contribution types

| Type | Examples | Required evidence |
|---|---|---|
| Additive field | New optional key under an existing status object | Fixture update + validator pass |
| New read endpoint | Battery summary, dependency map, history snapshot | Route docs, auth/allowlist notes, smoke curl |
| Control action | Profile apply, idle-policy toggle | Idempotency notes, rollback, deny-by-default checks |
| Refactor | Extract helpers inside `uploader.py` | Behavior-equivalent tests / contract unchanged |

### Rules

1. **Additive by default.** Prefer optional fields with safe defaults over renames.
2. **Fixture is law.** Any `/status/full` shape change updates `fixtures/status-full-contract.json` in the same PR.
3. **Live check when possible.** Run `helper-contract-check` or documented curls against the helper container.
4. **No secrets in responses.** Tokens, `.env` values, and backup paths that reveal home directories must not appear in JSON consumed by the dashboard.
5. **Control endpoints stay LAN-gated.** Follow nginx allowlist and existing auth patterns; do not weaken them for “community convenience.”
6. **Deprecate explicitly.** Removals use the Stage 6 deprecation notice framework (`DEP-*`) before deletion.

### Suggested endpoint doc table (website living section)

When implementing, maintain a short table (README or playbook anchor) mapping:

| Dashboard need | Helper route | Contract artifact |
|---|---|---|
| Full status board | `/status/full` | `fixtures/status-full-contract.json` |
| Service health chips | `/status/*` family | Existing routes + CI |
| Future battery widget | proposed `/status/battery` | This Stage 7 page + fixture snippet |
| Future history charts | proposed `/status/resources/history` | Local resource history page |

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| HTTP API | Existing Flask helper | Second microservice for dashboard JSON |
| Schema proof | Fixture + Python validator | Hand-wavy “looks fine in browser” |
| Authz | Nginx allowlist + current helper guards | Dashboard-only “security” |
| Community intake | GitHub Issues for API ideas | Posting suggestions into helper storage |

## Rollout

1. Land this page under `suggestions/website/`.
2. Link it from CONTRIBUTING under helper/dashboard PRs.
3. Require PR template mention when `helper/` or the status fixture changes.
4. Implement Stage 7 product endpoints (battery, history, dependencies, idle policy) only under this contract.

## Acceptance criteria

- [ ] Helper/dashboard PRs cite this contract or an equivalent checklist.
- [ ] `/status/full` changes always update the fixture and validator in the same PR.
- [ ] No merged helper route stores community suggestions or votes.
- [ ] Control-plane and secret rules remain explicit.

## Rollback

Keep the page advisory; maintainers can reject helper PRs that skip the fixture without disabling existing CI.

## Success metrics

- Zero accidental `/status/full` breaks caught only in production.
- New operator widgets reuse helper routes instead of scraping Docker directly from the browser.
- Contributors open fewer “rebuild the API” suggestions after reading this page.
