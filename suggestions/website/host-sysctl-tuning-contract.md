---
title: Host Sysctl Tuning Contract
description: Constructional contract for optional host sysctl knobs (inotify, swappiness) applied through existing tu-vm.sh host helpers, without a second supervisor or privileged-by-default services.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Host Sysctl Tuning Contract

## Problem

File watchers (Open WebUI uploads, the Tika/MinIO processor, helper bind-mounts, optional Playwright) can exhaust default `fs.inotify.max_user_watches` on a laptop. Swap-happy hosts fight the energy-tier design: idle services get paged out, then pay a spike when a Tier 2 service starts.

There is no documented, idempotent sysctl drop-in for TU-VM. Contributors who hit "too many open files" or surprise swap often propose a privileged `sysctl` sidecar, a custom kernel, or another systemd supervisor.

Stage 11 covers **who may run privileged host ops** (sudoers, docker.sock). Stage 16 covers **daily checkup**. This page is only **which sysctl knobs are in scope and how they are applied**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` | Already performs narrow host edits (Docker daemon.json, resolv backup) |
| `docker-compose.yml` | No `sysctls:` on services today (and most knobs are **host** namespaced) |
| Stage 11 `privileged-host-ops-contract.md` (expected sibling) | Sudoers / privileged path; not the knob list |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install/remove; not sysctl |
| Stage 13 `host-cleanup-and-prune-contract.md` (expected sibling) | Disk prune, not kernel tunables |
| Stage 20 `systemd-user-unit-install-contract.md` (expected sibling) | Optional user unit; not a second supervisor |

Out of scope:

- A privileged `sysctler` container on every compose up
- Custom kernels, tuned profiles as a distro, or `tuned` daemon
- Changing container `ulimits` except where a knob requires it (Nginx already sets `nofile`)
- Network stack rewrites (`net.core.*`, ip forwarding) in the same PR

## Proposal

Ship an **opt-in** drop-in `/etc/sysctl.d/99-tu-vm.conf` applied by a `tu-vm.sh` subcommand (or a flag on an existing host helper). Default clones do nothing to the host kernel.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Knobs | `/etc/sysctl.d/99-tu-vm.conf` | `fs.inotify.max_user_watches`, `fs.inotify.max_user_instances`, `vm.swappiness` |
| Apply | `tu-vm.sh` (opt-in) | `sysctl --system` or `sysctl -p` on that file |
| Detect | `tu-vm.sh doctor` | Report current vs recommended values; do not auto-write |
| Compose | none by default | Use Compose `sysctls:` only for **namespaced** knobs that a service truly owns |

### Rules

1. **Opt-in host writes.** Never apply sysctl during `docker compose up` or first-boot without an explicit command.
2. **Reuse `tu-vm.sh`, not a new supervisor.** No extra systemd service whose only job is sysctl.
3. **Allowlist the keys.** First wave is inotify watches/instances and `vm.swappiness`. New keys need a suggestion Issue plus this page update.
4. **Doctor reports, apply writes.** `doctor` must stay read-only for these knobs.
5. **Laptop-safe numbers.** Recommend conservative raises (for example watches `524288`, swappiness `10`), not server-class infinity.
6. **GitHub remains intake.** Requests for a custom kernel stay Issues.

### Suggested contributor checklist

```text
1. Read tu-vm.sh doctor and any existing host-file helpers
2. Add recommended values as comments in a checked-in example (for example host/sysctl.d/99-tu-vm.conf)
3. Add an opt-in tu-vm.sh command that copies the file and runs sysctl --system
4. Extend doctor to print current inotify/swappiness without writing
5. Do not add a privileged sysctl sidecar to docker-compose.yml
6. Do not apply knobs from cron or daily checkup
7. Document sudo requirement and how to remove the drop-in
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Host knobs | systemd-style `sysctl.d` + `tu-vm.sh` | Privileged containers, `tuned`, custom kernels |
| Detection | existing `doctor` | A new metrics daemon |
| Privilege | Stage 11 sudoers notes | Broad NOPASSWD for all sysctl |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: checked-in example drop-in + opt-in apply + read-only doctor.
3. Keep compose start unchanged.

## Acceptance criteria

- [ ] Default start does not write `/etc/sysctl.d`.
- [ ] Opt-in apply is idempotent and limited to the allowlisted keys.
- [ ] `doctor` reports values without requiring sudo write.
- [ ] No privileged sysctl sidecar or extra systemd supervisor is added.
- [ ] Removal path (delete drop-in, `sysctl --system`) is documented.

## Rollback

Delete `/etc/sysctl.d/99-tu-vm.conf` and reload sysctl. Container behavior returns to distro defaults.

## Success metrics

- Inotify failures have a documented fix instead of a new container.
- Energy-minded hosts can lower swappiness without a performance product.
- Host writes stay an explicit operator action.
