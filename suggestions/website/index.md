---
title: Community Suggestions Website
description: Publishable Stage 64 website markdown for the backup running-state gate, the n8n workflow file, and the status accessibility curl.
last_updated: 2026-10-30
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day backups and status accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#89 already specify the docs framework, governance, and most product contracts.

**Stage 64** (this run) records three defects checked on 2026-10-30. They are not restatements of Stages 1–63.

- `create_backup` runs `pg_dump` and the volume loop only when `docker compose ps --format json | grep -q '"State":"running"'` succeeds. `tu-vm.sh` uses `set -o pipefail`. `grep -q` closes the pipe at the first match, and a slow producer then fails the `if` while a container is running. Compose v5.1.0 also omits stopped containers unless `-a` or `--status` is set, so a stopped project skips the volume tarballs entirely. `docker volume inspect` does not need a running container. `pg_isready` already gates the dump.
- The same function writes `n8n-workflows.json` with `find /home/node/.n8n -name '*.json' -exec cat`. Two JSON files become one member that `json.loads` rejects. No JSON files still create a zero-byte member, because `find` exits 0. Compose sets `DB_TYPE=postgresdb` on the database `pg_dump` already saves. n8n 2.25.7 already ships `export:workflow --all --output=<file>` for a single JSON array.
- `show_access_info` curls `https://$vm_ip` with `-k -s` and no `--fail` or `--max-time`, then prints "Services are accessible". A 500 response exits 0. A peer that accepts TCP and stalls was still running after 3 seconds. The landing server serves `index.html` itself, so that curl does not read the Tier 1 checks `show_status` already printed.

The contracts:

- Archive volumes when `docker volume inspect` succeeds. Leave `pg_dump` on `pg_isready`. Do not use `grep -q` on a `pipefail` pipeline as the gate.
- Delete the `find` and `cat` workflow member. Keep the Postgres dump. If a portable file remains, use `n8n export:workflow --all --output=<file>` and pack it only when it is one JSON array.
- Drive the status summary from `check_service_health`. A static dashboard response is the landing page, not "services".

No second backup product, workflow store, or monitoring agent.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–63 website pages (open PRs #27–#89) | Implement those contracts in code; do not rewrite them here |
| `create_backup` in `tu-vm.sh` | The function the backup pages change |
| `check_service_health` | The status signal the curl page should print |
| `pg_isready` inside `create_backup` | The dump gate that stays |
| n8n `export:workflow` in the pinned 2.25.7 image | The optional portable file |

Stage 63 (open PR #89) owns the floating `alpine` volume helper, keep-latest promotion of an empty dump, and the archive mode. Stage 61 (open PR #87) owns creating the n8n Postgres schema. Stage 52 (open PR #78) owns `test_endpoints` SNI. Stage 57 (open PR #83) owns the `tu.lan` labels in `show_access_info`. This stage does not edit those lines.

## Page map (Stage 64)

| Page | Purpose |
|---|---|
| [Backup running gate](./backup-running-gate-contract.md) | Volume archives do not depend on `grep -q` of `docker compose ps` |
| [n8n workflow file export](./n8n-workflow-file-export-contract.md) | `n8n-workflows.json` is not a concatenation of every JSON file |
| [Status access curl](./status-access-curl-contract.md) | "Services are accessible" follows Tier 1 health, not a static curl |

## Expected sibling pages

Stages 1–63 live on open PRs #27–#89 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `backup-volume-image-pin-contract.md`, `backup-rotation-empty-dump-contract.md`, `backup-archive-mode-contract.md`, `n8n-postgres-schema-contract.md`, `endpoint-probe-sni-contract.md`, `pihole-domain-suffix-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 64** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Volume bytes | `docker volume inspect` and the existing loop | A volume-backup plugin |
| Workflow rows | `pg_dump` of `ai_platform` | `cat` of `*.json` |
| Status line | `check_service_health` | An unbounded curl of the dashboard |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: volume backups run when the volumes exist
3. Operator day-to-day: the n8n workflow member is one JSON array or is absent
4. Operator day-to-day: `tu-vm.sh status` agrees with the Tier 1 health rows

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
