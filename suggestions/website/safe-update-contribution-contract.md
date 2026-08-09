---
title: Safe-Update Contribution Contract
description: Constructional contract for community contributions that extend scripts/safe-update.sh pin maps, check/apply/rollback flow, and weekly update wrappers—without inventing a second updater.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Safe-Update Contribution Contract

## Problem

Operators need a repeatable path to refresh pinned Compose digests without ad-hoc `docker pull` folklore. Historical suggestions invent parallel “auto-updaters,” watchtower-style daemons, or host package managers that fight `docker-compose.yml` digests. Contributors need a **reuse-first contract** for extending the existing safe-update lane.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/safe-update.sh` | `--check` / `--apply` / `--rollback` for pinned image digests |
| `scripts/weekly-stack-update.sh` | Cron-friendly wrapper around the same path |
| `tu-vm.sh` | Operator verbs that should stay thin wrappers |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Channel / pin / rollback policy language |
| Stage 8 `smart-startup-optimization.md` (expected sibling) | `--plan` style rehearsal patterns |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install/remove hygiene |
| Stage 14 `cli-subcommand-contribution-contract.md` (expected sibling) | Dispatcher-vs-`scripts/` rules |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes that should name the same verbs |

Out of scope:

- Watchtower / unattended host-wide image churn as the default
- Rewriting digests by hand in PRs without `--check` evidence
- Silent cron apply without backup + rollback path
- A second Python/Go updater that bypasses `PINNED_IMAGE_SOURCES`

## Proposal

Publish a **safe-update contribution contract** for community PRs that touch update automation.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Pin map | `PINNED_IMAGE_SOURCES` in `safe-update.sh` | Service key matches Compose service name; source tag documented |
| Check UX | `--check` output | Human-readable before/after digest intent; no secrets |
| Apply path | `--apply` | Backup of `docker-compose.yml`, restart notes, failure → rollback guidance |
| Rollback | `--rollback` | Restores last backup; docs say when it is insufficient |
| Cron wrapper | `weekly-stack-update.sh` / host cron | Opt-in; defaults to check-friendly posture |
| Docs | playbooks / README | Same verb names as `tu-vm.sh help` |

### Rules

1. **One updater.** Prefer extending `safe-update.sh` over a parallel auto-update service.
2. **Digest honesty.** Community image bumps must keep digest pins unless an Issue explicitly accepts floating tags for a Tier 2 sidecar.
3. **Rehearsal first.** New behavior needs `--check` (or `--plan`) before `--apply`.
4. **Backup before mutate.** `--apply` must continue to snapshot `docker-compose.yml` (and document any additional artifacts).
5. **No secret printing.** Update logs must not echo registry credentials or `.env` values.
6. **Tier awareness.** Docs must say which services restart and that Tier 2 may be stopped.
7. **Cron is opt-in.** Weekly wrappers must not enable unattended apply without explicit operator choice.
8. **GitHub remains intake.** “Replace safe-update with product X” stays an Issue; default answer is extend this script.

### Suggested contributor checklist

```text
1. Identify lane: pin map vs check UX vs cron wrapper vs docs
2. bash -n scripts/safe-update.sh scripts/weekly-stack-update.sh
3. ./scripts/safe-update.sh --check   # or tu-vm.sh equivalent
4. Confirm backup path documented for --apply
5. No registry tokens or .env values in sample output
6. Playbook / README verb parity
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Update policy | Stage 8 image-update-channel language | Ad-hoc digest edits in random PRs |
| Implementation | `safe-update.sh` + weekly wrapper | Second updater binary |
| Operator UX | `tu-vm.sh` thin verbs | Hidden cron-only apply |
| Safety | backup + `--rollback` | Unattended latest-tag pulls |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 8 image-update-channel and Stage 11 host-cron pages when those merge.
3. Prefer **code** that keeps pin maps complete and `--check` noise low over more suggestion prose.

## Acceptance criteria

- [ ] Pin-map contribution rules are explicit.
- [ ] `--check` / `--apply` / `--rollback` responsibilities are stated.
- [ ] Cron apply remains opt-in with backup requirements.
- [ ] No parallel updater is required for new services.
- [ ] Secret-free logging is required.

## Rollback

Revert script/docs commits independently; operators keep prior `docker-compose.yml` backups. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer PRs that float tags or invent Watchtower defaults.
- New services added to Compose also appear in the pin map with `--check` coverage.
- Decline in “build a custom updater” suggestions as a prerequisite.
