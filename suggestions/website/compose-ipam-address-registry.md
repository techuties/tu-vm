---
title: Compose IPAM Address Registry
description: Constructional contract for unique static IPv4 allocation on ai_network so community Compose additions cannot collide—reuse the existing 172.20.0.0/16 IPAM instead of a second overlay network.
last_updated: 2026-08-13
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Compose IPAM Address Registry

## Problem

Every service in `docker-compose.yml` pins a static address on `ai_network` (`172.20.0.0/16`, gateway `172.20.0.1`). Nginx, helper probes, MCP clients, and playbooks often call those addresses directly. Duplicate assignments break Compose networking silently. The repository already recorded one collision: `mcp-playwright` previously used `172.20.0.30`, which is now reserved for `n8n_mcp`.

Community PRs that add a sidecar tend to copy a nearby IP. Historical suggestion branches asked for frameworks; they did not publish an **address registry** or a uniqueness check. Without that, contributors reinvent ad-hoc networks or “just let Docker DHCP,” which would invalidate documented IPs.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `networks.ai_network.ipam` | Single bridge subnet and gateway |
| Per-service `ipv4_address` | Stable targets for Nginx `proxy_pass` and helper checks |
| Compose comment on `mcp-playwright` | Documents the `.30` collision with `n8n_mcp` |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Edge routes that hard-code several `172.20.0.*` upstreams |
| Stage 12 `host-port-binding-contract.md` (expected sibling) | Host port conflicts—orthogonal to overlay IPs |
| Stage 4 `extension-pilot-scaffold.md` (expected sibling) | Extensions that add Compose fragments must pick unused IPs |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local overrides must not steal reserved addresses |

Out of scope:

- Introducing a second overlay (Calico, macvlan, IPv6 dual-stack) as a prerequisite
- Removing static IPs in favor of DNS-only discovery without updating Nginx and helper
- Publishing a hosted IPAM SaaS or a dashboard IP editor
- Changing the `172.20.0.0/16` subnet without a breaking-change review

## Proposal

Publish a **Compose IPAM address registry** and require community Compose additions to claim an unused address in-tree.

### Current allocation (as of this writing)

| Address | Service |
|---|---|
| `172.20.0.1` | Bridge gateway |
| `172.20.0.10` | `postgres` |
| `172.20.0.11` | `redis` |
| `172.20.0.12` | `qdrant` |
| `172.20.0.13` | `ollama` |
| `172.20.0.14` | `open-webui` |
| `172.20.0.15` | `n8n` |
| `172.20.0.16` | `pihole` (also in-container DNS) |
| `172.20.0.18` | `nginx` |
| `172.20.0.19` | `helper_index` |
| `172.20.0.20` | `tika` |
| `172.20.0.21` | `minio` |
| `172.20.0.22` | `affine` |
| `172.20.0.23` | `affine_migration` |
| `172.20.0.24` | `affine_postgres` |
| `172.20.0.25` | `affine_redis` |
| `172.20.0.26` | `mcp_gateway` |
| `172.20.0.27` | `browserless` |
| `172.20.0.29` | `langgraph_supervisor` |
| `172.20.0.30` | `n8n_mcp` |
| `172.20.0.31` | `mcp-filesystem` |
| `172.20.0.32` | `mcp-fetch` |
| `172.20.0.33` | `mcp-memory` |
| `172.20.0.34` | `mcp-playwright` |

Unallocated in the low range (examples, not reservations until claimed in Compose): `172.20.0.17`, `172.20.0.28`, then `.35+`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Claim an address | `docker-compose.yml` | New `ipv4_address` not used elsewhere |
| Document the claim | This registry or a generated table | PR updates the table or CI generates it |
| Nginx / helper callers | `nginx/conf.d/default.conf`, helper | Upstream IPs stay in lockstep |
| Uniqueness CI | `scripts/` + CI | Fail PRs that duplicate `ipv4_address` |
| DNS inside compose | `dns: 172.20.0.16` | Do not reassign Pi-hole’s `.16` |

### Rules

1. **One subnet.** Keep `172.20.0.0/16` until a documented breaking change. Do not add a second community network for convenience.
2. **Unique `ipv4_address`.** A Compose PR that repeats an address is invalid, even if containers rarely run together.
3. **Reserve `.1` and `.16`.** Gateway and Pi-hole DNS are not available for new services.
4. **Prefer `.35+` for new tools** unless a hole is explicitly claimed and listed.
5. **Update callers in the same PR** when an existing address moves (Nginx `proxy_pass`, extra_hosts, docs).
6. **Do not copy `mcp-playwright`’s old `.30`.** That comment exists because the collision already happened.
7. **GitHub remains intake.** Requests for dynamic IPAM products stay Issues unless accepted as scoped work.

### Suggested contributor checklist

```text
1. grep ipv4_address docker-compose.yml and confirm the candidate is unused
2. Assign the address in the new service block
3. Update this registry table (or the future generated artifact)
4. Update nginx/helper/docs if they hard-code the new or old IP
5. Run sudo docker compose config --quiet
6. Prefer a uniqueness check in CI over a second IPAM tool
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Address uniqueness | Compose file + CI grep/parser | Spreadsheet outside the repo |
| Service discovery | Existing container DNS names **and** documented IPs | Replacing Nginx upstreams without a migration |
| Extensions | Stage 4 scaffold claiming an unused IP | Each extension inventing `172.18.0.0/16` |
| Local overrides | Stage 8 compose-override rules | Override files that steal `.10`–`.34` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: a small uniqueness validator (for example, fail CI if any `ipv4_address` repeats).
3. Optionally generate the table from Compose so this page does not drift.

## Acceptance criteria

- [ ] Single-subnet rule is stated.
- [ ] Duplicate `ipv4_address` is defined as a contribution defect.
- [ ] Gateway `.1` and Pi-hole `.16` are reserved.
- [ ] Historical `.30` collision is documented as a negative example.
- [ ] Callers (Nginx/helper) must update in the same PR when IPs move.

## Rollback

Revert docs independently. A uniqueness script can be removed without changing running allocations. Do not reclaim in-use addresses without a migration note.

## Success metrics

- No further duplicate-IP Compose merges.
- New MCP/extension services land on unused addresses on the first review.
- Nginx upstreams and Compose IPs stay aligned.
