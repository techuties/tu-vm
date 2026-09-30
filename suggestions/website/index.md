---
title: Community Suggestions Website
description: Publishable Stage 46 website markdown for the MinIO client transport, the sync cron secret, and backup volume name prefixes.
last_updated: 2026-09-30
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation safe for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#71 already specify the docs framework, governance, and most product contracts.

**Stage 46** (this run) records three defects checked on 2026-09-30 against the tree on `dev`. They are not restatements of Stages 1–45.

- `run_minio_mc` and `scripts/sync-openwebui-minio.sh` start `minio/mc` with `--network host` and put the MinIO root password inside `MC_HOST_local`. `get_compose_network_name` already finds the network `ai_minio` is on, and the backup bucket listing already uses that network. Go 1.22 `net/url` rejects that URL when the password contains `/`, `?`, `#`, a bare `%`, or a space. The backup listing passes the same password through `sh -c` single quotes, so a `'` in the password breaks the command.
- `start_services` calls `ensure_sync_cron_job` after Tier 1 is up. That helper writes `MINIO_SYNC_PASSWORD=<resolved password>` into the user crontab and prints the whole line. The sync script already reads `.env`. The fallback line contains the insecure default password. Stage 11’s install command is `./tu-vm.sh install-cron`; start should not install this job by itself.
- `create_backup` archives only volume names that start with `docker_`. `verify_data_retention` already treats a volume as present when its name is the suffix or ends with `_<suffix>`. A checkout whose Compose project is `tu-vm` or `workspace` keeps data in `tu-vm_postgres_data` or `workspace_postgres_data`. The backup loop’s `docker volume inspect` fails quietly, so the archive has no data tarballs. `scripts/seed-chat-context.sh` hardcodes `docker_openwebui_files`, and the sync script’s fallback volume is `tu-vm_openwebui_files`.

The contracts:

- Talk to MinIO on the Compose network with `mc alias set` arguments, not a host-network URL
- Leave the sync password in `.env`, which the script already loads, and install that cron only from `install-cron`
- Archive volumes with the suffix match the retention check already uses

No new suggestion queue, voting database, identity provider, sync product, or backup product.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–45 website pages (open PRs #27–#71) | Implement those contracts in code; do not rewrite them here |
| `get_compose_network_name` | Network lookup the MinIO client should use |
| `verify_data_retention` suffix match | Volume identity the backup loop should use |
| `./tu-vm.sh install-cron` | The only installer for the sync cron |

Do **not** add a second MinIO client, a new sync daemon, or a restic/borg backup path. Do **not** republish Stage 11 cron policy, Stage 14’s sync playbook, Stage 18 backup format, Stage 19 AFFiNE volume names, Stage 24 archive encryption, Stage 30 Compose `name:`, Stage 30 Qdrant/MinIO healthcheck binaries, or Stage 44 image digest compare.

Stage 14 owns forward-versus-reverse TXT semantics and the operator playbook. Stage 19 owns adding `affine_storage`, `affine_config`, and `affine_postgres_data`. Stage 30 owns the top-level Compose `name:`. This stage only covers **how the client reaches MinIO**, **where the sync password is written**, and **which volume name the existing backup loop inspects**.

## Page map (Stage 46)

| Page | Purpose |
|---|---|
| [MinIO mc client transport](./minio-mc-client-transport-contract.md) | Compose network and `mc alias set` arguments, not host networking |
| [MinIO sync cron secret](./minio-sync-cron-secret-contract.md) | Start must not write the root password into crontab |
| [Backup volume prefix](./backup-volume-prefix-contract.md) | Archive the suffix `verify_data_retention` already accepts |

## Expected sibling pages

Stages 1–45 live on open PRs #27–#71 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `how-to-submit.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, `openwebui-minio-sync-day2-contract.md`, `host-cron-maintenance-contract.md`, `local-backup-restore-contribution-contract.md`, `affine-backup-volume-coverage-contract.md`, `compose-project-name-contract.md`, `qdrant-minio-healthcheck-binary-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 46** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| MinIO client | `get_compose_network_name` plus `mc alias set` argv | `--network host` and a password inside a URL |
| Sync schedule | Existing `install-cron` and the script’s `.env` read | A password assigned in the crontab |
| Volume identity | Suffix match already in `verify_data_retention` | A hardcoded `docker_` or `tu-vm_` list |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: MinIO client transport, then the sync cron secret
3. Data day-to-day: backup volume prefix, after Stage 19 AFFiNE coverage and Stage 30 project name
4. Quality gates: merge playbook

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
