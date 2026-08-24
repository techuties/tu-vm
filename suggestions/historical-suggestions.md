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
| Compose stop uses 10s SIGKILL | No `stop_grace_period` on stateful services | Proposed | Stage 25 grace on postgres/qdrant/minio/tika. |
| Helper/processor run as PID 1 | `sh -c` / bare python, no tini | Proposed | Stage 25 `init: true` on first-party Python. |
| First-party workers run as root | Processor and MCP tools omit `user:` | Proposed | Stage 25 numeric non-root; helper docker.sock exception. |
| Processor polls MinIO every 10s | `CHECK_INTERVAL=10` vs 180s energy probes | Proposed | Stage 25 `${CHECK_INTERVAL:-60}` + env.example. |
| MCP tools have no fork cap | CPU/memory limits only | Proposed | Stage 25 `pids_limit` on sandboxes. |
| Host sysctl cannot prefer who swaps | Stage 24 host `vm.swappiness` is global | Proposed | Stage 25 per-container `mem_swappiness`. |
| Tika has no healthcheck | Dependents use `service_started`; Stage 24 assumed a probe | Proposed | Stage 25 official `/tika` HTTP probe. |

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
