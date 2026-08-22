---
title: Inter-Service Network Isolation Contract
description: Constructional contract for splitting the single Compose bridge into role networks so data stores are not reachable from every tool container, without changing IPAM uniqueness or Fetch CIDR deny lists.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: security
impact: high
---

# Inter-Service Network Isolation Contract

## Problem

Every service joins `ai_network` (`172.20.0.0/16`). CHANGELOG already lists "Container network isolation," but isolation today means "not published on the host," not "Postgres cannot see Browserless." A compromised MCP tool, n8n worker, or browserless container can open TCP to `172.20.0.10:5432` and `172.20.0.21:9000`.

Stage 18 covers **unique static IPv4 allocation**. Stage 19 covers **Fetch egress CIDR deny**. This page is only **which Compose networks a service may join**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `networks.ai_network` | Single bridge, subnet `172.20.0.0/16`, gateway `.1` |
| Static `ipv4_address` on most services | IPAM registry (Stage 18) |
| Host publishes | Nginx 80/443; MinIO localhost 9000/9001 only |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | Address uniqueness on a given network |
| Stage 19 `mcp-fetch-cidr-deny-contract.md` (expected sibling) | Egress from Fetch, not east-west |
| Stage 12 `host-port-binding-contract.md` (expected sibling) | Host ports, not overlay topology |
| Stage 20 `ipv6-dual-stack-policy-contract.md` (expected sibling) | IPv6 all-or-nothing, not extra bridges |

Out of scope:

- Kubernetes NetworkPolicy, Cilium, or an overlay mesh
- Changing the `172.20.0.0/16` numbering plan on day one
- Fetch CIDR lists (Stage 19)
- Publishing extra host ports to "simplify" debugging

## Proposal

Introduce role networks on top of (or instead of a single attachment to) `ai_network`:

| Network | Members (examples) | Purpose |
|---|---|---|
| `edge` | `nginx`, `pihole` | Ingress and LAN DNS |
| `app` | `open-webui`, `n8n`, `helper_index`, AFFiNE app |
| `data` | `postgres`, `redis`, `qdrant`, `minio`, `tika` |
| `tools` | MCP servers, `browserless`, `n8n_mcp` |

A service joins only the networks it needs. `nginx` joins `edge` + `app` + `data` (or uses an explicit proxy hop). `postgres` joins `data` only. `browserless` joins `tools` (+ `app` if Open WebUI must reach it). Keep today's subnet and static IPs until a migration playbook exists; extra bridges may use adjacent subnets listed in the IPAM registry.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Compose | `networks:` on each service | Postgres has no NIC on `tools` |
| IPAM | Stage 18 registry | New subnets get unique ranges |
| Clients | connection strings | Hostnames still resolve on shared networks |
| Docs | playbook | "Why can't browserless ping Postgres?" |

### Rules

1. **Default deny east-west.** If a service does not need a database, it must not share that network.
2. **Do not invent a mesh.** Compose bridges are enough. No Consul, Linkerd, or extra sidecar.
3. **IPAM stays Stage 18.** New networks register subnets and static IPs there. Do not reuse `172.20.0.0/16` on two bridges.
4. **Fetch deny stays Stage 19.** Isolation does not replace egress CIDR lists.
5. **Helper docker.sock is unchanged.** Network isolation is not a substitute for control-plane auth (Stage 18 helper control-auth).
6. **Migrate incrementally.** First split can attach *additional* networks and then drop `ai_network` from data stores once clients are confirmed.
7. **GitHub remains intake.** Requests for Kubernetes NetworkPolicy stay Issues.

### Suggested contributor checklist

```text
1. List who actually connects to postgres, redis, qdrant, minio
2. Draft edge / app / data / tools membership without changing IPAM yet
3. Register any new subnet in the Stage 18 address registry
4. Attach extra networks first; remove ai_network from data stores last
5. Confirm nginx, n8n, Open WebUI, and helper still resolve service names
6. Do not publish extra host ports for debugging
7. Leave Fetch CIDR deny rules to Stage 19
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Segmentation | Extra Compose bridges | Kubernetes / a service mesh |
| Addresses | Stage 18 IPAM registry | Random DHCP on a second subnet |
| Egress | Stage 19 Fetch CIDR deny | Using isolation as the only Fetch control |
| Ingress | Existing Nginx on `edge` | Host-publishing databases |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add `data` + `tools` networks; attach them; keep `ai_network` until a follow-up removes it from stores.
3. Document a smoke path: n8n reaches Postgres; browserless cannot.

## Acceptance criteria

- [ ] At least one data store is not attached to the tool network.
- [ ] Nginx and declared clients still reach those stores by Compose DNS.
- [ ] New subnets are listed in the IPAM registry.
- [ ] No host port is added for Postgres, Redis, or Qdrant.
- [ ] No mesh or NetworkPolicy product is introduced.

## Rollback

Re-attach every service to `ai_network` only and remove extra network definitions. Static IPs on `ai_network` remain valid.

## Success metrics

- A process in `browserless` or an MCP filesystem tool cannot open Postgres.
- Operator docs explain membership in one table.
- IPAM uniqueness checks still pass.
