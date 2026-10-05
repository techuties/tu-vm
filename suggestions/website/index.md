---
title: Community Suggestions Website
description: Publishable Stage 51 website markdown for the dead External IP tile, stale MCP catalog counts, the helper Docker client timeout, and anonymous gateway docs on the Open WebUI host.
last_updated: 2026-10-05
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#76 already specify the docs framework, governance, and most product contracts.

**Stage 51** (this run) records four defects checked on 2026-10-05 against the tree on `dev`. They are not restatements of Stages 1–50.

- The landing KPI labeled **External IP** reads `external_ip` or `ip` from `GET /status`. `helper/uploader.py` `status()` never sets either field. A repo search finds those names only in `nginx/html/index.html`. The tile stays `--`.
- The same page says the MCP Gateway exposes **22 tools** and **541 node types** in two places. The gateway schema functions define 16 `n8n_*` tools, 5 `n8n_mcp_*` tools, and 6 `kb_*` tools (27) when the Compose defaults enable those three groups. AFFiNE tools are added at runtime. `GET /health` already returns `nodeTypesCount` from `mcp-gateway/n8n_node_types.json`. That file is gitignored and is not in this checkout, so a fresh tree loads zero node types while the HTML still says 541.
- Helper `docker_post` uses a 5 second HTTP timeout for both start and stop. Stop calls `POST /containers/{id}/stop` with no `t` query. The Engine's default wait before kill is 10 seconds. The client gives up first, and `control_service` turns that exception into HTTP 500.
- `https://oweb.tu.lan/api/mcp/` and `/api/langgraph/` proxy to FastAPI apps created with the default docs URLs. `/health` and `/openapi-tools.json` do not call `_check_auth`. The landing cards for both services say **Internal Only**. Compose healthchecks and `scripts/langgraph-e2e-smoke.sh` step 1 call `/health` with no token, so the liveness route has to stay open. The anonymous body and the stock docs do not.

The contracts:

- Remove the External IP tile. Do not add a public-address lookup.
- Stop hardcoding catalog integers. Count tools from the schema functions that already exist, and read node-type totals from `nodeTypesCount`.
- Make the helper's Docker stop call finish inside its own HTTP timeout.
- Keep unauthenticated `/health` as `{ok: true}` for the checks that already curl it. Require the existing bearer for detail and for `/openapi-tools.json`, and turn off stock FastAPI docs.

No new suggestion queue, voting database, wiki, IP-geolocation client, or second API gateway.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–50 website pages (open PRs #27–#76) | Implement those contracts in code; do not rewrite them here |
| `status()` `vm_ip` | Stage 45 owns the host `HOST_IP` source. This stage does not |
| `GET /health` on the gateway | Liveness for Compose and the smoke script |
| `_check_auth` | The bearer check detail routes should call |
| `_n8n_tool_schemas`, `_n8n_mcp_tool_schemas`, `_kb_tool_schemas` | The tool list the landing page should not freeze |

Do **not** republish Stage 50's AFFiNE Compose start, Pi-hole hosts file, update Check Now button, or Tika client timeout. Do **not** change `vm_ip` discovery (Stage 45) or container metric sources (Stage 44). Do **not** change which names are in `WRITE_TOOLS` (Stage 45 write-tool set) or the supervisor callback header (Stage 45 callback credential). Do **not** retune KB public read (Stage 41, PR #67) or MCP tool-listener auth (Stage 42, PR #68). Do **not** regenerate `n8n_node_types.json` here (Stage 15 extraction contract, PR #41).

## Page map (Stage 51)

| Page | Purpose |
|---|---|
| [External IP tile](./external-ip-kpi-contract.md) | Remove the KPI no payload fills |
| [MCP catalog counts](./mcp-catalog-count-contract.md) | Landing copy must follow the schema functions and `nodeTypesCount` |
| [Helper Docker API timeout](./helper-docker-api-timeout-contract.md) | Stop must return before the helper client gives up |
| [Gateway public docs](./gateway-public-docs-contract.md) | Anonymous routes on `oweb.tu.lan` stay liveness-only |

## Expected sibling pages

Stages 1–50 live on open PRs #27–#76 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `dashboard-vm-ip-source-contract.md`, `host-metrics-source-contract.md`, `n8n-node-types-extraction-contract.md`, `supervisor-write-tool-set-contract.md`, `mcp-tool-listener-auth-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 51** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| LAN address on the dashboard | `HOST_IP` (Stage 45) | A public IP lookup for a new tile |
| Tool and node counts | Schema functions and `nodeTypesCount` | Integers copied into HTML |
| Container stop | The Docker Engine API the helper already calls, with a wait that fits the client | A second start/stop client |
| Gateway auth | `_check_auth` and the Compose healthcheck curl | A new identity provider |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: an honest status strip, then catalog numbers that match the gateway
3. Operator day-to-day: a stop button that waits long enough, then gateway docs that match the token already required for `/invoke`
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
