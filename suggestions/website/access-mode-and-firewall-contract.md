---
title: Access Mode and Firewall Contract
description: Constructional contract for community contributions to secure, public, and locked access modes that reuse tu-vm.sh UFW helpers instead of inventing a second firewall product.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: security
impact: high
---

# Access Mode and Firewall Contract

## Problem

LAN-first security is a defining TU-VM property. Historical suggestions propose cloud WAFs, reverse-proxy auth gateways, or always-on public inbound exposure as the “community default.” Contributors need a **reuse-first contract** for changing access modes without weakening secure-by-default behavior or reinventing host firewall management.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh secure` / `public` / `locked` | Documented access-mode switches |
| UFW rules inside `enable_secure` / `enable_public` / locked helpers | Host firewall implementation |
| `quickstart --no-secure` | Explicit opt-out (warned, not recommended) |
| Nginx control allowlist (`nginx/dynamic/control_allowlist.conf`) | App-layer IP allowlist for `/control` and related paths |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Allowlist / control-plane PR rules |
| Stage 11 `tailscale-lan-bridge-contract.md` (expected sibling) | Optional remote LAN bridge, not a public open port |
| Stage 12 `nginx-edge-routing-contract.md` (sibling) | Vhost and proxy contribution rules |
| Helper announcements for inactive UFW / public mode | Operator-facing day-to-day signals |

Out of scope:

- Replacing UFW with a mandatory cloud WAF or enterprise NAC product
- Making public inbound the default for new installs
- Embedding operator-specific WAN IPs as committed defaults
- Combining access-mode changes with unrelated dashboard UI rewrites in one PR

## Proposal

Publish an **access mode and firewall contract** with clear lanes and non-negotiable defaults.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Mode helpers | `tu-vm.sh` `enable_secure` / `enable_public` / locked path | Diff shows LAN-first default preserved or explicitly justified |
| Quickstart flags | `quickstart --no-secure` docs and warnings | Warning text remains visible |
| Operator docs / playbooks | `#playbook-access-modes` (proposed) | Table of modes, ports, rollback |
| Announcement signals | `helper/uploader.py` UFW / public-mode tips | Priority taxonomy per Stage 12 announcements contract |
| Cross-links | Tailscale bridge + control-plane allowlist pages | Distinct layers documented |

### Rules

1. **Secure remains the recommended default.** Community PRs must not flip defaults to public without an RFC-style Issue and explicit operator notice.
2. **Modes are host-firewall concerns.** Do not invent a parallel firewall microservice; extend UFW helpers.
3. **Allowlist is not the firewall.** Nginx allowlist (Stage 5) and UFW modes are complementary layers—document both.
4. **Tailscale is optional remote LAN, not “public mode.”** Keep Stage 11 bridge guidance separate from WAN-open `public`.
5. **Rollback path required.** Every mode-changing PR documents how to return to `secure`.
6. **No secret WAN topology in git.** Sample rules may use RFC1918 examples only.
7. **GitHub remains intake.** Access-model redesigns are Issues/PRs, not dashboard voting.

### Suggested playbook shape

```text
#playbook-access-modes
1. Prefer: sudo ./tu-vm.sh secure
2. Temporary wider LAN/WAN testing: sudo ./tu-vm.sh public (then return to secure)
3. Hard lockdown: sudo ./tu-vm.sh locked (or documented locked helper)
4. Verify: sudo ufw status verbose; ./tu-vm.sh doctor
5. Remote LAN: follow Tailscale bridge playbook instead of leaving public mode on
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Host firewall | Existing UFW helpers | New firewall container by default |
| App control path | Nginx allowlist + helper whitelist APIs | Public unauthenticated `/control` |
| Remote access | Optional Tailscale + `sync-dns` | Permanent WAN-open defaults |
| Proof | `doctor` / `ufw status` / announcement signals | Screenshots alone |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-access-modes` when implementing docs polish.
3. Cross-link Stage 5 control-plane, Stage 11 Tailscale, and Stage 12 Nginx / announcements pages.
4. Keep CONTRIBUTING security checklist pointing at mode-changing PRs.

## Acceptance criteria

- [ ] Lanes distinguish UFW modes vs Nginx allowlist vs Tailscale bridge.
- [ ] Secure-default rule is explicit; public-default changes require RFC Issue.
- [ ] Rollback to `secure` is documented.
- [ ] No committed operator-specific WAN IPs in samples.
- [ ] Announcement / doctor signals are referenced for day-to-day verification.

## Rollback

Return operators to `sudo ./tu-vm.sh secure`; remove experimental firewall packages if any were added locally. Access-mode docs can be unpublished without Compose changes.

## Success metrics

- Fewer “add Cloudflare/WAF as default” suggestions that ignore existing modes.
- Access-related PRs cite this contract and include rollback notes.
- Operators can explain secure vs public vs Tailscale bridge without conflating them.
