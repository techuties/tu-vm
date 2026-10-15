---
title: Firewall Command Order Contract
description: Constructional contract so tu-vm.sh secure, public, and lock follow UFW first-match order and replace this script's previous rules.
last_updated: 2026-10-15
owner: maintainers
status: proposed
theme: security
impact: high
---

# Firewall Command Order Contract

## Problem

`./tu-vm.sh secure`, `public`, and `lock` append UFW rules and then print success. UFW uses the first matching rule. These commands append the general rule before the specific one, or the new mode after the old mode, so the sentence the script prints does not describe the firewall.

Debian `ufw(8)` (bookworm, May 2023) says: "Rule ordering is important and the first match wins. Therefore when adding rules, add the more specific rules first with more general rules later." A rule without `insert` or `prepend` is appended. `ufw` is not installed in this environment, so the table below is the command order in `tu-vm.sh` evaluated with that first-match rule. The functions were not executed.

`enable_secure` does this, in order:

```bash
ufw deny 80/tcp
ufw deny 443/tcp
ufw deny 53/tcp
ufw deny 53/udp
ufw allow from "$network_prefix.0/24" to any port 80
ufw allow from "$network_prefix.0/24" to any port 443
ufw allow from "$network_prefix.0/24" to any port 53
```

With `network_prefix` standing in as `192.168.1`, a packet from `192.168.1.50` to port 80 matches the first rule and is denied. The later allow is never consulted.

| After `secure` | Packet | First match |
|---|---|---|
| LAN web | `192.168.1.50` to `80/tcp` | rule 1 deny |
| LAN HTTPS | `192.168.1.50` to `443/tcp` | rule 2 deny |
| LAN DNS | `192.168.1.50` to `53/udp` | rule 4 deny |
| Tailscale client | `100.64.1.20` to `443/tcp` | rule 2 deny |
| Internet | `203.0.113.9` to `80/tcp` | rule 1 deny |

`enable_public` then appends `ufw allow 80/tcp`, `443/tcp`, `53/tcp`, and `53/udp`. Those allows sit after the denies, so a LAN or internet client is still denied. `lock_access` after a fresh `public` appends denies after the allows, so an internet client to `443/tcp` still matches the public allow.

`get_tailscale_ip` and `TAILSCALE_IP` already exist. `enable_secure` does not allow the Tailscale interface. An allow from the VM's own Tailscale address would match packets whose source is the VM, which is the wrong direction. Clients on a tailnet arrive on `tailscale0`.

Repeated runs append another copy of the same rules. Nothing deletes the previous mode first.

Stage 20 (open PR #46) owns IPv6 dual-stack policy. This page does not change that policy. It changes the order and replacement of the IPv4 rules these three functions already add.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `enable_secure`, `enable_public`, `lock_access` | The three modes operators already run |
| `ufw insert` and `ufw prepend` | Put a specific allow ahead of a general deny |
| `ufw delete` | Remove a rule this script added before switching mode |
| `get_network_prefix` / `HOST_IP` | The LAN prefix the allow should use |
| `get_tailscale_ip` | Detects that Tailscale is present. The allow is `in on tailscale0`, not that address as a source |
| Stage 20 `ipv6-dual-stack-policy-contract.md` (expected sibling, open PR #46) | IPv6 policy. Leave it there |
| Stage 52 allowlist pages (expected siblings, open PR #78) | Nginx `/control` allowlist. Not UFW |

Out of scope:

- Replacing UFW with nftables, firewalld, or a generated rules file
- The Nginx IP allowlist
- Opening or closing ports that these three functions do not already name
- IPv6 rule policy (Stage 20)

## Proposal

Each mode deletes the rules it may have appended, then adds the specific allows before the general denies.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Replacement | all three functions | `ufw delete` the deny and allow lines this script uses for ports 80, 443, and 53 before adding the new set. Ignore a delete that reports the rule was not present |
| Order | `enable_secure` | `ufw insert 1` the LAN allows, then append the denies for the same ports from anywhere else |
| Tailscale | `enable_secure` | When `tailscale0` exists, `ufw insert 1 allow in on tailscale0` for ports 80, 443, and 53 |
| Prefix | `enable_secure` | Build the `/24` from `HOST_IP` when that `.env` key is set. Otherwise keep `get_network_prefix` |
| Public | `enable_public` | After deleting the previous denies, append the public allows. Do not leave an earlier deny in front of them |
| Lock | `lock_access` | After deleting the previous allows, append the denies |

### Rules

1. **Specific allows come first.** After `secure`, a source in the chosen `/24` matches an allow for 80, 443, and 53 before any deny.
2. **Switching mode removes the previous mode.** `public` after `secure` is allowed from anywhere on those ports. `lock` after `public` is denied from anywhere on those ports. `secure` after `public` is the LAN allow, not the leftover public allow.
3. **Tailscale is an interface allow.** It is added only when `tailscale0` exists, and it is inserted with the LAN allows.
4. **The script does not enable UFW when it cannot see `ufw`.** Today's `|| true` hides a missing binary and still prints success. A missing `ufw` is a warning and a non-zero exit from that command.
5. **Comments stay `tu-vm`.** Add `comment 'tu-vm'` on every rule so a later delete can target the same text.

### Suggested contributor checklist

```text
1. Model or run: secure, then a LAN client to 443, and confirm the first match is allow
2. public after secure: an internet client to 443 matches allow
3. lock after public: an internet client to 443 matches deny
4. secure after public: an internet client to 443 matches deny, and the LAN client matches allow
5. With tailscale0 present, a packet ingress on that interface matches an allow inserted before the denies
6. A second secure run does not grow a second copy of the same rules
7. When ufw is absent, the command exits non-zero and does not print "Secure access enabled"
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Rule order | `ufw insert` for allows, then `ufw deny` | Appending the deny first |
| Mode switch | `ufw delete` of the previous tu-vm rules | A second firewall stack |
| Tailscale | `ufw allow in on tailscale0` | Allowing the VM's own Tailscale address as a source, or allowing `100.64.0.0/10` |
| LAN source | `HOST_IP` already in `.env` | A new discovery daemon |
