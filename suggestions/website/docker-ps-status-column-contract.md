---
title: Docker Ps Status Column Contract
description: Constructional contract so tu-vm.sh treats a running container as running when it reads docker ps.
last_updated: 2026-11-05
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Docker Ps Status Column Contract

## Problem

Four checks in `tu-vm.sh` ask `docker ps` whether a container is up by searching for the name and then the word `Up`:

```bash
docker ps | grep -q "ai_tika.*Up"
docker ps | grep -q "ai_minio.*Up"
docker ps | grep -q "tika_minio_processor.*Up"
docker ps | grep -q "ai_pihole.*Up"
```

The first three are how `check_pdf_processing_status` chooses "container is running" versus "container is not running". The fourth is the wait inside `handle_pihole_dns_replacement` `start`.

Docker CLI 28.5.2, the client on this machine, defaults to this table. The string is in `/usr/bin/docker`:

```text
table {{.ID}}  {{.Image}}  {{.Command}}  {{.RunningFor}}  {{.Status}}  {{.Ports}}  {{.Names}}
```

`Status` is the column that contains `Up`. `Names` is the last column. A running Tika line looks like this:

```text
a1b2c3d4e5f6   apache/tika:latest   "java -jar /tika-server.jar"   2 hours ago   Up 2 hours   9998/tcp   ai_tika
```

`ai_tika.*Up` needs the name first and `Up` later. On that line the name is last. The same shape misses MinIO, the processor, and Pi-hole.

Replayed on 2026-11-05 against fixture lines in that column order. The daemon was not started.

| Fixture | Pattern in `tu-vm.sh` | Match |
|---|---|---|
| Tika, status `Up 2 hours`, name `ai_tika` | `ai_tika.*Up` | no |
| Same line | `Up.*ai_tika` | yes |
| MinIO, status `Up 3 hours (healthy)`, name `ai_minio` | `ai_minio.*Up` | no |
| Processor, status `Up 1 hour`, name `tika_minio_processor` | `tika_minio_processor.*Up` | no |
| Pi-hole, status `Up 4 hours (healthy)`, name `ai_pihole` | `ai_pihole.*Up` | no |

`pdf-status` then prints "Tika container is not running", "MinIO container is not running", and "Processor container is not running" while those containers are up. The curl and `mc` checks below those branches never run.

The Pi-hole loop sleeps until `max_attempts` (30 times, 2 seconds) and then writes `/etc/resolv.conf` anyway. A container that is actually up does not end the wait early.

`check_service_health` already answers this question with `docker inspect` on the exact container name, then `{{.State.Running}}` and the health status. `show_dns_status` searches for `ai_pihole` anywhere on the line, which does match the name column. The four patterns above are the ones that cannot.

Checked from `tu-vm.sh` and from the Docker 28.5.2 client binary. `.env` was not created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `check_pdf_processing_status` | The three `pdf-status` lines operators read |
| `handle_pihole_dns_replacement` | The `ai_pihole.*Up` wait |
| `check_service_health` | Exact container name, running flag, health status |
| `get_container_name` | Map from a compose service to `ai_*` |
| `show_dns_status` | A `docker ps` name search that does not require `Up` after the name |
| Stage 54 `pdf-cli-probe-contract.md` (open PR #80) | Host curl to port 9998, and the MinIO password on the `mc` lines |
| Stage 55 `pihole-dns-restore-order-contract.md` (open PR #81) | Call `start` after the container exists, not between `down` and `up` |

Out of scope:

- Publishing Tika on a host port
- The MinIO password passed to `mc`
- Moving the Pi-hole restore call to after `compose up`
- Replacing Docker with another runtime

## Proposal

Use the inspect check that `check_service_health` already runs. Keep `docker ps` for human tables in `show_status`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| PDF status | The three `grep` tests in `check_pdf_processing_status` | `docker inspect` the exact name, or `docker ps -a --filter name=^/name$` and read `{{.State.Running}}` or `{{.Status}}` |
| Pi-hole wait | The `grep` in `handle_pihole_dns_replacement` | Same inspect. Leave the surrounding call order to Stage 55 |
| Human output | `show_status` and `show_dns_status` | Leave the table format |

### Rules

1. **A running container matches.** Status text `Up …` with the name in the last column is a hit.
2. **The name is exact.** `ai_n8n` must not count as `ai_n8n_mcp`. A filter uses an anchored name, which `check_service_health` already gets from `docker inspect`.
3. **Stopped stays stopped.** `Exited` or a missing container is the "not running" branch.
4. **Stage 54 still owns the curl and the password.** This page does not publish port 9998 and does not change `mc` arguments.
5. **Stage 55 still owns when the wait runs.** This page only makes the wait able to see a container that is up.
6. **One Docker CLI.** No second status agent.

### Suggested contributor checklist

```text
1. Build one fixture line in Docker 28.5.2 column order for ai_tika and confirm the new test accepts it
2. Repeat for ai_minio, tika_minio_processor, and ai_pihole
3. Confirm an Exited line, or a missing container, is still "not running"
4. Confirm ai_n8n_mcp does not satisfy an ai_n8n check
5. Confirm the host curl and the mc password lines are unchanged
6. Confirm the update_system call order around handle_pihole_dns_replacement is unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Running? | `docker inspect` as in `check_service_health` | `grep` of the default table |
| Exact name | Container name from `get_container_name` | An unanchored substring |
| PDF probes after that | The curl and `mc` lines Stage 54 already specifies | A new probe |
| Intake | GitHub Issue | A status webhook |

### Acceptance check

- [ ] A default `docker ps` line with `Up` before `ai_tika` counts as Tika running.
- [ ] The same is true for `ai_minio`, `tika_minio_processor`, and `ai_pihole`.
- [ ] A stopped or missing container still takes the not-running branch.
- [ ] `ai_n8n_mcp` does not satisfy a check for `ai_n8n`.
- [ ] The port 9998 curl and the `mc` password lines are unchanged.
- [ ] `update_system` still calls Pi-hole restore where it does today.
- [ ] The daemon was not started to prove this, and `.env` was not created.

### Rollback

Put the four `grep` patterns back. `pdf-status` again reports those containers down while they are up, and the Pi-hole wait again runs out its attempts even when `ai_pihole` is up.
