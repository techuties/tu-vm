---
title: Historical Suggestions
description: Existing and previously mentioned improvement ideas consolidated into one roadmap.
---

# Historical Suggestions

This page tracks ideas already mentioned in project documentation and changelog history, then translates them into actionable community tasks.

## Sources Reviewed

- `CHANGELOG.md` (notably future enhancement sections)
- `README.md` (monitoring, dashboard, optimization, and operations sections)

## Consolidated Backlog

| Suggestion | Existing Evidence | Suggested Status | Next Action |
|---|---|---|---|
| Quick action profiles (Work/AI/Energy modes) | Changelog planned feature | Proposed | Design profile schema in `tu-vm.sh` and dashboard API. |
| Battery status surfaced in dashboard | Changelog planned feature + battery guidance in docs | Proposed | Add helper API endpoint for battery info and UI widget. |
| Auto-stop inactive heavy services | Changelog planned feature | Proposed | Implement idle timeout policy for Tier 2 services (opt-in). |
| Resource usage history charts | Changelog planned feature | Proposed | Persist daily snapshots and expose trend endpoint. |
| Service dependency auto-start | Changelog potential improvement | Proposed | Add dependency map (e.g. Open WebUI + Ollama) in control layer. |
| Usage analytics and recommendations | Changelog potential improvement | Proposed | Add privacy-preserving local-only telemetry summary. |
| Expanded mobile dashboard UX | Changelog potential improvement | Partial | Define responsive layout acceptance tests and improve touch targets. |
| Community contribution standardization | Implicit gap across docs | Proposed | Introduce shared suggestion + proposal workflow and templates. |
| Helper image is floating `python:3-alpine` | Only always-on official image still unpinned | Proposed | Stage 27 digest pin via existing `tu-vm.sh update` map until Stage 22 bake. |
| Helper has `/health` but no Compose probe | nginx `depends_on` helper without `service_healthy` | Proposed | Stage 27 probe `/health`; do not probe `/status`. |
| Hard CPU limits do not pick a winner | Ollama/Tika can stall Pi-hole and Postgres | Proposed | Stage 27 `cpu_shares` / `blkio_weight` (distinct from OOM). |
| Host cron JSON lives on `/tmp` | helper bind-mounts host `/tmp` | Proposed | Stage 27 dedicated `state/` bind; distinct from Stage 26 Tika file. |
| Non-root helper cannot open docker.sock | Stage 25 leftover; socket is `root:docker` 660 | Proposed | Stage 27 `group_add` + `DOCKER_GID`. |
| Helper has no cgroup budget | Nginx/Pi-hole already 256M; helper unbounded | Proposed | Stage 27 `deploy.resources` (512M until bake). |
| Helper mounts the raw Docker socket | Flask only needs container list/start/stop | Proposed | Stage 27 Tecnativa docker-socket-proxy. |

## Prioritization Framework

Use this scoring model when selecting the next suggestion:

- **Operator Impact (1-5):** Daily usability gain for non-expert users.
- **Risk Reduction (1-5):** Security, reliability, or rollback safety improvements.
- **Implementation Complexity (1-5):** Lower score means easier delivery.
- **Community Leverage (1-5):** How much this enables external contributions.

Prioritize by highest `(Impact + Risk Reduction + Community Leverage) - Complexity`.

## Suggested First Implementation Wave

1. Quick action profiles.
2. Battery status widget and endpoint.
3. Auto-stop inactive Tier 2 services (configurable).
4. Contribution workflow standardization.

## Review Cadence

- During each release, review this page and:
  - Mark shipped items as complete.
  - Move partial items to a concrete acceptance checklist.
  - Add new suggestions discovered in issues/discussions.
