---
title: Container Log Retention Contract
description: Constructional contract for day-to-day container and nginx log retention that reuses Docker logging limits and local rotation instead of inventing a log-shipping platform.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Container Log Retention Contract

## Problem

Disk pressure often comes from unbounded container logs, nginx access logs, and cron append files—not only from named volumes. Historical suggestions jump to ELK/Loki stacks or cloud log drains that fight LAN-first privacy. Operators need a **boring retention contract** that keeps day-to-day log growth in check using tools already available on a Docker host.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Docker json-file logging (Compose default) | Container stdout/stderr |
| `nginx_logs` volume / nginx log files | Edge access/error logs |
| Cron append logs (MinIO sync, checkup) | Host files under `/var/log` patterns |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Metrics/dashboards (not log SaaS) |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Disk pressure ladder / volume cleanup |
| Stage 11 `host-cron-maintenance-contract.md` (sibling) | Cron job log paths |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | What is / is not backed up |

Out of scope:

- Mandating a centralized logging SaaS or always-on Loki/ELK Tier 1 stack
- Shipping private request bodies, tokens, or chat prompts to third parties
- Replacing metrics/observability contracts with log scraping as the only signal
- Committing production log dumps into the repository

## Proposal

Publish a **container log retention contract** with practical defaults and contribution lanes.

### Retention baseline (suggested defaults)

| Source | Guidance |
|---|---|
| Compose services | Prefer json-file options with `max-size` / `max-file` when changing logging config |
| Nginx logs | Rotate or truncate via documented operator steps; do not grow forever on small disks |
| Host cron logs | `logrotate` snippets or size-aware truncation notes beside cron contract |
| Support bundles | Redact secrets; sample tails only (PR #25 direction) |

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Compose logging options | `docker-compose.yml` service logging | Disk impact notes; rollback |
| Nginx log guidance | playbooks / README | Commands; restart/reload notes |
| Cron log hygiene | cron scripts / docs | Ties to host-cron contract |
| Disk playbooks | `#playbook-disk-pressure` adjacency | Before/after `df` evidence |
| Observability | metrics alerts on disk | Stage 6 observability lane—not full log export |

### Rules

1. **Local-first.** Retention happens on the host; remote shipping is opt-in and Decision-Logged if proposed as default.
2. **Size bounds beat infinite keep.** Document max-size strategies for chatty services (browserless, gateways, nginx).
3. **Privacy.** Logs may contain URLs, tokens, or prompts—treat exports like secrets.
4. **Coordinate with disk pressure.** Cleanup order should align with Stage 10 disk ladder (logs before reckless volume deletes).
5. **Do not gitignore-abuse.** Operator log files stay untracked; do not “fix” CI by committing truncated prod logs.
6. **Metrics ≠ log drain.** Prefer Prometheus/Grafana for health trends (Stage 6) when the goal is alerting.
7. **GitHub remains intake.** Retention redesigns are Issues/PRs.

### Suggested playbook shape

```text
#playbook-log-retention
1. df -h && docker system df
2. Identify largest container logs / nginx_logs / cron logs
3. Apply documented truncate/rotate or Compose logging max-size change
4. Re-check disk; avoid deleting named data volumes as a first step
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Container log caps | Docker json-file max-size/max-file | Custom log sidecar per service by default |
| Host file rotation | logrotate / documented truncate | Manual `rm -rf` of unknown paths |
| Alerting | Existing monitoring lane | Shipping all nginx logs offsite |
| Privacy | Redacted tails | Pasting full access logs into Issues |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-log-retention` when implementing docs polish.
3. Cross-link Stage 10 disk pressure, Stage 6 observability, and Stage 11 host-cron pages.
4. Consider Compose logging options only with smoke that services still start.

## Acceptance criteria

- [ ] Baseline table covers Compose, nginx, and cron log sources.
- [ ] Local-first and privacy rules are explicit.
- [ ] Disk-pressure coordination discourages deleting data volumes first.
- [ ] Remote log shipping is not the documented default.
- [ ] Contribution lanes identify where Compose vs docs changes belong.

## Rollback

Remove Compose logging option changes; restore previous nginx/cron log files from backup if needed. Retention docs can revert without affecting Tier 1 app data volumes.

## Success metrics

- Fewer disk-full incidents attributed to unbounded logs.
- Log-related PRs include size bounds and privacy notes.
- Disk Issues distinguish log growth from volume data growth.
