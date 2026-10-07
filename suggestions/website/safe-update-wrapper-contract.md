---
title: Safe-Update Wrapper Contract
description: Constructional contract so scripts/safe-update.sh delegates to tu-vm.sh and the community keeps one image-pin table.
last_updated: 2026-10-07
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Safe-Update Wrapper Contract

## Problem

Operators have two update implementations, and the docs name only one of them.

`README.md` lists `scripts/safe-update.sh` as a compatibility wrapper and says to use `./tu-vm.sh update`. The playbook at `docs/playbooks/README.md` tells operators to run `./tu-vm.sh update-check` and `./tu-vm.sh update`. `scripts/weekly-stack-update.sh` calls `"$TU_VM" update`.

`scripts/safe-update.sh` does not mention `tu-vm.sh`. It is a second updater:

- Its own `PINNED_IMAGE_SOURCES` map
- Its own `docker compose` pull, rewrite, and restart
- Its own `pg_dump -U ai_admin ai_platform` with no `PGPASSWORD`

Checked on 2026-10-07 by comparing the two tables in the tree:

| Service | `OFFICIAL_UPDATE_IMAGE_PAIRS` in `tu-vm.sh` | `PINNED_IMAGE_SOURCES` in `safe-update.sh` |
|---|---|---|
| `n8n_mcp` | `ghcr.io/czlonkowski/n8n-mcp:latest` | absent |
| The other 15 pinned services | present | present, same source tags |

A cron line or a contributor patch that still calls `scripts/safe-update.sh --apply` refreshes every pinned image except the n8n-mcp sidecar, and it does so with a dump path that `./tu-vm.sh update` does not use. Weekly cron and the playbook take the other path. The two can rewrite `docker-compose.yml` digests differently.

Stage 15 (open PR #41) told contributors to extend `safe-update.sh` and described the weekly script as a wrapper around that file. The weekly script on `dev` now calls `tu-vm.sh`. This page records that drift. Extend the pairs array that `tu-vm.sh` already owns. Keep `safe-update.sh` only so old flags keep working.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` `update_system`, `update_check`, `update_rollback` | The implementation weekly cron and the playbook already call |
| `OFFICIAL_UPDATE_IMAGE_PAIRS` | Source tag for each pinned service, including `n8n_mcp` |
| `scripts/weekly-stack-update.sh` | Root cron wrapper around `./tu-vm.sh update` |
| `docs/playbooks/README.md` anchor `playbook-safe-update` | Operator steps. They already name `tu-vm.sh` |
| `README.md` tree comment on `safe-update.sh` | The wrapper claim the script does not implement |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling, open PR #41) | Contribution rules from when that script was the body of the updater |
| Stage 44 image-update compare (expected sibling, open PR #70) | How the daily checkup should compare digests. It does not choose which updater runs |

Out of scope:

- A third updater, Watchtower, or Diun
- Changing which source tag a service tracks
- The daily checkup's digest compare
- Rewriting `OFFICIAL_UPDATE_IMAGE_PAIRS` into another format

## Proposal

`scripts/safe-update.sh` becomes the wrapper `README.md` already describes.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Flags | `safe-update.sh` | `--check` execs `./tu-vm.sh update-check`. `--apply` execs `./tu-vm.sh update`. `--rollback` execs `./tu-vm.sh update-rollback` |
| Pin table | `safe-update.sh` | Delete `PINNED_IMAGE_SOURCES`. Do not copy the array |
| Database dump | `safe-update.sh` | Delete the local `pg_dump` and the later `psql` checks. `./tu-vm.sh update` already calls `create_backup` |
| Docs | `README.md` tree comment | Keep the wrapper sentence. It becomes true |
| New images | `tu-vm.sh` | Add a row to `OFFICIAL_UPDATE_IMAGE_PAIRS` only |

### Rules

1. **One implementation.** Digest refresh, backup, and restart stay in `tu-vm.sh`.
2. **Old flags still work.** A crontab that calls `safe-update.sh --apply` reaches `./tu-vm.sh update`.
3. **One pin table.** `n8n_mcp` is refreshed because it is already in `OFFICIAL_UPDATE_IMAGE_PAIRS`, not because the wrapper grows a sixteenth entry.
4. **Do not shell out to both.** The wrapper must not pull images and then also call `tu-vm.sh`.

### Suggested contributor checklist

```text
1. scripts/safe-update.sh --check runs tu-vm.sh update-check and exits with that status
2. The script no longer contains PINNED_IMAGE_SOURCES or pg_dump
3. rg n8n_mcp tu-vm.sh shows the pair; rg n8n_mcp scripts/safe-update.sh shows nothing
4. scripts/weekly-stack-update.sh still calls tu-vm.sh update
5. docs/playbooks/README.md playbook-safe-update still names tu-vm.sh
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Refresh pins | `update_system` | A second compose rewrite loop |
| Cron | `scripts/weekly-stack-update.sh` | A new systemd unit |
| Rollback | `update_rollback` | A private copy of the compose file logic |
