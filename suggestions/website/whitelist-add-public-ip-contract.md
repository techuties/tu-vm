---
title: Allowlist Public IP Fallback Contract
description: Constructional contract so whitelist-add never sends the host to a public IP service when local route detection fails.
last_updated: 2026-10-06
owner: maintainers
status: proposed
theme: security
impact: high
---

# Allowlist Public IP Fallback Contract

## Problem

`./tu-vm.sh whitelist-add` with no argument is documented as auto-detecting the machine's own address. The first attempt is the host route. The second attempt leaves the machine.

```bash
whitelist_add() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        ip=$(get_vm_ip 2>/dev/null || true)
        if [[ -z "$ip" ]]; then
            ip=$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)
        fi
        ...
    fi
}
```

`get_vm_ip` is:

```bash
get_vm_ip() {
    ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1
}
```

That prints the source address of the host's route to the LAN or upstream gateway. It is the address an operator on that network presents to Nginx, or it is empty when the route lookup fails.

When it is empty, the function calls `api.ipify.org`. The response is the host's egress address as seen from the public internet. That call has two effects:

- The host contacts a third party during an access-control change. TU-VM's day-to-day path is otherwise LAN-local.
- The address written into `control_allowlist.conf` is not the address Nginx uses. The landing server sets `X-Real-IP` from `$remote_addr`. For a person on the LAN, that is a private address. For a person on Tailscale, `get_tailscale_ip` already exists in `tu-vm.sh` and is not consulted here. The public egress address matches neither of those clients, so the new `allow` line does not open `/control/` for the operator who ran the command.

The dashboard path does not do this. `whitelist_auto` records `_client_ip()` from the request that just hit the helper. Stage 45 owns a different lookup: the helper's UDP connect to `8.8.8.8` for the VM IP tile. Stage 51 owns the landing tile that reads `external_ip`. Neither of those is this shell fallback.

Checked on 2026-10-06 by reading `whitelist_add`, `get_vm_ip`, and `get_tailscale_ip` in `tu-vm.sh`. The public URL was not requested.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `get_vm_ip` | Host source address from `ip route`. This is the omitted-argument default |
| `get_tailscale_ip` | Optional second local address, already implemented, already used for `.env` |
| `whitelist_add` argument | Operator-supplied address when detection is not appropriate |
| Helper `whitelist_auto` | Enrolls the client of the current HTTP request |
| Stage 45 `dashboard-vm-ip-source-contract.md` (expected sibling, open PR #71) | Helper `vm_ip` must come from `HOST_IP`, not a socket to `8.8.8.8` |
| Stage 51 external-IP tile (expected sibling, open PR #77) | Remove the tile. Do not add a public lookup there |
| Stage 52 allowlist network rewrite (this branch) | What happens to CIDR lines during the rewrite. Independent of which address is chosen |

Out of scope:

- A geolocation or "what is my IP" feature on the landing page
- Changing `get_vm_ip` in the helper (Stage 45)
- Replacing Nginx allowlists with a VPN product
- Calling Tailscale's coordination server from this command

## Proposal

Keep auto-detect local. Delete the public fallback.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Default | `whitelist_add` with an empty argument | Use `get_vm_ip`. If that prints an address, validate it and add it |
| Failure | Same branch | If `get_vm_ip` is empty, print the usage line that already exists (`whitelist-add <ip>`) and return non-zero. Delete the `curl` to `api.ipify.org` |
| Tailscale | Optional second local candidate | If `get_vm_ip` is empty and `get_tailscale_ip` prints an address, add that address and say so in the log line. Still no HTTP call |
| Explicit | `whitelist-add <ip>` | Unchanged. The operator types the address Nginx will see |
| Docs | Command help string near `whitelist-add [ip]` | Say the omitted form uses the host route, and that a missing route requires an explicit address |

### Rules

1. **No public lookup.** `whitelist-add` does not call `api.ipify.org` or any other external address service.
2. **The address is one Nginx will compare.** Prefer `ip route` source, then the existing Tailscale IPv4 helper, then an argument.
3. **Failure is an error.** An empty detection does not write a placeholder address.
4. **Do not log secrets.** The address that was added may be logged. Tokens and the allowlist file's other lines are not sent anywhere.
5. **Leave the helper tile alone.** `HOST_IP` and the Stage 45 socket fallback are a different contract.

### Suggested contributor checklist

```text
1. Confirm whitelist_add has no curl to an external IP service
2. On a host with a default route, run whitelist-add with no argument and confirm the logged address matches `ip route get 1.1.1.1` source
3. Confirm an explicit whitelist-add 192.0.2.10 still validates and writes that address
4. Confirm a failed local detection exits non-zero and does not change the file
5. Confirm the landing page still has no external-IP lookup (Stage 51)
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local address | `get_vm_ip` / `get_tailscale_ip` | A web API |
| Operator override | The existing positional argument | A prompt or a new flag framework |
| Request client | Helper `whitelist_auto` | Teaching the shell to guess a WAN address |
| Community intake | A GitHub issue if detection is still wrong on a platform | A status page that shows the public address |

## Acceptance criteria

- `whitelist_add` contains no HTTP client call.
- With a working `ip route`, an omitted argument adds that source address.
- With no route and no Tailscale address, the command exits non-zero and the allowlist file is unchanged.
- An explicit argument is still validated with the Stage 52 network-aware parser once that parser lands; until then `ip_address` remains the validator for a single address.
- The helper `vm_ip` path is not edited by this change.

## Verification notes

Read on 2026-10-06 at `tu-vm.sh` `whitelist_add` (the `api.ipify.org` curl sits in the empty-argument branch after `get_vm_ip`). `get_tailscale_ip` is defined later in the same file and is not referenced from `whitelist_add`. The URL was not requested.

## Rollback

Put the `curl` fallback back. That restores the third-party call and the mismatched allow entry.
