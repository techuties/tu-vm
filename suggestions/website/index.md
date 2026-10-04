---
title: Community Suggestions Website
description: Publishable Stage 50 website markdown for the AFFiNE dashboard start path, the Pi-hole tu.lan hosts file, the update Check Now button, and the Tika client versus server timeout.
last_updated: 2026-10-04
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#75 already specify the docs framework, governance, and most product contracts.

**Stage 50** (this run) records four defects checked on 2026-10-04 against the tree on `dev`. They are not restatements of Stages 1–49.

- The landing-page Start button for AFFiNE calls the Docker Engine start API for `ai_affine` only. Compose `depends_on` is not consulted. `affine_postgres`, `affine_redis`, and `affine_migration` use `restart: "no"` and are not in the `tu-vm.sh` tier lists. `./tu-vm.sh start-service affine` uses `docker compose up -d`, which does start that group.
- When both a LAN address and a Tailscale address are set, `sync_pihole_dns_records` strips `address=` lines from `pihole/01-custom.conf` and writes `/etc/pihole/hosts/tu-lan.hosts` with `docker exec`, ignoring failure. The mounted snippet never contains `addn-hosts`, and the hosts file is not a compose mount. The copy of that snippet in git has upstream resolvers and no `tu.lan` records.
- The dashboard button labeled **Check Now** only GETs `/status/updates`. Helper returns `/tmp/tu-vm-update-status.json` when `last_check` is under 24 hours. When the file is missing or stale, helper writes `updates_available: false` and the message `Awaiting daily update check (scheduled)`. The page then titles that payload **System Up to Date**. `scripts/daily-checkup.sh` and `write_update_notification_entry` in `tu-vm.sh` are the writers that already exist. `update_check` prints to the terminal and does not write the file.
- Apache Tika's mounted XML caps a task at `900000` ms (15 minutes). The processor's Compose OCR budget starts at 1800 seconds and can wait up to 3600 seconds. OCR requests also send `X-Tika-Timeout-Millis` at that longer client budget. A one-megabyte OCR job therefore asks and waits for 30 minutes on a server that ends the task at 15.

The contracts:

- Start and stop AFFiNE through the Compose command `tu-vm.sh` already uses, including the dependency group, without a second orchestrator
- Load the `tu.lan` hosts file from the dnsmasq snippet Pi-hole already mounts, and write that file on the host
- Make the update button tell the truth about the checkup file, and stop rendering the placeholder as "System Up to Date"
- Cap the processor client budget at the Tika XML task timeout

No new suggestion queue, voting database, wiki, update scanner, or document extractor.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–49 website pages (open PRs #27–#75) | Implement those contracts in code; do not rewrite them here |
| `tu-vm.sh start-service` | The Compose start path the dashboard should call |
| `helper/uploader.py` `control_service` | The handler that today starts one container |
| `pihole/01-custom.conf` | The dnsmasq snippet that should name the hosts file |
| `/tmp/tu-vm-update-status.json` | The checkup file the button should display honestly |
| `tika-config/tika-config.xml` | The server task cap the processor must not exceed |

Do **not** republish Stage 49's announcement roster, unwired Open WebUI init hook, TLS cipher names, or the duplicated pull request checklist. Do **not** add `config/service-dependencies.yaml` (Stage 7). Do **not** retune `depends_on` conditions (Stage 24) or add the Tika readiness probe (Stage 48). Do **not** edit XML parser policy (Stage 19) except to treat `taskTimeoutMillis` as the numeric cap this stage already measured. Do **not** change update-file timezone parsing (Stage 44).

## Page map (Stage 50)

| Page | Purpose |
|---|---|
| [AFFiNE Compose start](./affine-compose-start-contract.md) | Dashboard Start must bring up the dependency group |
| [Pi-hole dual-stack hosts](./pihole-dual-stack-hosts-contract.md) | The mounted snippet must load the hosts file sync-dns writes |
| [Update Check Now button](./update-check-button-contract.md) | The button must not report a placeholder as up to date |
| [Tika client and server timeout](./tika-client-server-timeout-contract.md) | The processor must not wait longer than Tika's task cap |

## Expected sibling pages

Stages 1–49 live on open PRs #27–#75 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `service-dependency-map.md`, `compose-depends-on-health-contract.md`, `affine-collaboration-contribution-contract.md`, `update-status-file-contract.md`, `tika-xml-config-contribution-contract.md`, `tika-pipeline-readiness-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 50** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| AFFiNE start | `docker compose up -d affine` as `tu-vm.sh` already runs it | A dependency engine in the dashboard |
| Local DNS names | dnsmasq `addn-hosts` in the existing Pi-hole snippet | A second DNS server |
| Update status | The checkup JSON and its existing writers | A Flask update scanner |
| Extraction budget | The Tika XML task cap plus the existing processor | Another OCR sidecar |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: AFFiNE start, then Pi-hole name records
3. Operator day-to-day: an honest update button, then one Tika timeout budget
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
