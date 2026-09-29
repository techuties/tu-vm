---
title: Community Suggestions Website
description: Publishable Stage 45 website markdown for the Nginx health prefix, the supervisor callback header, the supervisor write-tool set, the n8n update deactivate side effect, and the dashboard VM IP source.
last_updated: 2026-09-29
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation safe for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#70 already specify the docs framework, governance, and most product contracts.

**Stage 45** (this run) records five defects checked on 2026-09-29 against the tree on `dev`. They are not restatements of Stages 1–44.

- App vhosts use prefix `location /health`, which also matches `/health/db` and `/healthz`. Those requests return Nginx’s static `healthy` body and never reach Open WebUI or n8n. The landing vhost already uses exact `location = /health`.
- `mcp-gateway` treats client header `X-LangGraph-Supervised` as proof that the LangGraph supervisor called back. The same `MCP_GATEWAY_TOKEN` the caller already presented is enough to skip delegation and write-approval. The header is not a second credential.
- `langgraph-supervisor` `WRITE_TOOLS` omits `n8n_delete_workflow` and `n8n_delete_execution`. The gateway still delegates those tools. Supervisor strict verify and supervisor dedupe do not apply, and the node then forces `verified = True`.
- `n8n_update_workflow` deactivates a live workflow when n8n returns HTTP 400 whose detail contains `trigger`, then retries the PUT. Nothing activates the workflow again if the retry fails, or after the retry succeeds.
- `GET /status` shows `vm_ip` from `HOST_IP` or from a UDP connect to `8.8.8.8`. The helper is on `ai_network`, not the host network, so the fallback address is the container address. The dashboard KPI prints that value as the VM address.

The contracts:

- Match app health locations the way the landing vhost already does
- Break the supervisor loop with the existing supervisor token, not a client header
- Use one write-tool set for delegation, strict verify, and dedupe
- Stop turning a failed workflow update into a deactivate
- Show the host `HOST_IP` the control script already detects, or show nothing

No new suggestion queue, voting database, identity provider, workflow engine, or metrics stack.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–44 website pages (open PRs #27–#70) | Implement those contracts in code; do not rewrite them here |
| Landing `location = /health` | The exact-match pattern app vhosts should copy |
| `LANGGRAPH_SUPERVISOR_TOKEN` | Existing second secret; use it as the callback credential |
| `confirm=true` inside n8n tool handlers | Stays the write guard; this stage does not remove it |
| `tu-vm.sh` `HOST_IP` detection | Host-side address source for the dashboard |

Do **not** add a new edge proxy, a second supervisor, or a public IP-lookup service. Do **not** republish Stage 11 log retention, Stage 22 journald, Stage 18 `no-new-privileges`, Stage 42 Nginx `add_header` inheritance, Stage 43 client-IP trust, Stage 43 dashboard `textContent`, or Stage 44 helper mount, helper image, update-status, digest compare, or host metric sources.

Stage 18 owns the helper control token and the 401. Stage 42 owns unknown `/control/<service>` names. Stage 12 owns announcement categories. Stage 44 owns load, memory, disk, and battery sources. This stage only covers the **VM address** field.

## Page map (Stage 45)

| Page | Purpose |
|---|---|
| [Nginx static health prefix](./nginx-static-health-prefix-contract.md) | Exact `location = /health` so `/health/db` and `/healthz` reach the app |
| [Supervisor callback credential](./supervisor-callback-credential-contract.md) | Only the supervisor token may skip a second delegation |
| [Supervisor write-tool set](./supervisor-write-tool-set-contract.md) | Deletes join the same strict-verify and dedupe set as other n8n writes |
| [n8n update deactivate](./n8n-update-deactivate-contract.md) | A failed update must not leave the workflow stopped |
| [Dashboard VM IP source](./dashboard-vm-ip-source-contract.md) | The KPI shows host `HOST_IP` or an empty value |

## Expected sibling pages

Stages 1–44 live on open PRs #27–#70 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `how-to-submit.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, `nginx-edge-routing-contract.md`, `autonomous-write-guard-policy.md`, `helper-control-auth-contract.md`, `host-metrics-source-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 45** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Edge health | Exact `location =` already used on the landing vhost | A second health sidecar |
| Supervisor loop break | `LANGGRAPH_SUPERVISOR_TOKEN`, already in Compose and `env.example` | A new approval service |
| Write confirm | Existing `confirm=true` checks in `mcp-gateway/app.py` | Removing confirms to make updates “just work” |
| VM address | `HOST_IP` written by `tu-vm.sh` on the host | A UDP probe to a public resolver from the helper |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Edge day-to-day: header inheritance (Stage 42), then exact health locations
3. AI pipeline day-to-day: callback credential, write-tool set, n8n update deactivate
4. Operator day-to-day: VM address source, after Stage 44 metric sources
5. Quality gates: merge playbook

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
