---
title: Open WebUI Recovery Command Contract
description: Constructional contract so the health hint's recover-openwebui command is registered and uses the Docker API instead of a privileged host-PID kill and a daemon restart.
last_updated: 2026-10-28
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Open WebUI Recovery Command Contract

## Problem

`check_health` recognizes a stuck Open WebUI container and prints a command the script does not implement.

```text
warn "Detected stuck Open WebUI container (Docker BaseFS/exec failure pattern)."
warn "Run: ./$SCRIPT_NAME recover-openwebui"
```

`main` dispatches subcommands in a `case` statement. `recover-openwebui` is not one of the arms. The `*)` arm calls `error`, and `error` logs the message and `exit 1`. The help text that follows `error` in that arm does not run. `show_help` does not list the command either.

The function that matches the hint, `recover_openwebui_container`, is never called. If a later change only adds the `case` arm and calls that function, recovery does this:

```text
pid="$(docker inspect -f '{{.State.Pid}}' ai_openwebui ...)"
docker run --rm --privileged --pid=host alpine sh -c "kill -9 $pid"
sudo systemctl restart docker
```

`State.Pid` is a PID in the host namespace. `--pid=host` lets the helper see every host process. `--privileged` drops the seccomp and capability limits on that helper. The image name `alpine` has no tag, so the pull follows `alpine:latest`. Between `docker inspect` and `kill -9`, the kernel can assign that PID to a different process. `systemctl restart docker` then stops every container on the machine, including Postgres, Redis, MinIO, and Pi-hole, as the default path for one stuck UI container.

`is_container_stuck` already describes the failure it cares about: `docker exec` returns a BaseFS error, or the container is running with PID 0. Those checks use `docker inspect` and `docker exec`. They do not need a second container.

Checked on 2026-10-28 by reading `check_health`, `recover_openwebui_container`, `is_container_stuck`, `show_help`, and both `case` statements in `main`. A search of `tu-vm.sh` finds the string `recover-openwebui` only in the health hint. No container was killed and the Docker daemon was not restarted.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `check_health` | Prints the hint when `open-webui` failed and `is_container_stuck` is true |
| `is_container_stuck` | BaseFS / empty-exec detector to keep |
| `docker kill` and `docker rm -f` | Engine API operations that address a container by name |
| `start_single_service` | `docker compose up -d <service>`, already the supported start path |
| Stage 11 privileged host ops (open PR #37) | Sudoers scope for documented host commands. Unchanged here |
| Stage 18 container hardening (open PR #44) | `privileged: true` on Compose services. This page is a `docker run`, not a service |
| Stage 60 image pin (open PR #86) | `alpine:latest` inside the sync script. The untagged `alpine` in this function is part of this recovery contract |

Out of scope:

- A new watchdog, systemd unit, or process supervisor
- Changing Open WebUI's healthcheck path (`/health/db` stays)
- Restarting the Docker daemon as the normal recovery step
- Killing PIDs other than the Open WebUI container's own process, and not by host PID

## Proposal

Register `recover-openwebui` and implement it with the Docker API the rest of `tu-vm.sh` already uses.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Dispatch | `main` case | `recover-openwebui) recover_openwebui_container ;;` |
| Help | `show_help` diagnostics list | One line: recreate a stuck `ai_openwebui` without restarting Docker |
| Recovery | `recover_openwebui_container` | `docker kill ai_openwebui`, then `docker compose up -d --force-recreate open-webui` |
| Stuck check | `is_container_stuck` | Keep the BaseFS string check. Call it again after recreate and print the result |
| Daemon | Same function | Delete the `systemctl restart docker` step from the default path |

### Rules

1. **The hint must name a real command.** `./tu-vm.sh recover-openwebui` reaches `recover_openwebui_container` and returns 0 when recreate succeeds.
2. **Address the container by name.** `docker kill` and `docker compose` take `ai_openwebui` / `open-webui`. They do not read `State.Pid`.
3. **No privileged helper.** Do not pass `--privileged`, `--pid=host`, or an `alpine` image.
4. **Leave the daemon up.** A stuck UI container is not a reason to restart every other service. Operators who need a daemon restart already have `systemctl` outside this script.
5. **Keep the detector.** `is_container_stuck` stays the gate inside `check_health`. Recovery is still manual.
6. **Do not invent a supervisor.** One subcommand is enough.

### Suggested contributor checklist

```text
1. ./tu-vm.sh help includes recover-openwebui
2. The main case arm calls recover_openwebui_container
3. The function contains no --privileged, --pid=host, or systemctl restart docker
4. The function contains no docker run of an alpine image
5. A stuck ai_openwebui is recreated with docker compose up -d --force-recreate open-webui
6. Postgres and the other Tier 1 containers are not stopped by that command
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop a container | `docker kill` / `docker rm -f` | `kill -9` of `State.Pid` |
| Start it again | `docker compose up -d --force-recreate open-webui` | Restarting `docker.service` |
| Privilege | The daemon socket `tu-vm.sh` already uses | `--privileged --pid=host` |
| Intake | GitHub Issue if the BaseFS strings need to grow | A second recovery script |
