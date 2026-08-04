---
title: Privileged Host-Ops Contract
description: Constructional contract for community contributions involving sudoers, disk extend, and other privileged host operations that keep privileges narrow and reusable instead of granting broad root automation.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: security
impact: high
---

# Privileged Host-Ops Contract

## Problem

Some day-to-day TU-VM operations genuinely need host privilege: weekly updates via cron, LVM disk extend, package-assisted maintenance. Historical suggestions casually add `NOPASSWD: ALL`, custom setuid wrappers, or “run the whole stack as root.” The community needs a **privileged host-ops contract** so contributors extend existing narrow helpers instead of inventing broad privilege escalation paths.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/tu-vm-update.sudoers.example` | Narrow passwordless sudo for `tu-vm.sh update` |
| `scripts/extend-disk.sh` / disk helpers | Guided volume growth |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Disk pressure recipes and LVM notes |
| Stage 11 `host-cron-maintenance-contract.md` (sibling) | Cron jobs that may call privileged update |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Network/control-plane security (different lane) |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Credential lifecycle |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |

Out of scope:

- Granting passwordless root for arbitrary repo scripts
- Running Docker itself as an unauthenticated network service
- Embedding operator passwords in sudoers samples or Issues
- Replacing documented helpers with opaque one-liner gist pastes as the supported path

## Proposal

Publish a **privileged host-ops contract** with least-privilege lanes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Sudoers samples | `scripts/*.sudoers.example` | Absolute command paths; `visudo -cf` validation notes |
| Disk growth | `extend-disk` / playbooks | Stage 10 disk contract; irreversible-step warnings |
| Cron + sudo pairing | weekly update path | Host-cron contract + narrow sudoers |
| Docs | README / playbooks | Threat notes; who should install drop-ins |
| CI | N/A for host root | Do not require privileged host ops in PR CI |

### Rules

1. **Narrow commands only.** Sudoers entries must pin executable paths and subcommands (as the update example does)—not `ALL`.
2. **Examples are not auto-installed.** Drop-ins remain operator-copied; docs say how to validate with `visudo -cf`.
3. **Irreversible ops need warnings.** Disk extend / partition changes must say backup-first and failure modes.
4. **No secrets in sudoers.** Passwords, tokens, and private paths with credentials do not belong in samples.
5. **Separate network privilege.** Opening firewall ports or widen allowlists follows Stage 5—not this page.
6. **Contributor CI stays unprivileged.** Cloud/agent CI must not depend on passwordless root host mutation.
7. **GitHub remains intake.** Privilege model changes are Issues with security checklist attention.

### Suggested sudoers review checklist

- [ ] Command path is absolute and points at the operator’s checkout intentionally
- [ ] Arguments are constrained (no wildcards that allow arbitrary script execution)
- [ ] File mode guidance (`440`) and `visudo -cf` validation documented
- [ ] Pairing cron user matches the sudoers user
- [ ] Rollback = remove drop-in and re-login/cron without privilege

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Passwordless update | Existing sudoers example pattern | `NOPASSWD: ALL` |
| Disk growth | Existing extend helpers + Stage 10 | Blind `fdisk` snippets in Issues |
| Scheduled privileged work | Host-cron contract + narrow sudo | Root shells from n8n/LLM tools |
| Security review | SECURITY.md + PR checklist | Undocumented privilege in “chore” PRs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link host-cron and disk-pressure pages.
3. Reference this contract from CONTRIBUTING security checklist when privileged files change.
4. Keep Decision Log for any widening of sudoers scope beyond single-command update.

## Acceptance criteria

- [ ] Lanes cover sudoers samples, disk growth, cron pairing, and docs.
- [ ] Rules forbid broad passwordless root and secret-bearing sudoers.
- [ ] Validation via `visudo -cf` is documented for samples.
- [ ] CI is explicitly unprivileged regarding host root mutation.
- [ ] Network/control-plane privilege changes are redirected to Stage 5.

## Rollback

Remove sudoers drop-ins; stop privileged cron lines; return to interactive `sudo ./tu-vm.sh update`. Disk extend rollback is storage-specific—follow Stage 10 warnings and backups taken before growth.

## Success metrics

- Fewer PRs proposing broad sudoers “for convenience.”
- Privileged-file PRs include the narrow-command checklist.
- Disk and cron privileged paths stay tied to existing helpers.
