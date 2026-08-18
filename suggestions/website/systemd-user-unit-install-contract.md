---
title: systemd User-Unit Install Contract
description: Constructional contract for an optional systemd --user unit that starts Tier 1 via existing Compose/tu-vm.sh helpers instead of a second supervisor, host cron duplicate, or always-on wrapper daemon.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# systemd User-Unit Install Contract

## Problem

Operators reboot laptops and expect Tier 1 to come back. Today they re-run `./tu-vm.sh start` (or rely on Compose `restart:` policies for containers that already exist). Community PRs that want “start on login” tend to install **system** units as root, wrap the entire 4k-line `tu-vm.sh` as `Type=simple` (it exits after `compose up`), or add a second supervisor (supervisord, pm2).

Stage 11 already covers **host cron** for checkup/update. This page is the **login/boot unit** for the core stack, using systemd because it is already on the target distros.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh start` | One-shot: secrets, SSL, allowlist, `compose up -d` Tier 1 |
| Compose `restart:` | `unless-stopped` vs `"no"` per service |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install/remove — not a boot unit |
| Stage 14 `cli-subcommand-contribution-contract.md` (expected sibling) | How to add `tu-vm.sh` subcommands |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling) | Scheduled health, not start-on-boot |
| Stage 17 `weekly-stack-update-contribution-contract.md` (expected sibling) | Scheduled update |
| Stage 18 `beginner-quickstart-contribution-contract.md` (expected sibling) | Portable-default onboarding |

Out of scope:

- A root `systemd` service that bypasses the operator user and Docker socket permissions
- `Type=simple` on `tu-vm.sh start` (the script is not a long-running daemon)
- Replacing Compose restart policies with systemd `Restart=always` on every container
- Kubernetes / Quadlet as a merge prerequisite
- Windows Task Scheduler (see the WSL2 contract)

## Proposal

Ship an **optional user unit** that calls existing commands.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Unit template | e.g. `packaging/systemd/tu-vm-core.service` | `Type=oneshot`, `RemainAfterExit=yes` |
| Install helper | `./tu-vm.sh install-user-unit` (optional) | Copies unit, `systemctl --user enable --now` |
| Stop | `ExecStop=` | `docker compose stop` of Tier 1 only, or `tu-vm.sh stop` if that exists |
| Linger | `loginctl enable-linger` | Documented; default off so headless users opt in |
| Uninstall | matching subcommand | Disable + remove unit; do not delete Compose volumes |

### Rules

1. **User, not system.** `systemctl --user`. Do not require root beyond Docker group as the project already does.
2. **Oneshot.** `Type=oneshot` + `RemainAfterExit=yes`. `ExecStart` must be a command that **exits 0 after Tier 1 is up**.
3. **Do not daemonize `tu-vm.sh`.** If start is too heavy for a unit (SSL generation, interactive prompts), ExecStart should call a non-interactive path (`docker compose up -d` with the documented Tier 1 list, after `.env` exists).
4. **Idempotent.** Re-running the unit must not regenerate secrets or overwrite TLS.
5. **No second cron.** Checkup and weekly update stay Stage 11/16/17 timers or cron. Do not fold them into this unit.
6. **WSL note.** WSL2 systemd is a sibling contract; the unit file can be the same, but enablement differs.
7. **GitHub remains intake.** Requests for a GUI “service manager” app stay Issues.

### Suggested contributor checklist

```text
1. Read tu-vm.sh start and Compose restart policies
2. Write a Type=oneshot RemainAfterExit=yes user unit
3. ExecStart must exit; do not use Type=simple on tu-vm.sh
4. Document loginctl enable-linger as optional
5. Provide enable and disable instructions (or subcommands)
6. Do not install a system-wide unit as root by default
7. Keep cron checkup/update on their existing contracts
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Boot start | systemd --user | supervisord / pm2 / a custom daemon |
| Stack lifecycle | Existing `tu-vm.sh` + Compose | Re-implementing health in the unit |
| Scheduled work | Stage 11 cron / systemd timers later | Stuffing checkup into ExecStart |
| Uninstall | `systemctl --user disable --now` | Leaving orphan root units |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: a checked-in unit template plus `tu-vm.sh` enable/disable helpers that are non-interactive.
3. Optional: `systemd-analyze --user verify` in contributor docs.

## Acceptance criteria

- [ ] User-level oneshot unit is the prescribed shape.
- [ ] `tu-vm.sh start` is not treated as a long-running daemon.
- [ ] Linger is opt-in and documented.
- [ ] Cron/update contracts remain separate.
- [ ] Uninstall does not destroy volumes.

## Rollback

`systemctl --user disable --now tu-vm-core.service` and remove the unit file. Compose and data volumes stay. Operators return to manual `./tu-vm.sh start`.

## Success metrics

- Reboot/login recovery uses the unit instead of a custom supervisor.
- No root system unit ships by default.
- Checkup cron is not duplicated inside the unit.
