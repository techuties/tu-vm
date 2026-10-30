---
title: Community Suggestions Website
description: Publishable Stage 63 website markdown for the floating backup helper image, empty-dump rotation, and world-readable backup archives.
last_updated: 2026-10-29
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day backups accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#88 already specify the docs framework, governance, and most product contracts.

**Stage 63** (this run) records three defects checked on 2026-10-29 against `create_backup` in `tu-vm.sh`. They are not restatements of Stages 1–62.

- The volume loop archives each Docker volume with `docker run … alpine tar czf`. Omitting the tag selects `alpine:latest`. Stage 60 (open PR #86) pins `alpine:latest` only inside `scripts/sync-openwebui-minio.sh`. Stage 62 (open PR #88) pins it only inside `scripts/seed-chat-context.sh`.
- A failed `pg_dump` still creates a zero-byte `database.sql` because the failure is swallowed with `|| warn`. The following archive is newer, so keep-latest rotation deletes the previous backup. Stage 18 (open PR #44) keeps one archive on purpose. This page only refuses to promote a failed dump into that single slot.
- `umask` on this host is `0022`, and `create_backup` never runs `chmod` on the archive. The tarball is mode `644`. The `.env` member inside can be mode `600` and still be readable by anyone who can read the archive. `generate_secrets` already sets `.env` to mode `600`.

The contracts:

- Pack volume tarballs with the Postgres image digest Compose already pins. That image is the Alpine build and contains `tar`.
- Leave the previous archive in place when the new `database.sql` is missing or empty, or when a volume that exists produced no tarball.
- Create the archive and the `backups/` directory with the same owner-only mode the script already applies to `.env`.

No second backup product, encryption tool, or archive format.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–62 website pages (open PRs #27–#88) | Implement those contracts in code; do not rewrite them here |
| `create_backup` in `tu-vm.sh` | The function these three pages change |
| Pinned Postgres image | The helper image that should run `tar` |
| `chmod 600` in `generate_secrets` | The mode the backup archive should use |
| Stage 18 keep-latest rotation (open PR #44) | Still keep one archive, after the new one is known to be usable |

Stage 46 (open PR #72) owns volume-name prefixes and the MinIO `mc` transport, including the untagged `minio/mc` listing inside `create_backup`. Stage 53 (open PR #79) owns `pihole -g` during backup. Stage 60 owns `alpine:latest` in the sync script. Stage 62 owns `alpine:latest` in the seed script and the privileged recovery container. This stage does not edit those lines.

## Page map (Stage 63)

| Page | Purpose |
|---|---|
| [Backup volume image pin](./backup-volume-image-pin-contract.md) | Volume archives are packed with the pinned Postgres image |
| [Backup rotation empty dump](./backup-rotation-empty-dump-contract.md) | A failed database dump does not become the only archive |
| [Backup archive mode](./backup-archive-mode-contract.md) | Backup tarballs are owner-readable, matching `.env` |

## Expected sibling pages

Stages 1–62 live on open PRs #27–#88 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `backup-volume-prefix-contract.md`, `pihole-backup-gravity-contract.md`, `sync-client-image-pin-contract.md`, `seed-context-image-pin-contract.md`, `disk-pressure-volume-ops-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 63** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Volume archive | `tar` inside the pinned Postgres image | Floating `alpine` |
| Last backup | Keep-latest, after a non-empty dump | A second retention product |
| Secret files | Mode `600`, which `generate_secrets` already uses | A new encryption wrapper |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: volume backups do not pull a floating helper image
3. Operator day-to-day: a failed database dump leaves the previous archive in place
4. Operator day-to-day: the backup tarball is as private as `.env`

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
