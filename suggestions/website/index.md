---
title: Community Suggestions Website
description: Publishable Stage 55 website markdown for firewall commands that match in the order UFW evaluates, an update rollback that restores the compose file it rewrote, a Docker daemon DNS change that keeps the existing daemon.json, and a Pi-hole DNS restore that waits until the resolver is up.
last_updated: 2026-10-15
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#80 already specify the docs framework, governance, and most product contracts.

**Stage 55** (this run) records four defects checked on 2026-10-15 against the tree on `dev`. They are not restatements of Stages 1–54.

- `enable_secure`, `enable_public`, and `lock_access` append UFW rules. UFW keeps the first match. `secure` adds a deny for ports 80, 443, and 53 before the LAN allow, so the LAN allow never matches. `public` after `secure` stays denied. `lock` after `public` stays allowed.
- `update_rollback` restores the newest `backups/docker-compose_*.yml`. `./tu-vm.sh update` rewrites `docker-compose.yml` in place and never writes that filename. `create_backup` stores a `.tar.gz`. A bare `docker compose up -d` in rollback starts all 24 compose services, including Tier 2.
- `configure_docker_dns set` replaces `/etc/docker/daemon.json` with a DNS-only document and restarts Docker. On this machine the file's only key is `storage-driver: fuse-overlayfs`. A failed DNS check calls `error`, which exits, and does not restore the backup.
- `handle_pihole_dns_replacement start` runs after `docker compose down` and before `docker compose up`. It still writes `nameserver 127.0.0.1`, sets the immutable attribute, and stops `systemd-resolved` while `ai_pihole` is stopped.

The contracts:

- Insert the specific UFW allows, then the general denies, and delete this script's previous rules before switching mode.
- Save `docker-compose.yml` under the filename `update_rollback` already reads, and start Tier 1 plus the services that were already running.
- Merge a `dns` key into `daemon.json` and put the backup back if the DNS check fails.
- Point host DNS at Pi-hole only after the Tier 1 start has the container answering.

No new firewall product, snapshot service, Docker configuration manager, or resolver.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–54 website pages (open PRs #27–#80) | Implement those contracts in code; do not rewrite them here |
| `ufw allow`, `ufw deny`, `ufw insert`, `ufw delete` | The firewall commands these three modes already call |
| `update_rollback` and `OFFICIAL_UPDATE_IMAGE_PAIRS` | The rollback path and the pin table |
| `configure_docker_dns` | The daemon.json writer to keep |
| `handle_pihole_dns_replacement` | The resolv.conf writer to move later in `update_system` |

Do **not** republish Stage 54's secret writer, PDF probes, processor metadata cap, or rclone secret refresh. Stage 53 owns the safe-update wrapper. This stage makes `./tu-vm.sh update-rollback` able to see a snapshot that `./tu-vm.sh update` actually wrote.

## Page map (Stage 55)

| Page | Purpose |
|---|---|
| [Firewall command order](./firewall-command-order-contract.md) | `secure`, `public`, and `lock` follow UFW first-match order |
| [Update rollback snapshot](./update-rollback-compose-snapshot-contract.md) | Rollback restores the compose file from this update and does not start every service |
| [Docker daemon DNS merge](./docker-daemon-dns-merge-contract.md) | A DNS override keeps the storage driver and is restored if the check fails |
| [Pi-hole DNS restore order](./pihole-dns-restore-order-contract.md) | Host DNS switches to Pi-hole after the container is up |

## Expected sibling pages

Stages 1–54 live on open PRs #27–#80 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `safe-update-wrapper-contract.md`, `ipv6-dual-stack-policy-contract.md`, `pihole-dual-stack-hosts-contract.md`, `pihole-v6-ftlconf-env-contract.md`, `local-backup-restore-contribution-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 55** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Host firewall | The `ufw` binary `tu-vm.sh` already calls, with `insert` and `delete` | nftables, firewalld, or a generated ruleset |
| Update rollback | `update_rollback` and the `docker-compose_*.yml` name it already globs | A second rollback script |
| Docker DNS | One `dns` key merged into the existing `daemon.json` | A new daemon config file |
| Resolver handoff | `handle_pihole_dns_replacement` after Tier 1 is up | A new DNS manager |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: firewall modes that match what the command prints
3. Operator day-to-day: an update that can roll back the compose pins it changed
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
