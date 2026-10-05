---
title: MCP Catalog Count Contract
description: Constructional contract so the landing page stops advertising 22 tools and 541 node types, and uses the gateway schema functions plus nodeTypesCount instead.
last_updated: 2026-10-05
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# MCP Catalog Count Contract

## Problem

The landing page states a fixed catalog size in two copy blocks:

```html
<div class="pipeline-node-sub">22 tools &middot; 541 node types<br/>Validation &middot; Reference docs</div>
```

```html
<div class="svc-desc">Tool router exposing 22 tools and 541 n8n node schemas via OpenAPI. ...</div>
```

The gateway does not use either integer. Built-in tools are three functions, counted from the `"name"` fields on 2026-10-05:

| Function | Tools | Default gate |
|---|---|---|
| `_n8n_tool_schemas` | 16 | `N8N_MCP_ENABLED` and server `n8n` (Compose default on) |
| `_n8n_mcp_tool_schemas` | 5 | `N8N_MCP_SERVER_ENABLED` and server `n8n_mcp` (Compose default on) |
| `_kb_tool_schemas` | 6 | `KB_MCP_ENABLED` and server `kb` (Compose default on) |

That is 27 built-in tools before AFFiNE. `_affine_enabled()` appends whatever `affine-mcp-server` lists at runtime, which is not a fixed 22.

Node types are `len(_n8n_node_types)` after `_reload_node_types()` reads `/app/n8n_node_types.json`. `GET /health` already returns that length as `nodeTypesCount`. The JSON file is listed in `.gitignore` (`mcp-gateway/n8n_node_types.json`) and is not in this checkout. The loader logs a warning and leaves the list empty, so `nodeTypesCount` is 0 until `scripts/extract-n8n-node-types.sh` has produced the file. The HTML still says 541.

`README.md` already tells operators to count tools from the live spec:

```bash
docker exec ai_mcp_gateway curl -s http://localhost:9002/openapi-tools.json
```

Checked by reading both HTML strings, the three schema functions, `_reload_node_types`, `/health`, `.gitignore`, and the Compose mount `./mcp-gateway/n8n_node_types.json:/app/n8n_node_types.json:ro`. The gateway was not started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Schema functions in `mcp-gateway/app.py` | The built-in tool list |
| `GET /health` `nodeTypesCount` | The loaded node-type total |
| `GET /openapi-tools.json` | The spec `list_tools` and the README curl already use |
| `scripts/extract-n8n-node-types.sh` | The generator for the gitignored catalog |
| Stage 15 `n8n-node-types-extraction-contract.md` (expected sibling, open PR #41) | How contributors refresh the JSON file |
| Stage 51 gateway public-docs page (this folder) | Who may read `/health` detail and `/openapi-tools.json` |

Out of scope:

- Committing `n8n_node_types.json` or inventing a new extractor
- A dashboard poller that calls the gateway on every refresh
- Changing which tools exist
- AFFiNE MCP command selection

## Proposal

Describe the router without frozen integers. If a number is shown, it has to come from the functions and the health field that already compute it.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Pipeline copy | `index.html` MCP node | Say tool router, validation, and reference docs. Drop `22 tools` and `541 node types` |
| Service card | MCP `svc-desc` | Same words, no integers |
| Health | existing `/health` | When the request already satisfies `_check_auth`, include `builtinToolCount` as the length of the three schema lists that are enabled. Keep `nodeTypesCount` as the file length |
| Anonymous health | same route | Stay `{ok: true}` for Compose. The public-docs page in this stage owns that split. This page only adds the count field on the authenticated body |
| Extractor | unchanged | Operators keep `./scripts/extract-n8n-node-types.sh` |

### Rules

1. **Copy follows code.** 27 is the current built-in total with defaults on. Do not write 27 into HTML either. The next tool PR would make it stale again.
2. **Node types follow `nodeTypesCount`.** A missing gitignored file means zero, which is the honest number until extraction runs.
3. **Do not build a count microservice.** The schema functions and `/health` are enough.
4. **Do not fetch the gateway from the browser on the status interval.** The landing page is static text unless a later change reads a same-origin helper field. That later change is optional and out of this page.
5. **Leave extraction on the Stage 15 contract.** This page does not change the script, the Dockerfile `COPY`, or the bind mount.
6. **Leave tool auth and KB public read alone.** Counting tools is not a reason to change `_check_auth` policy beyond the authenticated health body the sibling page already asks for.

### Suggested contributor checklist

```text
1. Count name fields in the three schema functions and confirm 16 + 5 + 6
2. Remove both hardcoded 22 / 541 strings from index.html
3. Add builtinToolCount next to nodeTypesCount on the authenticated health body
4. With no n8n_node_types.json, confirm nodeTypesCount is 0
5. After extract-n8n-node-types.sh, confirm nodeTypesCount matches the file length
6. Do not commit the generated JSON from this change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tool total | The three schema functions | A number in HTML |
| Node-type total | `nodeTypesCount` | The historical 541 |
| Refreshing the catalog | `scripts/extract-n8n-node-types.sh` | A new scraper |
| Operator check | README `docker exec` curl of the existing spec | A dashboard client |

## Acceptance criteria

- `nginx/html/index.html` contains neither `22 tools` nor `541`.
- Authenticated `GET /health` includes `builtinToolCount` equal to the enabled built-in schemas (27 with today's defaults and all three groups on).
- Authenticated `GET /health` still includes `nodeTypesCount` from the loaded file.
- A checkout without `n8n_node_types.json` reports `nodeTypesCount` 0.
- No new catalog file is committed and the extractor script is unchanged.

## Verification notes

Counted schema names with an AST walk of `mcp-gateway/app.py` on 2026-10-05: 16 + 5 + 6. Confirmed `.gitignore` contains `mcp-gateway/n8n_node_types.json` and that path is absent in the worktree. `/health` returns `nodeTypesCount: len(_n8n_node_types)`.

## Rollback

Restore the two HTML sentences and omit `builtinToolCount`. Extraction and the node-type file stay as they are.
