---
title: Community Suggestions Website
description: Publishable Stage 47 website markdown for checkup container identity, checkup writes, backup restore, and write-approval fail-closed behavior.
last_updated: 2026-10-01
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation safe for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#72 already specify the docs framework, governance, and most product contracts.

**Stage 47** (this run) records four defects checked on 2026-10-01 against the tree on `dev`. They are not restatements of Stages 1–46.

- `scripts/daily-checkup.sh` decides a container is down only when `docker ps` prints `not running` or `Exited`. A stopped container makes `docker ps` (without `--all`) exit 0 with an empty status, so the down branch never runs. The same status lookup uses `--filter name=`, and Moby matches that filter with an unanchored regular expression, so `ai_n8n` also matches `ai_n8n_mcp`. An empty Bash array rendered with `printf '"%s",'` becomes the JSON array `[""]`.
- The same checkup updates the Open WebUI `config` row when the embedding engine is `ollama`, and it calls node-type reload. A scheduled pulse should report. It should not repair.
- `restore_backup` extracts the archive `create_backup` built, then copies `.env` and merges `nginx/` and `ssl/`. It never unpacks volume tarballs, never copies `helper/`, `pihole/`, or `tika-minio-processor/`, and starts Compose with `up -d` and no service list. `read` under `set -e` exits on EOF before the y/N check. GNU cp 9.4 merges into the live tree and leaves files that exist only on the machine.
- `MCP_WRITE_APPROVAL_REQUIRED=true` with an empty `MCP_WRITE_APPROVAL_TOKENS` accepts any non-empty `approvalToken` or `X-Write-Approval-Token`. The allow-list check runs only when the set is non-empty.

The contracts:

- Classify containers with the exact `docker inspect` the checkup already uses, and emit `[]` for an empty list
- Leave repair out of the daily pulse
- Make `restore_backup` apply the archive `create_backup` already writes, using the Tier 1 service list `start_services` already has
- Fail closed when write approval is required and no approval tokens are configured

No new suggestion queue, voting database, monitoring product, backup product, or approval service.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–46 website pages (open PRs #27–#72) | Implement those contracts in code; do not rewrite them here |
| `docker inspect` in `daily-checkup.sh` | Exact container state the status lookup should use |
| `TIER1_SERVICES` / `TIER2_SERVICES` | The start list restore should pass to Compose |
| `pg_isready` inside `create_backup` | The readiness check restore should wait on |
| `MCP_WRITE_APPROVAL_REQUIRED` and `MCP_WRITE_APPROVAL_TOKENS` | The existing approval gate; fix its empty-set branch |

Do **not** add a second health agent, a restic/borg path, or an approval inbox. Do **not** republish Stage 11 cron policy, Stage 15 node-type extraction, Stage 18 backup format and keep-latest rotation, Stage 19 Compose profiles, Stage 44 update-status timestamps or host metrics, Stage 45 supervisor callback header or `WRITE_TOOLS`, or Stage 46 MinIO client transport, cron secrets, and volume-name prefixes.

Stage 15 owns how node types are extracted. Stage 18 owns archive layout and the decision to keep one tarball. Stage 46 owns which volume names `create_backup` inspects. This stage only covers **how checkup identifies a container**, **that checkup must not write**, **how restore applies an archive that already exists**, and **how the existing approval flag behaves when the token list is empty**.

## Page map (Stage 47)

| Page | Purpose |
|---|---|
| [Checkup container state](./daily-checkup-container-state-contract.md) | Exact inspect status, and an empty JSON array |
| [Checkup stays read-only](./daily-checkup-readonly-contract.md) | Do not UPDATE Open WebUI config or reload node types from the daily pulse |
| [Backup restore apply](./backup-restore-apply-contract.md) | Apply the archive in place, then start Tier 1 only |
| [Write approval fail-closed](./write-approval-fail-closed-contract.md) | An empty approval-token list must deny writes |

## Expected sibling pages

Stages 1–46 live on open PRs #27–#72 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `how-to-submit.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, `daily-checkup-contribution-contract.md`, `n8n-node-types-extraction-contract.md`, `local-backup-restore-contribution-contract.md`, `autonomous-write-guard-policy.md`, `openwebui-offline-embeddings-contract.md`, `backup-volume-prefix-contract.md`, `minio-sync-cron-secret-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 47** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Container state | `docker inspect` by exact name | `docker ps --filter name=` |
| Scheduled pulse | `scripts/daily-checkup.sh` writing status JSON | A repair hidden inside the pulse |
| Restore | `restore_backup` plus `TIER1_SERVICES` | A second backup CLI or bare `compose up -d` |
| Write confirm | Existing approval env vars, deny when unset | A new approval service, or any non-empty string |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: checkup container state, then checkup read-only behavior
3. Data day-to-day: restore apply, after Stage 18 format and Stage 46 volume names
4. Safety day-to-day: write approval fail-closed, beside the Stage 11 policy page

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
