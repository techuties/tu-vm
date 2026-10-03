---
title: Community Suggestions Website
description: Publishable Stage 49 website markdown for the announcement roster, the unwired Open WebUI init hook, Nginx TLS cipher names, and the duplicated pull request checklist.
last_updated: 2026-10-03
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#74 already specify the docs framework, governance, and most product contracts.

**Stage 49** (this run) records four defects checked on 2026-10-03 against the tree on `dev`. They are not restatements of Stages 1–48.

- The landing-page announcement banner only watches twelve containers. Compose defines twenty-four. AFFiNE, the MCP gateway, LangGraph, Browserless, n8n-mcp, and the MCP tool containers can crash-loop while the banner still says all systems are operational. The daily checkup already writes `/tmp/tu-vm-health-status.json`, and nothing in the repo reads that file.
- `scripts/init-openwebui.sh` is mode `0755`, ends in `exec "$@"`, and is bind-mounted into Open WebUI. The `open-webui` service sets neither `entrypoint` nor `command`. The pinned image config (`linux/amd64`, Cmd `bash start.sh`, empty Entrypoint) never calls the script. README still calls the file an init hook.
- Eight HTTPS server blocks repeat `ssl_ciphers` names `ECDHE-RSA-AES256-GCM-SHA512` and `DHE-RSA-AES256-GCM-SHA512`. OpenSSL 3.0.13 reports `no cipher match` for each of those names alone. The combined string still loads, and the only TLS 1.2 suites it selects are the two SHA-384 names.
- `.github/pull_request_template.md` contains two `## Verification` headings and a second copy of the security checkboxes with no heading. Contributors see the same day-to-day checklist twice.

The contracts:

- Drive the banner and the checkup from the Compose container roster, and read the health file the checkup already writes
- Run the existing init script as the Open WebUI entrypoint so the image command still starts the app
- Keep one Nginx cipher include whose names OpenSSL accepts
- Keep one copy of the pull request checklist

No new suggestion queue, voting database, status product, TLS terminator, or Open WebUI fork.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`.github/pull_request_template.md`](../../.github/pull_request_template.md) | The checklist to deduplicate |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–48 website pages (open PRs #27–#74) | Implement those contracts in code; do not rewrite them here |
| Helper `/announcements` and `TIER1_CONTAINERS` | The banner roster to extend |
| `scripts/daily-checkup.sh` health JSON | The file the banner should read |
| `scripts/init-openwebui.sh` | The hook to invoke |
| `ssl_ciphers` in `nginx/conf.d/default.conf` | The suite list to correct once |
| Pinned Open WebUI image Cmd `bash start.sh` | The process the hook must exec |

Do **not** republish Stage 47 checkup `docker ps` name matching, Stage 44 update-status timezone handling, Stage 48 startup gating, the Qdrant `curl` probe, Tika readiness, or the pipeline-worker card. Stage 15 owns the init-script contribution lane. This stage only wires the hook Compose currently skips.

## Page map (Stage 49)

| Page | Purpose |
|---|---|
| [Announcement service roster](./announcement-service-roster-contract.md) | The banner must cover the containers Compose actually runs |
| [Open WebUI init hook](./openwebui-init-hook-unwired-contract.md) | The mounted script has to be the entrypoint |
| [Nginx TLS cipher names](./nginx-tls-cipher-suite-contract.md) | Drop suite names OpenSSL does not implement |
| [Pull request checklist](./pr-template-checklist-contract.md) | One security section and one verification section |

## Expected sibling pages

Stages 1–48 live on open PRs #27–#74 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `dashboard-announcements-contract.md`, `open-webui-init-firstboot-contract.md`, `daily-checkup-container-state-contract.md`, `nginx-login-rate-limit-contract.md`, `tier1-startup-gate-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 49** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Operational banner | Helper `/announcements` plus the checkup JSON | A new alerting product |
| First-boot patch | The existing init script as entrypoint | A fork of Open WebUI |
| TLS policy | One Nginx `include` snippet | A second reverse proxy |
| Review checklist | The existing pull request template | A custom review bot |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: announcement roster, then the init hook
3. Edge day-to-day: one TLS cipher include
4. Contributor day-to-day: a single pull request checklist

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
