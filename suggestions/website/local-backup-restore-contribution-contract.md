---
title: Local Backup/Restore Contribution Contract
description: Constructional contract for community changes to tu-vm.sh backup and restore—reuse the existing archive format and rotation instead of a second backup product.
last_updated: 2026-08-13
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Local Backup/Restore Contribution Contract

## Problem

`./tu-vm.sh backup` and `restore` are the local reliability path: copy config (including `.env`), selected Docker volumes, Postgres dump, Pi-hole/Open WebUI/n8n snippets, then `tar czf` under `backups/`. Rotation currently **keeps only the latest** archive. Ollama model volumes are excluded on purpose. Several volumes (AFFiNE, MCP memory, Qdrant in some layouts, compose project prefix) are easy to miss.

Stage 6 describes a **community drill cadence**. Stage 9 describes **optional rclone offsite**. Contributors still need a **format and hygiene contract** so PRs do not invent restic/borg as a prerequisite, print `.env` into logs, or silently disable rotation.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup()` / `restore_backup()` in `tu-vm.sh` | Local archive create/restore |
| `BACKUP_DIR=backups` | On-disk location (gitignored) |
| Volume loop (`docker_postgres_data`, …) | Named volume tarballs |
| `pg_dump` via `postgres` service | Logical DB backup |
| Pre-update backup name `pre_update_*` | Update safety net |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Recurring restore proof, not format |
| Stage 9 `offsite-backup-rclone-contract.md` (expected sibling) | Remote copy of *this* archive |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Secrets in `.env` copied into archives |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Disk pressure vs large archives |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling) | Update snapshots vs operator backups |

Out of scope:

- Replacing local tar with restic/borg/kopia as a merge prerequisite
- Uploading archives to public object storage from CI
- Including Ollama model layers in the default archive
- Logging backup file contents (they contain `.env`)

## Proposal

Publish a **local backup/restore contribution contract** for PRs that change what is archived, how it is rotated, or how restore applies it.

### What the archive is for

| Include by default | Exclude by default | Opt-in / follow-up |
|---|---|---|
| `.env`, `nginx/`, `ssl/`, `helper/`, `pihole/`, processor tree | `docker_ollama_data` (re-pull models) | AFFiNE / MCP memory / extra volumes with size notes |
| Listed compose volumes when present | Unrelated host paths | Configurable keep-N rotation (today: keep 1) |
| `database.sql` when Postgres is ready | Printing dump or `.env` to stdout | Encryption-at-rest for `backups/*.tar.gz` |

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Volume set | `create_backup` loop | Use `docker volume inspect`; respect compose project prefix |
| Rotation | keep-latest logic | Changing keep-count is an operator-visible, documented flag |
| Restore | `restore_backup` | Inverse of archive; does not start extra Tier 2 by surprise |
| Secrets | logs + CI | Never `cat` `.env` or dump SQL in traces |
| Offsite | Stage 9 rclone | Copy the tar; do not re-implement dump |
| Drill | Stage 6 | Restore into a disposable path or documented dry-run |

### Rules

1. **One local format.** Extend `create_backup` / `restore_backup`; do not add a parallel `scripts/backup2.sh` as the supported path.
2. **Archives contain secrets.** Treat `backups/` as credential material: gitignore, no CI upload, no verbose file listings of `.env`.
3. **Keep-latest is intentional.** PRs that keep unbounded tarballs must add an explicit retention setting and disk-pressure notes.
4. **Do not default-include Ollama models.** Call that out in operator docs when people expect “full disk clone.”
5. **Volume names must honor compose project prefix**, not only the `docker_*` hard-code, if the PR touches the loop.
6. **Rclone wraps this archive.** Offsite is not a second dump implementation.
7. **GitHub remains intake.** Requests for enterprise backup appliances stay Issues unless accepted.

### Suggested contributor checklist

```text
1. Extend create_backup/restore_backup rather than a new backup tool
2. Confirm backups/ stays gitignored and is not uploaded by CI
3. If adding volumes, document size impact and restore order
4. If changing rotation, document keep-count and disk use
5. Never print .env or SQL dumps in command output
6. Coordinate offsite copies with the rclone contract
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local snapshot | `tu-vm.sh backup` | Second backup CLI |
| Restore proof | Stage 6 drill | Untested “we tar’d something” |
| Offsite | Stage 9 rclone | Ad-hoc `curl` to random hosts |
| Secrets | Stage 8 rotation + archive hygiene | Committing `backups/*.tar.gz` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: compose-project-aware volume names; optional `TU_VM_BACKUP_KEEP` with default 1.
3. Add a playbook anchor such as `#playbook-backup-restore` only when the recipe is real.

## Acceptance criteria

- [ ] Single local backup entrypoint rule is stated.
- [ ] Archives are treated as secret-bearing.
- [ ] Keep-latest default is preserved unless an explicit retention setting is added.
- [ ] Ollama models remain excluded by default.
- [ ] Offsite copies reuse this archive rather than a second dump.

## Rollback

Revert `tu-vm.sh`/docs independently. Prior backup set and rotation return. Docs-only publication needs no runtime rollback.

## Success metrics

- Restore drills succeed from a documented tar.
- No CI or issue templates request upload of `backups/*.tar.gz`.
- Volume coverage grows without filling laptop disks by surprise.
