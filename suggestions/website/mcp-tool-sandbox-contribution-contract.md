---
title: MCP Tool Sandbox Contribution Contract
description: Constructional contract for community changes to mcp-tools Playwright, filesystem, fetch, and memory images—reuse the existing Compose sidecars and catalog instead of host npx MCP servers.
last_updated: 2026-08-13
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# MCP Tool Sandbox Contribution Contract

## Problem

Optional MCP tool servers (`mcp-playwright`, `mcp-filesystem`, `mcp-fetch`, `mcp-memory`) are the community-facing way to give n8n and Open WebUI tools. They are built from `mcp-tools/*/Dockerfile`, pinned to `ai_network` addresses, and intended to stay Tier 2. Today the sandboxes are loose: Playwright uses `--allowed-hosts *`, filesystem writes the shared `mcp_shared` volume, fetch has unbounded egress, and memory persists `mcp_memory_data`.

Stage 1 catalog and Stage 4 catalog-CI describe *how to list* tools. Stage 11 Browserless and Stage 14 n8n-mcp cover adjacent products. Contributors still need a **sandbox contract** so new MCP images do not run on the host, mount `$HOME`, or disable isolation “to make the demo work.”

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-tools/playwright/Dockerfile` | Headless Chromium MCP on port 3000 |
| `mcp-tools/filesystem/Dockerfile` | `@modelcontextprotocol/server-filesystem` on `/shared` via supergateway |
| `mcp-tools/fetch/Dockerfile` | `mcp-server-fetch` via supergateway |
| `mcp-tools/memory/Dockerfile` | Persistent graph in `/data/memory.json` |
| `docker-compose.yml` MCP tool services | IPs `.31`–`.34`, resource limits, Pi-hole DNS |
| Volume `mcp_shared` / `mcp_memory_data` | Isolated data—not the operator home directory |
| Stage 1 `mcp-tools-catalog.md` (expected sibling) | Human catalog entries |
| Stage 4 `mcp-catalog-ci-contract.md` (expected sibling) | `mcp-tools/catalog.yaml` validation |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Gateway/supervisor **code**, not tool images |
| Stage 11 `browserless-automation-contribution-contract.md` (expected sibling) | Browserless product lane (do not duplicate as a second Chromium) |
| Stage 14 `n8n-mcp-sidecar-contribution-contract.md` (expected sibling) | n8n node intelligence sidecar |

Out of scope:

- Installing `@modelcontextprotocol/server-*` on the host or via ad-hoc `npx` in operator cron
- Mounting `/`, `$HOME`, or Docker socket into filesystem MCP
- Making Playwright/Fetch always-on Tier 1
- A marketplace UI or paid MCP registry

## Proposal

Publish an **MCP tool sandbox contract** for PRs that add or change `mcp-tools/*` images and their Compose services.

### Per-tool sandbox expectations

| Tool | Allowed surface | Must not |
|---|---|---|
| Playwright | Headless browser; tighten `--allowed-hosts` over time | Privileged, host network, or GUI display by default |
| Filesystem | `/shared` on `mcp_shared` only | Bind-mount operator home, repo root, or `/var/run/docker.sock` |
| Fetch | HTTP(S) egress with future allowlist/blocklist | SSRF into `172.20.0.0/16` control plane without review |
| Memory | `/data/memory.json` on `mcp_memory_data` | Mixing memory with Open WebUI chat DB |

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Image recipe | `mcp-tools/<id>/Dockerfile` | Pinned or documented npm/pip versions; no host network |
| Compose service | `docker-compose.yml` | Unused IP (Stage 18 IPAM), resource limits, `restart: "no"` or explicit unless-stopped rationale |
| Catalog | Stage 4 `catalog.yaml` when present | Name, port, required volumes, risk notes |
| Volume | `volumes:` | Named volume, not a host path, unless an override |
| Docs | README / playbooks | How n8n MCP Client should connect on the LAN |

### Rules

1. **Stay in Compose.** Community MCP tools ship as images under `mcp-tools/`, not as undocumented host processes.
2. **Filesystem MCP sees `/shared` only.** Broader mounts require a security review and Stage 8 override, not a default.
3. **Do not widen Playwright `--allowed-hosts *` further** (for example host network). Prefer tightening when a demo no longer needs `*`.
4. **Fetch must not be treated as an internal admin client.** PRs that teach Fetch to call helper control routes or `.env` endpoints are out of policy.
5. **Memory volume is not a backup of operator secrets.** Do not copy `.env` into `mcp_memory_data`.
6. **Reuse Browserless** for heavy browser automation when Playwright MCP is the wrong fit; do not add a third Chromium service by default.
7. **GitHub remains intake.** Shadow MCP servers on the operator laptop are not the contribution path.

### Suggested contributor checklist

```text
1. Add or edit mcp-tools/<id>/Dockerfile (no host network, no docker.sock)
2. Claim an unused ipv4_address and deploy.resources limits
3. Keep volumes to named Compose volumes
4. Document ports, n8n MCP Client settings, and risk notes
5. Update catalog.yaml when that Stage 4 artifact exists
6. Run a targeted image build only when the Dockerfile changed
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tool images | Existing `mcp-tools/*` + supergateway pattern | Host `npx` MCP |
| Catalog | Stage 1/4 catalog + CI | A second marketplace |
| Browser | Playwright MCP **or** Browserless, not both as defaults | Extra Chromium stacks |
| Local extra mounts | Stage 8 compose-override | Shipping `$HOME` mounts in tree |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Dockerfile lint comments or CI grep for `docker.sock` and host binds in `mcp-tools/`.
3. Follow-up: optional Fetch CIDR deny for `172.20.0.0/16` and helper ports.

## Acceptance criteria

- [ ] MCP tools remain Compose images under `mcp-tools/`.
- [ ] Filesystem default is `/shared` only.
- [ ] docker.sock and home-directory mounts are disallowed as defaults.
- [ ] Fetch is not an internal control-plane client.
- [ ] Catalog/IPAM/resource contracts apply to new tools.

## Rollback

Revert image/Compose/docs independently. Prior tool images return. Docs-only publication needs no runtime rollback.

## Success metrics

- New MCP tools land as sandboxed Compose services.
- No merged default that mounts docker.sock or `$HOME` into filesystem MCP.
- n8n MCP Client docs stay accurate for LAN SSE ports.
