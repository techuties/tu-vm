---
title: Community Suggestions Website
description: Publishable Stage 44 website markdown for the helper project mount, helper image build, update-status files, image update checks, and host metric sources.
last_updated: 2026-09-28
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation safe for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#69 already specify the docs framework, governance, and most product contracts.

**Stage 44** (this run) records five defects checked on 2026-09-28 against the tree on `dev`. They are not restatements of Stages 1–43.

- `helper_index` bind-mounts the repository root at `/docker-project`. Nothing in `helper/uploader.py` reads that path. The process runs as root, so a mode `600` `.env` and `ssl/` private keys on that tree are readable inside the container.
- The same service uses floating `python:3-alpine` and runs `apk` plus `pip install` on every start, as root, beside the Docker socket. `tika-minio-processor/Dockerfile` already shows the build pattern to copy.
- `GET /updates` parses `last_check` with `datetime.now()` and, on failure, rewrites `/tmp/tu-vm-update-status.json` with `updates_available: false`. Host scripts write `date -Iseconds`, which includes a UTC offset. Python 3 raises `TypeError` when a naive clock is subtracted from that value, so the handler takes the failure path and erases a real checkup.
- `scripts/daily-checkup.sh` compares `docker inspect` `.Id` (image config id) with a registry manifest digest, and it looks up tag names that `docker-compose.yml` does not use. Fifteen of seventeen Compose `image:` lines are digest pins. The two floating references are `python:3-alpine` and `ghcr.io/czlonkowski/n8n-mcp:latest`.
- Dashboard memory, disk, and battery text come from files inside the helper container. Battery reads `/sys/class/power_supply/BAT0/`, which the helper service does not mount, so the historical battery widget never appears.

The contracts:

- Drop the unused repository mount
- Build the helper the same way the processor is built
- Keep one status directory, and do not let the helper invent a “no updates” file
- Compare registry manifest digests for the images Compose actually runs
- Read host metrics through narrow read-only files, or label them as container-local

No new suggestion queue, voting database, identity provider, update daemon, or metrics stack.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–43 website pages (open PRs #27–#69) | Implement those contracts in code; do not rewrite them here |
| [`.github/dependabot.yml`](../../.github/dependabot.yml) | Already updates GitHub Actions; the docker ecosystem is the matching knob for image bumps |
| [`tika-minio-processor/Dockerfile`](../../tika-minio-processor/Dockerfile) | Pattern for a pinned helper image |

Do **not** add Watchtower, Diun, a custom updater service, Prometheus, or a second dashboard. Do **not** republish Stage 11 log retention, Stage 22 journald, Stage 18 `no-new-privileges`, Stage 42 helper name fallthrough, Stage 42 Nginx `add_header` inheritance, Stage 42 processor byte caps, Stage 42 MCP pins, Stage 43 client-IP trust, or Stage 43 dashboard `textContent`.

Stage 18 owns the control token, the 401, and the fact that the Docker socket is a privileged review item. This stage does not remove the socket. Stage 12 owns announcement categories. Stage 43 owns how announcement strings are inserted into the page. This stage only covers **where status JSON is stored** and **that a parse failure must not rewrite it**.

## Page map (Stage 44)

| Page | Purpose |
|---|---|
| [Helper project mount](./helper-project-mount-contract.md) | Remove the unused repository bind so `.env` and TLS keys are not in the helper container |
| [Helper image build](./helper-image-build-contract.md) | Build the helper from a lockfile instead of installing packages on every start |
| [Update status file](./update-status-file-contract.md) | One status directory; the helper must not clobber a timezone-aware checkup |
| [Image update compare](./image-update-compare-contract.md) | Compare manifest digests for the Compose pins operators actually run |
| [Host metrics source](./host-metrics-source-contract.md) | Dashboard load, memory, disk, and battery read a declared host source |

## Expected sibling pages

Stages 1–43 live on open PRs #27–#69 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `how-to-submit.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, `helper-control-auth-contract.md`, `dashboard-announcements-contract.md`, `helper-control-service-allowlist-contract.md`, `helper-client-ip-trust-contract.md`, `dashboard-untrusted-text-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 44** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Helper dependencies | Dockerfile plus `requirements.txt`, as the processor already does | `pip install` on container start |
| Image bump PRs | Dependabot `package-ecosystem: docker` next to the existing Actions entry | A new update product |
| LAN “what changed” | The existing checkup script, pointed at Compose `image:` lines | A second tag list maintained by hand |
| Host numbers | Narrow read-only files the helper already knows how to read | A new metrics stack for four KPIs |
| Status handoff | One directory shared by checkup, processor, and helper | Host `/tmp` plus a per-user fallback the dashboard never reads |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Control day-to-day: token (Stage 18), service names (Stage 42), client IP (Stage 43), then helper mount and image build
3. Operator day-to-day: update status files, image digest compare, host metric sources
4. Quality gates: merge playbook

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas, including the battery widget this stage corrects
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
