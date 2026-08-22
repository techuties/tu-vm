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
| Repeated Nginx TLS stanzas | Sixteen `server` blocks copy `ssl_certificate` and headers | Proposed | Stage 23 extract `nginx/snippets/` includes; optional Compose `configs:`. |
| MinIO has no object history | `setup_minio_buckets` only `mc mb` | Proposed | Stage 23 opt-in `mc version` / `mc ilm` on pipeline buckets. |
| Nginx rootfs is writable | Config mounts are `:ro`; image root is not | Proposed | Stage 23 `read_only` + tmpfs for pid/cache. |
| Postgres GUCs are ignored | `POSTGRES_SHARED_BUFFERS` env is not official image config | Proposed | Stage 23 `postgres -c` plus `statement_timeout`. |
| Qdrant memory is untuned | 1G limit, no config, engine HNSW defaults | Proposed | Stage 23 official config / quantization; no second vector DB. |
| Timezones disagree | n8n hardcodes Zurich; cron has a separate TZ; others UTC | Proposed | Stage 23 one `TU_VM_TZ`; host NTP; no time container. |
| Single Compose bridge | All services on `ai_network` 172.20.0.0/16 | Proposed | Stage 23 role networks; keep Stage 18 IPAM and Stage 19 Fetch deny. |

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
