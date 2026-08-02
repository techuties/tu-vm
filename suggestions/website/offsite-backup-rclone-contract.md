---
title: Offsite Backup Rclone Contract
description: Constructional contract for optional offsite backup remotes that reuse tu-vm.sh backup artifacts and existing rclone usage instead of inventing a cloud disaster-recovery control plane.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Offsite Backup / rclone Contract

## Problem

`tu-vm.sh` already creates local backups and uses rclone for MinIO host mounts. Historical suggestions jump to mandatory cloud DR appliances, proprietary agents, or reinvented sync daemons. Community operators who want an **optional offsite copy** need a reuse-first contract that layers rclone remotes on top of existing backup artifacts—and stays opt-in.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh backup` / `restore` | Local backup artifacts |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Practiced local recovery |
| rclone usage in `tu-vm.sh` (MinIO mounts) | Already-present rclone dependency path |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Remote credential hygiene |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Snapshot-before-update habits |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| LAN-first security posture | Offsite must be explicit, not silent |

Out of scope:

- Requiring cloud storage accounts for a successful install
- Replacing local backup/restore with cloud-only backups
- Storing remote access keys in git, Issues, or website markdown
- Building a custom multi-cloud orchestration UI in the dashboard

## Proposal

Define an **optional offsite lane**: local backup first, rclone copy second.

### Recommended flow

```text
./tu-vm.sh backup pre-offsite-YYYYMMDD
rclone copy ./backups/<artifact> <remote>:<path> --checksum
# record evidence in a private operator log or redacted drill note
```

### Contribution lanes

| Lane | Examples | Evidence |
|---|---|---|
| Playbooks | `#playbook-offsite-backup` | Commands, retention, restore-from-remote drill |
| Scripts | Thin wrapper calling existing `backup` then `rclone copy` | `--plan` mode; no keys printed |
| Docs | Remote provider examples (S3-compatible, SFTP) | Placeholder env names only |
| Drill extension | Stage 6 drill adds optional offsite step | Checkbox in community drill template |

### Rules

1. **Local restore must work without the remote.** Offsite is defense-in-depth.
2. **Credentials live in operator-only rclone config or env**—never in the repo.
3. **`--plan` / dry-run first** for any wrapper script.
4. **Encryption guidance:** prefer client-side encrypted remotes or provider SSE; document tradeoffs briefly.
5. **Retention:** document pruning so offsite mirrors do not grow forever.
6. **Support bundles must redact remote names/keys** (align with PR #25).

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Transfer | rclone (already in operator toolchain) | New sync agent binary |
| Artifact format | Existing `tu-vm.sh backup` outputs | Parallel backup format per cloud |
| Scheduling | cron / systemd timers calling documented commands | Hidden dashboard cron SaaS |
| Proof | Stage 6 drill + optional offsite checkbox | “We enabled cloud” without restore test |

## Rollout

1. Publish this page; link from Stage 6 backup drill as an optional extension.
2. Add playbook anchor with S3-compatible and SFTP examples using placeholders.
3. Only then consider `./tu-vm.sh backup --offsite --plan` as a thin wrapper.
4. Keep MinIO rclone **mount** docs distinct from rclone **offsite copy** docs to avoid confusion.

## Acceptance criteria

- [ ] Offsite backup is documented as optional and disable-able.
- [ ] No sample commands embed real keys, tokens, or account IDs.
- [ ] Local `backup`/`restore` path remains primary.
- [ ] Drill guidance includes at least one restore-from-remote checklist item.
- [ ] Wrapper (if any) supports non-destructive plan/dry-run output.

## Rollback

Stop cron timers; remove remote stanzas from operator rclone config; local backups remain. No Compose service changes required for docs-only adoption.

## Success metrics

- Operators who opt in complete at least one restore-from-remote drill per quarter.
- Fewer proposals for mandatory cloud DR control planes.
- Incident retros mention offsite copies without credential leaks in public Issues.
