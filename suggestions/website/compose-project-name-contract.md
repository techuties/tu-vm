---
title: Compose Project Name Contract
description: Constructional contract for a top-level Compose name so project labels, networks, and volume prefixes stay stable regardless of clone directory.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Compose Project Name Contract

## Problem

`docker-compose.yml` has no top-level `name:`. Compose then derives the project name from the **directory**:

| Clone path | Project name | Network / volume prefix |
|---|---|---|
| `/opt/tu-vm` | `tu-vm` | `tu-vm_ai_network`, `tu-vm_postgres_data` |
| `/home/me/src/tu-vm` | `tu-vm` | same |
| `/tmp/tu-vm-pr-55` | `tu-vm-pr-55` | **different** volumes and network |

Cloud agents, extra worktrees, and `cp -r` checkouts silently create a second stack. `tu-vm.sh` talks to `container_name` (`ai_postgres`), which is global, so two projects **cannot** run at once — but volume names diverge, `docker compose down` in the wrong directory looks like data loss, and CI labels (`com.docker.compose.project`) do not match docs.

Stage 18 is IPAM. Stage 28 is `include:`. This page is leftover **project identity**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose Specification `name:` | Official project name |
| `COMPOSE_PROJECT_NAME` env | Override without editing YAML |
| `container_name: ai_*` | Already globally unique |
| `tu-vm.sh` inspect maps | Keyed by `container_name`, not project |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | Addresses, not project id |
| Stage 28 `compose-include-split-contract.md` (expected sibling) | File split; still one project |

Out of scope:

- Removing `container_name` (would make project name the only identity)
- A lockfile that refuses non-canonical directories
- Running two full stacks on one host (IPAM and `container_name` forbid it)

## Proposal

Set an explicit project name at the top of `docker-compose.yml`:

```yaml
name: tu-vm
```

Document `COMPOSE_PROJECT_NAME` as the escape hatch for intentional isolation (rare). `./tu-vm.sh` should not invent a second naming scheme.

Do **not** rename existing volumes in place. Operators whose current project is already `tu-vm` see no change. Operators whose directory produced another prefix keep their volumes until they migrate or set `COMPOSE_PROJECT_NAME` to the old value.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | top-level `name:` | `tu-vm` |
| Docs | README / this page | One sentence on clone-path independence |
| Scripts | `tu-vm.sh` | No new naming API |
| CI | `docker compose config` | Confirm `name` survives interpolation |

### Rules

1. **Use the Compose key.** Do not wrap `docker compose -p` in every script.
2. **Keep `container_name`.** This page does not replace CLI names.
3. **Do not auto-migrate volumes.** Call out the prefix in the playbook if someone already used a non-canonical directory.
4. **`include:` children inherit the parent name** (Stage 28). Do not set a second `name:` in fragments.
5. **GitHub remains intake.** Requests for "multi-stack on one host" conflict with IPAM.

### Suggested contributor checklist

```text
1. Add top-level name: tu-vm
2. docker compose config shows the name
3. From a differently named directory, compose still uses tu-vm_* prefixes
4. Existing tu-vm_* volumes still attach
5. Document COMPOSE_PROJECT_NAME as the override
6. Leave container_name maps in tu-vm.sh unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stable project id | Compose `name:` | Directory-name lock scripts |
| CLI identity | Existing `container_name` | Renaming every container to drop `ai_` |
| File split | Stage 28 `include:` | A second project per fragment |
| Addresses | Stage 18 IPAM | Encoding the project in IPv4 |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one-line Compose PR plus a README note.
3. If CI or a cloud agent already created `<dir>_postgres_data`, keep using that directory or set `COMPOSE_PROJECT_NAME` until a planned volume move.

## Acceptance criteria

- [ ] `docker-compose.yml` has top-level `name: tu-vm`.
- [ ] `docker compose config` reports that name from any clone path.
- [ ] Operators whose project was already `tu-vm` see no volume rename.
- [ ] `container_name` values are unchanged.
- [ ] Stage 28 `include:` fragments do not set a conflicting `name:`.

## Rollback

Delete `name:`. Compose falls back to the directory. Existing `tu-vm_*` volumes remain; a directory-derived name may look like an empty stack.

## Success metrics

- Extra worktrees do not create a second volume prefix by accident.
- Docs and `docker volume ls` agree on `tu-vm_*`.
- Contributors stop proposing a `pwd` check in `tu-vm.sh`.
