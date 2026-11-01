---
title: Community Suggestions Website
description: Publishable Stage 65 website markdown for the Pi-hole admin password default, stopped-container cleanup, and the weekly apt upgrade.
last_updated: 2026-11-01
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day admin login, on-demand start, and the weekly update reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#90 already specify the docs framework, governance, and most product contracts.

**Stage 65** (this run) records three defects checked on 2026-11-01. They are not restatements of Stages 1–64.

- Pi-hole's Compose default is `${PIHOLE_PASSWORD:-'SwissPiHole2024!'}`. Compose v5.1.0 keeps the quote characters. With `PIHOLE_PASSWORD` unset or empty, `docker compose config` renders `WEBPASSWORD` as `'SwissPiHole2024!'`. The password operators type, and the string `generate_secrets` already compares, does not include those quotes.
- `./tu-vm.sh cleanup` runs `docker system prune -f`. A successful `./tu-vm.sh update` then runs `docker container prune -f`. Both remove stopped containers. `start` and `update` had just created Tier 2 containers with `--no-start` so the dashboard can start them. The helper start API returns 404 when that container is gone. On this Docker CLI, `docker volume prune -f` without `--all` removes anonymous volumes only. Named data volumes are not the defect.
- `update_system` runs `apt-get upgrade -y` before any image pull. Weekly cron calls that command and holds a lock for the whole run. `apt-get -y` answers apt's own questions. It does not pass the dpkg flags whose help text says "don't prompt". A config-file question has no operator on Sunday morning, and the lock stays held while that question is open.

The contracts:

- Give Pi-hole the same required-variable interpolation AFFiNE already uses, without quote characters around the fallback.
- Stop deleting stopped Compose containers from `cleanup` and from the post-update prune. Keep the named volumes where they are.
- Make the apt step in `tu-vm.sh update` use the dpkg options that do not prompt, so the weekly lock cannot sit on a config-file question.

No second password manager, container cleaner, or unattended-upgrades product.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–64 website pages (open PRs #27–#90) | Implement those contracts in code; do not rewrite them here |
| `AFFINE_DB_PASSWORD:?` in Compose | The required-variable form Pi-hole should copy |
| `generate_secrets` | Already replaces the unquoted Pi-hole default in `.env` |
| `docker compose up -d --no-start` | How stopped Tier 2 containers are created for the dashboard |
| `scripts/weekly-stack-update.sh` | The cron wrapper that already calls `tu-vm.sh update` |
| dpkg `--force-confdef` and `--force-confold` | The flags whose help text says not to prompt |

Stage 53 (open PR #79) owns teaching the start gate the unquoted Pi-hole default. Stage 54 (open PR #80) owns the global `CHANGE_ME_SECURE_PASSWORD` replace. Stage 55 (open PR #81) owns UFW rule order and the Pi-hole DNS restore call. Stage 46 (open PR #72) owns volume name prefixes. This stage does not edit those lines.

## Page map (Stage 65)

| Page | Purpose |
|---|---|
| [Pi-hole admin password quotes](./pihole-webpassword-quote-contract.md) | The Compose default must not include the quote characters |
| [Stopped container prune](./stopped-container-prune-contract.md) | Cleanup must leave the Tier 2 containers the dashboard starts |
| [Weekly apt prompt](./weekly-update-apt-prompt-contract.md) | `apt-get upgrade` in the weekly job must not wait on a config-file question |

## Expected sibling pages

Stages 1–64 live on open PRs #27–#90 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `startup-secret-gate-contract.md`, `secret-generation-identity-contract.md`, `firewall-command-order-contract.md`, `pihole-dns-restore-order-contract.md`, `backup-volume-prefix-contract.md`, `safe-update-wrapper-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 65** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Pi-hole password | Compose `${VAR:?message}` already used for AFFiNE | A second secrets service |
| Stopped Tier 2 containers | `docker compose up -d --no-start` plus the Docker start API | A new orchestrator |
| Disk cleanup | `docker image prune` for dangling images, and prune filters that skip Compose containers | `docker system prune` as one undifferentiated command |
| Weekly packages | `Dpkg::Options` on the apt command `tu-vm.sh` already runs | A second updater such as unattended-upgrades |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: the Pi-hole admin password matches the value in `.env`
3. Operator day-to-day: dashboard Start still finds on-demand containers after cleanup
4. Operator day-to-day: Sunday's package upgrade finishes without a question on the console

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
