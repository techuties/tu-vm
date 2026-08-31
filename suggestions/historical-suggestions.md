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
| Pi-hole v6 ignores v5 env names | Compose still sets `WEBPASSWORD` / `PIHOLE_DNS_` / `ServerIP` | Proposed | Stage 30 official `FTLCONF_*`; keep `PIHOLE_PASSWORD`. |
| `MINIO_ROOT_USER` is documentation-only | Compose and processor hardcode `admin` | Proposed | Stage 30 interpolate the env key everywhere. |
| MCP / processor still default to `ai_*` hosts | Stage 28/29 moved Postgres and Open WebUI Tika | Proposed | Stage 30 leftover service-DNS defaults. |
| n8n behind Nginx without hop/cookie env | Vhost already sets `X-Forwarded-*` | Proposed | Stage 30 `N8N_PROXY_HOPS` + `N8N_SECURE_COOKIE`. |
| Qdrant / MinIO probes assume `curl` | Minimal vendor images | Proposed | Stage 30 image-honest `wget` / `mc ready`. |
| Compose project follows clone directory | No top-level `name:` | Proposed | Stage 30 `name: tu-vm`. |
| `N8N_PASSWORD` looks like editor login | Keys only reach `mcp_gateway` | Proposed | Stage 30 rename or annotate; no deprecated basic auth. |

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
