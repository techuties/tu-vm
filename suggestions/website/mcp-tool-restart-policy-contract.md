---
title: MCP Tool Restart Policy Contract
description: Constructional contract so the filesystem, fetch, and memory MCP tools stay stopped across a Docker restart, matching the other Tier 2 services.
last_updated: 2026-10-27
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# MCP Tool Restart Policy Contract

## Problem

Three on-demand MCP tools come back after a Docker restart. The rest of Tier 2 does not.

`tu-vm.sh` lists `mcp-playwright`, `mcp-filesystem`, `mcp-fetch`, and `mcp-memory` in `TIER2_SERVICES`. Portable start creates them with `docker compose up -d --no-start` and leaves them stopped. The dashboard and `start-service` are how an operator turns one on.

Compose restart policies do not match that list:

```text
mcp-playwright   restart: "no"
mcp-filesystem   restart: unless-stopped
mcp-fetch        restart: unless-stopped
mcp-memory       restart: unless-stopped
```

`ollama`, `n8n`, `affine`, `mcp_gateway`, `langgraph_supervisor`, and `browserless` also use `restart: "no"`.

Docker ignores `unless-stopped` for a container that is stopped. A portable `up --no-start` therefore does not boot these three by itself. The split shows up after the first successful start. A later daemon restart starts any container whose policy is `unless-stopped` and that was not explicitly stopped. `restart: "no"` stays down. On a host that meets the 4GB minimum, those three Node processes are 256M reservations each, and the filesystem tool is the one Stage 42 (open PR #68) already calls out for listener auth.

Stage 18 (open PR #44) already states the rule: Tier 2 restart stays manual, and a higher memory cap is not a reason to auto-start Tier 2. The tree still breaks that rule on these three services. This page names the lines to change. It does not add a new supervisor or a new auth design.

Checked on 2026-10-27 by reading `docker-compose.yml` restart keys and `TIER2_SERVICES` in `tu-vm.sh`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `TIER2_SERVICES` | Already includes the four MCP tool services |
| `start_services` portable branch | `up -d --no-start` for Tier 2 |
| Dashboard `/control/<service>/start` | Starts one container when the operator asks |
| `mcp-playwright` `restart: "no"` | The policy the other three should match |
| Stage 18 resource budget (open PR #44) | The rule this page applies |
| Stage 42 pins and listener auth (open PR #68) | Image tags and auth. Unchanged here |

Out of scope:

- A process supervisor or a new compose profile
- MCP listener authentication
- Image digest pins
- Changing published ports (these services publish none)

## Proposal

Set `restart: "no"` on `mcp-filesystem`, `mcp-fetch`, and `mcp-memory`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `mcp-filesystem`, `mcp-fetch`, `mcp-memory` | `restart: "no"` |
| Comment | the MCP tool section header | One line that Tier 2 tools start from the dashboard or `tu-vm.sh start-service` |
| Docs | playbook | After a reboot, these three stay stopped until the operator starts them again |

No change to `TIER2_SERVICES`. No change to the helper name map. Those already start the containers on request.

### Rules

1. **Match `mcp-playwright`.** `restart: "no"` on all four MCP tool services.
2. **Keep the dashboard start.** `unless-stopped` is not a substitute for `/control/mcp-filesystem/start`.
3. **Leave memory limits where Stage 18 put them.** This change is the restart key only.
4. **Leave image pins and listener auth on Stage 42.**
5. **Do not add a watcher that starts them when n8n starts.** An operator who wants them up uses the existing start path.

### Suggested contributor checklist

```text
1. Confirm mcp-filesystem, mcp-fetch, and mcp-memory use restart: "no"
2. Confirm mcp-playwright is unchanged at restart: "no"
3. Confirm portable start still uses up -d --no-start for Tier 2
4. Confirm a daemon restart does not start a tool that was not running
5. Confirm the dashboard Start button still starts the named container
6. Confirm Dockerfiles and auth were not edited
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| On-demand lifetime | Compose `restart: "no"` | `unless-stopped` for a Tier 2 tool |
| Start control | `tu-vm.sh` and the helper `/control` route | A side process that watches Docker |
| Memory budget | Stage 18 limits | A higher limit so the auto-restart fits |
| Auth | Stage 42 listener contract | A new token design in this change |
| Intake | GitHub Issue | A forked MCP server |
