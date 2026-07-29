---
title: Backup Restore Community Drill
description: Constructional day-to-day reliability drill that reuses tu-vm.sh backup, restore, and update-rollback commands so community operators prove recovery instead of assuming it.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Backup / Restore Community Drill

## Problem

`tu-vm.sh` already exposes `backup`, `restore`, `update-rollback`, and pre-update snapshots. Historical suggestions and operator folklore still treat backups as “a command that exists” rather than a **practiced recovery path**. Community day-to-day reliability needs a lightweight drill framework—scheduled, documented, and evidence-based—without inventing a new disaster-recovery product.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh backup [name]` | Create named backup artifacts under `backups/` |
| `./tu-vm.sh restore <file>` | Restore from backup archive |
| `./tu-vm.sh update-rollback` | Compose snapshot rollback after failed updates |
| `scripts/safe-update.sh` / weekly update flows | Update path that should snapshot first |
| `scripts/daily-checkup.sh` | Existing operational ritual to hook lightly |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator-facing recipes |
| Stage 2 operator profiles / Stage 5 playbook matrix (expected siblings) | Resource and version context |
| Stage 5 community health digest (expected sibling) | Can summarize drill completion counts (no host PII) |

Out of scope:

- Cloud DR replication SaaS as a default requirement
- Guaranteeing zero-downtime restores on every hardware class
- Backing up operator secrets into git or public Issues
- Replacing `tu-vm.sh` backup internals with a parallel backup CLI

## Proposal

Publish a **community drill playbook** that operators and contributors run on a cadence, then record evidence in GitHub (Discussion or Issue) using a short template—not a custom portal.

### Drill cadence

| Cadence | Audience | Depth |
|---|---|---|
| Monthly (recommended) | Self-hosters | Backup create + listing verification |
| Quarterly | Maintainers / volunteers | Backup → restore on a **non-prod** copy or lab VM |
| After major Compose changes | Contributors | Documented dry-run of rollback notes in the PR |

### Monthly drill (v1 steps)

1. `./tu-vm.sh doctor` (environment sanity).
2. `./tu-vm.sh backup drill-$(date +%Y%m%d)`.
3. Confirm artifact exists under `backups/` and note size class (small/medium/large)—do **not** upload the archive to GitHub.
4. `./tu-vm.sh check-config` (or `doctor` again) to ensure the control plane still responds.
5. File a GitHub Discussion comment or Issue checklist with: date, TU-VM version/tag, backup name, pass/fail, time taken, hardware class id if known.

### Quarterly restore drill (lab only)

1. Provision or snapshot a lab host (not the only production node).
2. Restore the drill backup per `./tu-vm.sh restore …`.
3. Run `./scripts/smoke-test.sh --live` when nginx tier is up.
4. Record pass/fail + rollback time; link to playbook version matrix row.

### Evidence template (paste into GitHub)

```markdown
### Backup/restore drill

- Date:
- TU-VM version / commit:
- Hardware class (optional):
- Backup command result: pass / fail
- Restore exercised: yes (lab) / no (backup-only month)
- Smoke after restore: pass / fail / n/a
- Notes (no secrets):
```

### Website / playbooks placement

- Community → Reliability → this page
- Add a short anchor in `docs/playbooks/README.md` pointing here (when implementing)
- Optional: Stage 5 health digest counts “drill reports labeled `drill-backup` this month”

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Backup engine | Existing `tu-vm.sh backup/restore` | New Borg/Restic wrapper as a prerequisite |
| Evidence | GitHub Issue/Discussion template | Uploading backup tarballs to the repo |
| Scheduling | Calendar + optional n8n reminder workflow | Always-on agent that mutates production |
| Secrets | Stay on host / operator vault | Paste `.env` into drill reports |

## Rollout

1. Land this page under `suggestions/website/`.
2. Add playbook anchor + optional Issue form checkbox later (“Drill report”).
3. Seed one maintainer quarterly lab restore and link it from `implemented-showcase` when done.
4. Optionally catalog an n8n **reminder** workflow (Stage 6 n8n catalog) that only notifies—never restores autonomously.

## Acceptance criteria

- [ ] Drill steps call existing `tu-vm.sh` commands only.
- [ ] Evidence template forbids secret/upload of backup archives.
- [ ] Monthly vs quarterly depth is explicit.
- [ ] Playbook or CONTRIBUTING links to this page when implemented.

## Rollback

Stop scheduling drills; keep backup commands. Remove digest hooks if noisy.

## Success metrics

- At least one drill evidence thread per release cycle.
- Restore-time notes inform hardware matrix / playbook version updates.
- Fewer “update left me broken with no rollback practice” Issues.
