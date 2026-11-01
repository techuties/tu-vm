---
title: Weekly Apt Prompt Contract
description: Constructional contract so tu-vm.sh update applies OS packages without a dpkg config-file prompt during the weekly cron job.
last_updated: 2026-11-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Weekly Apt Prompt Contract

## Problem

`scripts/weekly-stack-update.sh` is the Sunday cron entry. It takes a lock on `/tmp/tu-vm-weekly-update.lock` and then runs `tu-vm.sh update`. The lock is held until that process exits. A second Sunday logs "Skipped: another weekly update is already running" and exits 0.

Inside `update_system`, the package step is:

```bash
apt-get update
apt-get upgrade -y
apt-get autoremove -y
apt-get autoclean
```

This runs before Pi-hole DNS is switched and before images are pulled. `apt-get` 2.8.3's help points at `apt-get(8)`. That manual says `-y` is "Automatic yes to prompts" for apt itself (`APT::Get::Assume-Yes`). The script never sets `DEBIAN_FRONTEND` and never passes `Dpkg::Options`.

`dpkg` 1.22.6 on this host documents the gap in `dpkg --force-help`:

| Flag | Help text |
|---|---|
| `confnew` | Always use the new config files, don't prompt |
| `confold` | Always use the old config files, don't prompt |
| `confdef` | Use the default option for new config files if one is available, otherwise you will be prompted unless `confold` or `confnew` is also given |

`upgrade -y` selects none of those. A package that ships a changed conffile therefore still has a question. Weekly cron has no operator sitting at a terminal. While that question is open, the flock stays held and later weeks skip.

The apt lines were not executed. No package was upgraded while checking this.

The same `tu-vm.sh update` is what an operator runs by hand from the landing-page update panel. The flags belong on that one command so both the button's instructions and the cron job share one non-interactive package step.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `update_system` apt lines | The only package step to change |
| `scripts/weekly-stack-update.sh` | Already calls `tu-vm.sh update` and already holds the lock |
| `dpkg --force-confdef` and `--force-confold` | The pair dpkg documents as not prompting |
| `scripts/tu-vm-update.sudoers.example` | Root rights for that same update command |
| Stage 53 safe-update wrapper (open PR #79) | `safe-update.sh` should delegate here. It should not grow a third apt invocation |
| Stage 55 DNS restore (open PR #81) | The Pi-hole resolv.conf order. This page does not move that call |
| Stage 55 firewall order (open PR #81) | UFW rules. Unchanged here |

Out of scope:

- Installing `unattended-upgrades` or a second scheduler
- Changing which packages are held
- Moving `handle_pihole_dns_replacement` (Stage 55)
- Image pulls and digest pins
- Answering the prompt by always installing the packager's conffile (`confnew`)

## Proposal

Pass dpkg the two flags that keep the current conffile and do not prompt. Set `DEBIAN_FRONTEND=noninteractive` for that apt sequence only.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Environment | The apt sequence in `update_system` | `DEBIAN_FRONTEND=noninteractive` for those four apt-get commands |
| Conffiles | `upgrade` and `autoremove` | `-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold` |
| Lock | `weekly-stack-update.sh` | Leave the flock. It is correct once apt cannot wait |
| Wrapper | `scripts/safe-update.sh` | Do not add apt there. Stage 53 already points that script at `tu-vm.sh` |

### Rules

1. **Operator-edited configs stay.** `confold` with `confdef` keeps the installed conffile when the package also ships one. Do not pass `confnew`.
2. **One package step.** Cron and the manual `./tu-vm.sh update` both use these flags because both call `update_system`.
3. **The DNS switch stays where Stage 55 put it.** This change only stops apt from blocking before that call.
4. **A failed apt still fails the update.** `-y` plus the dpkg flags is not `--force-yes`. Essential-package and held-package aborts stay apt's job.
5. **Do not add a second updater.** `unattended-upgrades` is a different product. The weekly script already has a job.

### Suggested contributor checklist

```text
1. Confirm upgrade and autoremove pass Dpkg::Options for confdef and confold
2. Confirm DEBIAN_FRONTEND=noninteractive is set on those apt-get commands
3. Confirm confnew is absent
4. Confirm weekly-stack-update.sh still only calls tu-vm.sh update
5. Confirm handle_pihole_dns_replacement call order is unchanged
6. Confirm safe-update.sh did not gain its own apt-get upgrade
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| No conffile question | `Dpkg::Options::=--force-confdef` and `--force-confold` | A new unattended-upgrades install |
| Non-interactive apt | `DEBIAN_FRONTEND=noninteractive` on this sequence | A wrapper script around apt |
| Weekly entry | `scripts/weekly-stack-update.sh` | A second cron line that upgrades packages on its own |
| Intake | GitHub Issue | A dashboard button that runs apt directly |

### Acceptance check

- [ ] `update_system` passes `--force-confdef` and `--force-confold` to `apt-get upgrade` and `apt-get autoremove`.
- [ ] Those commands run with `DEBIAN_FRONTEND=noninteractive`.
- [ ] `--force-confnew` is not added.
- [ ] `weekly-stack-update.sh` still delegates to `tu-vm.sh update` and still uses the existing flock.
- [ ] The Pi-hole DNS replacement calls are unmoved.
- [ ] `apt-get upgrade` was not executed to write this page.

### Rollback

Remove the two `Dpkg::Options` flags and the `DEBIAN_FRONTEND` assignment. Weekly cron returns to today's `apt-get upgrade -y`. No package downgrade is implied.
