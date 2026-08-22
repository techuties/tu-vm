---
title: MinIO Object Versioning and ILM Contract
description: Constructional contract for optional MinIO bucket versioning and lifecycle expiration using existing mc helpers, without replacing bucket naming or inventing a second object store.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: operations
impact: high
---

# MinIO Object Versioning and ILM Contract

## Problem

`setup_minio_buckets()` in `tu-vm.sh` creates `tika-pipe`, `n8n-workflows`, and `shared-documents` (plus related prefixes) with `mc mb --ignore-existing`. There is no versioning and no lifecycle rule. Accidental overwrites in the document pipeline are permanent. Community PRs that notice this often propose Nextcloud, SeaweedFS, or a second MinIO for "backups."

Stage 15 covers **bucket names, retention naming, and corpus hygiene**. Stage 18 covers **volume tar backup**. This page is only **object versioning and ILM** inside the existing `ai_minio`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `minio` | Single `minio/minio` server on `minio_data` |
| `tu-vm.sh` `setup_minio_buckets` / `run_minio_mc` | Official `minio/mc` against localhost:9000 |
| `tika_minio_processor` | Watches `tika-pipe` and `n8n-workflows` |
| Stage 15 `minio-bucket-lifecycle-contract.md` (expected sibling) | Naming and which buckets exist |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Tika + MinIO pipeline behavior |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Volume tar, not object ILM |

Out of scope:

- Replacing MinIO or adding a second object store
- Changing bucket names or who may create buckets
- Publishing port 9000 beyond the existing localhost bind
- Turning ILM into a substitute for `tu-vm.sh backup`

## Proposal

Extend `setup_minio_buckets()` with official `mc version` and `mc ilm` so operators can keep a short overwrite history on pipeline buckets and expire stale versions. Defaults stay off so disk does not grow on first start.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| CLI | `tu-vm.sh` `setup_minio_buckets` | `mc version enable` / `mc ilm rule add` |
| Env | `env.example` | `MINIO_VERSIONING=false`, `MINIO_ILM_DAYS` |
| Docs | playbook or this contract | Restore a previous object version with `mc` |
| Backup | existing volume tar | Versioned objects ride along in `minio_data` |

### Rules

1. **Reuse `run_minio_mc`.** Do not add a Python MinIO admin client or a new container for lifecycle.
2. **Opt-in, bucket-scoped.** Versioning on `tika-pipe` is a different decision than `shared-documents`. Do not enable all buckets by default.
3. **ILM expires versions, not the live object, unless named.** A first rule should target noncurrent versions (`--noncurrent-expire-days`) so the processor's current object remains.
4. **Versioning is not backup.** Offsite and host tar remain Stage 18 / Stage 9 rclone. ILM must not delete the only copy of a bucket.
5. **Processor compatibility.** `tika_minio_processor` must keep reading the latest object. If a watch loop lists versions, that is a bug.
6. **Disk pressure stays Stage 10.** If `minio_data` is tight, do not raise ILM retention; point operators at volume ops.
7. **GitHub remains intake.** Requests for a second object store stay Issues.

### Suggested contributor checklist

```text
1. Read setup_minio_buckets and run_minio_mc in tu-vm.sh
2. Add opt-in env flags defaulting to disabled
3. After mb --ignore-existing, call mc version and mc ilm only when enabled
4. Target noncurrent versions first; do not expire current objects by default
5. Document mc cp --version-id restore for one bucket
6. Confirm tika_minio_processor still sees the latest object
7. Leave bucket names and localhost port binds unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Object admin | Official `minio/mc` already wrapped | A new admin API or MinIO SDK service |
| History | Bucket versioning | A second MinIO / Nextcloud |
| Expiry | `mc ilm` noncurrent rules | Cron `mc rm` scripts as the policy |
| Disaster recovery | Existing `tu-vm.sh backup` | Treating ILM as the backup system |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: opt-in flags + `mc version` / `mc ilm` in `setup_minio_buckets`.
3. Add a playbook note for restoring one overwritten object.

## Acceptance criteria

- [ ] Default start does not enable versioning.
- [ ] When enabled, `tika-pipe` can recover an overwritten object by version id.
- [ ] ILM default, if any, expires noncurrent versions only.
- [ ] Bucket names and `run_minio_mc` remain the admin path.
- [ ] No second object store is added.

## Rollback

Disable the env flags and re-run setup (or `mc version suspend` / `mc ilm rule rm`). Existing current objects remain. Old versions stay until ILM or a manual delete.

## Success metrics

- Operators recover a mistaken overwrite without restoring the whole `minio_data` volume.
- Disk growth from versions is bounded by a documented ILM day count.
- Pipeline watchers keep processing the latest object only.
