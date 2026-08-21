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
| Helper apk/pip on every start | `helper_index` `command:` installs docker-cli and Flask at boot | Proposed | Stage 22 bake `helper/Dockerfile`; keep `./helper:/app`. |
| Postgres restore is dump-only | `create_backup()` `pg_dump` + `postgres_data` tar; no WAL policy | Proposed | Stage 22 name dump-only default; opt-in WAL/PITR behind `tu-vm.sh`. |
| Digest pins are unverified | Compose `@sha256:`; Trivy is config; no cosign | Proposed | Stage 22 opt-in `cosign verify` on the signed subset. |
| Secrets only in `.env` | Interpolation; no Compose `secrets:` | Proposed | Stage 22 keep `.env` onboarding; optional `*_FILE` mounts. |
| Qdrant backup is volume-only | `docker_qdrant_data` tar; no snapshot API | Proposed | Stage 22 official Qdrant snapshots + compaction playbook. |
| Log driver unnamed | Daemon `json-file` in CHANGELOG; no Compose `logging:` | Proposed | Stage 22 json-file default; opt-in journald. |
| Helper live-reload undocumented | `./helper:/app` already mounts; no Compose Watch | Proposed | Stage 22 document bind-mount; optional `develop.watch`. |

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
