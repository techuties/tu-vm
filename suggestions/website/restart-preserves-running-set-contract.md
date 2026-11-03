---
title: Restart Preserves the Running Set Contract
description: Constructional contract so tu-vm.sh restart brings back the Compose services that were running, using the status snapshot update_system already takes.
last_updated: 2026-11-03
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Restart Preserves the Running Set Contract

## Problem

Help describes one command for a running stack:

```text
restart                  Restart all services
```

`main` calls `restart_services` with no arguments. That function is:

```bash
restart_services() {
    info "Restarting $PROJECT_NAME services..."
    stop_services
    sleep 2
    start_services
}
```

`start_services` with no argument selects a mode from `TU_VM_DEFAULT_MODE`, and the default in code is `portable`:

```bash
default_mode="$(resolve_env_value TU_VM_DEFAULT_MODE portable)"
# ...
case "${1:-}" in
    --server|server|--all) mode="server" ;;
    --portable|portable|--tier1) mode="portable" ;;
    "") ;;
esac
```

Portable mode starts `TIER1_SERVICES` and creates `TIER2_SERVICES` with `up -d --no-start`. Server mode starts the Compose service list (Ollama still follows `should_start_ollama_in_server`). `./tu-vm.sh server` reaches server mode only because `main` passes `--server`. `restart` never passes that word.

Replayed on Bash 5.2.21 by copying the mode `case`, without executing `tu-vm.sh` (that script's `main` creates `.env` through `check_env_file`):

| Call shape | Mode `start_services` selects |
|---|---|
| `restart` → `start_services` with no argument, default `portable` | `portable` |
| `restart` → `start_services` with no argument, `TU_VM_DEFAULT_MODE=server` | `server` |
| `start_services --server` | `server` |

The env default is not the set that is running. An operator who started with `./tu-vm.sh server` and left `TU_VM_DEFAULT_MODE` unset gets a portable stack after `restart`: Tier 2 services that were up stay down. An operator who set `TU_VM_DEFAULT_MODE=server` and last started portable gets the full server set after `restart`, including services that were stopped.

`update_system` already records the live set before it stops anything:

```bash
$compose_cmd ps --services --status running
```

Compose v5.1.0 `ps --help` documents `--services` and `--status`. After the image refresh, `update_system` starts Tier 1, then `up -d` on the previously running names, then `up -d --no-start` on the names that were stopped. `restart_services` does not call that snapshot.

Checked on 2026-11-03 by reading `restart_services`, `start_services`, `update_system`, and `show_help`, and by the mode replay above. `.env` was not created. The Docker daemon was not started. `./tu-vm.sh restart` was not run.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `restart_services` | The command help calls "Restart all services" |
| `stop_services` | What restart already calls. Stage 66 owns `down` versus `stop` inside this function |
| `start_services` | Env, allowlist, DNS, certificates, MinIO buckets, rclone mount, and the three cron installers |
| `update_system` | `ps --services --status running`, then `up -d` for that list, then `up -d --no-start` for the others |
| `TIER1_SERVICES` / `TIER2_SERVICES` | The portable and server sets. They stay the sets for `start`, `portable`, and `server` |
| `TU_VM_DEFAULT_MODE` | The default for a bare `start`. It is the wrong source for `restart` |
| Stage 66 stop page (branch `cursor/community-suggestions-structure-7911`) | `stop_services` itself. Unchanged here |
| Stage 65 stopped-container prune (open PR #91) | Prune removing stopped containers. Unchanged here |

Out of scope:

- A second orchestrator, a restart history file, or a systemd unit
- Changing `stop_services` from `down` to `stop` (Stage 66)
- Changing what bare `start`, `portable`, and `server` launch
- Treating `TU_VM_DEFAULT_MODE=server` as "restart whatever was up"

## Proposal

Snapshot the Compose services, call the existing stop, then bring back that snapshot with the same two `up` forms `update_system` already uses. Keep the prep `start_services` already runs by calling those functions, not by pasting their bodies.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Snapshot | `restart_services` | Before `stop_services`, record running names with `ps --services --status running` and the complement as the stopped names, matching `update_system` |
| Stop | `restart_services` | Keep the `stop_services` call |
| Prep | `restart_services` | Call `check_env_file`, `ensure_nginx_allowlist_file`, `ensure_host_ip_configured`, `ensure_tailscale_ip_configured`, `sync_pihole_dns_records`, and `generate_ssl_certificates` |
| Restore | `restart_services` | `up -d` the running names, then `up -d --no-start` the stopped names |
| After start | `restart_services` | Call `setup_minio_buckets`, `mount_minio_storage`, `ensure_sync_cron_job`, `ensure_daily_checkup_cron_job`, and `ensure_weekly_update_cron_job` when Tier 1 is ready, as `start_services` already does |
| Empty snapshot | `restart_services` | When both lists are empty, call `start_services` with no mode so the existing default still applies |
| Help | `show_help` | Say that `restart` returns the services that were running and leaves the others stopped |

### Rules

1. **The running set is the restart target.** A server-mode stack comes back as that service list. A portable stack comes back as Tier 1.
2. **Stopped services stay stopped and present.** The `--no-start` loop from `update_system` is what keeps a later dashboard Start from seeing a missing container after `down`.
3. **`stop_services` stays as it is.** Stage 66 is the only change to `down` versus `stop`. Both forms are safe for a later `up -d` of the saved names: `down` recreates them, `stop` starts them.
4. **Bare `start` still reads `TU_VM_DEFAULT_MODE`.** Only `restart` stops using that value as a stand-in for the live set.
5. **An empty project still has a start.** No running and no stopped names means `start_services` with no argument.
6. **Skip empty `up` lists.** With `set -u`, pass a list only when it has at least one name.

### Suggested contributor checklist

```text
1. Replay the mode case: restart with no argument and default portable selects portable today
2. After the change, a saved running list of n8n plus Tier 1 is the list passed to up -d
3. A saved stopped name is passed to up -d --no-start
4. Confirm stop_services still contains the same compose subcommand it had before this change
5. Confirm bare start with no TU_VM_DEFAULT_MODE still selects portable
6. Confirm .env was not created to prove this page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Which services were up | `docker compose ps --services --status running` in `update_system` | A mode flag stored in `.env` on every start |
| Which services stay down | The stopped-name `--no-start` loop in `update_system` | `start_services --server` whenever any Tier 2 name was up |
| Certificates, DNS, cron, buckets | The functions `start_services` already calls | A copy of those function bodies |
| Intake | GitHub Issue | A restart daemon |

### Acceptance check

- [ ] `restart_services` records running and stopped service names before it calls `stop_services`.
- [ ] The running names are started with `up -d`.
- [ ] The stopped names are created or refreshed with `up -d --no-start`.
- [ ] `stop_services` is unchanged.
- [ ] Bare `start` still defaults to portable when `TU_VM_DEFAULT_MODE` is unset.
- [ ] Help describes restart as restoring the services that were running.
- [ ] `./tu-vm.sh restart` was not executed to prove this, so `.env` was not created.

### Rollback

Restore `restart_services` to `stop_services`, `sleep 2`, and `start_services`. Bare `start` is unchanged either way. `restart` again follows `TU_VM_DEFAULT_MODE`.
