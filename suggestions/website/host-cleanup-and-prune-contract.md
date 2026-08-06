---
title: Host Cleanup and Prune Contract
description: Constructional contract for day-to-day cleanup of backups, logs, and Docker disk waste using tu-vm.sh cleanup and safe prune lanes instead of unattended destructive docker system prune.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Host Cleanup and Prune Contract

## Problem

Disk fills up from old backups, container logs, and dangling images. Historical suggestions jump to `docker system prune -a --volumes` in cron or invent storage SaaS. Stage 10/11 already cover disk pressure and log retention; this page contracts **day-to-day cleanup** via `tu-vm.sh cleanup` and safe prune hygiene for the community.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh cleanup` | Clean up old backups and logs |
| `./tu-vm.sh backup` / `restore` | Data safety before aggressive cleanup |
| Stage 11 `container-log-retention-contract.md` (expected sibling) | Log max-size / retention policy |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | LVM extend and volume pressure |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Prove restore before deleting backups |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Image pin/update—not blind deletes |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Disk-full triage entry |
| Docker CLI prune features | Optional manual lanes with warnings |

Out of scope:

- Unattended `docker system prune -a --volumes` as a default cron
- Deleting named volumes that hold Postgres/MinIO/Qdrant data without explicit restore proof
- Replacing local cleanup with a mandatory cloud tiering product
- Conflating cleanup with Stage 9 offsite rclone backups (complementary)

## Proposal

Publish a **host cleanup and prune contract** with explicit safety lanes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Cleanup command | `tu-vm.sh cleanup` | What it deletes; retention knobs; dry-run if present/proposed |
| Backup retention | `backups/` policies in docs | Minimum keep-count; restore drill link |
| Image prune | Documented optional Docker prune | Never includes volumes by default |
| Log retention | Stage 11 contract | Compose logging options |
| Playbooks | `#playbook-host-cleanup` (proposed) | Measure → backup → cleanup → optional prune |
| Disk pressure | Stage 10 contract | Extend/move when cleanup is not enough |

### Rules

1. **Measure first.** Point operators at `df`, doctor/diagnose disk signals, or README disk guidance before deleting.
2. **Prefer `cleanup` over raw prune.** Extend `tu-vm.sh cleanup` for backup/log hygiene rather than teaching destructive Docker folklore first.
3. **Volumes are sacred.** Community docs must not recommend `--volumes` prune without an explicit typed confirmation story and restore plan.
4. **Keep restore evidencable.** Do not delete “all backups” in one shot; keep a minimum retention aligned with Stage 6 drills.
5. **Images ≠ data.** Dangling image prune is safer than volume prune; still document that pins/updates (Stage 8) are the normal path.
6. **Cron stays opt-in and mild.** If cleanup is scheduled (Stage 11 cron), it must not run destructive volume wipes.
7. **GitHub remains intake.** Proposals for cold-storage SaaS remain optional overlays evaluated via Issues.

### Suggested playbook shape

```text
#playbook-host-cleanup
1. df -h && ./tu-vm.sh doctor
2. ./tu-vm.sh backup                  # if about to delete backup generations
3. ./tu-vm.sh cleanup                 # backups/logs per command semantics
4. Optional: docker image prune       # dangling images only; no --volumes
5. If still tight: follow Stage 10 disk-pressure playbook (extend/move)
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Routine hygiene | `tu-vm.sh cleanup` | Unattended prune -a --volumes |
| Log growth | Stage 11 retention | Unlimited json-file logs |
| Capacity | Stage 10 volume ops | Silent deletion of databases |
| Offsite copies | Stage 9 rclone contract | Assuming cloud tiering exists |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-host-cleanup` when implementing docs polish.
3. Cross-link Stage 10 disk-pressure, Stage 11 log retention, and Stage 6 backup drill.
4. Prefer **code** dry-run / retention flags on `cleanup` over new suggestion prose.

## Acceptance criteria

- [ ] Measure-first and volumes-sacred rules are explicit.
- [ ] `cleanup` is preferred over raw Docker prune folklore.
- [ ] Backup retention / restore-drill linkage is present.
- [ ] Playbook orders backup before destructive cleanup.
- [ ] No default cron runs `prune --volumes`.

## Rollback

Revert cleanup script experiments; operators retain manual file deletion and Docker prune at their own risk. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer disk-full emergencies caused by unbounded logs/backups.
- Fewer Issues reporting accidental volume wipes after following docs.
- Increased use of `tu-vm.sh cleanup` citations in operator reports.
