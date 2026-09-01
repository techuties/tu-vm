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
| n8n Compose ships a public encryption default | `N8N_ENCRYPTION_KEY:-1e2f3a4b…` in Compose | Proposed | Stage 31 fail-closed or no published hex default. |
| Open WebUI has no public origin env | Nginx is `oweb.tu.lan`; Compose omits `WEBUI_URL` | Proposed | Stage 31 official `WEBUI_URL`. |
| Decorative `WEBUI_*` keys | `WEBUI_AUTH_SECRET` / rate-limit env vs upstream list | Proposed | Stage 31 wire-or-delete after citing official docs. |
| MinIO console URLs ignore `.env` | `env.example` has keys; Compose hardcodes `*.tu.lan` | Proposed | Stage 31 interpolate official MinIO URL env. |
| Helper TCP probes mix `ai_*` hosts | `/status/*` uses container names for sockets | Proposed | Stage 31 service DNS for probes; keep `container_name` for Docker API. |
| n8n / Pi-hole TZ still hardcoded | Stage 23 policy; Compose still `Europe/Zurich` | Proposed | Stage 31 `TU_VM_TZ` leftovers only. |
| Qdrant has no API key | Open listener on `ai_network` | Proposed | Stage 31 official Qdrant + Open WebUI key. |

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
