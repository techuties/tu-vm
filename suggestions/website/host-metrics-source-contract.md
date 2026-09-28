---
title: Host Metrics Source Contract
description: Constructional contract so dashboard load, memory, disk, and battery numbers come from a declared host source instead of unmounted helper-container paths.
last_updated: 2026-09-28
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Host Metrics Source Contract

## Problem

Historical suggestions already ask for battery status on the dashboard and for resource numbers operators can trust. The helper grew those reads in place. The Compose service never gained the files those reads need.

`GET /status` and `GET /announcements` both run inside `helper_index`:

- `os.getloadavg()` and `/proc/meminfo` for the memory KPI and the high-load / memory-pressure announcements
- `os.statvfs('/')` for `disk_mb` and the low-disk announcement
- `/sys/class/power_supply/BAT0/status` and `.../capacity` for battery announcements

`helper_index` volumes do not include host `/proc`, host `/`, or `/sys/class/power_supply`. The battery `open` raises `FileNotFoundError`, which is swallowed, so the historical battery widget never renders. Disk figures are the container root filesystem, which the landing page prints as the machine disk (`kpi-disk` in `nginx/html/index.html`). Load and `/proc/meminfo` are whatever that container’s proc shows, with no label that they are container views.

`monitoring/prometheus.yml` is not a Compose service. Standing up Prometheus, node_exporter, and Grafana for four existing fields would be a new stack. The helper already returns `load_avg`, `memory_mb`, `disk_mb`, and battery announcements. Point those reads at a declared source.

This does not add charts. Resource-history charts stay a separate historical idea until someone accepts that issue.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` `status()` | Fills `load_avg`, `memory_mb`, `disk_mb`, `cpu_cores` |
| `helper/uploader.py` announcements resource block | Load, memory, disk, and `BAT0` copy |
| `nginx/html/index.html` | Prints `kpi-cpu`, `kpi-mem`, and `kpi-disk` from `/status/full` with `textContent` |
| `suggestions/historical-suggestions.md` | Battery widget and resource history are already tracked there |
| `monitoring/prometheus.yml` | Unused by Compose. Not the vehicle for this fix |

Out of scope:

- Adding Prometheus, node_exporter, Grafana, or a metrics SaaS
- Persisting resource history or drawing charts
- Mounting the host root filesystem into the helper
- Changing announcement `type` values (Stage 12) or HTML insertion (Stage 43)

## Proposal

Declare the source of each number. Mount only the files required, read-only.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Battery | helper volumes | If the host has `BAT0`, mount `status` and `capacity` read-only at the paths the code already opens. If the directory is absent, skip the mount and keep the current quiet `except`. |
| Disk | `STATUS_DISK_PATH` | `statvfs` that path. Default it to a read-only mount of the filesystem that holds Docker data (often `/var/lib/docker`), not container `/`. Document the default in `env.example`. |
| Memory and load | helper proc | Either read `/proc/meminfo` and the load average from a read-only `/host/proc` mount and say so in the JSON, or add `metrics_source: container` and stop implying the numbers are the VM. |
| API | `/status` | Add `metrics_source` with values `host` or `container`. Do not rename `memory_mb` or `disk_mb`. |
| Copy | announcements | Battery text stays the existing sentences. Disk and memory text should name the source when it is still the container (“container disk”, not “the VM”). |

### Rules

1. **Do not mount `/` or all of `/sys`.** Battery is two files. Disk is one directory. Proc, if used, is a read-only `/host/proc` mount, not the host root.
2. **Absence of a battery is success.** Desktops and VMs without `BAT0` stay quiet. Do not log a warning on every announcement poll.
3. **Keep the JSON fields the dashboard already reads.** `metrics_source` is additive.
4. **Do not deploy the files under `monitoring/`** as part of this change. They are not wired into Compose.
5. **Do not collect history.** A later issue can persist snapshots. This contract only makes the live numbers honest.
6. **Leave announcement categories alone.** Low-disk and low-battery stay `warning` / `info` as they are today.

### Suggested contributor checklist

```text
1. Note that BAT0 is not in helper_index volumes
2. Add the narrow read-only mounts or set metrics_source to container
3. Point statvfs at STATUS_DISK_PATH
4. Keep memory_mb and disk_mb shapes
5. Confirm the landing KPIs still fill via textContent
6. Do not add a Prometheus service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Live KPIs | The existing `/status` fields | A new metrics product |
| Battery | The two sysfs files the helper already opens | A new battery API or a desktop agent |
| Disk path | One env var and a read-only mount | Parsing `df` in a shell from the helper |
| Charts later | An accepted issue on top of honest samples | Building history storage in this change |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `metrics_source` and the disk path first, with no new mounts, so the UI stops calling container disk “the machine” on the day of the change.
3. Add the `BAT0` and disk mounts only where those host paths exist. `tu-vm.sh` can skip a missing battery directory.

## Acceptance criteria

- [ ] `/status` includes `metrics_source` set to `host` or `container`.
- [ ] `disk_mb` is `statvfs` of `STATUS_DISK_PATH`, and the default is not container `/` once the host path is mounted.
- [ ] When `BAT0` is mounted, a discharging capacity under 20 still produces the existing low-battery announcement.
- [ ] When `BAT0` is not on the host, announcements still succeed and do not log a missing-file error every poll.
- [ ] `kpi-mem` and `kpi-disk` still render through `textContent`.
- [ ] Compose does not gain a Prometheus or Grafana service in this change.

## Rollback

Remove the extra mounts and `metrics_source`. The previous container-local reads return. Docs-only publication needs no runtime rollback.

## Success metrics

- Operators on a laptop see the battery announcement the historical notes already promised, without a new API.
- Operators on a VM do not see a false low-disk warning sourced from the helper image’s own root.
- The landing page can say whether a number is the host or the container.
