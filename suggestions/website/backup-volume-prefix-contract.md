---
title: Backup Volume Prefix Contract
description: Constructional contract so create_backup archives Compose volumes by the suffix match verify_data_retention already uses.
last_updated: 2026-09-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Backup Volume Prefix Contract

## Problem

`create_backup` looks up a fixed list of volume names:

```text
docker_postgres_data docker_redis_data docker_qdrant_data
docker_n8n_data docker_pihole_data docker_minio_data
docker_openwebui_files docker_nginx_logs docker_pihole_dnsmasq
```

The comment above the loop says the project prefix is usually `docker_`. Compose does not set a top-level `name:` today, so the prefix is the directory name. A clone at `/opt/tu-vm` creates `tu-vm_postgres_data`. This checkout’s directory is `workspace`, which creates `workspace_postgres_data`. Stage 30 (open PR #56) proposes `name: tu-vm`, which creates `tu-vm_*` from any directory. None of those names start with `docker_` unless the project name is `docker`.

`docker volume inspect` on a missing name fails, and the loop has no `warn`. The backup directory still receives `.env`, nginx, and a `pg_dump` when Postgres is up. The volume tarballs are simply absent. Restore copies config files and the SQL dump. It never had the MinIO, Qdrant, Open WebUI upload, or Pi-hole tarballs to put back.

`verify_data_retention` already solves the prefix:

```bash
volume_names="$(docker volume ls --format '{{.Name}}' 2>/dev/null || true)"
has_volume() {
    local suffix="$1"
    if printf "%s\n" "$volume_names" | grep -Eq "(^|_)${suffix}$"; then
        return 0
    fi
    return 1
}
```

That function is nested inside `verify_data_retention`, so `create_backup` cannot call it. The rule is the part to reuse: a volume matches when its name is the suffix or ends with `_<suffix>`.

The same split shows up outside the backup loop:

| Caller | Name it uses | When the project is `tu-vm` |
|---|---|---|
| `create_backup` | `docker_openwebui_files` | Inspect fails, uploads are not archived |
| `scripts/sync-openwebui-minio.sh` fallback | `tu-vm_openwebui_files` | Correct only for project `tu-vm`. The script first inspects `ai_openwebui` mounts, and that path is the one to keep |
| `scripts/seed-chat-context.sh` | `docker_openwebui_files` | `docker run -v` fails or creates an empty unused volume |
| `scripts/rollout-gates.sh` default | `/var/lib/docker/volumes/tu-vm_mcp_gateway_data/_data/...` | Correct only for that prefix and the default Docker data root. `PROOF_PATH` already overrides it |

Checked on 2026-09-30 by applying the two naming rules to the nine backup suffixes. The `docker_` list intersects a `tu-vm_` list in zero names. The suffix expression matches all nine.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `verify_data_retention` | Suffix match against `docker volume ls` |
| `create_backup` / `restore_backup` | Tar of config plus optional `database.sql`. Volume tarballs are the gap |
| `get_compose_network_name` | Same idea for networks: inspect the live object, do not hardcode `docker_` |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling, open PR #44) | Archive format, rotation, secret-safe logs |
| Stage 19 `affine-backup-volume-coverage-contract.md` (expected sibling, open PR #45) | Add AFFiNE volume suffixes. It already defers the prefix to a follow-up |
| Stage 24 `backup-archive-encryption-contract.md` (expected sibling, open PR #50) | Optional encryption of the finished tar. Do not wrap a tar that is missing data |
| Stage 30 `compose-project-name-contract.md` (expected sibling, open PR #56) | Top-level `name: tu-vm`. This page must keep working after that lands |
| Sync script mount inspect | Live volume name from `ai_openwebui` when the container exists |

Out of scope:

- Adding the AFFiNE suffixes (Stage 19)
- Encrypting the archive (Stage 24)
- Setting Compose `name:` (Stage 30)
- A second backup tool
- Renaming existing volumes
- Ollama model layers (the backup comment already excludes them)

## Proposal

Lift the suffix match to script scope, or copy that one expression into `create_backup`. Archive each logical volume whose live name matches. Pass the matched name to `docker run -v`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Matcher | `tu-vm.sh` | One `volume_by_suffix` helper used by retention and backup |
| Backup loop | `create_backup` | Suffixes `postgres_data`, `redis_data`, `qdrant_data`, `n8n_data`, `pihole_data`, `minio_data`, `openwebui_files`, `nginx_logs`, `pihole_dnsmasq` |
| Tarball name | backup directory | Use the suffix (`postgres_data.tar.gz`), not the project-prefixed name, so restore does not care which directory created the backup |
| Restore | `restore_backup` | For each suffix tarball, resolve the current volume name and extract into it. Create the volume with Compose before extract if it is missing |
| Seed script | `scripts/seed-chat-context.sh` | Resolve `openwebui_files` the same way, or inspect `ai_openwebui` the way the sync script does |
| Sync fallback | `scripts/sync-openwebui-minio.sh` | Keep the container mount inspect. Replace the `tu-vm_openwebui_files` fallback with the suffix match. If nothing matches, exit with the existing “nothing to sync” message |
| Proof default | `scripts/rollout-gates.sh` | Default `PROOF_PATH` via the suffix `mcp_gateway_data` when that volume exists; keep the argument override |

### Rules

1. **Match the suffix `verify_data_retention` already uses.** `name` or `*_name` for suffix `name`. Do not anchor on `docker_` or `tu-vm_`.
2. **Warn when a suffix is missing.** Silent `inspect` failure is why operators think the backup worked. One warning line per missing suffix is enough. Do not print file names from inside the volume.
3. **Tarball basename is the suffix.** `openwebui_files.tar.gz` restores onto `workspace_openwebui_files` or `tu-vm_openwebui_files` without a rename table.
4. **Do not migrate old tarballs in code.** If a backup directory already contains `docker_postgres_data.tar.gz`, restore may read that name as a fallback for the same suffix. Do not rewrite historical archives.
5. **AFFiNE names stay on Stage 19.** When that list is added, it uses this helper. This PR does not add `affine_storage` by itself.
6. **More than one match is an error for that suffix.** Two volumes both ending in `_postgres_data` means two projects. Warn and skip that suffix rather than archiving the wrong one.
7. **Secrets stay out of the log.** `.env` is still copied as a file. Do not `tar -tv` it in the info output. Stage 18 owns listing hygiene.

### Suggested contributor checklist

```text
1. Add volume_by_suffix with the verify_data_retention expression
2. create_backup loops suffixes and writes <suffix>.tar.gz
3. A tu-vm_ or workspace_ volume is archived; a docker_ name is not required
4. Missing suffix prints one warning and continues
5. restore extracts <suffix>.tar.gz into the current matching volume
6. seed-chat-context and the sync fallback use the same suffix for openwebui_files
7. Two matching volumes for one suffix warn and skip
8. Do not add AFFiNE suffixes or archive encryption in this change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Find a volume | Suffix match already in `verify_data_retention` | Hardcoded `docker_*` or `tu-vm_*` |
| Find a network | `get_compose_network_name` | A parallel volume-only naming scheme |
| Project id | Stage 30 `name: tu-vm` when that PR merges | Encoding the directory into every script |
| AFFiNE data | Stage 19 suffix list on this helper | A separate AFFiNE backup command |
| Archive crypto | Stage 24 wrap after the tar exists | Encrypting an archive that skipped the data volumes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Change `create_backup` and `restore_backup` together so a new archive can be restored.
3. On a host whose volumes use a non-`docker_` prefix, run backup and confirm `<suffix>.tar.gz` files exist for each present volume. Docs-only publication needs no runtime rollback.

## Acceptance criteria

- [ ] `create_backup` does not require the `docker_` prefix.
- [ ] The matcher is the same expression `verify_data_retention` uses, shared or copied once.
- [ ] New tarballs are named by suffix.
- [ ] A missing suffix produces a warning.
- [ ] Two matches for one suffix skip that suffix with a warning.
- [ ] `restore_backup` extracts suffix tarballs into the current project’s volumes.
- [ ] `scripts/seed-chat-context.sh` and the sync script fallback do not hardcode `docker_openwebui_files` or `tu-vm_openwebui_files`.
- [ ] AFFiNE coverage, archive encryption, and Compose `name:` are unchanged.

## Rollback

Restore the `docker_` list. New suffix-named tarballs remain on disk and are ignored by the old restore path. Data volumes are not renamed.

## Success metrics

- A backup taken in a `tu-vm` or `workspace` directory contains the data volume tarballs.
- Retention checks and backups agree on which volumes exist.
- Stage 30’s `name: tu-vm` does not empty the backup.
