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
| First-boot health waits a full `interval` | Compose `interval: 180s` without `start_interval` | Proposed | Stage 29 native `start_interval`; keep energy-aware interval. |
| Nginx cannot go read-only yet | Official image writes `/run` and `/var/cache/nginx` | Proposed | Stage 29 tmpfs runtime; then Stage 23 `read_only`. |
| n8n filesystem binary path is implicit | `N8N_BINARY_DATA_MODE=filesystem` and no prune | Proposed | Stage 29 named directory + `EXECUTIONS_DATA_PRUNE`. |
| No Compose service catalog labels | Tier tables live in README / comments / scripts | Proposed | Stage 29 `tu-vm.tier` / `tu-vm.role` labels. |
| Open WebUI / processor use `ai_tika` | Service DNS already used for ollama/postgres | Proposed | Stage 29 `tika` / `minio` hosts; keep `container_name`. |
| Postgres `/dev/shm` stays 64MB | `shared_buffers` default 256MB | Proposed | Stage 29 `shm_size` on both Postgres services. |
| Redis probe puts password on argv | `redis-cli -a` in healthcheck | Proposed | Stage 29 `REDISCLI_AUTH`; not Stage 24 ACL. |

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
