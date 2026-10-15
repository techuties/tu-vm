---
title: Pi-hole DNS Restore Order Contract
description: Constructional contract so update_system points host DNS at Pi-hole only after the Tier 1 container is answering.
last_updated: 2026-10-15
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Pi-hole DNS Restore Order Contract

## Problem

`update_system` asks Pi-hole to become the host resolver while the Pi-hole container is stopped, then marks `/etc/resolv.conf` immutable.

The call order in `update_system` is:

| Order | Call | Pi-hole container |
|---|---|---|
| 1 | `handle_pihole_dns_replacement stop` | Still running. Host resolv.conf is switched to public resolvers |
| 2 | Image pulls | Public resolvers |
| 3 | `docker compose down` | Stopped and removed |
| 4 | `handle_pihole_dns_replacement start` | Still stopped |
| 5 | `docker compose up -d` for Tier 1 | Starts during this step |

Step 4 is `handle_pihole_dns_replacement start`. That branch:

1. Stops and disables `systemd-resolved`.
2. Calls `configure_docker_dns restore`, which restarts Docker.
3. Waits up to about 60 seconds for `docker ps` to show `ai_pihole` up.
4. Writes `/etc/resolv.conf` with `nameserver 127.0.0.1` and two public resolvers after it.
5. Runs `chattr +i` on that file.
6. Waits again for `docker exec ai_pihole pihole status`.

Step 3 has already removed the container, and step 5 has not created it. The wait in step 4 ends in the warning "Pi-hole may not be fully ready yet, but DNS is configured", and the function still returns. `chattr +i` has already run.

Until `compose up` finishes and Pi-hole is healthy, the host's first resolver is `127.0.0.1` with nothing listening, `systemd-resolved` is disabled, and the file cannot be replaced without `chattr -i`. If `compose up` then fails, the host stays on that file.

The sibling page in this stage owns `/etc/docker/daemon.json`. This page does not change that file. Stage 30 (open PR #56) owns Pi-hole v6 environment keys. Stage 50 (open PR #76) owns dual-stack host records. Neither page moves this call.

Checked on 2026-10-15 by reading `update_system` and `handle_pihole_dns_replacement`. The update command was not run.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `handle_pihole_dns_replacement` | Already knows how to write public resolvers and how to write the Pi-hole resolv.conf |
| `update_system` | The only caller that currently invokes `start` between `down` and `up` |
| `check_service_health` / `docker exec ai_pihole pihole status` | The readiness tests the `start` branch already loops on |
| `/etc/resolv.conf.pihole.backup` | The one-shot copy `stop` already takes |
| Stage 55 `docker-daemon-dns-merge-contract.md` | `daemon.json` merge and restore |
| Stage 30 `pihole-v6-ftlconf-env-contract.md` (expected sibling, open PR #56) | v6 environment keys |
| Stage 50 `pihole-dual-stack-hosts-contract.md` (expected sibling, open PR #76) | Host records Pi-hole serves |

Out of scope:

- Replacing Pi-hole or `systemd-resolved` with another resolver
- Editing `daemon.json` (sibling page)
- Pi-hole v6 env keys or gravity during backup
- How clients on the LAN choose a DNS server

## Proposal

Leave the public resolv.conf in place until Tier 1 is up and `ai_pihole` answers. Only then write `127.0.0.1` and set the immutable attribute.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Call site | `update_system` | Remove the `start` call that sits between `compose down` and `compose up` |
| After Tier 1 | `update_system`, after `up -d` of `TIER1_SERVICES` and a successful Pi-hole wait | Call `handle_pihole_dns_replacement start` |
| Ready check | `start` | Write resolv.conf and run `chattr +i` only after `docker exec ai_pihole pihole status` succeeds |
| systemd-resolved | `start` | Stop it only in that same success path, once port 53 is held by `ai_pihole` |
| Failure | `start` | If Pi-hole never becomes ready, leave the public resolv.conf from `stop` in place and return non-zero. Do not set `chattr +i` |

### Rules

1. **`127.0.0.1` is written only while `ai_pihole` is up.** `compose down` is not a reason to point the host at loopback.
2. **The immutable flag follows a successful status check.** A failed `compose up` leaves resolv.conf editable and on the public resolvers `stop` installed.
3. **`systemd-resolved` stays available until Pi-hole has port 53.** It is not disabled during the window when the container does not exist.
4. **`daemon.json` is unchanged by this page.** Merge and restore stay on the sibling contract.

### Suggested contributor checklist

```text
1. Trace update_system: compose down, compose up of Tier 1, then the start action
2. A start call while ai_pihole is absent does not write nameserver 127.0.0.1 and does not run chattr +i
3. After pihole status succeeds, resolv.conf lists 127.0.0.1 first
4. If the status wait times out, resolv.conf is still the public file from stop and is not immutable
5. daemon.json is not opened by this change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Resolver handoff | The existing `stop` and `start` actions, called in an order the container can satisfy | A new local resolver |
| Readiness | `pihole status` inside the wait this function already has | A fixed `sleep` |
| Backup of resolv.conf | `/etc/resolv.conf.pihole.backup` | A second copy under `backups/` |
