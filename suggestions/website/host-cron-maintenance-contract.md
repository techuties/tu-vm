---
title: Host Cron Maintenance Contract
description: Constructional contract for community contributions to day-to-day host cron maintenance that reuses tu-vm.sh install-cron, daily checkup, and weekly update scripts instead of inventing a fleet scheduler.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Host Cron Maintenance Contract

## Problem

Day-to-day reliability depends on a few host cron jobs (MinIO sync, daily checkup, weekly stack update). Historical suggestions propose systemd timers everywhere, Kubernetes CronJobs on a single VM, or unattended updaters without rollback. Contributors need a **reuse-first contract** for changing or documenting these jobs without turning TU-VM into a fleet control plane.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh install-cron` / ensure_* helpers | Idempotent cron installation |
| `scripts/daily-checkup.sh` | Daily health/maintenance checks |
| `scripts/weekly-stack-update.sh` | Scheduled update window |
| `scripts/sync-openwebui-minio.sh` | Frequent knowledge sync |
| `scripts/safe-update.sh` / update flows | Manual and assisted updates |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Pin/check/update/rollback channels |
| Stage 8 `release-canary-community-program.md` (expected sibling) | Human pre-release validation |
| Stage 11 `privileged-host-ops-contract.md` (sibling) | Sudoers / privilege narrowing |
| [`docs/playbooks/README.md`](../../docs/playbooks/README.md) `#playbook-safe-update` | Operator update recipe |

Out of scope:

- Replacing cron with a mandatory external scheduler SaaS
- Unattended major upgrades that skip backup / smoke / rollback
- Embedding production MinIO passwords in committed cron samples
- Managing other hosts’ crontabs from this repository

## Proposal

Publish a **host cron maintenance contract** with clear lanes and safety rules.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Job install helpers | `tu-vm.sh` ensure_* / `install-cron` | Idempotency proof; no secret commits |
| Checkup script | `scripts/daily-checkup.sh` | Exit codes, log path, non-destructive default |
| Weekly update script | `scripts/weekly-stack-update.sh` | Calls existing update channel; rollback path |
| Sync job | `scripts/sync-openwebui-minio.sh` | Credential sourcing from env; log rotation note |
| Docs / playbooks | `#playbook-safe-update` + cron notes | Schedule expectations, how to disable |
| Sudoers pairing | `scripts/tu-vm-update.sudoers.example` | Stage 11 privileged-host-ops checklist |

### Rules

1. **Idempotent install.** Re-running `install-cron` must update lines, not duplicate them.
2. **Secrets from environment.** Cron lines may reference env or resolved runtime values; never commit real passwords.
3. **Update jobs call existing channels.** Weekly automation must use `tu-vm.sh` update flows / Stage 8 policy—not raw `docker pull` loops.
4. **Disable path required.** Docs must show how to remove or comment cron lines safely.
5. **Logs stay local.** Prefer append to `/var/log/...` with retention guidance (Stage 11 log contract); do not ship checkup output to public Issues.
6. **Privilege minimal.** Passwordless sudo only for documented update entrypoints (privileged-host-ops).
7. **GitHub remains intake.** Schedule redesigns are Issues/PRs.

### Suggested playbook shape

```text
#playbook-host-cron
1. ./tu-vm.sh install-cron
2. crontab -l | grep -E 'daily-checkup|weekly-stack-update|sync-openwebui-minio'
3. Review log tails after first tick
4. To disable: remove matching lines and re-run install only when ready
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Scheduling | Host cron via existing helpers | New scheduler microservice |
| Updates | Stage 8 image channel + playbooks | Watchtower rewriting pins |
| Privileges | Narrow sudoers example | `NOPASSWD: ALL` |
| Proof | `doctor` / smoke / checkup exit codes | Screenshots of cron GUIs as sole evidence |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-host-cron` when implementing docs polish.
3. Cross-link Stage 8 update channel and Stage 11 privileged-host-ops / log retention pages.
4. Keep CONTRIBUTING silent on requiring cron for doc-only contributors.

## Acceptance criteria

- [ ] Lanes distinguish checkup vs weekly update vs MinIO sync vs docs.
- [ ] Idempotent install and disable path are documented.
- [ ] Secret-handling rule forbids committed credentials in cron samples.
- [ ] Weekly automation references Stage 8 update/rollback policy.
- [ ] Privilege narrowing points at the sudoers example contract.

## Rollback

Remove cron lines installed by TU-VM helpers; stop using passwordless sudoers drop-ins; continue with manual `./tu-vm.sh update` / checkup. No Compose service removal required.

## Success metrics

- Fewer “add Kubernetes CronJobs / Watchtower” suggestions for single-host installs.
- Cron-related PRs include idempotency and secret-hygiene notes.
- Operators can disable scheduled updates without undocumented surgery.
