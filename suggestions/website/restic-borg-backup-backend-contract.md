---
title: restic / borg Backup Backend Contract
description: Constructional contract for an optional restic or borg backend behind tu-vm.sh backup and restore, without replacing the existing tar-volume format or inventing a new backup CLI.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# restic / borg Backup Backend Contract

## Problem

`tu-vm.sh backup` already creates a dated `backups/backup_*.tar.gz`: config copies, `pg_dump`, and `alpine tar czf` of named volumes. Rotation currently keeps the latest archive. Stage 18 describes that **format**, project-aware volume names, and optional `TU_VM_BACKUP_KEEP`. Stage 9 describes **rclone** as an offsite copy of those archives.

Operators who want incremental, encrypted, deduplicated history still propose replacing `backup` with a standalone restic/borg tutorial, a new command name, or a hosted backup SaaS.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` `create_backup()` / restore | Tar-volume format and rotation |
| `BACKUP_DIR=backups` | Local archive directory |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Drill cadence using existing commands |
| Stage 9 `offsite-backup-rclone-contract.md` (expected sibling) | Copy archives off-box |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Host disk pressure |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Format, rotation, secret-safe tar |
| Stage 19 `affine-backup-volume-coverage-contract.md` (expected sibling) | Which AFFiNE volumes enter the loop |
| Stage 20 `affine-redis-durability-contract.md` (expected sibling) | When AFFiNE Redis joins the loop |

Out of scope:

- Replacing `tu-vm.sh backup` / `restore` with a new CLI name
- Making restic or borg the default for first-time operators
- Hosted backup products
- Changing rclone (Stage 9) except as a transport for repository data

## Proposal

Add an **optional backend switch** that keeps the same operator verbs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | `create_backup()` | Tar.gz remains the portable default |
| Env | e.g. `TU_VM_BACKUP_BACKEND=tar\|restic\|borg` | Opt-in; unset means tar |
| Wrapper | `tu-vm.sh backup` / `restore` | Same subcommands; backend is an implementation detail |
| Repo | Existing `backups/` or documented path | restic/borg repo lives beside or instead of tar files |
| Offsite | Stage 9 rclone | Still copies **artifacts**, not a second scheduler |
| Secrets | `.env` / restic password env | Never commit repository passwords |

### Rules

1. **Tar stays default.** Quickstart and first backup must work with no extra packages.
2. **One command surface.** Do not add `./tu-vm.sh restic-backup`. Use `backup` / `restore` plus env or `--backend`.
3. **Pick one optional engine in the first implementation.** restic (single binary, encryption default) is the suggested first opt-in; borg is an allowed alternative, not a parallel flag in the same PR.
4. **Restore must be backend-aware.** A restic snapshot cannot be fed to the tar extract path without a clear error.
5. **Do not drop volume coverage.** Whatever Stage 18/19/20 added to the volume loop must be offered to the optional backend (include/exclude lists stay shared).
6. **Ollama models stay excluded** unless the operator opts in (current tar behavior).
7. **GitHub remains intake.** Requests for BorgBase / restic REST servers stay Issues; document rclone as the offsite lane.

### Suggested contributor checklist

```text
1. Read create_backup() and the Stage 18 contract
2. Keep tar as the default backend
3. Add TU_VM_BACKUP_BACKEND (or equivalent) without renaming commands
4. Share the same volume list as the tar loop
5. Fail restore loudly if the archive/backend does not match
6. Do not commit repository passwords
7. Leave rclone as copy/transport, not a third backup engine
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Default backup | Existing tar.gz loop | Requiring restic on day one |
| Incremental/encrypted | restic or borg behind `backup` | A new `tu-backup` binary |
| Offsite | Stage 9 rclone | Cron that calls restic directly outside `tu-vm.sh` |
| Rotation | Existing keep policy / `TU_VM_BACKUP_KEEP` | Unlimited local snapshots by default |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** only after Stage 18 volume-name and keep-count follow-ups are stable: add `TU_VM_BACKUP_BACKEND=restic` as opt-in with a documented install of the restic binary.
3. Optional: playbook section “Incremental backups” that starts from `./tu-vm.sh backup` and never introduces a second command name.

## Acceptance criteria

- [ ] Default backup remains tar.gz with no extra packages.
- [ ] Optional restic or borg is selected by env/flag, not a new verb.
- [ ] Restore rejects mixed backends with a clear error.
- [ ] rclone remains the offsite copy lane.
- [ ] Volume include/exclude lists stay shared with the tar loop.

## Rollback

Unset `TU_VM_BACKUP_BACKEND` (or remove the branch). Existing `backups/*.tar.gz` files keep restoring through the current path. Optional repositories can be deleted independently.

## Success metrics

- Operators who want incremental history use `tu-vm.sh backup` instead of a side tutorial.
- First-run backups still succeed without restic/borg installed.
- No second backup CLI name appears in `--help`.
