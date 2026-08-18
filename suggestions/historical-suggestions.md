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
| Community contribution standardization | Implicit gap across docs | Partial | GitHub Issue/PR templates + CONTRIBUTING exist; publishable contracts live in `suggestions/website/`. |
| Processor Python vs second worker | `tika-minio-processor/` universal modules | Proposed | Stage 20 Python contract—watch/retry/status stay in the Alpine image. |
| Nginx stub_status vs public metrics | Commented nginx scrape job; no stub_status | Proposed | Stage 20 internal stub_status paired with opt-in exporter. |
| AFFiNE Redis ephemeral | `--save "" --appendonly no`; no volume | Proposed | Stage 20 named volume + explicit AOF/RDB policy. |
| IPv6 dual-stack | IPv4-only IPAM and Nginx listens | Proposed | Stage 20 IPv4-first; dual-stack is all-or-nothing. |
| Start on login / reboot | Manual `tu-vm.sh start` | Proposed | Stage 20 systemd `--user` oneshot unit. |
| Windows contributor path | CONTRIBUTING is Linux-oriented | Proposed | Stage 20 WSL2 + same bash scripts; no `/mnt/c` clones. |
| n8n login vs webhooks | Single `location /` on n8n.tu.lan | Proposed | Stage 20 prefix split before applying `zone=login`. |

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
