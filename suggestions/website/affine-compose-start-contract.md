---
title: AFFiNE Compose Start Contract
description: Constructional contract so the landing-page Start and Stop actions for AFFiNE use the Compose command tu-vm.sh already runs, including the database, cache, and migration containers.
last_updated: 2026-10-04
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# AFFiNE Compose Start Contract

## Problem

The landing page starts AFFiNE by POSTing `/control/affine/start`. Helper maps that name to container `ai_affine` and calls the Docker Engine:

```text
POST /containers/ai_affine/start
```

That API starts one container. It does not read Compose `depends_on`. The `affine` service declares:

```yaml
depends_on:
  affine_redis:
    condition: service_healthy
  affine_postgres:
    condition: service_healthy
  affine_migration:
    condition: service_completed_successfully
```

Those three services set `restart: "no"`. They are also absent from `TIER1_SERVICES` and `TIER2_SERVICES` in `tu-vm.sh`. A normal `./tu-vm.sh start` therefore does not leave them running. After that start, the dashboard button starts `ai_affine` alone. The workspace process comes up without its database, cache, or migration job.

The CLI path already does the right thing. `start_single_service` runs:

```text
docker compose up -d affine
```

Compose then creates and starts `affine_redis`, `affine_postgres`, and `affine_migration` before `affine`. Stop is the mirror image of the bug: `/control/affine/stop` stops only `ai_affine`, so the database and Redis keep their `restart: "no"` containers running until something else stops them.

`control_service` has a one-off extra start for the MCP gateway and LangGraph. AFFiNE has no equivalent, and a second special case inside the helper would be another hand-maintained graph. The Compose file is already the graph.

Checked by reading `helper/uploader.py` (`name_map` and `control_service`), the `affine*` services in `docker-compose.yml`, and `start_single_service` / `TIER2_SERVICES` in `tu-vm.sh`. No containers were started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `control_service` | Authenticated start/stop handler |
| `name_map['affine']` | `(ai_affine, affine)` |
| `start_single_service` | `docker compose up -d <service>` |
| `stop_single_service` | `docker compose stop <service>` |
| Helper image command | Installs `docker-cli-compose` and runs `docker compose version` |
| `/docker-project` mount | Read-only copy of the repo, including `docker-compose.yml` and `.env` |
| `get_compose_network_name` | Fallback project label `tu-vm` |
| Stage 7 dependency map (expected sibling, open PR history) | A future YAML and `--with-deps` flag. Not this bug |
| Stage 24 depends-on health (expected sibling) | Which `condition:` to use. AFFiNE's conditions are already the strict ones |
| Stage 9 AFFiNE collaboration page (expected sibling) | Contribution lanes for the product. Not the start API |

Out of scope:

- A new orchestrator, `wait-for-it` sidecar, or `config/service-dependencies.yaml`
- Changing AFFiNE `depends_on` conditions
- Auto-starting AFFiNE at boot
- Deleting `affine_postgres_data` or `affine_storage` on stop
- The Stage 49 roster gap for the announcement banner

## Proposal

For the logical service `affine`, start and stop through Compose, using the project that already owns the containers.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Start | `control_service` when `compose_service == 'affine'` | `docker compose -p <project> --project-directory /docker-project -f /docker-project/docker-compose.yml up -d affine` |
| Stop | Same handler | `docker compose ... stop affine affine_redis affine_postgres` |
| Project id | Docker inspect on an existing Tier 1 container | Read label `com.docker.compose.project`. If it is missing, use `tu-vm`, matching `get_compose_network_name` |
| Env | Compose project directory | Let Compose load `/docker-project/.env`. `AFFINE_DB_PASSWORD` is already required by the Compose file |
| Other services | Unchanged | Keep the Engine API for services that do not have a stopped dependency group |

### Rules

1. **Compose is the starter.** Do not add a Python list of AFFiNE dependencies beside `depends_on`.
2. **Same project.** A compose invocation whose project name is the helper working directory (`app` or `docker-project`) creates a second stack and then fights `container_name`. Take the project from the running stack's label.
3. **Use the project mount.** Build contexts and `.env` live under `/docker-project`. The compose file mounted at `/app/docker-compose.yml` is the wrong directory for this command.
4. **Stop the group, keep the volumes.** Stopping `affine_redis` and `affine_postgres` is the energy-correct follow-through. Do not `down`, and do not remove volumes. Leave `ai_affine_migration` exited; the next `up -d affine` runs it again only if Compose still needs `service_completed_successfully`.
5. **Auth stays put.** `_authorized` and the Nginx allowlist still gate the route. This page does not widen who may call `/control/`.
6. **Do not special-case every Tier 2 service here.** n8n depends on Postgres, which is Tier 1. This contract is the AFFiNE group, because that group is `restart: "no"` and outside the tier arrays.

### Suggested contributor checklist

```text
1. Read control_service start/stop and start_single_service
2. On affine start, run compose up -d affine in the existing project
3. On affine stop, compose stop affine affine_redis affine_postgres
4. Read com.docker.compose.project from a running Tier 1 container
5. Confirm ai_affine_postgres and ai_affine_redis are running after a dashboard Start
6. Confirm those two are stopped after a dashboard Stop, and the volumes still exist
7. Do not add a dependency YAML or a wait-for-it container
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Start order | Compose `depends_on`, already on `affine` | A helper dictionary of AFFiNE peers |
| CLI parity | `start_single_service` | A second start implementation in JavaScript |
| Project identity | Compose label on the running stack | Hardcoding the helper container's working directory |
| Intake | GitHub Issue with the suggestion template | A local queue of start requests |

## Acceptance criteria

- Dashboard Start on AFFiNE results in running `ai_affine`, `ai_affine_postgres`, and `ai_affine_redis`, and a successful `ai_affine_migration` exit.
- Dashboard Stop stops those three long-running containers and does not delete volumes.
- The Compose project name matches the stack that already created `ai_postgres`.
- `POST /control/ollama/start` still uses the existing Engine API.
- Unauthenticated `/control/affine/start` stays 401.

## Verification notes

Read-only pass on 2026-10-04. Docker was not required: Engine `start` does not apply Compose `depends_on`, and the three peers are `restart: "no"` and absent from both tier arrays. The helper image command already installs the Compose CLI.

## Rollback

Restore the single-container Engine start and stop for `affine`. The CLI `start-service` path is unchanged either way.
