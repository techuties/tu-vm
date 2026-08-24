---
title: Tika Healthcheck Honesty Contract
description: Constructional contract for adding a real Apache Tika live probe so Stage 24 depends_on service_healthy can apply, without a dummy exit 0 or a document-pipeline SaaS.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tika Healthcheck Honesty Contract

## Problem

`open-webui` and `tika_minio_processor` depend on `tika`, but the `tika` service in `docker-compose.yml` has **no `healthcheck` block**. Stage 24's depends_on contract assumed Tika already had a probe (alongside redis/qdrant/minio). That is not true on `dev` today:

- Tika publishes only `restart`, Java heap, a bind-mounted XML config, and a static IP.
- Dependents use `condition: service_started`, which is true as soon as the Java process exists — not when port **9998** answers.
- The processor comment says "Healthcheck disabled for on-demand service (Tier 2)" even though Tika **and** the processor are **Tier 1**.

Stage 13 covers **how to write an honest probe** in general. Stage 19 covers **Tika XML**. Stage 24 covers **which `depends_on` condition to use when a probe exists**. This page is the missing **Tika probe itself**, so Stage 24 can be implemented without inventing a fake check.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Apache Tika Server | `GET /tika` (or `/tika/text`) on 9998 returns 200 when live |
| `tika-config/tika-config.xml` | Parsers/OCR/timeouts; not liveness |
| Image already used by other probes | `curl` exists in several images; confirm Tika image or use `CMD-SHELL` wget |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Probe honesty rules |
| Stage 19 `tika-xml-config-contribution-contract.md` (expected sibling) | XML contribution |
| Stage 24 `compose-depends-on-health-contract.md` (expected sibling) | Flip to `service_healthy` **after** a probe exists |

Out of scope:

- Dummy `["CMD", "true"]` / `exit 0` so Compose shows green
- Changing OCR timeouts or heap in the same PR
- A Tika cluster, Kubernetes operator, or "document SaaS"
- Adding a helper API that proxies Tika health (dashboard can keep using processor status)

## Proposal

Add a **live HTTP probe** on `tika` using the server's own `/tika` endpoint. Then flip dependents to `service_healthy` (Stage 24). Use an energy-aware interval consistent with other local infra (`30s` like minio/qdrant is fine; do not copy unused `HEALTH_CHECK_*=30` as a global slider).

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Probe | `tika` healthcheck | `curl -fsS http://127.0.0.1:9998/tika` (or image-equivalent) |
| Start window | `start_period` | 30–60s for JVM + XML load |
| Dependents | `open-webui`, `tika_minio_processor` | Stage 24 `service_healthy` **after** this lands |
| Comment fix | processor block | Remove the false "Tier 2 / healthcheck disabled" comment |
| Energy | interval | `30s` local infra; do not set `180s` if Open WebUI would wait two minutes on a dead Tika |

### Rules

1. **Probe the HTTP API, not `pgrep java`.** A stuck JVM is not "healthy."
2. **No dummy success.** Stage 13 forbids `exit 0` placeholders.
3. **Do not wait on this page to invent depends_on.** If the probe is not merged yet, keep `service_started` and say why.
4. **Confirm curl exists in the pinned Tika image** or use a wget/CMD that the image actually has. Do not add a sidecar just to run curl.
5. **Interval is local infra, not the 180s dashboard tier.** A dead Tika should fail within a minute, not three.
6. **GitHub remains intake.** Requests for a managed document pipeline stay Issues.

### Suggested contributor checklist

```text
1. Confirm how the pinned apache/tika image exposes /tika
2. Add healthcheck with start_period for JVM
3. Use curl or wget already in the image; no sidecar
4. Flip open-webui and processor to service_healthy in the same or next PR
5. Fix the processor "Tier 2 healthcheck disabled" comment
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Liveness | Official Tika HTTP `/tika` | `pgrep`, dummy exit 0 |
| Start gating | Stage 24 `service_healthy` | wait-for-it sidecar |
| XML/OCR | Stage 19 bind-mount | Baking a new Tika image for a probe |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Tika `healthcheck` first; dependents' `service_healthy` immediately after (or same PR if tested).
3. Correct the processor comment so community PRs stop treating the worker as Tier 2.

## Acceptance criteria

- [ ] `tika` has a healthcheck that hits the HTTP API (not a dummy).
- [ ] `start_period` covers JVM + XML load.
- [ ] Probe binary exists in the pinned image (no curl sidecar).
- [ ] Processor comment no longer calls this path Tier 2 / healthcheck-disabled.
- [ ] `docker compose config` still renders.

## Rollback

Remove the Tika `healthcheck` and restore `service_started` on dependents. XML and volumes are unchanged.

## Success metrics

- Open WebUI and the processor do not start RAG/watch until Tika answers `/tika`.
- Stage 24 depends_on work can list Tika truthfully.
- Contributors add probes that match the official API instead of `exit 0`.
