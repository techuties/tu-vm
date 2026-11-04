---
title: Dual-Stack DNS Record Contract
description: Constructional contract so sync_pihole_dns_records writes LAN and Tailscale tu.lan names into the bind-mounted dnsmasq file.
last_updated: 2026-11-04
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Dual-Stack DNS Record Contract

## Problem

`sync_pihole_dns_records` is what `start_services` runs so clients can open `oweb.tu.lan` and the other names. Pi-hole loads `./pihole/01-custom.conf` from a read-only bind mount at `/etc/dnsmasq.d/01-custom.conf`.

When only a LAN address is known, the function writes `address=` lines into that file. Replayed with `HOST_IP=192.0.2.10` and no Tailscale address, the file contained 9 `address=` lines, starting with `address=/.tu.lan/192.0.2.10`.

When both a LAN address and a Tailscale address are known, the function takes the other branch. Replayed with `HOST_IP=192.0.2.10` and `TAILSCALE_IP=203.0.113.20`:

| Container visible to `docker ps` | `address=` lines | `addn-hosts` or `hostsdir` | Other write |
|---|---|---|---|
| No | 0 | 0 | None. The function still logged success |
| Yes (`ai_pihole`) | 0 | 0 | `docker exec` wrote `/etc/pihole/hosts/tu-lan.hosts` inside the container, then `pihole reloaddns` |

The mounted file in that branch is upstream resolvers and a comment that names `/etc/pihole/hosts/tu-lan.hosts`. Nothing in the mounted file tells dnsmasq to read that path. The checked-in `pihole/01-custom.conf` is that same text: comments and three `server=` lines, no `address=` line.

The container write also depends on Pi-hole already running. `start_services` calls this function before `docker compose up`. On that call the container is often absent, the `docker exec` does not run, and the success message is still printed. The next start of Pi-hole then serves the mounted file, which has no `tu.lan` names.

The single-IP branch already has the durable record: `address=` lines in the file that is mounted either way. Dual-stack needs the same durability for both addresses. `DNSMASQ_LOCALISE_QUERIES` is already set on the Pi-hole service so two host records can answer from the client's subnet. Those host records have to be in a file dnsmasq is given on disk.

Replayed on 2026-11-04 in a temp directory with a stub `docker`. The repo copy of `pihole/01-custom.conf` was not modified. The Docker daemon was not started. `.env` was not created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `sync_pihole_dns_records` | The only writer of `pihole/01-custom.conf` |
| Single-IP branch | Nine `address=` lines, including `address=/.tu.lan/<ip>` |
| `./pihole/01-custom.conf` | Bind-mounted into Pi-hole. Survives a stopped container |
| `DNSMASQ_LOCALISE_QUERIES` | Already `true` on the Pi-hole service |
| `show_dns_client_setup` | Tells operators that dual-stack returns the LAN address on LAN and the Tailscale address on Tailscale |
| Stage 30 `pihole-v6-ftlconf-env-contract.md` (open PR #56) | v6 `FTLCONF_*` names. Unchanged here |
| Stage 12 `lan-dns-client-onboarding-contract.md` (open PR #38) | How clients point at Pi-hole. Unchanged here |

Out of scope:

- A second DNS resolver container
- Renaming `FTLCONF_*` variables or editing Pi-hole image pins
- Changing `PIHOLE_DNS_BIND_ADDR` or the quoted `WEBPASSWORD` default
- Committing a real LAN or Tailscale address into `01-custom.conf`

## Proposal

Make the dual-stack branch leave both addresses in the bind-mounted file, using the same `address=` style the single-IP branch already writes, plus one directive in that file that loads a host file when two addresses must both exist.

For two addresses, localise-queries needs host lines rather than a single `address=` override. Put those lines in a file next to `01-custom.conf` (for example `pihole/tu-lan.hosts`) and add `addn-hosts=` or `hostsdir=` in `01-custom.conf` pointing at the mounted path. Write both files before checking whether `ai_pihole` is running. Keep the `docker exec` reload only as a refresh when the container is already up.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| One address | Existing `address=` block | Leave it |
| Two addresses | `sync_pihole_dns_records` dual-stack branch | Write host lines and an `addn-hosts` or `hostsdir` line into the mounted tree |
| Stopped container | The same function | Success means the mounted files contain the names. A missing container is not success by itself |
| Running container | `docker exec … pihole reloaddns` | Keep as a reload, after the files exist on the host |
| Operator text | `show_dns_client_setup` | Leave the LAN versus Tailscale instructions |

### Rules

1. **The mounted file is the record.** Names that exist only inside a running container are gone whenever that write did not happen.
2. **Both addresses are written up front.** The dual-stack branch writes the host file and the dnsmasq directive before the `docker ps` test.
3. **Reuse `address=` for one address.** The single-IP branch stays the template for a single target.
4. **Localise-queries stays.** Two host lines plus the existing `DNSMASQ_LOCALISE_QUERIES=true` are the dual-stack behavior `show_dns_client_setup` already describes.
5. **Examples stay documentation addresses.** `192.0.2.0/24` and `203.0.113.0/24` are the stand-ins. Real addresses belong in `.env`, which is not committed.
6. **Stage 30 still owns v6 environment names.** This page does not rename `FTLCONF_*` keys.

### Suggested contributor checklist

```text
1. Replay with only HOST_IP=192.0.2.10 and confirm address= lines in the mounted conf
2. Replay with HOST_IP and TAILSCALE_IP and a stopped container
3. Confirm the mounted conf references a host file and that file contains both addresses
4. Confirm docker exec is not required for those files to exist
5. Confirm pihole/01-custom.conf in git is still a sample with documentation addresses only
6. Confirm .env was not created and the Docker daemon was not started
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| One address | `address=` lines already in `sync_pihole_dns_records` | A generated zone file in a new container |
| Two addresses | Host lines plus `addn-hosts` or `hostsdir` in the mounted conf | A hosts file that dnsmasq is never pointed at |
| Per-client answer | `DNSMASQ_LOCALISE_QUERIES` already on the service | A second Pi-hole |
| Reload | `pihole reloaddns` when the container is up | Treating a skipped `docker exec` as a published zone |

### Acceptance check

- [ ] With one address, `pihole/01-custom.conf` still receives `address=` lines for `tu.lan` and the service names.
- [ ] With LAN and Tailscale addresses, the mounted conf contains `addn-hosts=` or `hostsdir=`, and the referenced file contains both addresses for every name.
- [ ] Those files are written when `docker ps` does not show `ai_pihole`.
- [ ] The function's success message is printed only after those files are in place.
- [ ] `docker exec` remains a reload for a container that is already running.
- [ ] `FTLCONF_*` names, the Pi-hole image pin, and `WEBPASSWORD` are unchanged.
- [ ] The Docker daemon was not started to prove this, and `.env` was not created.

### Rollback

Restore the dual-stack branch that writes only upstream resolvers into `01-custom.conf` and copies host lines with `docker exec` when the container is up. Single-IP `address=` lines stay as they are.
