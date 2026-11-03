---
title: Community Suggestions Website
description: Publishable Stage 67 website markdown for restart, quickstart flags, and the Compose command tu-vm.sh selects.
last_updated: 2026-11-03
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend so day-to-day restart, beginner quickstart, and Compose selection stay reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#91 already specify the docs framework, governance, and most product contracts. Stage 66 is on branch `cursor/community-suggestions-structure-7911`.

**Stage 67** (this run) records three defects checked on 2026-11-03. They are not restatements of Stages 1–66.

- `./tu-vm.sh restart` calls `stop_services` and then `start_services` with no mode argument. With the default `TU_VM_DEFAULT_MODE` of `portable`, a stack that was started with `./tu-vm.sh server` comes back as portable. `update_system` already snapshots `docker compose ps --services --status running` and restores that set.
- `./tu-vm.sh quickstart` documents `--server` and `--no-secure` as separate words. `main` passes only `"${2:-}"`. `quickstart --server --no-secure` therefore starts the full stack and still runs `enable_secure`. The reverse order skips the firewall and stays portable. The single token `--server-no-secure` is the only combination the function accepts.
- `get_docker_compose_cmd` in `tu-vm.sh` selects a `docker-compose` binary whenever `command -v` finds one. `scripts/doctor.sh`, `scripts/check-config.sh`, and `scripts/smoke-test.sh` ask `docker compose version` first and use `docker-compose` only when the plugin is absent. On this machine Compose is v5.1.0 and `docker-compose` is absent, so both paths print `docker compose`. A `docker-compose` stub placed first on `PATH` is what `tu-vm.sh` selects, while the three scripts still select `docker compose`.

The contracts:

- Restart the services that were running, and recreate the services that were stopped without starting them, using the same Compose status filters `update_system` already uses.
- Parse every word after `quickstart`, and allow `--server` together with `--no-secure`.
- Select the Compose CLI with the plugin-first order the doctor, check-config, and smoke scripts already share.

No second process manager, installer, or Compose distribution.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–66 website pages (open PRs #27–#91 and the Stage 66 branch) | Implement those contracts in code; leave their pages as they are |
| `update_system` running and stopped service lists | The restart behavior to copy |
| `quickstart_beginner`, `setup_platform`, `start_services`, `enable_secure` | The beginner path to keep |
| `compose_cmd` in `doctor.sh`, `check-config.sh`, and `smoke-test.sh` | The Compose selection order `tu-vm.sh` should match |

Stage 66 owns `stop_services` (`docker compose down` versus `docker compose stop`). This stage calls `stop_services` and leaves that function unchanged. Stage 65 (open PR #91) owns container prune. The beginner quickstart contribution page on branch `cursor/community-suggestions-system-0fa7` owns portable-by-default onboarding. This stage only fixes argument parsing on that same command.

## Page map (Stage 67)

| Page | Purpose |
|---|---|
| [Restart preserves the running set](./restart-preserves-running-set-contract.md) | `./tu-vm.sh restart` must bring back the services that were running |
| [Quickstart flag combination](./quickstart-flag-combination-contract.md) | `--server` and `--no-secure` must work together |
| [Compose CLI selection](./compose-cli-selection-contract.md) | `tu-vm.sh` must pick the same Compose CLI the other scripts already pick |

## Expected sibling pages

Stages 1–66 are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Leave those files uncopied here.

Representative filenames only: `openwebui-audio-model-parameter-contract.md`, `stop-preserves-containers-contract.md`, `optional-command-argument-contract.md`, `pihole-webpassword-quote-contract.md`, `backup-running-gate-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 67** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Restart target | `docker compose ps --services --status`, already used in `update_system` | A second record of which mode was last used |
| Quickstart flags | The `case` arms already inside `quickstart_beginner` | A new CLI parser |
| Compose CLI | Plugin-first `compose_cmd` already in three scripts | Installing or pinning another Compose binary |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: Restart brings back the services that were running
3. Operator day-to-day: Quickstart accepts `--server` and `--no-secure` together
4. Contributor day-to-day: `tu-vm.sh` and `doctor` use the same Compose CLI

When a static site is adopted, move or mount these pages into the docs content root. Keep a single editable copy.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
