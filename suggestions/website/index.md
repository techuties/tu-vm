---
title: Community Suggestions Website
description: Publishable Stage 43 website markdown for control-allowlist client IP trust and dashboard rendering of untrusted operator text.
last_updated: 2026-09-27
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation safe for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#68 already specify the docs framework, governance, and most product contracts.

**Stage 43** (this run) records two defects checked on 2026-09-27 against the tree on `dev`. They are not restatements of Stages 1–42.

- `helper/uploader.py` `_client_ip()` enrolls the first `X-Forwarded-For` hop. `location = /whitelist/auto` sets that header with `$proxy_add_x_forwarded_for`, so a client can choose the address written into the control allowlist. The same anonymous response includes the `ips` array.
- `nginx/html/index.html` assigns announcement titles, announcement messages, processor filenames, and control error bodies with `innerHTML`. Log samples and object keys are attacker-influenced text. The page stores `CONTROL_TOKEN` in `localStorage`.

The contracts:

- Enroll the Nginx peer (`X-Real-IP` / `$remote_addr`) and stop returning the allowlist from anonymous bootstrap
- Render those dashboard strings as text on the existing page

No new suggestion queue, voting database, identity provider, sanitizer library, or dashboard framework.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–42 website pages (open PRs #27–#68) | Implement those contracts in code; do not rewrite them here |

Do **not** add a local voting database, suggestion queue API, or a second community login. Do **not** republish Stage 11 log retention, Stage 22 journald, Stage 18 `no-new-privileges`, Stage 42 helper name fallthrough, Stage 42 Nginx `add_header` inheritance, Stage 42 processor byte caps, or Stage 42 MCP pins.

Stage 13 owns `whitelist-add` and lockout recovery. Stage 18 owns the control token and anonymous 401. Stage 12 owns announcement categories and priorities. This stage only covers **peer-address trust**, **the public bootstrap body**, and **text insertion**.

## Page map (Stage 43)

| Page | Purpose |
|---|---|
| [Helper client IP trust](./helper-client-ip-trust-contract.md) | Bootstrap enrolls the peer and does not list the allowlist anonymously |
| [Dashboard untrusted text](./dashboard-untrusted-text-contract.md) | Log samples, filenames, and error bodies render as text |

## Expected sibling pages

Stages 1–42 live on open PRs #27–#68 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `how-to-submit.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, `ip-allowlist-day2-contract.md`, `helper-control-auth-contract.md`, `dashboard-announcements-contract.md`, `helper-control-service-allowlist-contract.md`, `nginx-add-header-inheritance-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 43** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Allowlist edits | `./tu-vm.sh whitelist-*` and the existing helper | A new access-control service |
| Client address | Nginx `$remote_addr` | The first `X-Forwarded-For` hop |
| Dashboard text | `textContent` on `nginx/html/index.html` | DOMPurify or a UI rewrite |
| Announcements | Existing `/announcements` JSON | A push or chat product |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Control day-to-day: token (Stage 18), service names (Stage 42), then client IP trust
3. Dashboard day-to-day: announcement taxonomy (Stage 12), then untrusted text
4. Quality gates: merge playbook

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
