---
title: Backup Archive Encryption Contract
description: Constructional contract for optional encryption of local tu-vm.sh backup tarballs so README claims match the archive format, without replacing tar with restic or rclone.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: security
impact: high
---

# Backup Archive Encryption Contract

## Problem

`README.md` "Data Protection" claims backups use **compressed and encrypted storage**. `create_backup` writes a plaintext `backups/*.tar.gz` that includes `.env`, TLS material, nginx state, and database dumps.

Anyone with host filesystem access — or a copied backup directory — has every secret. The docs promise encryption that the script does not implement.

Stage 18 covers **archive format, rotation, and secret-safe listing**. Stage 9 covers **optional rclone offsite**. Stage 21 covers an **optional restic/borg backend**. Stage 22 covers **Postgres WAL/PITR**. This page is only **how the existing tar.gz is wrapped at rest**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` `create_backup` / `restore_backup` | tar + gzip; keep-latest rotation; excludes Ollama models |
| `README.md` Data Protection | Claims encryption that is not implemented |
| `backups/` | Gitignored local directory |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Drill cadence, not crypto |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Format and rotation |
| Stage 9 `offsite-backup-rclone-contract.md` (expected sibling) | Remote transport of the archive |
| Stage 21 `restic-borg-backup-backend-contract.md` (expected sibling) | Optional **backend swap**, not a wrapper |

Out of scope:

- Replacing `tar` with restic/borg as the default (Stage 21)
- Offsite upload (Stage 9)
- Encrypting Docker volumes in place
- Changing rotation from "keep latest" in the same PR

## Proposal

Keep gzip tar as the default clone path (fast, inspectable on a trusted laptop). Add **opt-in** archive wrapping with `age` (preferred) or `openssl enc` using a key from `.env`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | `*.tar.gz` | Today's behavior |
| Opt-in wrap | `*.tar.gz.age` or `*.tar.gz.enc` | `BACKUP_ARCHIVE_KEY` / `BACKUP_ARCHIVE_RECIPIENT` |
| Restore | same functions | Detect suffix; decrypt then existing extract |
| Docs | README + `env.example` | Align the "encrypted storage" sentence with reality |

### Rules

1. **Default stays plaintext gzip** until an operator sets a key. Do not surprise existing restore muscle memory.
2. **Wrap the archive; do not reimplement backup.** Encryption happens after `tar czf`, decryption before `tar xzf`.
3. **Prefer `age`.** It is purpose-built, script-friendly, and avoids `openssl enc` footguns. Bundle `age` via distro package or a documented dependency; do not vendor a Go crypto product.
4. **Key is not in the archive.** `.env` is inside the tarball today; the wrap key must live outside the payload (operator secret, or a recipient pubkey whose private key is off-box).
5. **README must match code.** If encryption stays optional, the feature list must say "optional encryption" until the flag is on.
6. **Rotation unchanged.** Encrypted and plaintext names participate in the same keep-latest rule.
7. **GitHub remains intake.** Requests to make restic the default stay Stage 21 Issues.

### Suggested contributor checklist

```text
1. Read create_backup / restore_backup and the README encryption claim
2. Add optional BACKUP_ARCHIVE_KEY (or age recipient) defaulting to unset
3. After tar czf, wrap when the key is set; delete the plaintext tar
4. Teach restore to detect .age / .enc and unwrap first
5. Never write the wrap key into the tarball
6. Fix README wording so "encrypted" is accurate
7. Leave rclone and restic backends to their own contracts
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| File encryption | `age` (or documented `openssl enc`) | Homegrown XOR, zip passwords, committed keys |
| Backup contents | existing `create_backup` loop | A second backup script |
| Remote copies | Stage 9 rclone of the **wrapped** file | Encrypting only in transit |
| Dedup / PITR | Stage 21 restic / Stage 22 WAL | Using those to "fix" the README claim |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: opt-in wrap + restore detect + README honesty (even before wrap lands, fix the claim).
3. Keep rotation and excluded volumes as they are.

## Acceptance criteria

- [ ] README no longer claims encryption unless a wrap is actually configured.
- [ ] Unset key keeps `*.tar.gz` restore compatible.
- [ ] Set key produces a wrapped artifact and restore unwraps it.
- [ ] The wrap key is not stored inside the archive.
- [ ] rclone/restic defaults are not changed.

## Rollback

Unset the key and restore from a retained plaintext tar if one exists. Code rollback is removing the wrap/unwrap branches.

## Success metrics

- Docs and `create_backup` tell the same story.
- A copied `backups/` directory is not automatically a full secret leak when the operator opted in.
- Contributors extend the existing functions instead of adding `backup-encrypted.sh`.
