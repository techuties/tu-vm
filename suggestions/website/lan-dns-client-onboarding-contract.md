---
title: LAN DNS Client Onboarding Contract
description: Constructional contract for community contributions to router and client DNS onboarding that reuses dns-clients and existing Pi-hole/Tailscale playbooks instead of shipping a custom client app.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: networking
impact: medium
---

# LAN DNS Client Onboarding Contract

## Problem

First-hour success often fails at the client: phones and laptops never use Pi-hole DNS, or routers still point at ISP resolvers. Historical suggestions invent captive portals, MDM profiles as mandatory defaults, or a second DNS product. Contributors need a **reuse-first onboarding contract** that makes day-to-day client setup boring and reliable.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh dns-clients` | Operator hints for routers and clients |
| `./tu-vm.sh sync-dns` | LAN/Tailscale DNS record sync |
| `#playbook-pihole-tailscale` in `docs/playbooks/README.md` | Dual-stack DNS recipe |
| Stage 9 `pihole-dns-hygiene-contribution.md` (expected sibling) | Blocklist / hygiene lane |
| Stage 11 `tailscale-lan-bridge-contract.md` (expected sibling) | Tailscale dual-stack bridge |
| Stage 2 `persona-entry-paths.md` (expected sibling) | First-hour persona routes |
| Stage 12 `host-port-binding-contract.md` (sibling) | Port 53 conflicts that block DNS |
| `env.example` `PIHOLE_DNS_BIND_ADDR` / IP vars | Bind and publish knobs |

Out of scope:

- Mandatory custom VPN/DNS client apps for every household device
- Replacing Pi-hole with another DNS stack as a drive-by default
- Corporate MDM as a required dependency for home LAN operators
- Documenting illegal interception or covert DNS hijacking techniques

## Proposal

Publish a **LAN DNS client onboarding contract** focused on router-first and hint-driven setup.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Client hints | `tu-vm.sh dns-clients` output | Clear router-first / device fallback steps |
| Playbooks | `#playbook-dns-clients` (proposed) + existing Pi-hole/Tailscale playbook | Copy-paste safe steps |
| Env / bind docs | `env.example` comments | When to bind `0.0.0.0` vs LAN-only |
| Persona links | Stage 2 persona entry paths | “Household operator” first hour |
| Conflict handling | Stage 12 port-binding contract | systemd-resolved / other :53 owners |
| Hygiene vs onboarding | Stage 9 Pi-hole hygiene | Keep blocklist work separate |

### Rules

1. **Router-first.** Prefer DHCP DNS pointing at the TU-VM/Pi-hole address before per-device hacks.
2. **Hints over apps.** Extend `dns-clients` text and playbooks; do not ship a mandatory companion app.
3. **Separate hygiene.** Blocklist tuning stays in Stage 9; onboarding stays about reachability and resolver choice.
4. **Separate remote bridge.** Tailscale dual-stack remains Stage 11; onboarding links to it when relevant.
5. **Call out port 53 conflicts.** Point to doctor/port-binding remediation when Pi-hole cannot bind.
6. **IPv4/IPv6 honesty.** Document what is tested; do not claim full IPv6 client coverage without evidence.
7. **GitHub remains intake.** Onboarding UX ideas are Issues/PRs.

### Suggested playbook shape

```text
#playbook-dns-clients
1. Confirm Pi-hole is up and port 53 is free (doctor / port-binding contract)
2. ./tu-vm.sh sync-dns
3. ./tu-vm.sh dns-clients
4. Set LAN DHCP DNS to the printed TU-VM DNS address
5. Verify a client resolves a *.tu.lan name
6. Optional remote LAN: follow Tailscale bridge playbook
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| DNS server | Existing Pi-hole service | Second DNS product by default |
| Operator hints | `dns-clients` + playbooks | Mandatory mobile apps |
| Remote users | Stage 11 Tailscale bridge | Opening WAN UDP/53 by default |
| Proof | Resolve tests + doctor | Screenshots of router UIs alone |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-dns-clients` and deep-link it from the dashboard operator hub when implementing.
3. Cross-link Stage 9 hygiene, Stage 11 Tailscale, Stage 2 personas, and Stage 12 port-binding pages.
4. Prefer improving `dns-clients` wording in **code**/docs over new suggestion files.

## Acceptance criteria

- [ ] Router-first rule is explicit.
- [ ] Onboarding is distinct from blocklist hygiene and Tailscale bridge.
- [ ] Port 53 conflict pointer exists.
- [ ] Playbook lists sync-dns → dns-clients → DHCP → verify.
- [ ] No mandatory companion-app requirement.

## Rollback

Revert hint/playbook text; Pi-hole and sync-dns continue to function. No schema migration.

## Success metrics

- Fewer first-hour Issues that ignore DHCP DNS configuration.
- `dns-clients` output cited in Issues as the starting checklist.
- Onboarding PRs stop proposing captive portals as the default path.
