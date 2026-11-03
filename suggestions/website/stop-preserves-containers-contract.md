---
title: Stop Preserves Containers Contract
description: Constructional contract so ./tu-vm.sh stop stops containers without removing them, matching stop-service and the dashboard Start API.
last_updated: 2026-11-02
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Stop Preserves Containers Contract

## Problem

`./tu-vm.sh stop` calls `stop_services`, and that function removes the project containers:

```bash
stop_services() {
    info "Stopping $PROJECT_NAME services..."
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd down
    info "Services stopped successfully!"
}
```

`docker compose stop --help` on Compose v5.1.0 says the command stops services. `docker compose down --help` on the same binary says it stops and removes containers and networks. The script does not pass `-v`. Named volumes are not what this page is about. The containers themselves are removed.

`stop_single_service` already uses the command that keeps the container:

```bash
info "Stopping service: $svc"
$compose_cmd stop "$svc"
```

The dashboard Start path cannot create a container. `control_service` in `helper/uploader.py` returns 404 when `docker_inspect` finds nothing:

```text
Container {container} does not exist.
Create it on the host with: docker compose up -d --no-start {compose_service}
```

`start` in portable mode creates Tier 2 containers with `up -d --no-start` so that Start button has something to start. `./tu-vm.sh stop` deletes those containers. The next Start returns 404 until someone runs a full `up` again. `restart` calls `stop_services` and then `start_services`, so a full restart still comes back. The broken path is stop, then the dashboard, without another `./tu-vm.sh start`.

Two other `down` calls stay where they are. `update_system` uses `down` before it starts the stack again, and Stage 55 owns the DNS calls around that window. `restore_backup` uses `down` before it copies files back. This page is only `stop_services`.

Checked on 2026-11-02 by reading `stop_services`, `stop_single_service`, and `control_service`, and by reading Compose v5.1.0 help text. The daemon was not started. `./tu-vm.sh stop` was not run.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `stop_services` | The all-services command to change |
| `stop_single_service` | Already runs `docker compose stop` |
| `control_service` | Returns 404 when the container record is gone |
| `start_services` portable branch | Creates stopped Tier 2 containers with `--no-start` |
| Stage 65 stopped-container prune (open PR #91) | `docker system prune` and `docker container prune`. Unchanged here |
| Stage 55 DNS restore order (open PR #81) | The `down` inside `update_system`. Unchanged here |
| Stage 47 backup restore apply (open PR #73) | What restore writes back. The `down` in `restore_backup` stays |

Out of scope:

- A new orchestrator or a process supervisor
- `docker volume prune`, including `--all` (Stage 65)
- The `down` in `update_system` and the `down` in `restore_backup`
- Changing the helper 404 text

## Proposal

Make `./tu-vm.sh stop` stop the project the way `stop-service` stops one service.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| All-services stop | `stop_services` | `$compose_cmd stop` |
| One service | `stop_single_service` | Leave `docker compose stop` |
| Dashboard | `control_service` | Leave the 404 that reports a missing container |
| Update and restore | `update_system`, `restore_backup` | Leave both `down` lines |

### Rules

1. **`stop` does not remove containers.** After `./tu-vm.sh stop`, `docker inspect` on a Tier 1 container such as `ai_postgres` still succeeds, and `State.Running` is false.
2. **`stop` does not remove the Compose network.** `down` removes networks. `stop` does not. Dashboard Start uses the existing container on that network.
3. **Do not pass `-v`.** Named volumes stay. This is the same boundary Stage 65 drew for prune.
4. **`restart` may keep calling `stop_services` and then `start_services`.** `start` already runs `up -d`, which starts containers that `stop` left behind.
5. **Do not edit the update or restore `down` lines in this change.** They are different procedures.

### Suggested contributor checklist

```text
1. Read docker compose stop --help and docker compose down --help and confirm only stop_services changes command
2. Confirm stop_single_service still uses stop
3. Confirm update_system and restore_backup still use down
4. Confirm the helper 404 text was not edited
5. Confirm no -v flag was added
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop every service | `docker compose stop` | `docker compose down` in the stop command |
| Stop one service | The existing `stop-service` arm | A second stop implementation |
| Start a stopped container | The helper Docker start API | Creating the container from the dashboard |
| Intake | GitHub Issue | A new power button stack |

### Acceptance check

- [ ] `stop_services` runs `docker compose stop` and does not run `down`.
- [ ] `stop_single_service` is unchanged.
- [ ] `update_system` and `restore_backup` still contain their current `down` lines.
- [ ] The command does not pass `-v` or `--volumes`.
- [ ] No container was stopped to prove the help text.

### Rollback

Restore the `down` line in `stop_services`. Containers already removed by an older `stop` stay removed until `docker compose up -d` or `up -d --no-start` creates them again. Volumes are not part of this rollback.
