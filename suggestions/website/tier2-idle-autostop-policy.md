---
title: Tier 2 Idle Auto-Stop Policy
description: Constructional opt-in policy for stopping inactive heavy Tier 2 services using existing compose tiers and tu-vm.sh controls instead of a custom orchestrator.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tier 2 Idle Auto-Stop Policy

## Problem

CHANGELOG planned features and historical suggestions ask for **auto-stop of inactive heavy services**. Operators already use Tier 1 (always-on) vs Tier 2 (on-demand) mentally, but there is no published, opt-in idle policy. Without a contract, proposals invent schedulers, agents, or cloud autoscalers that fight Compose and `tu-vm.sh`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Tier 1 / Tier 2 model in `AGENTS.md`, `README.md`, `tu-vm.sh` | Resource-aware startup split |
| `./tu-vm.sh` start/stop/status surfaces | Operator control plane |
| Helper idle/stale status hints in `helper/uploader.py` | Early “idle” signaling for some checks |
| Stage 2 `operator-service-profiles.md` (expected sibling) | Named Work/AI/Energy style profiles |
| Stage 4 `operator-profile-cli.md` (expected sibling) | `tu-vm.sh profile` plan/apply |
| Stage 6 backup/restore drill | Safety net before aggressive stop policies |
| n8n (Tier 2) | Optional reminder automation—not a second orchestrator |

Out of scope:

- Stopping Tier 1 core services by default
- ML-based “intent prediction” as a prerequisite
- Cloud cluster autoscaling APIs
- Autonomous restores or destructive cleanup

## Proposal

Publish an **opt-in idle auto-stop policy** that operators enable explicitly.

### Policy object (v1)

```yaml
idle_autostop:
  enabled: false          # default OFF
  check_interval_minutes: 15
  idle_after_minutes: 60
  apply_to:
    - ollama
    - # other documented Tier 2 heavy services only
  never_stop:
    - postgres
    - redis
    - nginx
    - helper_index
  notify: local           # local status flag / log only in v1
```

### Behavior

1. **Default off.** Fresh installs never surprise-stop services.
2. **Tier 2 only.** Policy allowlist is explicit; Tier 1 names are rejected by validation.
3. **Idle definition (v1).** No recent operator interaction via helper control routes and no meaningful container activity signal agreed in the implementation PR (document the exact signal).
4. **Dry-run first.** `./tu-vm.sh idle-policy --plan` prints what would stop.
5. **Profile synergy.** Energy Save / similar Stage 2 profiles may set recommended defaults but still require opt-in enablement.
6. **Audit trail.** Local log line + optional status field; no cloud telemetry.

### Day-to-day operator flow

```bash
./tu-vm.sh idle-policy show
./tu-vm.sh idle-policy --plan
./tu-vm.sh idle-policy enable
./tu-vm.sh idle-policy disable
```

(Exact subcommands may wrap existing scripts; avoid a parallel CLI binary.)

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Process model | Compose + `tu-vm.sh` stop | New supervisor daemon as required core |
| Scheduling | Existing cron/daily-checkup hook or simple loop in helper | Kubernetes-style controllers on a single VM |
| Notifications | Status board / local log | Pushing idle events to third parties |
| Safety | never_stop list + opt-in | Global “kill idle containers” |

## Rollout

1. Land this constructional page; collect hardware-class feedback via Issues.
2. Implement config schema in `.env` / config file with validation in `check-config`.
3. Ship `--plan` before enable.
4. Document playbook anchor and link Energy Save profile recommendations.
5. Record ship in Stage 3 `implemented-showcase` when done.

## Acceptance criteria

- [ ] Default remains disabled.
- [ ] Tier 1 services cannot be listed in `apply_to` (validator rejects).
- [ ] Dry-run path exists before first automatic stop.
- [ ] Rollback is `idle-policy disable` (or env flag) with no data loss expectation beyond stopping containers.
- [ ] Docs state exact idle signal used in v1.

## Rollback

Disable the policy flag; leave services manually managed via existing start/stop commands.

## Success metrics

- Laptop/Homelab operators report lower idle RAM/GPU use when enabled.
- No production incidents from accidental Tier 1 stops.
- Fewer duplicate “please add autoscaling” suggestions once the policy page is linked from the status board.
