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
| Chromium /dev/shm is 64MB | browserless and mcp-playwright omit `shm_size` | Proposed | Stage 26 `shm_size: 1gb` on Chromium services. |
| n8n-mcp image is `:latest` | Only official sidecar still unpinned | Proposed | Stage 26 digest pin via existing `tu-vm.sh update` map. |
| MCP tools auto-start on reboot | filesystem/fetch/memory use `unless-stopped` | Proposed | Stage 26 `restart: "no"` to match Tier 2. |
| Tika and MinIO have no cgroup limits | Other Tier 1 services set `deploy.resources` | Proposed | Stage 26 limits; keep Tika `-Xmx1536m` under 2G. |
| Processor scratch uses host `/tmp` | Shared bind with helper status JSON | Proposed | Stage 26 relocate `STATUS_FILE` then processor tmpfs. |
| Postgres/MinIO inherit 1024 fds | Only nginx sets `ulimits.nofile` | Proposed | Stage 26 copy Nginx 65535 block to datastores. |
| OOM killer treats Ollama and Pi-hole as peers | No `oom_score_adj` | Proposed | Stage 26 sacrifice Ollama/Tika before DNS/DB. |

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
