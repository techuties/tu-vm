---
title: Pi-hole Dual-Stack Hosts Contract
description: Constructional contract so the existing Pi-hole dnsmasq snippet actually loads the tu.lan hosts file sync-dns already writes.
last_updated: 2026-10-04
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Pi-hole Dual-Stack Hosts Contract

## Problem

`./tu-vm.sh sync-dns` (`sync_pihole_dns_records`) has two writers.

When only one address is in play, it writes `address=` lines into `pihole/01-custom.conf`. That file is bind-mounted at `/etc/dnsmasq.d/01-custom.conf`, so dnsmasq loads `*.tu.lan`.

When both a LAN address and a Tailscale address are present and they differ, it takes the other branch. It rewrites `01-custom.conf` with upstream `server=` lines only, and it tries to store the names here:

```text
/etc/pihole/hosts/tu-lan.hosts
```

That write is a `docker exec` into `ai_pihole`, and the command is followed by `|| true`. The function then logs success and returns 0 even when the container is not running, so the hosts file was never created.

The repository never tells dnsmasq to read that path. A search for `tu-lan.hosts` finds the writer in `tu-vm.sh` and a comment in `pihole/01-custom.conf`. There is no `addn-hosts=` line. The hosts file is not a compose volume. The file that is mounted, the one in git today, is the dual-stack shape: upstream resolvers and the comment, and no `address=` records.

So the default snippet ships no `tu.lan` data, and the dual-stack branch removes the `address=` records that the single-IP branch uses. Names are supposed to come from a hosts file the mounted config does not include.

Checked by reading `sync_pihole_dns_records`, `pihole/01-custom.conf`, and the `pihole` service volumes in `docker-compose.yml`. Pi-hole was not started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `pihole/01-custom.conf` | The snippet mounted into dnsmasq |
| `sync_pihole_dns_records` | The only writer of `tu-lan.hosts` |
| `DNSMASQ_LOCALISE_QUERIES` | Already set, so two addresses in one hosts file can follow the client subnet |
| Compose volume `./pihole/01-custom.conf` | The delivery path that already works for `address=` |
| Stage 6 Pi-hole DNS hygiene page (expected sibling, open PR history) | Resolver hygiene. Not this include |
| LAN DNS onboarding page (expected sibling) | How a client points at Pi-hole. Not the record file |
| Pi-hole v6 FTLCONF page (expected sibling) | Environment variable names. Leave that migration alone |

Out of scope:

- Replacing Pi-hole with CoreDNS, Unbound, or a second resolver
- Changing which IP is chosen for LAN or Tailscale
- Pi-hole v6 environment-variable renames
- The Stage 49 TLS cipher list

## Proposal

Keep dnsmasq and the existing snippet. Point that snippet at a hosts file that lives in the repo mount, and fail the sync when the write does not happen.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Include | `pihole/01-custom.conf` | Add `addn-hosts=/etc/pihole/hosts/tu-lan.hosts` next to the upstream `server=` lines |
| Host file | `pihole/hosts/tu-lan.hosts` on the host, mounted read-only into the container at that path | `sync-dns` writes this file on the host. Do not `docker exec` it into a running container |
| Dual-stack lines | Same hosts file | Keep the two lines the function already prints: `$lan_ip $names` and `$ts_ip $names` |
| Single-IP | Either `address=` or one hosts line | One mechanism. Prefer the hosts file for both branches so localise-queries and the single-IP case share a file |
| Failure | `sync_pihole_dns_records` | If the hosts file cannot be written, return non-zero. Remove the `|| true` on that write |
| Reload | Existing `pihole reloaddns` | Keep it, and only after the mounted file is in place |

### Rules

1. **The mounted snippet is the contract.** A hosts file that no config line names is not published.
2. **Write on the host.** The container may be down during `setup`. A volume file created only by `docker exec` misses that run.
3. **Do not add a DNS server.** `addn-hosts` is the dnsmasq feature this image is already running.
4. **Keep localise-queries.** Two A records in the hosts file are why `DNSMASQ_LOCALISE_QUERIES` is set. Do not replace that with a single `address=` when both IPs exist.
5. **Success means the file exists.** Logging "synced" after a skipped `docker exec` is the bug.
6. **Leave v6 env migration on its page.** If the pinned image ignores `dnsmasq.d`, that is the FTLCONF contract, not a reason to add CoreDNS here.

### Suggested contributor checklist

```text
1. Read the dual-stack branch of sync_pihole_dns_records and pihole/01-custom.conf
2. Add addn-hosts for tu-lan.hosts in the mounted snippet
3. Write the hosts file on the host and mount it into the container
4. Return an error when that write fails
5. Run sync-dns with Pi-hole stopped and confirm the hosts file exists before start
6. Confirm dig of oweb.tu.lan against Pi-hole returns the expected address
7. Do not add a second DNS implementation
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local names | dnsmasq `addn-hosts` in the existing snippet | A new resolver container |
| Two client subnets | `DNSMASQ_LOCALISE_QUERIES`, already set | Per-client hosts files on laptops |
| Delivery | The compose mount that already ships `01-custom.conf` | `docker exec` into a container that may be down |
| Intake | GitHub Issue | A dashboard form for DNS edits |

## Acceptance criteria

- `pihole/01-custom.conf` contains an `addn-hosts` line for `tu-lan.hosts`.
- The hosts file is a host path mounted into the container, not only a file created by `docker exec`.
- `sync-dns` exits non-zero when that file cannot be written.
- With both a LAN IP and a Tailscale IP configured, the hosts file contains both lines and the snippet does not drop name data.
- No new DNS container is added.

## Verification notes

Repository search on 2026-10-04: `tu-lan.hosts` appears in `tu-vm.sh` and in the comment inside `pihole/01-custom.conf`. `addn-hosts` appears nowhere. The dual-stack branch returns 0 after a `docker exec` guarded by `|| true`.

## Rollback

Restore the current `01-custom.conf` and the `docker exec` writer. Single-IP `address=` behavior returns with the old function.
