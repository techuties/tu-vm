---
title: AFFiNE Backup Volume Coverage Contract
description: Constructional contract for including AFFiNE named volumes in tu-vm.sh backup/restore so collaboration data is not silently omitted from the existing archive format.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: operations
impact: high
---

# AFFiNE Backup Volume Coverage Contract

## Problem

`create_backup()` in `tu-vm.sh` archives a fixed list of Compose volumes:

```text
docker_postgres_data docker_redis_data docker_qdrant_data
docker_n8n_data docker_pihole_data docker_minio_data
docker_openwebui_files docker_nginx_logs docker_pihole_dnsmasq
```

AFFiNE declares three named volumes that are **not** in that loop: `affine_storage`, `affine_config`, and `affine_postgres_data`. There is also no `pg_dump` of `affine_postgres`. Operators who run `./tu-vm.sh backup` after using AFFiNE can restore Tier 1 data and still lose workspaces, blobs, and the AFFiNE database.

Stage 9 covers AFFiNE collaboration recipes. Stage 18 covers backup **format and rotation**. This page is the **coverage gap** for AFFiNE volumes only.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup()` volume loop | Hard-coded `docker_*` names |
| Compose volumes `affine_storage` / `affine_config` / `affine_postgres_data` | AFFiNE blobs, config, SQL data |
| `affine_postgres` service | Separate Postgres from `ai_platform` |
| Stage 9 `affine-collaboration-contribution-contract.md` (expected sibling) | Product recipes, not backup |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Postgres hygiene for the primary DB |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Archive format, keep-N, secret-safe logs |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | AFFiNE IPs `.22`–`.25` |

Out of scope:

- A second AFFiNE-specific backup product (restic, built-in AFFiNE export as a prerequisite)
- Including Ollama model layers
- Uploading AFFiNE archives off-site (Stage 9 rclone)
- Changing default rotation (`TU_VM_BACKUP_KEEP`) except to note size impact

## Proposal

Extend the **existing** backup loop and restore path so AFFiNE volumes are first-class when those volumes exist.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Volume tarballs | `create_backup()` loop | `affine_storage`, `affine_config`, `affine_postgres_data` with compose-project prefix |
| Logical DB | Optional `pg_dump` via `affine_postgres` | Only when that container is running |
| Restore | `restore_backup()` | Same names; skip if volume absent |
| Size note | Backup log line | AFFiNE blobs can dwarf the current archive |
| Prefix | Stage 18 follow-up | Honor compose project name, not only `docker_` |

### Rules

1. **Reuse `create_backup()`.** Do not add `./tu-vm.sh backup-affine`.
2. **Inspect before archive.** `docker volume inspect` already skips missing volumes—keep that so hosts that never started AFFiNE stay fast.
3. **Do not dump AFFiNE into `database.sql`.** That file is `ai_platform`. Use a distinct `affine-database.sql` (or volume-only) so restore cannot apply the wrong dump to `postgres`.
4. **Secrets.** AFFiNE archives may contain workspace content and `AFFINE_DB_PASSWORD` via `.env` copy. Do not print archive listings of those files.
5. **State size.** Document that enabling AFFiNE coverage can make `backups/` large; rotation still applies.
6. **Restore order.** Restore `affine_postgres_data` (or dump) before starting `affine`; keep `affine_migration` semantics unchanged.
7. **GitHub remains intake.** Requests for AFFiNE’s cloud backup stay Issues.

### Suggested contributor checklist

```text
1. List compose volumes: affine_storage affine_config affine_postgres_data
2. Add them to the backup loop with the same project-prefix rule as other volumes
3. If adding pg_dump, write affine-database.sql (not database.sql)
4. Skip quietly when AFFiNE was never started
5. Restore test: empty host or volume-remove + restore + affine up
6. Do not log .env or workspace file names
7. Note archive size in the backup info line
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local restore | Existing `backup` / `restore` | AFFiNE-only scripts |
| Offsite | Stage 9 rclone of *this* archive | A second remote |
| Collaboration features | Stage 9 AFFiNE contract | Backup as a feature showcase |
| Disk pressure | Stage 10 volume ops | Unlimited keep-all AFFiNE snapshots |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add the three volume names to the loop and a distinct dump filename if logical backup is included.
3. Mention AFFiNE coverage in `./tu-vm.sh help` backup notes.

## Acceptance criteria

- [ ] AFFiNE volumes are in the backup loop when present.
- [ ] Missing AFFiNE volumes do not fail backup.
- [ ] Primary `database.sql` remains `ai_platform` only.
- [ ] Restore path documents AFFiNE start order.
- [ ] No second backup command is introduced.

## Rollback

Remove the extra volume names from the loop. Existing archives without AFFiNE tarballs remain valid.

## Success metrics

- Operators who use AFFiNE can restore workspaces from `./tu-vm.sh restore`.
- Hosts that never started AFFiNE see no backup failure or large empty work.
- Community backup PRs extend the loop instead of adding a product.
