---
title: Community Suggestions Website
description: Publishable Stage 62 website markdown for the unwired Open WebUI recovery command, the seed-context floating image, and the hardcoded disk-extend devices.
last_updated: 2026-10-28
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#87 already specify the docs framework, governance, and most product contracts.

**Stage 62** (this run) records three defects checked on 2026-10-28 against the tree on `dev`. They are not restatements of Stages 1–61.

- `check_health` tells the operator to run `./tu-vm.sh recover-openwebui`. `main` has no such command, so the hint exits as an unknown command. The unused function that would implement it kills a host PID from a `--privileged --pid=host` container and then restarts the Docker daemon.
- `scripts/seed-chat-context.sh` copies the assistant context pack with `alpine:latest`. Stage 60 (open PR #86) pins the sync script's client and says that tag is only used there. The seed script is a second pull.
- `scripts/extend-disk.sh` always runs `pvresize /dev/sda3` and `lvextend` on `/dev/ubuntu-vg/ubuntu-lv`. On this host the root filesystem is `/dev/vdc`. Neither hardcoded path exists.

The contracts:

- Register recovery as a real subcommand that uses the Docker API (`docker kill` / `docker compose up -d --force-recreate open-webui`). Leave the Docker daemon running.
- Copy the context pack with the Open WebUI image this stack already pins. Leave the volume-name rule on the Stage 46 page.
- Grow the logical volume that actually holds `/`, or stop when `/` is not LVM. Leave the operator ladder on the Stage 10 page.

No second process supervisor, second backup product, or partition editor.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–61 website pages (open PRs #27–#87) | Implement those contracts in code; do not rewrite them here |
| `tu-vm.sh` `check_health` | The hint that should name a command `main` actually runs |
| `docker kill` / `docker compose` | The recovery tools already on the operator's host |
| Pinned Open WebUI image | The image that should copy the context pack |
| `findmnt` and LVM tools | The discovery `extend-disk.sh` should use before it resizes |

Do **not** republish Stage 61's n8n schema, Qdrant client flags, or MCP restart policy. Stage 60 (open PR #86) owns `alpine:latest` inside `scripts/sync-openwebui-minio.sh` only. Stage 46 (open PR #72) owns the `docker_openwebui_files` volume name. Stage 10 (open PR #36) owns the disk-pressure ladder. Stage 11 (open PR #37) owns sudoers scope. This stage does not add `privileged: true` to Compose.

## Page map (Stage 62)

| Page | Purpose |
|---|---|
| [Open WebUI recovery command](./openwebui-recovery-command-contract.md) | The health hint runs a command that exists, and that command does not restart Docker |
| [Seed context image pin](./seed-context-image-pin-contract.md) | The context pack is copied without pulling `alpine:latest` |
| [Disk extend device discovery](./extend-disk-device-contract.md) | Growth targets the root filesystem's volume, or exits when there is no LVM |

## Expected sibling pages

Stages 1–61 live on open PRs #27–#87 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `sync-client-image-pin-contract.md`, `backup-volume-prefix-contract.md`, `disk-pressure-volume-ops-contract.md`, `privileged-host-ops-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 62** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Stuck container | Docker Engine API | A privileged container that shares the host PID namespace |
| Context copy | Pinned Open WebUI image | A floating helper image |
| Disk growth | `findmnt` plus the LVM tools already assumed by the script | Hardcoded `/dev/sda3` |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: `./tu-vm.sh health` names a recovery command the script actually implements
3. Contributor day-to-day: seeding assistant context does not fetch a new image tag
4. Operator day-to-day: disk growth reads the root device before it calls `pvresize`

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
