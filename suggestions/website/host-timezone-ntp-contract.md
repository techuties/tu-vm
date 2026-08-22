---
title: Host Timezone and NTP Contract
description: Constructional contract for a single operator timezone and host clock source shared by cron, n8n, and container logs, without adding a time-server container or rewriting scheduled jobs.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Host Timezone and NTP Contract

## Problem

n8n hardcodes `GENERIC_TIMEZONE: Europe/Zurich`. Weekly stack updates use `TU_VM_WEEKLY_UPDATE_TZ` defaulting to the same zone. Other containers inherit the image timezone (usually UTC). Cron lines, Nginx access logs, Postgres timestamps, and dashboard clocks can disagree. Community PRs then add `chrony` as a Compose service or scatter `TZ=Europe/Zurich` on every container.

There is no existing stage that owns host clock policy. Stage 11 covers **which host cron jobs exist**. Stage 17 covers **weekly update content**. This page is only **timezone and NTP**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `n8n` | `GENERIC_TIMEZONE: Europe/Zurich` hardcoded |
| `tu-vm.sh` weekly cron | `TU_VM_WEEKLY_UPDATE_TZ:-Europe/Zurich` |
| Container images | Default UTC unless `TZ` is set |
| Host | systemd-timesyncd or chrony already common on Debian/Ubuntu laptops |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install/remove, not TZ |
| Stage 17 `weekly-stack-update-contribution-contract.md` (expected sibling) | What the weekly job does |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling) | Daily job schedule text |

Out of scope:

- Running NTP or chrony inside Compose
- Changing cron schedules or job bodies
- Locale/language packs
- Assuming every operator is in Europe/Zurich

## Proposal

Introduce one env, `TU_VM_TZ` (or reuse `TZ`), documented in `env.example`. Pass it to services that already expose a timezone setting (`GENERIC_TIMEZONE`, `TZ`). Keep host NTP on the host: document `timedatectl` and do not add a time container.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Env | `env.example` `TU_VM_TZ` | One operator-facing zone |
| Compose | `n8n.GENERIC_TIMEZONE` and optional `TZ` on others | Interpolated, not hardcoded |
| Cron | `tu-vm.sh` weekly/daily installers | Same variable as Compose |
| Host docs | playbook / CONTRIBUTING | `timedatectl status`; no Compose NTP |

### Rules

1. **One name.** `TU_VM_TZ` (or documented alias `TZ`) is the only operator timezone. Do not keep a second `GENERIC_TIMEZONE` default that can drift.
2. **Host clock is the source of truth.** Containers may set `TZ` for log labels. They must not run `ntpd`.
3. **Do not add a time service.** No `chrony`, `ntp`, or `timemaster` container in `docker-compose.yml`.
4. **Cron uses the same variable.** Weekly and daily installers already accept a TZ prefix; point them at `TU_VM_TZ`.
5. **Default may stay Europe/Zurich** for compatibility, but it must be overridable without editing Compose.
6. **NTP documentation is host-level.** Point at `systemd-timesyncd` or the distro chrony package. Do not vendor a time config in this repo unless a playbook snippet is needed.
7. **GitHub remains intake.** Requests for a mesh-wide time appliance stay Issues.

### Suggested contributor checklist

```text
1. Find GENERIC_TIMEZONE and TU_VM_WEEKLY_UPDATE_TZ
2. Add TU_VM_TZ to env.example with the current default
3. Point n8n GENERIC_TIMEZONE at ${TU_VM_TZ:-Europe/Zurich}
4. Point weekly/daily cron TZ= at the same variable
5. Optionally set TZ on nginx/helper if log alignment is needed
6. Document timedatectl; do not add a Compose NTP service
7. Leave cron schedules and job scripts unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Zone name | One env interpolated everywhere | Hardcoded Zurich in Compose |
| Clock sync | Host systemd-timesyncd / chrony | A time container on `ai_network` |
| Schedules | Existing `tu-vm.sh` cron installers | A second scheduler for TZ reasons |
| Logs | Container `TZ` when labels matter | Rewriting the logging driver (Stage 22) |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `TU_VM_TZ` in `env.example`, n8n interpolation, cron installer reuse.
3. Add a short playbook note: set host timezone, then `TU_VM_TZ`, then restart n8n.

## Acceptance criteria

- [ ] n8n timezone is interpolated from a documented env var.
- [ ] Weekly cron uses the same variable.
- [ ] No NTP/chrony container is added.
- [ ] Default remains backward compatible if unset.
- [ ] Host clock sync is documented, not containerized.

## Rollback

Restore the hardcoded `Europe/Zurich` strings. Cron and n8n behave as they do today.

## Success metrics

- An operator in another zone changes one env value.
- Dashboard, n8n executions, and weekly logs agree on local time.
- No PR adds a time-server service to Tier 1.
