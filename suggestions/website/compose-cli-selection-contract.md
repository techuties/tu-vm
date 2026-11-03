---
title: Compose CLI Selection Contract
description: Constructional contract so tu-vm.sh selects Docker Compose with the plugin-first order doctor, check-config, and smoke-test already use.
last_updated: 2026-11-03
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Compose CLI Selection Contract

## Problem

Day-to-day commands in `tu-vm.sh` ask `get_docker_compose_cmd` for the Compose CLI:

```bash
get_docker_compose_cmd() {
    if command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}
```

Any executable named `docker-compose` on `PATH` wins, including a leftover Compose V1 binary. The plugin is never asked.

Three maintained scripts already use the opposite order. `scripts/doctor.sh`, `scripts/check-config.sh`, and `scripts/smoke-test.sh` each define `compose_cmd` as:

```bash
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
fi
```

`scripts/safe-update.sh` and `scripts/switch-pdf-loader.sh` call `docker compose` directly.

Replayed on 2026-11-03 with both functions copied into the shell. This host has Docker Compose plugin v5.1.0 and no `docker-compose` on the default `PATH`. A temporary stub named `docker-compose` printed `legacy-compose-stub` and exited 0. The stub directory was removed afterward. The Docker daemon was not started.

| PATH | `get_docker_compose_cmd` (tu-vm.sh) | `compose_cmd` (doctor, check-config, smoke-test) |
|---|---|---|
| Default, Compose v5.1.0, no `docker-compose` binary | `docker compose` | `docker compose` |
| Stub `docker-compose` placed first | The stub path | `docker compose` |

On the default PATH the two orders agree, so a quickstart on this host hides the split. On a host that still has a `docker-compose` binary, `./tu-vm.sh doctor` and `./scripts/check-config.sh` render the project with the plugin, and `./tu-vm.sh start` renders it with the other binary. The same `docker-compose.yml` then has two interpreters: one for the contributor check and one for the operator command.

Checked by reading `get_docker_compose_cmd` and the three `compose_cmd` functions, and by the replay above. `.env` was not created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `get_docker_compose_cmd` | The selector every `tu-vm.sh` Compose call uses |
| `compose_cmd` in `scripts/doctor.sh` | Plugin first, `docker-compose` only as fallback |
| `compose_cmd` in `scripts/check-config.sh` | The same order, used by CI and pre-push |
| `compose_cmd` in `scripts/smoke-test.sh` | The same order |
| `scripts/safe-update.sh` | Already invokes `docker compose` |
| Compose plugin v5.1.0 | The CLI this environment actually runs |
| Stage 64 and Stage 55 pages (open PRs #90 and #81) | What `ps` and rollback do with whatever CLI was selected. Unchanged here |

Out of scope:

- Vendoring a Compose binary or pinning a Compose release in this repo
- Rewriting `doctor.sh`, `check-config.sh`, or `smoke-test.sh` (they already agree)
- Replacing `tu-vm.sh` with raw `docker compose` for operators
- Editing Compose service definitions

## Proposal

Make `get_docker_compose_cmd` use the plugin-first test the three scripts already use. Keep `docker-compose` as the fallback for a host whose only CLI is that name.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Selection | `get_docker_compose_cmd` | If `docker compose version` succeeds, print `docker compose`. Else if `command -v docker-compose` succeeds, print `docker-compose` |
| Call sites | `$compose_cmd up`, `ps`, `build`, and the rest | Leave them. They already expand the string this function prints |
| Doctor and CI | `compose_cmd` in the three scripts | Leave the order as it is |
| Failure | Neither CLI works | Keep a clear error. `check_docker_compose` already rejects a host with neither `docker-compose` nor `docker compose version` |

### Rules

1. **The plugin wins when it runs.** `docker compose version` succeeding means every `tu-vm.sh` Compose command uses `docker compose`.
2. **A lone `docker-compose` still works.** Hosts without the plugin keep the fallback the doctor script already has.
3. **Doctor and start agree.** With both binaries present, `./tu-vm.sh doctor` and `./tu-vm.sh start` use the same CLI.
4. **Call sites stay word-split expansions of one string.** `docker compose` remains two words, as it is today when the plugin is selected.
5. **The three scripts stay the source of the order.** Copy that condition. Leave their functions in place.

### Suggested contributor checklist

```text
1. On a PATH with only the Compose plugin, print docker compose
2. On a PATH with a docker-compose stub ahead of the plugin, still print docker compose
3. On a PATH whose docker compose version fails and docker-compose exists, print docker-compose
4. Confirm doctor.sh, check-config.sh, and smoke-test.sh compose_cmd functions are unchanged
5. Confirm .env was not created to prove this page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Compose CLI | Plugin-first test already in `doctor.sh` | A new wrapper script |
| Fallback | `docker-compose` when the plugin is absent | Deleting the fallback |
| Version proof | `docker compose version`, already used by the three scripts | Parsing `docker --help` |
| Intake | GitHub Issue | A Compose installer in `tu-vm.sh` |

### Acceptance check

- [ ] `get_docker_compose_cmd` tries `docker compose version` before `command -v docker-compose`.
- [ ] When the plugin answers, the function prints `docker compose`.
- [ ] When the plugin is missing and `docker-compose` exists, the function prints `docker-compose`.
- [ ] `compose_cmd` in `doctor.sh`, `check-config.sh`, and `smoke-test.sh` is unchanged.
- [ ] A `docker-compose` stub earlier on `PATH` does not override a working plugin.
- [ ] The Docker daemon was not started to prove this, and `.env` was not created.

### Rollback

Restore the `command -v docker-compose` test as the first branch. Hosts with only the plugin behave the same. Hosts with both binaries return to starting the stack with `docker-compose` while doctor uses the plugin.
