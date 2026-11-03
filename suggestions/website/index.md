---
title: Community Suggestions Website
description: Publishable Stage 66 website markdown for the Open WebUI audio repair, stack stop, and optional tu-vm.sh arguments.
last_updated: 2026-11-02
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day audio repair, stack stop, and the help text reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#91 already specify the docs framework, governance, and most product contracts.

**Stage 66** (this run) records three defects checked on 2026-11-02. They are not restatements of Stages 1–65.

- `fix-openwebui-audio` pastes the model into a double-quoted `psql -c` string. A model value `o'brien` produces SQL text `'"o'brien"'`, which is not one string literal. The same command writes the Redis engine as the characters `"openai"`, and the checker compares that raw value to `openai`.
- `./tu-vm.sh stop` runs `docker compose down`. Compose v5.1.0 describes that command as stop and remove containers and networks. `stop-service` already uses `docker compose stop`, which leaves the container in place. The helper start API returns 404 when the container is gone.
- `tu-vm.sh` sets `set -u`. Help lists `logs [service]`, `pdf-logs [service]`, and `backup [name]` as optional. Those three arms, and `restore`, pass `"$2"`. With no second word, Bash 5.2.21 exits on an unbound `$2` before the function can print usage or apply its default name.

The contracts:

- Pass the speech-to-text model through `psql -v` and a JSON encoder, and normalize the Redis engine with the helper the checker already uses for the model.
- Make `./tu-vm.sh stop` stop containers the way `stop-service` already does, so a later dashboard Start still finds them.
- Pass `"${2:-}"` from `main` so the functions that already document an optional argument actually run.

No second speech-to-text service, container orchestrator, or argument parser.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–65 website pages (open PRs #27–#91) | Implement those contracts in code; do not rewrite them here |
| `psql -v` and `:'variable'` | The client quoting the audio repair should use |
| `docker compose stop` in `stop_single_service` | The stop behavior the all-services command should copy |
| `${2:-}` on `start-service`, `whitelist-add`, and `fix-openwebui-audio` | The optional-argument form already used in `main` |

Stage 53 (open PR #79) owns Postgres and Redis passwords on the probes that forgot them. The audio tools already pass those passwords. Stage 65 (open PR #91) owns `docker system prune` and `docker container prune`. Stage 63 (open PR #89) and Stage 64 (open PR #90) own the inside of `create_backup`. Stage 47 (open PR #73) owns backup restore apply. This stage does not edit those lines.

## Page map (Stage 66)

| Page | Purpose |
|---|---|
| [Open WebUI audio model parameter](./openwebui-audio-model-parameter-contract.md) | The repair must pass the model as data, and the checker must read it back as data |
| [Stop preserves containers](./stop-preserves-containers-contract.md) | `./tu-vm.sh stop` must leave containers for the dashboard Start button |
| [Optional command arguments](./optional-command-argument-contract.md) | Help text that marks an argument optional must survive `set -u` |

## Expected sibling pages

Stages 1–65 live on open PRs #27–#91 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `pihole-webpassword-quote-contract.md`, `stopped-container-prune-contract.md`, `service-probe-credentials-contract.md`, `backup-running-gate-contract.md`, `backup-restore-apply-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 66** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| SQL model value | `psql -v` and `:'model'` | A new settings service |
| JSON Redis value | `json.dumps` in the Python the repo already runs | Hand-built quote characters |
| Stop the stack | `docker compose stop`, already used for one service | A second process manager |
| Optional CLI words | `"${2:-}"`, already used in this `case` | A new argument framework |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: audio repair stores the model that was typed
3. Operator day-to-day: Stop leaves containers the dashboard can start
4. Operator day-to-day: `logs`, `pdf-logs`, and `backup` follow the help text

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
