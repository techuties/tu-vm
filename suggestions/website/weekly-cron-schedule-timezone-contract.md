---
title: Weekly Cron Schedule Clock Contract
description: Constructional contract so the Sunday tu-vm update runs at 03:30 Europe/Zurich on Debian cron, which schedules from the host timezone.
last_updated: 2026-11-04
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Weekly Cron Schedule Clock Contract

## Problem

`ensure_weekly_update_cron_job` says the weekly update is Sunday 03:30 Europe/Zurich. The line it installs is:

```text
30 3 * * 0 TZ=Europe/Zurich <repo>/scripts/weekly-stack-update.sh >> <repo>/logs/weekly-update.log 2>&1
```

Those first five fields are minute 30, hour 3, every day of the month, every month, Sunday. The sixth field is the command, and it begins with `TZ=Europe/Zurich`.

Debian cron 3.0pl1-184ubuntu2, from the `crontab(5)` page in package `cron`, states the limitation directly: the daemon runs with one timezone, it does not support per-user timezones, and a `TZ` setting in the crontab affects only the commands, not when those commands are started. The daemon uses `/etc/localtime`. The same page's workaround is a `date` test in the child, not a `CRON_TZ` line. Strings in `/usr/sbin/cron` from that package do not mention `CRON_TZ`.

This host's `/etc/timezone` is `Etc/UTC`. On Sunday 2026-11-08:

| Clock | Instant |
|---|---|
| 03:30 Europe/Zurich | 02:30 UTC |
| 03:30 UTC, which is what `30 3 * * 0` matches here | 04:30 CET |

The shell prefix still changes `date` inside `weekly-stack-update.sh`. It does not move the start. A UTC host therefore runs the full `tu-vm.sh update` an hour later than the comment in winter, and two hours later during CEST.

Replayed on 2026-11-04 by building the same string the function builds and splitting fields. The cron daemon was not installed and no crontab was written. `apt-get upgrade` was not run. `.env` was not created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `ensure_weekly_update_cron_job` | The only installer for this line |
| `TU_VM_WEEKLY_UPDATE_TZ` | Defaults to `Europe/Zurich`. Keep the name |
| `scripts/weekly-stack-update.sh` | Lock, log, and `tu-vm.sh update`. Leave the body |
| Debian `crontab(5)` LIMITATIONS | Child `date` test for a zone the daemon does not schedule in |
| Stage 17 `weekly-stack-update-contribution-contract.md` (open PR #43) | What the weekly script is allowed to do. Unchanged here |
| Stage 23 `host-timezone-ntp-contract.md` (open PR #49) | One timezone name for containers and host NTP. Unchanged here |
| Stage 65 `weekly-update-apt-prompt-contract.md` (open PR #91) | Noninteractive `apt-get` inside `update_system`. Unchanged here |

Out of scope:

- Installing cronie or any daemon that advertises `CRON_TZ`
- Adding a Compose scheduler or a second update script
- Changing the daily checkup schedule (`0 9 * * *` has no Zurich claim)
- Editing `weekly-stack-update.sh`, sudoers, or the apt commands

## Proposal

Keep one crontab line, produced by `ensure_weekly_update_cron_job`. Match Europe/Zurich with the child `date` test Debian cron documents. Run the test every hour at minute 30 on Sunday, and start the existing script only when local time in `TU_VM_WEEKLY_UPDATE_TZ` is 03:30.

Percent signs in a crontab command become newlines unless they are escaped. The test has to use `\%`.

```text
30 * * * 0 TZ=${TU_VM_WEEKLY_UPDATE_TZ:-Europe/Zurich} [ "$(date +\%H:\%M)" = 03:30 ] && <repo>/scripts/weekly-stack-update.sh >> <repo>/logs/weekly-update.log 2>&1
```

On a UTC host in November the guard is true at 02:30 UTC. In July it is true at 01:30 UTC. Both of those instants are 03:30 in Zurich, and both are still Sunday. The hour field cannot stay `3`, because that is 03:30 in the daemon's zone.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Schedule | `ensure_weekly_update_cron_job` | Hour `*`, minute `30`, Sunday, then a `date` guard in `TU_VM_WEEKLY_UPDATE_TZ` |
| Zone name | `TU_VM_WEEKLY_UPDATE_TZ` | Keep the default `Europe/Zurich` |
| Job body | `scripts/weekly-stack-update.sh` | Leave lock, log, and `tu-vm.sh update` |
| Comment | The comment above the function | State that the daemon zone is the host zone and the guard selects Zurich |
| Other jobs | Daily checkup and MinIO sync lines | Leave their schedules |

### Rules

1. **The five schedule fields follow the host clock.** Debian cron 3.0pl1 will not move them because the command starts with `TZ=`.
2. **`CRON_TZ` is not the fix on this cron.** The packaged man page says the daemon has one timezone, and the binary does not mention `CRON_TZ`.
3. **The guard uses the existing variable.** `TU_VM_WEEKLY_UPDATE_TZ` stays the zone `date` sees. Escape `%` as `\%`.
4. **One installer.** The function still deletes previous `weekly-stack-update.sh` lines and appends one line. It does not install a second product.
5. **The script body stays.** Rollback, flock, and the `.env` abort remain in `weekly-stack-update.sh`.
6. **Stage 23 and Stage 65 stay the owners of their pages.** Container `TZ` and `apt-get` prompts are not edited here.

### Suggested contributor checklist

```text
1. Build the cron line and confirm fields 1-5 are 30 * * * 0
2. Confirm the command starts with TZ=$TU_VM_WEEKLY_UPDATE_TZ and a date test equal to 03:30
3. Confirm every % in the crontab command is written as \%
4. Confirm weekly-stack-update.sh is unchanged
5. Confirm no crontab was loaded and apt-get upgrade was not run
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| When to run | Debian cron child `date` test | `CRON_TZ`, cronie, or a new scheduler |
| Zone name | `TU_VM_WEEKLY_UPDATE_TZ` | A second variable for the same Sunday job |
| What runs | `scripts/weekly-stack-update.sh` | A copy of `tu-vm.sh update` inside the crontab |
| Host clock | `/etc/localtime`, already what this cron uses | A time-server container |

### Acceptance check

- [ ] The installed line's hour field is `*`, the minute field is `30`, and the day-of-week field is `0`.
- [ ] The command sets `TZ` from `TU_VM_WEEKLY_UPDATE_TZ` and continues only when `date` in that zone prints `03:30`.
- [ ] Percent signs in the command are escaped for crontab.
- [ ] `scripts/weekly-stack-update.sh` is unchanged.
- [ ] The daily checkup line and the MinIO sync line are unchanged.
- [ ] The cron daemon was not started to prove this, no user crontab was replaced, and `.env` was not created.

### Rollback

Restore `30 3 * * 0 TZ=$tz` as the start of the line. Hosts whose `/etc/localtime` is already `Europe/Zurich` behave as the comment describes. Hosts on UTC return to firing at 03:30 UTC.
