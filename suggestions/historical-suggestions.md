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
| Nginx hardcoded upstream IPs | Product vhosts use `172.20.0.x`; landing uses `helper_index` | Proposed | Stage 21 Docker-DNS `proxy_pass` with `resolver 127.0.0.11`. |
| Platform Redis volume unused | `redis_data` mounted; `--appendonly no --save ""` | Proposed | Stage 21 explicit AOF/RDB policy for `ai_redis` only. |
| Helper is one Flask file | `helper/uploader.py` ~1000 lines | Proposed | Stage 21 in-tree modules; keep one Flask entrypoint. |
| ARM64 / multi-arch pins | Digest pins; checkup already maps `uname -m` | Proposed | Stage 21 multi-arch index digests; no second compose file. |
| Podman / rootless Docker | Scripts assume Docker Engine + compose v2 | Proposed | Stage 21 `DOCKER_HOST` shim; distinct from WSL2. |
| No LSM profiles | Compose has limits, no `security_opt` | Proposed | Stage 21 AppArmor/seccomp on top of Stage 18 cap_drop. |
| Incremental encrypted backups | `create_backup()` tar.gz + rclone offsite | Proposed | Stage 21 optional restic/borg behind `tu-vm.sh backup`. |

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
