---
title: MCP Fetch CIDR Deny Contract
description: Constructional contract for denying MCP Fetch access to 172.20.0.0/16 and other link-local ranges so community tool images cannot SSRF the Compose data plane.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: security
impact: high
---

# MCP Fetch CIDR Deny Contract

## Problem

`mcp-fetch` builds `mcp-tools/fetch/Dockerfile` (`mcp-server-fetch` behind supergateway) and joins `ai_network` at `172.20.0.32`. The image has **no** destination allow/deny list. From inside the bridge, Fetch can request Postgres (`.10`), Redis (`.11`), helper (`.19`), MinIO (`.21`), and other RFC1918 neighbors. That is SSRF against the data plane.

Stage 18 sandbox contract already notes that Fetch has unbounded egress. This page is the **concrete CIDR deny** for the Compose subnet and related private ranges, not a general rewrite of MCP tooling.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-tools/fetch/Dockerfile` | `python3 -m mcp_server_fetch` on port 3002 |
| `docker-compose.yml` `mcp-fetch` | `172.20.0.32`, resource limits, Pi-hole DNS |
| `networks.ai_network.ipam` | `172.20.0.0/16` |
| Stage 4 `mcp-catalog-ci-contract.md` (expected sibling) | Catalog listing, not network policy |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling) | Operator write postures |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Edge, not east-west Fetch |
| Stage 18 `mcp-tool-sandbox-contribution-contract.md` (expected sibling) | Broader sandbox (no `$HOME`, no docker.sock) |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | Address map Fetch must not target |

Out of scope:

- A service mesh or iptables product as a prerequisite
- Blocking all outbound HTTPS (Fetch’s job is external HTTP)
- Making Fetch always-on Tier 1
- Host `npx` MCP Fetch outside Compose

## Proposal

Deny Fetch from targeting the Compose network and other non-public destinations while allowing normal external URLs.

### Deny set (minimum)

| CIDR / target | Why |
|---|---|
| `172.20.0.0/16` | Entire `ai_network` |
| `127.0.0.0/8` | Container localhost services |
| `10.0.0.0/8`, `192.168.0.0/16`, `172.16.0.0/12` | RFC1918 (LAN and other bridges) |
| `169.254.0.0/16` | Link-local / cloud metadata |
| `::1`, `fc00::/7`, `fe80::/10` | IPv6 loopback / ULA / link-local if enabled |

Operators who need Fetch to call a **published** LAN vhost (`https://oweb.tu.lan`) should go through Nginx, not raw `http://172.20.0.14:8080`. Even vhost calls may be undesirable; default deny of literal RFC1918 IPs is required. Hostname allowlists are a later, documented exception.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Wrapper or env | `mcp-tools/fetch/Dockerfile` or entrypoint | Deny list enforced before `mcp_server_fetch` |
| Tests | `scripts/` or CI | Requests to `http://172.20.0.10:5432` fail |
| Docs | Catalog / this page | What Fetch may call |
| Compose | Extra env only | No docker.sock, no `network_mode: host` |

### Rules

1. **Deny `172.20.0.0/16` by default.** This is the non-negotiable Stage 19 control.
2. **Prefer a small wrapper** around `mcp_server_fetch` if upstream has no CIDR flag. Do not switch MCP servers just to get a deny list.
3. **Fail closed.** A parse error in the deny list must not allow all destinations.
4. **Do not mount docker.sock** to “inspect allowed services.”
5. **Keep resource limits.** SSRF hardening is not a reason to drop Stage 18 budgets.
6. **Exceptions are explicit.** If a maintainer later allows a single internal hostname, it is an Issue + documented env, not a commented-out deny.
7. **GitHub remains intake.** Requests for an outbound proxy product stay Issues.

### Suggested contributor checklist

```text
1. Read mcp-tools/fetch/Dockerfile
2. Add a deny list that includes 172.20.0.0/16 and RFC1918/link-local
3. Prove http://172.20.0.10/ and http://169.254.169.254/ are rejected
4. Prove a normal public HTTPS URL still works (or skip-live in CI)
5. Do not add host network or docker.sock
6. Update the MCP catalog blurb when Stage 1/4 pages merge
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fetch tool | Existing `mcp-tools/fetch` image | Host `npx` Fetch |
| Address map | Stage 18 IPAM registry | Ad-hoc extra_hosts to internals |
| Sandbox | Stage 18 MCP sandbox contract | Privileged Fetch |
| Edge access | Nginx vhosts + allowlist | Fetch as a backdoor to helper |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: wrapper or upstream flags plus a CI case that `172.20.0.16` / `.10` are denied.
3. Mention the deny set in `mcp-tools/fetch` comments.

## Acceptance criteria

- [ ] `172.20.0.0/16` is denied by default.
- [ ] RFC1918 and link-local ranges are included.
- [ ] Fail-closed behavior is required.
- [ ] No docker.sock or host network.
- [ ] External Fetch remains the intended use.

## Rollback

Remove the wrapper/env; document that internal SSRF returns until re-applied. Do not “temporarily allow 172.20.0.0/16” in a default image.

## Success metrics

- Fetch cannot read helper, Postgres, or MinIO by IP.
- Community MCP PRs keep the deny list.
- External documentation Fetch still works for operators who opt into the tool.
