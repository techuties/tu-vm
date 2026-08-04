---
title: Tailscale LAN Bridge Contract
description: Constructional contract for optional Tailscale dual-stack access that reuses existing sync-dns and Pi-hole localise-queries instead of inventing a second VPN or public exposure path.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tailscale LAN Bridge Contract

## Problem

Operators often need reachability from a personal tailnet without turning TU-VM into a public internet appliance. Historical suggestions invent WireGuard sidecars, reverse-proxy SaaS tunnels, or “just open 443 to the world.” The repo already supports Tailscale-aware DNS via `HOST_IP` / `TAILSCALE_IP` and `./tu-vm.sh sync-dns`, but the community website lacked a **bridge contract** that separates remote reachability from Pi-hole blocklist hygiene.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `HOST_IP`, `TAILSCALE_IP`, `DNS_RECORD_IP` in `env.example` | Address inputs for dual-stack records |
| `./tu-vm.sh sync-dns` | Writes Pi-hole `*.tu.lan` records for LAN + Tailscale |
| `./tu-vm.sh dns-clients` | Client/router hints |
| [`docs/playbooks/README.md`](../../docs/playbooks/README.md) `#playbook-pihole-tailscale` | Operator recipe |
| Stage 9 `pihole-dns-hygiene-contribution.md` (expected sibling) | Blocklists / DNS hygiene (different lane) |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Nginx allowlist / control-plane security |
| Stage 10 `tls-certificate-lifecycle-contract.md` (expected sibling) | Cert trust on remote clients |

Out of scope:

- Replacing Tailscale with a mandatory second VPN product in Compose
- Making public inbound port-forwarding the default remote-access story
- Building a Tailscale admin UI inside the Nginx dashboard
- Duplicating Stage 9 blocklist policy under a “remote access” label

## Proposal

Publish a **Tailscale LAN bridge contract** with explicit modes and contribution lanes.

### Modes

| Mode | Who | Behavior |
|---|---|---|
| **LAN only (default)** | Most installs | `HOST_IP` / local DNS; no Tailscale required |
| **LAN + Tailscale bridge** | Operators with `tailscale` on the host | Set `TAILSCALE_IP` (or auto-detect); `sync-dns` registers both; clients use the matching nameserver |
| **Intentionally exposed host** | Rare | Public CA / inbound exposure only with Decision Log + Stage 10 TLS public-CA mode—not implied by Tailscale docs |

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Docs / playbooks | `#playbook-pihole-tailscale` and README notes | Commands, rollback (“unset TAILSCALE_IP / re-sync”) |
| Env defaults / comments | `env.example` | Clear dual-stack comments; no secrets |
| `sync-dns` behavior | `tu-vm.sh` | Idempotency, conflict notes with MagicDNS |
| Control-plane allowlist | Nginx dynamic allowlist helpers | Stage 5 checklist when remote clients need control UI |
| Status projection | Optional helper fields | Stage 7 helper contract + fixtures |

### Rules

1. **Optional by default.** Tailscale must remain non-mandatory for Tier 1.
2. **Reuse Pi-hole DNS.** Prefer `sync-dns` + localise-queries over a second DNS product.
3. **Do not widen control plane silently.** Remote clients that need `/control` still go through allowlist rules (Stage 5).
4. **Separate hygiene from bridge.** Blocklist changes use Stage 9; reachability uses this page.
5. **No tokens in git.** Tailscale auth keys never land in Compose samples or Issues.
6. **TLS honesty.** Self-signed warnings on tailnet clients are expected unless operators import trust (Stage 10).
7. **GitHub remains intake.** Topology redesigns are Issues/PRs, not dashboard forms.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Personal remote access | Host Tailscale + existing DNS sync | Cloudflare Tunnel / frp as silent default |
| Split DNS | Pi-hole localise-queries | Hand-edited conflicting A records in multiple systems |
| Control access | Existing allowlist tooling | “Allow all” because a laptop is on a tailnet |
| Docs | Existing playbook anchor | New VPN microservice README tree |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Keep `#playbook-pihole-tailscale` as the operator recipe; link here for contribution rules.
3. Cross-link Stage 5 control-plane, Stage 9 Pi-hole hygiene, and Stage 10 TLS pages.
4. If product defaults ever require Tailscale, record a Decision Log entry first.

## Acceptance criteria

- [ ] Modes distinguish LAN-only vs optional Tailscale bridge vs rare public exposure.
- [ ] Docs state Tailscale is optional and reuse `sync-dns`.
- [ ] Control-plane allowlist constraints are referenced for remote UI access.
- [ ] Stage 9 blocklist hygiene is explicitly out of scope for this contract.
- [ ] No sample commits Tailscale auth keys or disables TLS to “fix warnings.”

## Rollback

Unset or correct `TAILSCALE_IP`, re-run `./tu-vm.sh sync-dns`, and remove remote client nameserver overrides. LAN-only operation remains the fallback.

## Success metrics

- Fewer duplicate “add WireGuard / open the firewall” suggestions.
- Tailscale Issues arrive with `sync-dns` evidence and allowlist notes.
- Blocklist PRs route to Stage 9 instead of this bridge lane.
