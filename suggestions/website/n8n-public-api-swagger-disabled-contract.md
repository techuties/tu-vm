---
title: n8n Public API Swagger Disabled Contract
description: Constructional contract to set official N8N_PUBLIC_API_SWAGGERUI_DISABLED=true so the API playground is off, while keeping the public API enabled for mcp_gateway and n8n-mcp day-to-day community tools.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Public API Swagger Disabled Contract

## Problem

The `n8n` service does not set `N8N_PUBLIC_API_SWAGGERUI_DISABLED`. Official n8n defaults that flag to `false`, so the Swagger UI (API playground) is reachable under the public API path. On a shared community host, the playground advertises every REST operation next to a login that community members already use for workflows.

`N8N_PUBLIC_API_DISABLED=true` would hide the playground **and** break day-to-day integrations: `mcp_gateway` and `n8n_mcp` call the n8n API with `N8N_API_KEY`. Community suggestions that “turn off the n8n API for security” reinvent a blunt switch and strand the MCP lane this repo already ships.

This is distinct from:

- Stage 34 `openwebui-api-keys-endpoint-contract.md` (Open WebUI keys, not n8n Swagger)
- Stage 30 `n8n-auth-env-honesty-contract.md` (owner/basic-auth env)
- Stage 32 `n8n-runners-enabled-contract.md` (task runners, not API docs)
- Helper `CONTROL_TOKEN` (dashboard, not n8n REST)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` environment | Public API flags unset (Swagger on by official default) |
| `mcp_gateway` / `n8n_mcp` | Already use `N8N_INTERNAL_URL` + `N8N_API_KEY` |
| `env.example` | `N8N_API_KEY`, `N8N_REQUIRE_API_KEY` |
| Official n8n deployment env | `N8N_PUBLIC_API_SWAGGERUI_DISABLED`, `N8N_PUBLIC_API_DISABLED`, `N8N_PUBLIC_API_ENDPOINT` |
| GitHub Issues suggestion form | Intake if someone wants a LAN OpenAPI file in docs |

Out of scope:

- Disabling the public API (`N8N_PUBLIC_API_DISABLED`)
- A custom API gateway in front of n8n
- Rewriting Stage 34 Open WebUI API-key endpoint limits
- Publishing live Swagger as a community website feature

## Proposal

Disable the official playground only:

```text
N8N_PUBLIC_API_SWAGGERUI_DISABLED: "true"
```

Leave `N8N_PUBLIC_API_DISABLED` unset/false. Keep `N8N_REQUIRE_API_KEY=true` on the gateway (already in `env.example`). Do not invent `TU_VM_N8N_HIDE_SWAGGER`.

Documented API shape for contributors belongs in playbooks or upstream n8n docs, not an exposed playground on `n8n.${DOMAIN}`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official Swagger-disabled flag |
| Env schema | `env.example` | Comment that MCP/API keys still work |
| Docs | n8n + MCP playbooks | Use API keys; do not open `/api/v1/docs` |

### Rules

1. **Official key only.** Do not nginx-403 the docs path as the primary control.
2. **Do not disable the public API.** MCP day-to-day depends on it.
3. **Do not confuse with Open WebUI keys.** Stage 34 owns that product.
4. **GitHub remains intake.** Static OpenAPI-in-docs requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_PUBLIC_API_SWAGGERUI_DISABLED
2. Set the flag true on the n8n service
3. Recreate n8n and confirm the Swagger UI is gone
4. Confirm mcp_gateway / n8n_mcp still authenticate with N8N_API_KEY
5. Do not set N8N_PUBLIC_API_DISABLED=true
6. Do not rewrite Stage 34 Open WebUI API-key pages
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide API playground | Official `N8N_PUBLIC_API_SWAGGERUI_DISABLED` | nginx location hacks as the source of truth |
| Keep MCP/n8n API | Leave public API enabled + existing API keys | `N8N_PUBLIC_API_DISABLED=true` |
| Open WebUI programmatic chat | Stage 34 official Open WebUI keys | One “disable all APIs” essay |
| Contributor API docs | Upstream n8n docs + playbooks | Shipping live Swagger on the LAN vhost |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Missing Swagger UI is expected; MCP paths stay.

## Acceptance criteria

- [ ] `n8n` sets `N8N_PUBLIC_API_SWAGGERUI_DISABLED=true`.
- [ ] `N8N_PUBLIC_API_DISABLED` is not set true.
- [ ] `mcp_gateway` / `n8n_mcp` API usage is unchanged.
- [ ] Stage 34 Open WebUI API-key page is not rewritten.

## Rollback

Set the flag `false` (official default). API keys and workflows remain.

## Success metrics

- The n8n vhost no longer serves an interactive API playground.
- Community MCP integrations keep working without a new gateway.
