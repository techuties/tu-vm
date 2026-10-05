---
title: Gateway Public Docs Contract
description: Constructional contract so oweb.tu.lan publishes MCP and LangGraph liveness only, and detail plus OpenAPI docs require the bearer those apps already check.
last_updated: 2026-10-05
owner: maintainers
status: proposed
theme: security
impact: high
---

# Gateway Public Docs Contract

## Problem

Nginx publishes both apps on the Open WebUI vhost:

```nginx
location /api/mcp/ {
    proxy_pass http://172.20.0.26:9002/;
}
location /api/langgraph/ {
    proxy_pass http://172.20.0.29:9010/;
}
```

The landing cards say **Internal Only** and print `ai_mcp_gateway:9002` and `ai_langgraph_supervisor:9010`. `status()` and `./tu-vm.sh info` already advertise `https://oweb.tu.lan/api/mcp/` and `https://oweb.tu.lan/api/langgraph/`.

Both processes are created as `FastAPI(...)` with only `title` and `version`. FastAPI then serves `/docs`, `/redoc`, and `/openapi.json` with no dependency. The gateway also has:

```python
@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "ok": True,
        "affine_enabled": _affine_enabled(),
        "n8n_enabled": _n8n_enabled(),
        "n8n_mcp_enabled": _n8n_mcp_enabled(),
        "kb_enabled": _kb_enabled(),
        "write_approval_required": _write_approval_required(),
        "allowed_servers": sorted(_allowed_servers()),
        "langgraph_supervisor_enabled": ...,
        "langgraph_supervisor_url": langgraph_supervisor_url,
        "nodeTypesCount": len(_n8n_node_types),
        "nodeTypesLoadedAt": _node_types_loaded_at,
    }
```

```python
@app.get("/openapi-tools.json", include_in_schema=False)
async def openapi_tools_spec() -> JSONResponse:
```

Neither handler calls `_check_auth`. `/openapi-tools.json` returns every built-in tool name and its input schema.

LangGraph `/health` is also open and returns `strict_verify`, `gateway_url`, and `sorted(WRITE_TOOLS)`.

These callers need a tokenless 200 from `/health` and nothing else:

| Caller | Request |
|---|---|
| Compose `mcp_gateway` healthcheck | `curl -fsS http://localhost:9002/health` |
| Compose `langgraph_supervisor` healthcheck | `curl -fsS http://localhost:9010/health` |
| `scripts/langgraph-e2e-smoke.sh` step 1 | `GET ${BASE_URL}/api/langgraph/health` with no `Authorization` |
| `scripts/langgraph-e2e-smoke.sh` step 2 | `GET /api/mcp/health` with a bearer. The handler ignores the header today |

`/invoke` and `/execute` already require a bearer. `_check_auth` compares `MCP_GATEWAY_TOKEN`. The supervisor's `/execute` compares `LANGGRAPH_SUPERVISOR_TOKEN` or, when that is empty, `MCP_GATEWAY_TOKEN`.

Checked on 2026-10-05 in `nginx/conf.d/default.conf` (the two locations), both `FastAPI(...)` constructors, both `/health` handlers, `openapi_tools_spec`, the Compose healthchecks, and the smoke script. The routes were not requested on a live stack.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `_check_auth` | Bearer check for gateway routes that mutate or list tools |
| Supervisor `/execute` token check | The same secret family for LangGraph |
| Compose healthchecks | Must keep succeeding with no header |
| Smoke step 1 | Must keep succeeding with no header |
| `README.md` troubleshooting curls | `docker exec` against `/health` and `/openapi-tools.json` with no header |
| Landing reach tags | Say Internal Only while the vhost publishes the APIs |
| Stage 45 write-tool set (expected sibling, open PR #71) | Which names belong in `WRITE_TOOLS`. This page does not edit that set |
| Stage 45 callback credential (expected sibling, open PR #71) | The `X-LangGraph-Supervised` header. Leave it |
| Stage 42 listener auth (expected sibling, open PR #68) | Filesystem, fetch, memory, and Playwright listeners. Not these two FastAPI apps |
| Stage 41 KB public read (expected sibling, open PR #67) | Unauthenticated KB read tools. Leave that flag |

Out of scope:

- A new login, OAuth server, or dashboard session for MCP
- Moving the proxy off `oweb.tu.lan`
- Changing `WRITE_TOOLS` membership
- Requiring a token on the Compose healthcheck curl

## Proposal

Anonymous `/health` stays a liveness probe. Everything that describes the deployment requires the bearer those code paths already implement. The landing card should name the vhost path operators already use.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Stock docs | both `FastAPI(...)` apps | Set `docs_url=None`, `redoc_url=None`, and `openapi_url=None` |
| Gateway `/health` | `mcp-gateway/app.py` | With no valid bearer, return `{ok: true}` and 200. With a bearer that passes `_check_auth`, return the current object, plus `builtinToolCount` from the catalog-count page |
| Tool spec | `/openapi-tools.json` | Call `_check_auth` before building the spec |
| LangGraph `/health` | `langgraph-supervisor/app.py` | With no valid bearer, return `{ok: true}` and 200. With the bearer `/execute` already accepts, return today's detail object |
| README curls | troubleshooting section | Pass `Authorization: Bearer` from `MCP_GATEWAY_TOKEN` inside `docker exec` when the curl needs `nodeTypesCount` or the tool spec |
| Landing cards | MCP and LangGraph | Replace **Internal Only** with the web path `status()` already publishes (`oweb.tu.lan/api/mcp/` and `oweb.tu.lan/api/langgraph/`). State that calls need the existing token |
| Smoke and Compose | unchanged curls | They only check HTTP success of `/health` |

### Rules

1. **Liveness stays open.** Compose and smoke step 1 keep a tokenless 200 from `/health`.
2. **Detail requires the existing secret.** Do not invent a second docs token. Gateway detail uses `MCP_GATEWAY_TOKEN`. LangGraph detail uses the `/execute` check.
3. **Turn off stock docs.** `/docs`, `/redoc`, and `/openapi.json` are not part of the smoke script or the README curls. Disabling them is the whole change for those three paths.
4. **`/openapi-tools.json` is a catalog, not a healthcheck.** It gets `_check_auth`. Update the README `docker exec` line so operators still can count tools.
5. **Do not edit `WRITE_TOOLS`.** Hiding the list on anonymous `/health` is the change. Which names are in the set stays on the Stage 45 page.
6. **Do not lock the four MCP tool listeners here.** That is the Stage 42 listener page.
7. **Do not flip `KB_PUBLIC_READ_ENABLED`.** Anonymous KB reads stay on their own contract.
8. **The reach tag matches the vhost.** The cards stop saying Internal Only for routes Nginx publishes on `oweb.tu.lan`.

### Suggested contributor checklist

```text
1. Confirm Compose healthchecks and smoke step 1 use tokenless GET /health
2. Disable FastAPI docs, redoc, and openapi_url on both apps
3. Return {ok: true} from both /health handlers when the bearer is missing
4. Require _check_auth on /openapi-tools.json
5. curl /api/mcp/docs and /api/mcp/openapi-tools.json without a token and expect 404 and 401
6. curl both /health URLs without a token and expect 200 and a body of {ok: true}
7. Repeat /health with the existing bearer and expect the detail fields
8. Update the README docker exec lines that need those fields
9. Point the two landing cards at the oweb.tu.lan paths
10. Do not add a new auth service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Gateway auth | `_check_auth` | A new middleware stack |
| Supervisor auth | The `/execute` bearer check | A second token name |
| Liveness | Existing Compose `curl` of `/health` | Putting the token into the healthcheck |
| Tool spec | `/openapi-tools.json` behind that bearer | Stock `/docs` left on the vhost |
| Card label | The URL `status()` and `tu-vm.sh info` already print | A new hostname |

## Acceptance criteria

- `GET /api/mcp/health` and `GET /api/langgraph/health` with no token return 200 and a JSON object whose only field is `ok: true`.
- The same URLs with the existing bearer return the detail fields those handlers return today.
- `GET /api/mcp/docs`, `/api/mcp/redoc`, and `/api/mcp/openapi.json` are not served.
- `GET /api/mcp/openapi-tools.json` with no token returns 401.
- The same URL with `MCP_GATEWAY_TOKEN` returns the spec.
- Compose healthchecks remain tokenless `curl` commands and still treat HTTP 200 as healthy.
- Smoke step 1 stays a tokenless health GET and still passes on HTTP success.
- The MCP and LangGraph cards no longer say Internal Only. They show the `oweb.tu.lan` API paths.
- `WRITE_TOOLS`, the supervised-call header, and `KB_PUBLIC_READ_ENABLED` are unchanged.

## Verification notes

Read the FastAPI constructors, both health handlers, `openapi_tools_spec`, the Nginx locations, the Compose healthchecks, and smoke steps 1 and 2 on 2026-10-05. No request was sent to a running stack.

## Rollback

Restore the FastAPI defaults and the full anonymous health bodies, and restore the Internal Only tags. Compose healthchecks stay valid either way.
