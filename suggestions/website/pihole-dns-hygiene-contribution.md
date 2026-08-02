---
title: Pi-hole DNS Hygiene Contribution
description: Constructional contract for community contributions to Pi-hole day-to-day DNS hygiene that reuse the existing Pi-hole service and nginx allowlist patterns instead of adding another DNS stack.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Pi-hole DNS Hygiene Contribution

## Problem

Pi-hole is already a Tier 1 DNS / ad-blocking service in the stack. Historical suggestions invent alternate DNS UIs, custom blocklist microservices, or dashboard-native DNS editors that fight Pi-hole’s own admin surface. Operators still need clear **community contribution rules** for blocklists, local records, and LAN hygiene that keep day-to-day DNS boring and reliable.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `pihole` | DNS ad-blocking and local resolution |
| `pihole/` config tree | Image/config customizations already in-repo |
| `tu-vm.sh` allowlist helpers | Control-plane IP allowlisting (HTTP), related LAN hygiene |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Nginx allowlist / control-plane PR rules |
| Stage 3 `community-quality-gates.md` (expected sibling) | Evidence expectations |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Status endpoints `/status/pihole` | Health projection |

Out of scope:

- Replacing Pi-hole with unbound/CoreDNS/AdGuard as a silent default
- Building a second DNS admin UI inside the Nginx landing page
- Shipping aggressive blocklists that break critical updates without an escape hatch
- Managing DHCP for the whole LAN as a required TU-VM feature

## Proposal

Publish a **DNS hygiene contribution contract** with safe lanes.

### Contribution lanes

| Lane | Examples | Evidence |
|---|---|---|
| Docs / playbooks | First-hour Pi-hole, router upstream tips | Commands + rollback (“disable blocking”) |
| Config defaults | Safe baseline env in `env.example` | Diff + threat notes |
| Blocklist policy docs | Recommended list tiers (strict/balanced) | Link sources; no binary list dumps in git unless tiny samples |
| Local DNS records guidance | `tu.lan` / split DNS notes | Explicit conflict checks with Nginx hostnames |
| Status/helper | Richer `/status/pihole` fields | Stage 7 helper contract + fixtures |

### Rules

1. **Prefer Pi-hole’s admin API/UI** for runtime list changes; git holds policy and defaults, not every operator’s live list.
2. **Document break-glass:** how to disable blocking or bypass DNS when updates fail.
3. **Separate DNS hygiene from HTTP allowlists**—link Stage 5 control-plane contract, do not merge concepts.
4. **No credential leakage** (Pi-hole web password stays in `.env`).
5. **Port 53 assumptions** stay documented for cloud/agent and host conflict cases (see `AGENTS.md`).

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| DNS filtering | Existing Pi-hole | Parallel DNS container “just for community lists” |
| Local names | Pi-hole local records + existing `*.tu.lan` docs | Ad-hoc `/etc/hosts` instructions as the only path |
| Evidence | `/status/pihole` + playbook | Screenshots of unrelated routers as CI gates |
| Control plane IPs | `tu-vm.sh` allowlist helpers | Encoding allowlists into Pi-hole blocklists |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-pihole-hygiene` with balanced vs strict list guidance.
3. Align any helper field additions with Stage 7 fixture-additive rules.
4. Reference port 53 conflicts in contributor troubleshooting docs.

## Acceptance criteria

- [ ] Contributions identify a lane (docs / defaults / policy / helper).
- [ ] Break-glass disable/bypass steps are documented beside any stricter defaults.
- [ ] Pi-hole remains the DNS product—no silent replacement in the same PR without RFC labeling.
- [ ] Secrets never appear in samples; `env.example` placeholders only.
- [ ] HTTP allowlist changes defer to the Stage 5 control-plane contract.

## Rollback

Revert Compose/env defaults; operators can flush lists in Pi-hole UI. DNS can temporarily point clients at router/ISP resolvers without removing TU-VM.

## Success metrics

- Fewer conflicting DNS-stack proposals in Issues.
- Operators recover faster from over-blocking using documented break-glass steps.
- Community list policy PRs cite tiers instead of dumping giant proprietary lists into git.
