---
title: Daily Checkup Contribution Contract
description: Constructional contract for community contributions that extend scripts/daily-checkup.sh and the update-status JSON surface—without inventing a monitoring SaaS or second health platform.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Daily Checkup Contribution Contract

## Problem

Operators need a quiet, scheduled pulse on Tier 1 health and update readiness. Historical suggestions invent always-on RMM agents, cloud health dashboards, or duplicate Prometheus for “is the stack up?”. TU-VM already has `scripts/daily-checkup.sh` writing a local status artifact. Contributors need a **reuse-first contract** distinct from interactive doctor/diagnose and from digest-pin updates.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/daily-checkup.sh` | Scheduled health + update-status writer |
| `/tmp/tu-vm-update-status.json` (host path used by checkup) | Local status artifact for dashboard/helper consumers |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install/remove hygiene |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Interactive `doctor` / `diagnose` evidence |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling) | Digest check/apply/rollback lane |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Grafana/Prometheus (deeper metrics) |
| Stage 9 `dashboard-release-highlights-contract.md` (expected sibling) | Optional UI consumption of status signals |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes that should name the same verbs |

Out of scope:

- Replacing checkup with a vendor RMM or always-on agent
- Expanding checkup into a full metrics TSDB (use Stage 6 observability)
- Printing `.env` secrets, tokens, or private hostnames into status JSON
- Treating checkup failures as automatic `--apply` for image updates

## Proposal

Publish a **daily checkup contribution contract** for PRs that touch scheduled health reporting.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Health classification | `daily-checkup.sh` | Tier 1 vs Tier 2 (on-demand stopped ≠ down) |
| Status artifact | JSON writer | Stable keys; no secrets; schema notes in PR |
| Update signal | Checkup ↔ safe-update | Check-only posture by default; no silent apply |
| Cron wiring | Host cron / Stage 11 | Opt-in; install/remove documented |
| Consumers | helper / dashboard / playbooks | Read the same artifact; do not invent a second file |

### Rules

1. **One scheduled pulse.** Prefer extending `daily-checkup.sh` over a parallel cron health script.
2. **Tier awareness is mandatory.** On-demand Tier 2 services may be stopped without marking the stack “down.”
3. **No secrets in JSON.** Status artifacts must stay paste-safe for privacy-aware support (see PR #25 direction).
4. **Check ≠ apply.** Update availability signals must not trigger unattended digest mutation.
5. **Stable keys.** Renaming JSON fields requires helper/dashboard/fixture follow-through in the same change window.
6. **Cron is opt-in.** Document how operators enable/disable the schedule (Stage 11).
7. **GitHub remains intake.** Requests for cloud monitoring products stay Issues; default is local checkup + existing observability.

### Suggested contributor checklist

```text
1. Reproduce with ./scripts/daily-checkup.sh (or documented wrapper)
2. Confirm Tier 2 stopped containers are not counted as hard failures
3. Inspect status JSON for secrets/PII before proposing schema changes
4. If consumers change, update helper/dashboard/playbook references together
5. Keep safe-update apply paths out of this script
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Scheduled health | `daily-checkup.sh` + host cron | Vendor RMM agents |
| Interactive triage | Stage 12 doctor/diagnose | Duplicating doctor inside checkup |
| Deep metrics | Stage 6 Prometheus/Grafana | Turning checkup into a TSDB |
| Image updates | Stage 15 safe-update | Auto-apply from checkup |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Link playbook anchors for daily checkup / update-status when operators need them.
3. Prefer **code** that tightens Tier classification and schema docs over more prose.

## Acceptance criteria

- [ ] Tier 1 vs Tier 2 classification rule is stated.
- [ ] Secret-free status artifact rule is stated.
- [ ] Checkup is separated from safe-update apply.
- [ ] Cron remains opt-in via Stage 11 patterns.
- [ ] Consumer schema stability expectations are stated.

## Rollback

Revert script/docs commits independently; prior checkup behavior returns. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer false “stack down” reports when Tier 2 is intentionally stopped.
- Dashboard/helper consumers share one status artifact.
- Operators understand checkup vs doctor vs safe-update.
