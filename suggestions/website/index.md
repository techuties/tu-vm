---
title: Community Suggestions Website
description: Publishable Stage 53 website markdown for one update entry point, authenticated service probes, a Pi-hole backup that does not refresh gravity, and a start-time secret gate that sees every published default.
last_updated: 2026-10-07
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#78 already specify the docs framework, governance, and most product contracts.

**Stage 53** (this run) records four defects checked on 2026-10-07 against the tree on `dev`. They are not restatements of Stages 1–52.

- `README.md` calls `scripts/safe-update.sh` a compatibility wrapper for `./tu-vm.sh update`. The script never calls `tu-vm.sh`. It keeps a second pin table, and that table omits `n8n_mcp`. Weekly cron already calls `./tu-vm.sh update`.
- `verify_data_retention`, `scripts/daily-checkup.sh`, and `scripts/switch-pdf-loader.sh` open Postgres and Redis with hardcoded `ai_admin` / `ai_platform` and no password. `check_openwebui_audio_config` in `tu-vm.sh` already resolves the user, database, and passwords and exports `PGPASSWORD` and `REDISCLI_AUTH`.
- `create_backup` runs `pihole -g` while it is taking a backup. Current Pi-hole docs use that flag for Gravity, which downloads lists into the live `gravity.db`. The stdout of that run is saved as `pihole-gravity.txt`. The v5 teleporter flag `pihole -a -t` is the other command on that line. Current Pi-hole documents the export as `pihole-FTL --teleporter`.
- `env_has_insecure_values` and `validate_security` do not flag the published defaults that `generate_secrets` already knows how to replace: the n8n encryption key, the WebUI secrets, and `SwissPiHole2024!`. A `.env` that has a unique Postgres password and the public n8n key is treated as clean on start.

The contracts:

- Make `scripts/safe-update.sh` the wrapper the README already describes. One pin table: `OFFICIAL_UPDATE_IMAGE_PAIRS` in `tu-vm.sh`.
- Use the audio-config credential helper for every remaining Postgres and Redis probe. A retention check counts Redis only when the reply is `PONG`.
- Stop refreshing Pi-hole lists during backup. The volume archive is the copy of `gravity.db`. A config export, if one is still wanted, is `pihole-FTL --teleporter`.
- Teach the start-time secret gate the same published defaults `generate_secrets` already replaces. Do not add a new scanner.

No new suggestion queue, voting database, updater container, backup product, or secret manager.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes, including the safe-update playbook |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–52 website pages (open PRs #27–#78) | Implement those contracts in code; do not rewrite them here |
| `OFFICIAL_UPDATE_IMAGE_PAIRS` in `tu-vm.sh` | The pin table both update entry points should use |
| `resolve_env_value` plus the audio probes | The credential pattern the other probes should copy |
| `pihole-FTL --teleporter` | The export Pi-hole documents today |
| `generate_secrets` / `set_env_var_if_default` | The defaults the start gate should recognize |
| Stage 47 backup restore (open PR #73) | Dump and restore identity, archive apply, Tier 1 start |
| Stage 46 volume names (open PR #72) | Which volume tarball holds Pi-hole data |
| Stage 31 check-config secrets (open PR #57) | The CI gate. This stage is the `tu-vm.sh` start gate |
| Stage 30 Pi-hole `FTLCONF_*` (open PR #56) | Environment keys. This stage does not remap them |
| Stage 29 Redis healthcheck argv (open PR #55) | `REDISCLI_AUTH` on the Compose probe |

Do **not** republish Stage 52's allowlist parser, public-IP lookup, probe SNI, or archive object keys.

## Page map (Stage 53)

| Page | Purpose |
|---|---|
| [Safe-update wrapper](./safe-update-wrapper-contract.md) | One update implementation, with the old script as a flag-compatible wrapper |
| [Service probe credentials](./service-probe-credentials-contract.md) | Retention, checkup, and the PDF loader switch authenticate the way the audio tools already do |
| [Pi-hole backup gravity](./pihole-backup-gravity-contract.md) | Backup must not download blocklists into the live resolver |
| [Startup secret gate](./startup-secret-gate-contract.md) | `./tu-vm.sh start` flags every published default `generate_secrets` can replace |

## Expected sibling pages

Stages 1–52 live on open PRs #27–#78 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `safe-update-contribution-contract.md`, `backup-restore-apply-contract.md`, `backup-volume-prefix-contract.md`, `pihole-v6-ftlconf-env-contract.md`, `check-config-secret-coverage-contract.md`, `redis-healthcheck-auth-env-contract.md`, `open-webui-audio-stt-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 53** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Image refresh | `./tu-vm.sh update` and `OFFICIAL_UPDATE_IMAGE_PAIRS` | A second pin table or Watchtower |
| Database probes | `resolve_env_value`, `PGPASSWORD`, `REDISCLI_AUTH` | Hardcoded `ai_admin` with no password |
| Pi-hole copy | The volume archive, or `pihole-FTL --teleporter` | `pihole -g` during backup |
| Published defaults | The list `generate_secrets` already replaces | A new secret-scanning product |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: one update command, probes that can see the data, a backup that leaves DNS lists alone
3. Operator day-to-day: start-up that notices a published encryption key
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
