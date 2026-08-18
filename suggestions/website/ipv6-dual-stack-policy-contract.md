---
title: IPv6 Dual-Stack Policy Contract
description: Constructional contract for keeping TU-VM IPv4-first while defining how community PRs may add IPv6 dual-stack without a second network overlay or broken Pi-hole DNS.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: networking
impact: high
---

# IPv6 Dual-Stack Policy Contract

## Problem

The stack is IPv4-only today:

- Compose `ai_network` IPAM is `172.20.0.0/16` with static `ipv4_address` values and no `enable_ipv6`.
- Nginx `listen 80` / `listen 443 ssl` have no `listen [::]:443 ssl`.
- Default vhost Host checks allow dotted-quad IPv4, not IPv6 literals.
- Pi-hole DNS bind guidance in `env.example` is IPv4 (`HOST_IP`, `0.0.0.0`).

Community PRs that “enable IPv6” tend to flip Docker daemon `ipv6: true` globally, add a second overlay, or listen on `[::]` without updating allowlists, stub Host regexes, or MCP Fetch CIDR denies (Stage 19 covers IPv4 `172.20.0.0/16` only).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `networks.ai_network.ipam` | IPv4 subnet + gateway; static addresses |
| `nginx/conf.d/default.conf` | `listen 80` / `443`; Host regex for IPv4 literals |
| `env.example` `HOST_IP` / `PIHOLE_DNS_BIND_ADDR` | IPv4 operator knobs |
| Stage 11 `tailscale-lan-bridge-contract.md` (expected sibling) | Dual-homed IPv4 (LAN + tailnet), not IPv6 |
| Stage 12 `host-port-binding-contract.md` (expected sibling) | Bind conflicts |
| Stage 12 `lan-dns-client-onboarding-contract.md` (expected sibling) | Client DNS |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | IPv4 uniqueness |
| Stage 19 `mcp-fetch-cidr-deny-contract.md` (expected sibling) | IPv4 RFC1918 / Compose CIDR |

Out of scope:

- Requiring IPv6 as a merge gate for laptop operators
- A second mesh (Cilium, extra WireGuard) as a prerequisite
- NAT64/DNS64 gateways
- Publishing IPv6 on Docker-published host ports that are localhost-only today

## Proposal

Keep **IPv4 as the supported default**. Dual-stack is an opt-in, all-or-nothing change set.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Policy | This page + README networking note | “IPv4-first; IPv6 is opt-in dual-stack” |
| Compose | `enable_ipv6` + IPv6 IPAM | Unique addresses; Stage 18-style registry |
| Nginx | `listen [::]:80` / `[::]:443 ssl` **plus** IPv4 listens | Dual-stack, not IPv6-only |
| Host regex | default vhost `$host` checks | IPv6 literals are optional; prefer DNS names |
| Fetch/SSRF | MCP Fetch deny lists | Add ULA `fc00::/7`, link-local `fe80::/10` |
| DNS | Pi-hole / `sync-dns` | AAAA only when operators opt in |

### Rules

1. **IPv4 remains sufficient.** `./tu-vm.sh start` on an IPv4-only host must keep working. Do not make IPv6 a hard dependency.
2. **No IPv6-only listeners.** Adding `[::]:443` without keeping IPv4 `listen 443` is a defect.
3. **One network.** Use the existing `ai_network` with IPv6 IPAM if dual-stack is accepted. Do not add a second overlay “for v6”.
4. **SSRF follows addresses.** Fetch deny must cover IPv6 loopback, ULA, and link-local in the same PR as Compose IPv6.
5. **Allowlists.** Nginx control-plane allowlist syntax must document IPv6 CIDRs before anyone relies on public-mode + v6.
6. **DNS names over literals.** Prefer `tu.lan` / `*.tu.lan`. Do not require operators to put IPv6 literals in Host headers.
7. **GitHub remains intake.** Requests for “IPv6-only hosting” stay Issues.

### Suggested contributor checklist

```text
1. Confirm IPv4-only start still works with the change
2. If enabling Compose IPv6, add IPAM + unique addresses (registry)
3. Dual-stack Nginx listen (IPv4 and IPv6), never IPv6-only
4. Extend Fetch CIDR deny for ULA/link-local/loopback
5. Document PIHOLE_DNS_BIND_ADDR / AAAA behavior
6. Do not publish new host ports “so v6 works”
7. Note that Tailscale v4 dual-homing is a different contract
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Addressing | Existing Compose IPAM + optional IPv6 block | A second Docker network |
| Names | Pi-hole `*.tu.lan` | Teaching users raw IPv6 literals |
| Remote access | Stage 11 Tailscale | Extra VPN just for v6 |
| SSRF | Stage 19 Fetch deny, extended | Unbounded IPv6 literals in Fetch |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** only when an operator need is demonstrated: Compose `enable_ipv6` + Nginx dual listen + Fetch deny together.
3. Until then, document IPv4-first in README/playbooks so contributors stop opening incomplete v6 PRs.

## Acceptance criteria

- [ ] IPv4-only remains the supported default.
- [ ] Dual-stack is all-or-nothing (Compose + Nginx + Fetch deny).
- [ ] IPv6-only listeners are forbidden.
- [ ] Tailscale LAN bridge is not reused as an IPv6 design.

## Rollback

Remove `enable_ipv6` and `[::]` listens independently; IPv4 static addresses stay. Revert Fetch IPv6 denials only if no v6 listeners remain.

## Success metrics

- Incomplete “just enable ipv6” PRs get this contract instead of merging.
- Dual-stack changes land as one reviewable set.
- IPv4 laptop installs keep working.
