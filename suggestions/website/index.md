---
title: Community Suggestions Website
description: Publishable Stage 68 website markdown for the allowlist writer, the weekly cron clock, and dual-stack Pi-hole records.
last_updated: 2026-11-04
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend so day-to-day allowlist edits, the Sunday update, and `*.tu.lan` stay reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, Pi-hole, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#93 already specify the docs framework, governance, and the product contracts through Stage 67.

**Stage 68** (this run) records three defects checked on 2026-11-04. They are not restatements of Stages 1–67.

- `./tu-vm.sh whitelist-add` and `whitelist-remove` embed a Python writer in a quoted heredoc. The writer does not compile, so a normal documentation address never reaches the allowlist file. The IP check above that writer pastes the operator's argument into Python source. The helper API already writes the same file with `ipaddress` and an atomic replace.
- `ensure_weekly_update_cron_job` documents Sunday 03:30 Europe/Zurich. The line it builds is `30 3 * * 0 TZ=Europe/Zurich …`. Debian cron 3.0pl1 treats `TZ=` as part of the command. The daemon still fires from `/etc/localtime`. This host is `Etc/UTC`, so 03:30 UTC that Sunday is 04:30 in Zurich, and 03:30 in Zurich is 02:30 UTC.
- `sync_pihole_dns_records` writes `address=` names into the bind-mounted dnsmasq file when only one IP is known. With both a LAN IP and a Tailscale IP it writes upstream resolvers only, returns success, and copies host lines into the container only when `ai_pihole` is already running. The mounted file never gains `addn-hosts` or `hostsdir`.

The contracts:

- Write the allowlist with the helper's argv-and-`ipaddress` writer, including the validation step.
- Fire the weekly update when the clock in Europe/Zurich says 03:30, using the child `date` test Debian cron already documents.
- Publish both `*.tu.lan` addresses in the bind-mounted dnsmasq file the single-IP branch already maintains.

No second allowlist service, scheduler, or DNS server.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–67 website pages (open PRs #27–#93) | Implement those contracts in code; leave their pages as they are |
| Helper `_write_allowlist` | The allowlist writer `tu-vm.sh` should match |
| `scripts/weekly-stack-update.sh` | The Sunday job body to keep |
| Single-IP `address=` lines in `sync_pihole_dns_records` | The DNS record shape the dual-stack branch should also leave on disk |

Stage 13 (open PR #39) owns allowlist policy: default deny, no production addresses in git, local-console recovery. This stage only makes `whitelist-add` and `whitelist-remove` able to write the file the helper already writes. Stage 23 (open PR #49) owns one operator timezone name for containers. This stage only fixes when the weekly cron line runs. Stage 30 (open PR #56) owns Pi-hole v6 `FTLCONF_*` names. This stage leaves those names alone and fixes the file `sync_pihole_dns_records` writes today. Stage 65 (open PR #91) owns `apt-get` prompts inside `update_system`.

## Page map (Stage 68)

| Page | Purpose |
|---|---|
| [Allowlist writer syntax](./whitelist-writer-syntax-contract.md) | `whitelist-add` and `whitelist-remove` must run the helper's writer |
| [Weekly cron schedule clock](./weekly-cron-schedule-timezone-contract.md) | Sunday 03:30 Europe/Zurich must be the time the job actually runs |
| [Dual-stack DNS records](./pihole-dual-stack-dns-record-contract.md) | LAN and Tailscale names must land in the mounted dnsmasq file |

## Expected sibling pages

Stages 1–67 are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Leave those files uncopied here.

Representative filenames only: `ip-allowlist-day2-contract.md`, `host-timezone-ntp-contract.md`, `pihole-v6-ftlconf-env-contract.md`, `weekly-update-apt-prompt-contract.md`, `restart-preserves-running-set-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 68** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Allowlist file | Helper `_normalize_allow_entry` and `_write_allowlist` | A second file format |
| Sunday schedule | Debian cron's child `date` test, in the existing installer | Another scheduler or `CRON_TZ` |
| `*.tu.lan` | `address=` lines already written for one IP, in the mounted conf | A new DNS container |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: Allowlist add and remove write the same file the dashboard writes
3. Operator day-to-day: The weekly update runs at 03:30 Europe/Zurich
4. Operator day-to-day: `*.tu.lan` resolves on LAN and Tailscale from the mounted dnsmasq file

When a static site is adopted, move or mount these pages into the docs content root. Keep a single editable copy.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
