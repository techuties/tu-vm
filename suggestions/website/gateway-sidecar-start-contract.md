---
title: Gateway Sidecar Start Contract
description: Constructional contract so starting the MCP Gateway also starts the existing ai_n8n_mcp container. The helper already does this for LangGraph and does not do it for n8n-mcp.
last_updated: 2026-10-16
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Gateway Sidecar Start Contract

## Problem

Compose points the MCP Gateway at the n8n-mcp sidecar unless the operator overrides it:

```text
N8N_MCP_SERVER_ENABLED: ${N8N_MCP_SERVER_ENABLED:-true}
N8N_MCP_SERVER_URL: ${N8N_MCP_SERVER_URL:-http://ai_n8n_mcp:3000/mcp}
```

`n8n_mcp` is in `TIER2_SERVICES`. Portable `./tu-vm.sh start` creates that container with `up -d --no-start` and leaves it stopped. `restart` on the service is `"no"`.

The landing page can start the gateway. `controlService('mcp-gateway','start')` calls `POST /control/mcp-gateway/start`. In `helper/uploader.py` that branch inspects `ai_langgraph_supervisor` and, when the container exists and is not running, starts it. It then starts `ai_mcp_gateway`. There is no matching start for `ai_n8n_mcp`.

The same handler's `name_map` already accepts `n8n_mcp` and `n8n-mcp` and maps them to `ai_n8n_mcp`. Nothing in `nginx/html/index.html` calls that name. A search of the landing page on 2026-10-16 found no `n8n_mcp` and no `n8n-mcp`. Starting n8n from its own card starts only `ai_n8n`. The enrichment sidecar stays stopped, and the gateway's `n8n_mcp_*` tools call a container that portable mode deliberately did not start.

Open PR #40 is the contribution rule for this sidecar (do not replace it with a node-docs service). Open PR #68 is the control-name allowlist (unknown names must not fall through to arbitrary container ids). Neither page starts `ai_n8n_mcp` from the gateway action.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `control_service` in `helper/uploader.py` | Starts LangGraph as a dependency of `mcp_gateway` |
| `name_map` entries `n8n_mcp` and `n8n-mcp` | The Docker name is already accepted |
| `TIER2_SERVICES` in `tu-vm.sh` | Creates `n8n_mcp` stopped on portable start |
| Compose `n8n_mcp` environment | HTTP mode on port 3000 with `N8N_API_URL` aimed at `ai_n8n` |
| Landing page MCP Gateway card | The button operators already use |
| Open PR #40 sidecar contribution page (expected sibling) | Keep this container. Do not add a documentation microservice |
| Open PR #68 control allowlist page (expected sibling) | Do not widen the fallthrough that starts arbitrary containers |
| Stage 26 MCP tool `restart:` page (open PR #52) | Playwright, filesystem, fetch, and memory restart keys. Not this sidecar |

Out of scope:

- Starting n8n itself as a side effect of the gateway. The n8n card remains the way to start `ai_n8n`
- A dashboard product for MCP tool marketplaces
- Changing `N8N_MCP_SERVER_URL`
- The LangGraph token and write-approval contracts (Stages 45 and 47)

## Proposal

Use the LangGraph inspect-then-start block for `ai_n8n_mcp` as well.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Gateway start | `control_service` when `compose_service == 'mcp_gateway'` | If `ai_n8n_mcp` exists and is not running, `POST /containers/ai_n8n_mcp/start` before starting the gateway |
| n8n start | Same function when `compose_service == 'n8n'` | Same inspect-then-start of `ai_n8n_mcp` |
| Missing container | Same blocks | If inspect finds nothing, skip the sidecar and still start the requested service. Match the LangGraph guard (`lg_info and not running`) |
| Dashboard | `nginx/html/index.html` | No new card is required. The MCP Gateway and n8n buttons gain the sidecar. A status line may reuse a later `/status` probe. Do not add one in this change unless the existing `/status/mcp` pattern is copied exactly |
| Stop | `action == 'stop'` | Do not stop the sidecar when the gateway stops. Operators stop `n8n-mcp` only through an explicit control call |

### Rules

1. **Only start a container the map already names.** The id is `ai_n8n_mcp`. Do not pass the request path through to the Docker socket.
2. **Do not require the helper to read `N8N_MCP_SERVER_ENABLED`.** That variable is not in the `helper_index` environment. The LangGraph start does not consult `LANGGRAPH_SUPERVISOR_ENABLED` either. Absence of the container is the off switch.
3. **n8n stays operator-started.** Gateway start must not call `ai_n8n/start`.
4. **A stopped sidecar is the bug.** After portable start, Start on MCP Gateway leaves `ai_n8n_mcp` running when that container was created by `up --no-start`.
5. **Keep the image and the port.** Do not add a second n8n-mcp service.

### Suggested contributor checklist

```text
1. Create ai_n8n_mcp stopped, and ai_langgraph_supervisor stopped
2. POST /control/mcp-gateway/start with a valid control token
3. Confirm both ai_mcp_gateway and ai_n8n_mcp are running, and ai_n8n is not
4. POST /control/n8n/start and confirm ai_n8n_mcp is started with ai_n8n
5. POST /control/mcp-gateway/stop and confirm ai_n8n_mcp is still running
6. Confirm an unknown service name still follows the allowlist contract on open PR #68
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Dependency start | The LangGraph block already in `control_service` | Compose from inside the helper, or a new supervisor |
| Sidecar | `n8n_mcp` in `docker-compose.yml` | A node-docs service (open PR #40) |
| Button | The MCP Gateway and n8n cards | A new control API |
