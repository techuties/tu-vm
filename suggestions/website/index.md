---
title: Community Suggestions Website
description: Publishable Stage 48 website markdown for Tier 1 startup gating, the Qdrant health probe, Tika readiness, and the document-pipeline worker on the landing page.
last_updated: 2026-10-02
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation safe for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#73 already specify the docs framework, governance, and most product contracts.

**Stage 48** (this run) records four defects checked on 2026-10-02 against the tree on `dev`. They showed up because Qdrant, Tika, MinIO, and the MinIO processor are Tier 1. They are not restatements of Stages 1–47.

- `check_service_health` in `tu-vm.sh` treats Docker health `starting` as failure. `wait_for_services` gives each Tier 1 service about 20 seconds. PostgreSQL, Redis, Open WebUI, Pi-hole, and Nginx use a 180 second health interval, so a recreated container is still `starting` when the waiter stops. The failure branch skips Pi-hole DNS sync, MinIO bucket setup, the rclone mount, and the cron installers.
- The pinned Qdrant image (`qdrant/qdrant@sha256:75eab8c4ba42096724fdcfde8b4de0b5713d529dde32f285a1f86fdcb2c9e50c`, built 2026-06-03) installs `ca-certificates`, `tzdata`, and `libunwind8`. It does not install `curl`. The Compose healthcheck is `curl -sf http://localhost:6333/healthz`. After the 20 second start period and five failed retries, Docker marks `ai_qdrant` unhealthy and leaves it that way. Every later `./tu-vm.sh start` then takes the failure branch above.
- Apache Tika is Tier 1 and Open WebUI points `TIKA_SERVER_URL` at it, but the service has no healthcheck. The pinned image (`apache/tika@sha256:90b7fa1dc018434075fce9e1d9b88b1e3d0ea6979d0cf86e116c79a8073ae973`, built 2026-05-27) installs only `openjdk-21-jre-headless` and `ca-certificates`. Open WebUI and `tika_minio_processor` wait on `service_started`, which is true before port 9998 listens. The processor comment still says the healthcheck is disabled because the service is Tier 2.
- The helper already lists `tika_minio_processor` as Tier 1, and Nginx already proxies `/status/tika-processor`. The landing page Tier 1 grid and its `SERVICES` list never poll that route, so the always-on pipeline worker is invisible. Qdrant, MinIO, and Tika still have Stop buttons. PostgreSQL and Redis, the other always-on data services, do not.

The contracts:

- Let `starting` finish, and run MinIO bucket setup when MinIO is up
- Probe Qdrant with a program that image already contains
- Add a Tika readiness check the pinned image can run, and wait on it
- Show the pipeline worker with the status route Nginx already has

No new suggestion queue, voting database, health agent, custom Qdrant image, or second dashboard API.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–47 website pages (open PRs #27–#73) | Implement those contracts in code; do not rewrite them here |
| `check_service_health` / `wait_for_services` | The startup gate to fix |
| Compose `healthcheck` on the services that already have one | The probe and interval to correct |
| Helper `TIER1_CONTAINERS` and `/status/tika-processor` | The worker status the landing page should display |
| `setup_minio_buckets` | The first-boot step the startup gate must still reach |

Do **not** add a second orchestrator, a custom Qdrant or Tika image whose only job is to install `curl`, or a new status microservice. Do **not** republish Stage 44 host metrics or image digest compare, Stage 46 MinIO `mc` transport and backup volume prefixes, Stage 47 checkup container identity, checkup writes, backup restore, or write-approval fail-closed behavior. Stage 19 (open PR #45) owns `tika-config.xml`. This stage does not edit that file.

## Page map (Stage 48)

| Page | Purpose |
|---|---|
| [Tier 1 startup gate](./tier1-startup-gate-contract.md) | A health status of `starting` must not skip bucket setup and cron |
| [Qdrant health probe](./qdrant-healthcheck-probe-contract.md) | The pinned image has no `curl` |
| [Tika pipeline readiness](./tika-pipeline-readiness-contract.md) | Wait until Tika listens, with a probe the image can run |
| [Pipeline worker on the dashboard](./pipeline-worker-dashboard-contract.md) | Poll `/status/tika-processor` from the Tier 1 grid |

## Expected sibling pages

Stages 1–47 live on open PRs #27–#73 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `how-to-submit.md`, `docs-framework-adoption.md`, `stage-merge-playbook.md`, `tika-xml-config-contribution-contract.md`, `minio-mc-client-transport-contract.md`, `daily-checkup-container-state-contract.md`, `backup-restore-apply-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 48** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Startup gate | `wait_for_services` and Compose `healthcheck` | A new supervisor process |
| Qdrant probe | A binary already in the pinned image | A fork of `qdrant/qdrant` that adds `curl` |
| Tika readiness | Compose `healthcheck` plus `condition: service_healthy` | A wrapper image around `apache/tika` |
| Worker status | Existing `/status/tika-processor` | A second processor status service |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: startup gate, then Qdrant and Tika readiness
3. Dashboard day-to-day: pipeline worker card, beside the existing Tier 1 grid
4. Safety and backup contracts from Stages 45–47, unchanged by this stage

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
