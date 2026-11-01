---
title: Stopped Container Prune Contract
description: Constructional contract so cleanup and the post-update prune leave the stopped Tier 2 containers the dashboard starts.
last_updated: 2026-11-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Stopped Container Prune Contract

## Problem

On-demand services are created stopped on purpose. `start_services` in portable mode runs:

```bash
$compose_cmd up -d "${TIER1_SERVICES[@]}"
$compose_cmd up -d --no-start "${TIER2_SERVICES[@]}"
```

`update_system` repeats that idea after `compose down`: it starts Tier 1, restores anything that was running, then refreshes the rest with `up -d --no-start`. The helper start route then calls the Docker Engine start API. If the container is missing, it returns 404 and tells the operator to create it again with `docker compose up -d --no-start`.

Two cleanup paths delete those stopped containers.

| Caller | Command | When it runs |
|---|---|---|
| `cleanup` | `docker system prune -f` | `./tu-vm.sh cleanup`, including the low-disk announcement that prints `Run: ./tu-vm.sh cleanup` |
| `perform_docker_cleanup` | `docker container prune -f` | End of `./tu-vm.sh update`, only when `update_healthy` is true |

On this host, `docker container prune --help` says "Remove all stopped containers". The Docker reference for `docker system prune` warns that the command removes "all stopped containers", plus unused networks, dangling images, and unused build cache. Neither command knows that a stopped `ai_ollama` or `ai_n8n` is how the dashboard starts Tier 2.

`perform_docker_cleanup` also runs `docker volume prune -f`. On this CLI the help text is: `-a, --all` means "Remove all unused volumes, not just anonymous ones". The script does not pass `-a`. Named Compose volumes are outside that default. This page must not add `-a`. The defect is the container, which the dashboard needs in order to call start.

`cleanup` has no health gate. The low-disk banner points operators at it while Tier 2 is stopped, which is the normal portable-mode state. After the prune, Start on the landing page hits the 404 branch until someone recreates the container.

Checked on 2026-11-01 by reading `start_services`, `update_system`, `cleanup`, `perform_docker_cleanup`, the helper `control_service` 404 branch, and the announcement copy. `docker container prune --help` and `docker volume prune --help` were read locally. The daemon was not started, and no project container was pruned.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker compose up -d --no-start` | The create-stopped step both start and update already run |
| Helper `control_service` | Starts an existing container and already explains the 404 |
| `docker image prune -f` | Already the dangling-image step inside `perform_docker_cleanup` |
| `docker container prune --filter` | Existing way to limit which stopped containers are removed |
| Low-disk announcement | The operator-facing hint that names `./tu-vm.sh cleanup` |
| Stage 46 volume prefixes (open PR #72) | How volume names are discovered. Unchanged here |
| Stage 63 backup rotation (open PR #89) | Keep-latest tar rules. Unchanged here |
| Stage 48 startup gate (open PR #74) | Why `--no-start` must still be reached. Unchanged here |

Out of scope:

- A new cleanup service or a garbage-collection container
- `docker volume prune -a` or any named-volume deletion
- Backup rotation and archive mode (Stage 63)
- The `docker_` versus project prefix rule (Stage 46)
- Image digest compare (Stage 44, open PR #70)

## Proposal

Leave Compose project containers in place when they are stopped. Keep dangling-image cleanup. Do not widen volume prune.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Operator command | `cleanup` | Remove `docker system prune -f`. Keep backup rotation and log rotation |
| Post-update | `perform_docker_cleanup` | Remove the unrestricted `docker container prune -f` |
| Leftover non-project containers | Same function, if a prune remains | `docker container prune -f --filter label!=com.docker.compose.project` |
| Images | Same function | Keep `docker image prune -f` (dangling only) |
| Volumes | Same function | Keep `docker volume prune -f` without `--all`, or delete that line. Do not add `--all` |
| Banner | Helper low-disk text | It may keep naming `./tu-vm.sh cleanup` once that command no longer deletes Tier 2 containers |

### Rules

1. **A stopped Tier 2 container survives cleanup.** After `./tu-vm.sh cleanup`, `docker inspect ai_ollama` still succeeds when that container existed beforehand.
2. **A successful update does not delete the containers it just created with `--no-start`.** `perform_docker_cleanup` may still run when `update_healthy` is true.
3. **`docker system prune` is the wrong single command.** It always includes stopped containers. Dangling images already have `docker image prune -f`.
4. **Named volumes stay.** Do not pass `--all` to `docker volume prune`. Stage 46 still decides the volume names.
5. **The dashboard keeps using the Docker start API.** Do not add a second start path in this change. Stage 50 (open PR #76) owns the AFFiNE dependency group.

### Suggested contributor checklist

```text
1. Create a stopped Compose container with up -d --no-start and run cleanup
2. Confirm docker inspect still finds that container
3. Confirm a non-Compose stopped container can still be pruned if the filter lane is kept
4. Confirm docker volume prune is not invoked with --all
5. Confirm backup rotation and the Stage 63 archive rules were not edited
6. Confirm the helper 404 text still matches a container that was never created
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| On-demand containers | `up -d --no-start` and the existing start API | Recreating containers inside the helper |
| Dangling images | `docker image prune -f` | `docker system prune` |
| Foreign stopped containers | `docker container prune --filter label!=...` | Pruning every stopped container |
| Named data | Leave `volume prune` without `--all` | `--all` or a volume-backup plugin |

### Acceptance check

- [ ] `./tu-vm.sh cleanup` does not run `docker system prune`.
- [ ] Post-update cleanup does not remove containers labeled as part of this Compose project.
- [ ] `docker volume prune` is never passed `--all` by these functions.
- [ ] Dashboard Start for an existing stopped Tier 2 container is still a Docker start call.
- [ ] No project container was pruned while writing this page.

### Rollback

Put the previous prune lines back. Containers removed by a prune that already ran are recreated with `docker compose up -d --no-start`. Named volumes were not part of this contract.
