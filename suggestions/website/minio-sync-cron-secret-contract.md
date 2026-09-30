---
title: MinIO Sync Cron Secret Contract
description: Constructional contract so Tier 1 start does not write the MinIO root password into crontab or the start log.
last_updated: 2026-09-30
owner: maintainers
status: proposed
theme: security
impact: high
---

# MinIO Sync Cron Secret Contract

## Problem

`start_services` installs the Open WebUI sync cron after Tier 1 becomes ready:

```bash
# inside start_services, after setup_minio_buckets and mount_minio_storage
ensure_sync_cron_job
```

`ensure_sync_cron_job` resolves the live password and writes it into the crontab:

```bash
cron_line="*/2 * * * * MINIO_SYNC_PASSWORD=$resolved_pass $SCRIPT_DIR/scripts/sync-openwebui-minio.sh >> /var/log/sync-openwebui-minio.log 2>&1"
# ...
info "Cron job installed/updated: $cron_line"
```

When resolution fails, the fallback line is installed instead:

```bash
cron_line="*/2 * * * * MINIO_SYNC_PASSWORD=\${MINIO_ROOT_PASSWORD:-minio123456} $SCRIPT_DIR/scripts/sync-openwebui-minio.sh >> /var/log/sync-openwebui-minio.log 2>&1"
```

Checked on 2026-09-30 in `tu-vm.sh`:

| Call site | What lands on disk |
|---|---|
| `start_services` after a healthy Tier 1 | A crontab entry whose environment assignment is the current MinIO root password, plus the same string in the start log |
| Password could not be resolved | A crontab entry whose default is the insecure MinIO password. Cron does not load `.env`, so that default is what the job receives |
| `./tu-vm.sh install-cron` | The same helper, which is the documented installer |

`scripts/sync-openwebui-minio.sh` already loads `MINIO_ROOT_PASSWORD` from `.env` when `MINIO_SYNC_PASSWORD` is empty. The crontab assignment is not required for the job to authenticate. It copies the secret into a file operators back up, and `info` copies it into the start transcript.

The two-minute schedule and the host-network client are separate. The client transport is the sibling page on this branch. This page is only **who installs the job** and **whether the secret is in the line**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/sync-openwebui-minio.sh` | Reads `.env` itself |
| `ensure_sync_cron_job` / `install_cron_jobs` | Idempotent line replace for this script |
| `./tu-vm.sh install-cron` | Operator command that should remain the installer |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling, open PR #37) | Idempotent install, disable path, and “do not commit real passwords” |
| Stage 14 `openwebui-minio-sync-day2-contract.md` (expected sibling, open PR #40) | Sync playbook. It already says cron is opt-in and high-frequency sync is not a default |
| Sibling `minio-mc-client-transport-contract.md` | How the job reaches MinIO once it runs |

Out of scope:

- Daily checkup and weekly update cron lines (they do not embed the MinIO password)
- Changing `*/2` to another cadence in the same change
- A new scheduler
- Rewriting Stage 11’s install and disable playbook

## Proposal

Stop installing the sync cron from `start_services`. Keep `install-cron` as the only installer. The installed line is the script path and the log redirect. It does not assign `MINIO_SYNC_PASSWORD`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Start | `start_services` | Delete the `ensure_sync_cron_job` call |
| Installer | `ensure_sync_cron_job` | Line is `$SCRIPT_DIR/scripts/sync-openwebui-minio.sh` plus the existing log redirect |
| Log | `info` in that helper | Print that the sync cron was installed. Do not print the line when building a line that could contain a secret; after this change the line has no secret, and the log still must not echo `.env` |
| Fallback | same helper | Delete the `minio123456` default inside the cron line |
| Docs | playbook note only if a guide shows a sample crontab | Sample line has no password |

### Rules

1. **`start_services` does not install cron.** Operators who want the job run `./tu-vm.sh install-cron`, which Stage 11 already documents.
2. **The script reads `.env`.** Do not pass `MINIO_SYNC_PASSWORD` from crontab. An operator who exports it in the shell for a manual run can still do that; the installed line does not.
3. **No insecure default in the line.** If `.env` has no password, the script already exits with its existing error. Cron must not substitute the template password.
4. **Idempotent replace stays.** `sed` still deletes older lines that mention `sync-openwebui-minio.sh`, including lines from previous versions that embedded a password, and installs one new line.
5. **Do not log secrets.** The info line names the script. It does not print `MINIO_ROOT_PASSWORD` or a previous crontab entry that still contains one. When replacing an old line, do not echo the deleted text.
6. **Leave the other two jobs.** `ensure_daily_checkup_cron_job` and `ensure_weekly_update_cron_job` stay on `install-cron`. This page does not move them into `start_services` and does not remove them from it if they are already called there; only the sync helper is in scope. Checked call order: start currently calls all three. Remove only `ensure_sync_cron_job` from start. Leave the checkup and weekly calls as they are so this change does not reopen Stage 11.
7. **Cadence stays `*/2` until a separate issue.** Stage 14 already warns against high-frequency sync. Changing the schedule is not required to stop publishing the password.

### Suggested contributor checklist

```text
1. Remove ensure_sync_cron_job from start_services
2. Build the cron line without MINIO_SYNC_PASSWORD
3. Delete the minio123456 fallback line
4. info text does not include the password or the old crontab text
5. ./tu-vm.sh install-cron once; crontab -l shows the script path and no password
6. Run start again; crontab still has one sync line and the password is absent
7. A manual ./scripts/sync-openwebui-minio.sh still reads .env
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Install | Existing `install-cron` | Installing the sync job from `start_services` |
| Secret | `.env` mode `600`, already read by the script | A copy in crontab and in the start log |
| Replace old lines | Existing `sed` delete of `sync-openwebui-minio.sh` | Leaving a previous password line beside the new one |
| Schedule policy | Stage 11 and Stage 14 | A new cron daemon |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Change `tu-vm.sh` so start no longer calls the helper, and so the helper’s line has no password.
3. Operators who already ran start should run `install-cron` once after the change. The helper’s delete step removes the old password line. Until they do, the old line remains; the PR description should say that.

## Acceptance criteria

- [ ] `start_services` does not call `ensure_sync_cron_job`.
- [ ] `./tu-vm.sh install-cron` still installs one sync line.
- [ ] That line does not contain `MINIO_SYNC_PASSWORD` or the insecure default password.
- [ ] The helper does not print a resolved password or a previous cron line.
- [ ] Re-running `install-cron` does not duplicate the line.
- [ ] Daily checkup and weekly update lines are unchanged.
- [ ] The sync script still loads `.env` when the variable is unset.

## Rollback

Put the `ensure_sync_cron_job` call back in `start_services` and restore the previous line format. Then run `install-cron` or start once. The password is written into crontab again.

## Success metrics

- `crontab -l` after start does not contain the MinIO root password.
- Start logs do not contain it either.
- One `install-cron` run replaces any older password line.
