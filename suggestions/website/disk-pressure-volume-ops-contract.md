---
title: Disk Pressure and Volume Ops Contract
description: Constructional day-to-day contract for host disk pressure, LVM extend, and Docker volume cleanup that reuses scripts/extend-disk.sh and backup drills instead of destructive auto-cleaners.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Disk Pressure and Volume Ops Contract

## Problem

Home-lab VMs fill disks. Historical suggestions propose aggressive auto-prune daemons, silent volume wipes, or opaque “storage optimizers.” TU-VM already ships `scripts/extend-disk.sh`, Docker volumes, backups, and doctor-style checks—the missing piece is a **community website contract** for safe growth and cleanup that protect operator data.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/extend-disk.sh` | LVM logical volume growth on Ubuntu VMs |
| Docker named volumes in `docker-compose.yml` | Persistent service data |
| `./tu-vm.sh backup` / restore | Durability before cleanup |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Prove restore works |
| Stage 10 `data-plane-hygiene-contract.md` (sibling) | DB/vector retention context |
| Stage 7 `local-resource-history.md` (expected sibling) | Capacity trends (host-level) |
| Stage 9 `privacy-preserving-usage-analytics.md` (expected sibling) | Idle service tips (not disk wipes) |
| `./tu-vm.sh doctor` | Surface obvious host problems |

Out of scope:

- Default unattended `docker system prune -a --volumes`
- Auto-deleting MinIO buckets or Open WebUI data to reclaim space
- Requiring thin-provisioning SaaS
- Running extend-disk on non-LVM hosts without detection/docs

## Proposal

Define a **pressure → grow → tidy → rebuild** ladder for operators and contributors.

### Operator ladder

| Step | Action | Gate |
|---|---|---|
| 1. Detect | `df -h`, doctor, optional history | Confirm disk is the real bottleneck |
| 2. Grow | `sudo ./scripts/extend-disk.sh` when LVM/free PV exists | Script messaging; snapshot/backup if possible |
| 3. Tidy safe caches | Documented prune of **dangling** images/build cache only | Explicit commands; never volumes by default |
| 4. Tier 2 stop | Stop idle heavy services (Stage 7 idle policy / profiles) | Frees growth rate, not always bytes |
| 5. Targeted cleanup | Operator-chosen volume after backup | Named volume + restore plan |
| 6. Rebuild host | Last resort | Full backup + Decision Log if defaults change |

### Contribution rules

1. **No silent volume deletion** in cron or startup paths without opt-in env flags and backup warnings.
2. **Extend before delete.** Docs and dashboard tips should prefer growth/tidy guidance over destructive cleanup.
3. **Name volumes in UX.** Any cleanup UI must show volume names and owning services.
4. **Evidence in PRs.** Storage automation PRs include dry-run/`--plan` behavior where feasible.
5. **Hardware class awareness.** Link Stage 2 matrix minimum disk guidance for new services that need large volumes.
6. **Privacy.** Cleanup logs must not dump object keys or chat titles into public Issues.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Grow disk | `extend-disk.sh` | Custom partition editor UI in Nginx |
| Durability | Existing backup/restore | Hope-based prune |
| Idle savings | Profiles + Stage 7 autostop | Deleting databases to save power |
| Insights | doctor + optional history | Always-on storage SaaS agents |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-disk-pressure` with detect → extend → safe tidy steps.
3. Cross-link data-plane hygiene and backup drill pages.
4. If dashboard tips mention disk pressure, gate them behind Stage 9 feature flags.

## Acceptance criteria

- [ ] Ladder prefers detect/grow/safe tidy before volume deletion.
- [ ] Docs forbid default unattended volume prune.
- [ ] `extend-disk.sh` is the documented growth path for supported LVM Ubuntu VMs.
- [ ] Targeted cleanup requires backup/restore plan language.
- [ ] Contributor rules require opt-in flags for destructive automation.

## Rollback

Stop cleanup automation flags; restore from backup for mistaken deletes. LVM extend is generally not reversible without restore—document that clearly in the playbook.

## Success metrics

- Fewer catastrophic “prune deleted my MinIO data” reports.
- Operators discover `extend-disk.sh` from website/playbooks before forum lore.
- Storage-related PRs ship with `--plan`/dry-run notes.
