---
title: Update Rollback Compose Snapshot Contract
description: Constructional contract so tu-vm.sh update writes the compose snapshot update_rollback already reads, and rollback starts the services that were running.
last_updated: 2026-10-15
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Update Rollback Compose Snapshot Contract

## Problem

`./tu-vm.sh update` rewrites pinned image digests inside `docker-compose.yml` and can roll that rewrite back only if some other tool saved a file `update_rollback` recognizes.

`update_system` copies a backup with `create_backup` first. That function copies `.env`, `nginx/`, `ssl/`, `helper/`, `pihole/`, `tika-minio-processor/`, a Postgres dump, and volume tarballs into `backups/<name>.tar.gz`. It does not copy `docker-compose.yml`.

Later, still inside `update_system`, a digest change is written over `docker-compose.yml` with no sibling snapshot:

```bash
text = text[:m.start(2)] + new_ref + text[m.end(2):]
open(path, "w", encoding="utf-8").write(text)
```

`update_rollback` then does:

```bash
latest_compose=$(ls -t "$BACKUP_DIR"/docker-compose_*.yml 2>/dev/null | head -1 || true)
cp "$latest_compose" "$DOCKER_COMPOSE_FILE"
$compose_cmd up -d
```

The only writer of `backups/docker-compose_*.yml` in the tree is `scripts/safe-update.sh` `backup_compose`. Checked on 2026-10-15 with a directory that contained only the tar names `create_backup` produces (`pre_update_20261015_080000.tar.gz` and `backup_20261001_120000.tar.gz`). The glob `docker-compose_*.yml` was empty, which is the branch that prints "No docker-compose backup found".

When a leftover `docker-compose_20260901_010101.yml` was added, `ls -t | head -1` selected that older file. Rollback would copy it over a compose file `./tu-vm.sh update` had just rewritten, even though that yml was not taken at the start of this update.

`docker compose up -d` with no service list starts every service in the file. On 2026-10-15, `docker compose config --services` (with `env.example` loaded) printed 24 names. `TIER1_SERVICES` has 10. The other 14 include `ollama`, `n8n`, `n8n_mcp`, `affine`, `affine_postgres`, `affine_redis`, `affine_migration`, `mcp_gateway`, `langgraph_supervisor`, `browserless`, and the four `mcp-*` tools. `update_system` itself starts Tier 1 and then only the services that were running before the update. Rollback does not.

Stage 53 (open PR #79) says `scripts/safe-update.sh --rollback` should exec `./tu-vm.sh update-rollback`. After that wrapper lands, this function is the only rollback. It still needs a snapshot `./tu-vm.sh update` wrote. Stage 18 (open PR #44) says keep the local tar format and keep-latest rotation. This page does not change that tar.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `update_system` | Rewrites digests in `docker-compose.yml` |
| `create_backup` | Data and config tar taken before the update. It stays the data backup |
| `update_rollback` | The command `show_help` and the playbook already name |
| `scripts/safe-update.sh` `backup_compose` | Today's only writer of `docker-compose_*.yml` |
| `TIER1_SERVICES` | The set `update_system` always brings back |
| Stage 53 `safe-update-wrapper-contract.md` (expected sibling, open PR #79) | Old flags delegate here. It does not write the snapshot |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling, open PR #44) | Tar contents and keep-latest. Leave that archive alone |
| Stage 47 `backup-restore-apply-contract.md` (expected sibling, open PR #73) | How `restore_backup` applies the tar |

Out of scope:

- A second updater or a restic/borg backend
- Changing keep-latest for `backups/*.tar.gz`
- Which upstream tag a service tracks
- Restoring volume tarballs from this command. Operators use `./tu-vm.sh restore` for that

## Proposal

`update_system` writes the compose snapshot `update_rollback` already globs, immediately before the first digest rewrite. Rollback starts Tier 1 and the services recorded with that snapshot.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Snapshot | `update_system`, before the digest loop | `cp docker-compose.yml backups/docker-compose_<UTC timestamp>.yml` |
| Running set | same moment | Write `backups/running-services_<same timestamp>.txt`, one compose service name per line, from the `running_services` array this function already builds |
| Rollback file | `update_rollback` | Keep the `docker-compose_*.yml` glob. Copy that file only. Do not unpack the tar |
| Start set | `update_rollback` | `up -d` the names in the matching `running-services_*.txt` plus any missing `TIER1_SERVICES`. `up -d --no-start` for every other service in `config --services` |
| Missing snapshot | `update_rollback` | Keep the current error. Do not fall through to `up -d` |

### Rules

1. **The snapshot is the compose file from before this update's digest rewrite.** Its mtime is newer than any older `docker-compose_*.yml`, so `ls -t | head -1` selects it.
2. **The tar stays the data backup.** Rollback does not extract it and does not delete it.
3. **Rollback does not create Tier 2 containers that were not running.** A host that was on Tier 1 stays on Tier 1. `affine_migration` does not start unless it was in the running-services file.
4. **One pin table.** Digest refresh still uses `OFFICIAL_UPDATE_IMAGE_PAIRS` inside `tu-vm.sh`.

### Suggested contributor checklist

```text
1. After a dry copy of update_system's snapshot lines, backups/docker-compose_<ts>.yml matches the compose file from before the rewrite
2. update_rollback with only pre_update_*.tar.gz present still reports that no compose snapshot exists
3. update_rollback copies the newest docker-compose_*.yml and does not unpack a tar
4. With a running-services file that lists nginx and postgres, the up command includes Tier 1 and those names, and passes --no-start for ollama and n8n
5. docker compose config --services still lists 24 services; the rollback start set is the recorded subset
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Compose snapshot | The `docker-compose_*.yml` name `update_rollback` already uses | A new extension or a manifest database |
| Who was running | The `running_services` list `update_system` already captures | Starting every service `up -d` would create |
| Data backup | `create_backup` | Packing the compose rollback into a second archive format |
