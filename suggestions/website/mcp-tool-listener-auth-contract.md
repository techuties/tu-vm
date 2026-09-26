---
title: MCP Tool Listener Auth Contract
description: Constructional contract to keep filesystem, fetch, memory, and Playwright MCP listeners off host ports, and to avoid treating supergateway's outbound bearer flag as inbound authentication.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: security
impact: high
---

# MCP Tool Listener Auth Contract

## Problem

These Compose services accept unauthenticated HTTP from any peer on `ai_network`:

| Service | How it listens | Host `ports:` |
|---|---|---|
| `mcp-filesystem` | `supergateway` on port 3001, no token | none |
| `mcp-fetch` | `supergateway` on port 3002, no token | none |
| `mcp-memory` | `supergateway` on port 3003, no token | none |
| `mcp-playwright` | `@playwright/mcp --host 0.0.0.0 --allowed-hosts *` on port 3000 | none |

No host publish is the correct default. The footgun is the next debugging change: adding `ports:` or an Nginx `server_name` and assuming the listener is authenticated.

supergateway **4.0.0** (the pin target on the build-pin page) documents `--oauth2Bearer` and `--header` for calls **out** to a remote MCP server (`SSE → stdio` and `Streamable HTTP → stdio`). The option list also allows `--header` in `stdio → SSE` mode, which adds headers. It does **not** document an inbound bearer check. Putting `--oauth2Bearer` on the filesystem/fetch/memory `CMD` does not lock the listener. Playwright's current `CMD` has no token flag either. Do not invent one.

Stage 18 `mcp-tool-sandbox-contribution-contract.md` owns `--allowed-hosts *`, the `/shared` volume, fetch egress, and memory persistence. Stage 26 owns `restart: "no"` for filesystem, fetch, and memory. Stage 12 host-port binding owns the general "do not publish debug ports" rule. This page only states the **auth fact** for these four listeners and where a real bearer already exists.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-tools/*/Dockerfile` | Listen commands with no inbound token |
| Compose MCP tool services | No `ports:` mappings |
| `mcp-gateway` `MCP_GATEWAY_TOKEN` | Bearer check in `_check_auth` |
| supergateway 4.0.0 README | `--oauth2Bearer` is outbound |
| Stage 18 sandbox (expected sibling) | Hosts, volumes, egress |
| Stage 26 restart honesty (expected sibling) | Tier 2 `restart:` |
| Build-pin page (this stage) | Which supergateway version this claim uses |

Out of scope:

- A new identity provider in front of every tool
- Implementing inbound auth inside supergateway
- Changing `--allowed-hosts` (Stage 18)
- Publishing the tools on `tu.lan` hostnames
- Rewriting gateway auth

## Proposal

1. **Keep host ports unpublished.** Do not add `ports:` for 3000–3003. Do not add an Nginx vhost that proxies them to the LAN.
2. **Do not fake a lock.** Do not add `--oauth2Bearer` to the server-mode `CMD` and document it as authentication.
3. **Browser and Open WebUI access** continues through `mcp-gateway`, which already rejects a missing or wrong `MCP_GATEWAY_TOKEN`.
4. **Direct n8n MCP Client use** of these internal ports is an operator choice on `ai_network`. The catalog and this page say the listener is unauthenticated. If a future supergateway release documents a real inbound check, a PR may enable it only by citing that README section and a `curl` without the token that receives 401.
5. **Playwright** stays bound for in-network use only. Stage 18 continues to own `--allowed-hosts *`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | MCP tool services | Confirm `ports` stays absent |
| Dockerfiles | `CMD` | Do not add a decorative `--oauth2Bearer` |
| Docs | Stage 1 catalog sibling, when merged | One line: internal, no inbound token |
| Gateway | existing `/invoke` auth | Unchanged |

### Rules

1. **Cite the README before adding an auth flag.** 4.0.0 does not provide the inbound check.
2. **The gateway token is the community auth.** Do not create a second token type for the same call path.
3. **Debug port forwards are local and temporary.** They are not committed as `ports:`.
4. **Stage 18 still owns sandbox flags.** This page must not relax `--allowed-hosts` or mount the operator home.
5. **GitHub remains intake.** A request for public tool URLs is an Issue, not a vhost added in a docs PR.

### Suggested contributor checklist

```text
1. Confirm mcp-filesystem, mcp-fetch, mcp-memory, and mcp-playwright have no ports: mappings
2. Read the supergateway 4.0.0 README section for --oauth2Bearer
3. Leave server-mode CMD without that flag
4. Point LAN callers at mcp-gateway and MCP_GATEWAY_TOKEN
5. Do not add a public server_name for ports 3000-3003
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Authenticated tool calls | Existing gateway bearer | A new auth proxy per tool |
| Listener exposure | Compose network only | Host `ports:` plus a guessed flag |
| Package version | Build-pin page (`supergateway@4.0.0`) | Assuming a newer inbound-auth flag exists |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** only if a `ports:` mapping has appeared. On 2026-09-26 the tree has none, so the code change is "do not add one," plus a catalog sentence when Stage 1 is merged.
3. No restart is required for a docs-only landing of this page.

## Acceptance criteria

- [ ] Compose does not publish ports 3000–3003.
- [ ] Tool `CMD` lines do not use `--oauth2Bearer` as if it authenticated inbound HTTP.
- [ ] The page states that gateway access still uses `MCP_GATEWAY_TOKEN`.
- [ ] Stage 18 sandbox flags and Stage 26 `restart` keys are not rewritten.
- [ ] A future inbound-auth PR cites the supergateway README and shows an unauthenticated 401.

## Rollback

There is no runtime change while `ports` stay absent. If a later PR added a mistaken `--oauth2Bearer` gate, remove that flag.

## Success metrics

- Debug sessions do not land in git as published tool ports.
- Contributors stop treating `--oauth2Bearer` as a server password.
- Open WebUI tool calls keep using the gateway token they already have.
