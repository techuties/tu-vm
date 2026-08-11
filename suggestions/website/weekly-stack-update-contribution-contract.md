---
title: Weekly Stack Update Contribution Contract
description: Constructional contract for community contributions that extend scripts/weekly-stack-update.sh and the narrow sudoers example—without inventing a second updater, RMM agent, or broad passwordless root.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Weekly Stack Update Contribution Contract

## Problem

Operators want a quiet weekly refresh of OS packages and Compose images without babysitting the console. Historical suggestions invent fleet RMM agents, always-on auto-updaters, or broad `NOPASSWD: ALL` sudo. TU-VM already has `scripts/weekly-stack-update.sh` calling `tu-vm.sh update` behind a lock file, plus `scripts/tu-vm-update.sudoers.example`. Contributors need a **reuse-first contract** distinct from daily checkup pulses and digest-pin safe-update.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/weekly-stack-update.sh` | Cron-friendly full-stack update wrapper |
| `scripts/tu-vm-update.sudoers.example` | Narrow passwordless sudo for `tu-vm.sh update` |
| `tu-vm.sh update` | Backup → packages → pull → recreate → health gates |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install/remove hygiene |
| Stage 11 `privileged-host-ops-contract.md` (expected sibling) | Privileged host ops boundaries |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling) | Digest pin check/apply/rollback |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling) | Scheduled health/status pulse (not full update) |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Operator update channels |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes that should name the same verbs |

Out of scope:

- Replacing weekly update with a vendor patch-management SaaS
- Expanding sudoers to entire shells, editors, or unrestricted docker
- Auto-applying digest pin mutations from Stage 15 safe-update inside weekly cron
- Running weekly update when `.env` is missing (script already aborts)

## Proposal

Publish a **weekly stack update contribution contract** for PRs that touch the scheduled full-stack refresh lane.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Wrapper behavior | `weekly-stack-update.sh` | Lock file, logging, abort conditions |
| Privilege model | `tu-vm-update.sudoers.example` | Single-command NOPASSWD; path documented |
| Update body | `tu-vm.sh update` | Prefer extending update, not duplicating pull/recreate |
| Cron wiring | Host cron / Stage 11 | Opt-in; install/remove documented |
| Operator docs | playbooks / README | Same verbs as the script |

### Rules

1. **One weekly full-stack lane.** Prefer extending `weekly-stack-update.sh` over a parallel cron updater.
2. **Call `tu-vm.sh update`.** Do not re-implement backup/pull/recreate in a second script body.
3. **Narrow sudo only.** Sudoers examples must name the exact `tu-vm.sh update` path; never `ALL`.
4. **Lock and log.** Keep flock skip behavior and a local log path; do not spam cloud telemetry.
5. **`.env` required.** Never recreate secrets from `env.example` during unattended update.
6. **Distinct from checkup and safe-update.** Daily checkup reports; weekly update refreshes; safe-update manages digests.
7. **GitHub remains intake.** Requests for fleet RMM products stay Issues; default is local cron + existing update.

### Suggested contributor checklist

```text
1. Reproduce with scripts/weekly-stack-update.sh (or dry-run of documented pieces)
2. Confirm lock-file skip still works under concurrent starts
3. Keep sudoers example single-command and path-specific
4. Do not fold digest --apply into weekly cron by default
5. Update playbook/README verbs if operator-visible behavior changes
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Weekly refresh | `weekly-stack-update.sh` → `tu-vm.sh update` | Second updater product |
| Privilege | Narrow sudoers example | Broad NOPASSWD |
| Health pulse | Stage 16 daily checkup | Treating checkup as the updater |
| Digest pins | Stage 15 safe-update | Silent pin mutation from weekly cron |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Link playbook anchors for weekly update / sudoers when operators need them.
3. Prefer **code** that clarifies abort conditions and log hygiene over more prose.

## Acceptance criteria

- [ ] Weekly update is separated from daily checkup and safe-update apply.
- [ ] Narrow sudoers rule is stated.
- [ ] Lock/log and `.env`-required behaviors are preserved as contribution rules.
- [ ] Cron remains opt-in via Stage 11 patterns.
- [ ] Script body prefers calling `tu-vm.sh update`.

## Rollback

Revert script/docs/sudoers-example commits independently; prior weekly behavior returns. Docs-only publication needs no runtime rollback. Operators who installed custom sudoers must revert those host files manually.

## Success metrics

- Operators have one documented weekly refresh path.
- Sudo examples stay auditable and narrow.
- Fewer duplicate “auto-update agent” suggestions that ignore existing scripts.
