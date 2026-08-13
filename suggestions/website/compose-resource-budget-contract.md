---
title: Compose Resource-Budget Contract
description: Constructional contract for community changes to deploy.resources limits so laptop-friendly energy defaults are preserved instead of unlimited containers or a second orchestrator.
last_updated: 2026-08-13
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Compose Resource-Budget Contract

## Problem

TU-VM’s historical roadmap is energy-first: idle CPU dropped from ~30% to under 5%, Tier 2 services are on-demand, and every core service already declares `deploy.resources` limits and reservations. Community PRs that “just raise memory so it stops OOM” or omit limits on new sidecars undo that work. CHANGELOG planned features (profiles, idle autostop, battery widgets) assume budgets still exist.

Historical suggestion files asked for day-to-day tooling; they did not publish a **resource-budget contract** for Compose edits. Stage 2 operator profiles and Stage 7 idle-autostop describe *when* services run. This page describes *how much* they may consume when they do.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `deploy.resources` | Per-service memory/CPU limits and reservations |
| Healthcheck `interval: 180s` on several Tier 1 services | Energy-aware polling |
| `./tu-vm.sh start --portable` vs `--server` | Which services start, not their cgroup caps |
| CHANGELOG 2.0 / 2.2 energy notes | Documented idle-CPU and RAM targets |
| Stage 2 `operator-service-profiles.md` (expected sibling) | Named start sets |
| Stage 7 `tier2-idle-autostop-policy.md` (expected sibling) | Opt-in stop of idle heavy services |
| Stage 7 `battery-power-operator-signals.md` (expected sibling) | Battery UI, not cgroup policy |
| Stage 10 `gpu-acceleration-contribution-contract.md` (expected sibling) | GPU enablement must not imply unlimited CPU |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Honest checks vs aggressive 5s intervals |

Out of scope:

- Kubernetes / Nomad / a second scheduler as a prerequisite
- Swarm-only features that Compose ignores on this stack
- Making every service unlimited “until we measure”
- Turning Prometheus exporters into always-on Tier 1 (see Stage 6 observability; keep them opt-in)

## Proposal

Publish a **resource-budget contribution contract** for PRs that add or change Compose `deploy.resources`.

### Budget lanes (guidance, not a second product)

| Class | Typical memory limit | Typical CPU limit | Examples |
|---|---|---|---|
| Control plane | 128–256M | 0.1–0.25 | `nginx`, `helper_index` |
| Data plane (Tier 1) | 256–512M | 0.25–0.5 | `postgres`, `redis` |
| Chat UI | ~2G | ~1.0 | `open-webui` (already reduced from 3G) |
| Heavy AI / browser | 2–3G | 1.0–1.5 | `ollama`, `mcp-playwright` |
| MCP utilities | 256M | 0.25 | `mcp-fetch`, `mcp-filesystem`, `mcp-memory` |
| Document pipeline | 256–512M processor; Tika larger | 0.5–1.0 | `tika_minio_processor`, `tika` |

Reservations should stay below limits so portable hosts can still schedule Tier 1 together.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| New service | `docker-compose.yml` | Limits **and** reservations present |
| Limit increase | same file + PR notes | Why OOM/CPU, measured before/after, portable impact |
| Health interval | healthcheck block | Do not drop Tier 1 intervals to 5–15s without energy review |
| Restart policy | `restart:` | Tier 2 stays `no` / manual unless accepted |
| Local override | Stage 8 compose-override | Higher caps stay local, not default |

### Rules

1. **Every new service declares limits.** No unlimited community containers on `ai_network`.
2. **Do not silently undo 2.0/2.2 energy work.** Raising Open WebUI or Ollama caps needs measured evidence and a portable-mode note.
3. **Reservations must fit portable Tier 1.** Sum of always-on reservations should remain laptop-realistic.
4. **Tier 2 stays optional.** Resource limits are not a reason to auto-start Ollama, Playwright, or n8n.
5. **Healthchecks are part of the budget.** Aggressive intervals count as CPU spend.
6. **Prefer compose-override** for lab machines that need more RAM than the default.
7. **GitHub remains intake.** Requests for a Kubernetes port stay Issues unless accepted.

### Suggested contributor checklist

```text
1. Add deploy.resources.limits and reservations for any new service
2. Compare the class table; justify outliers in the PR
3. Note portable vs server impact in release notes if caps change
4. Keep Tier 2 restart policy manual unless a maintainer accepts always-on
5. Run sudo docker compose config --quiet
6. Do not add always-on exporters that poll every 5s
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Caps | Compose `deploy.resources` | A custom cgroup daemon |
| Start sets | Stage 2 profiles / `start --portable` | New orchestrator |
| Idle stop | Stage 7 autostop policy | Killing containers from a third watchdog |
| Local extra RAM | Stage 8 override file | Patching defaults for one workstation |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: CI warning when a service lacks `deploy.resources.limits.memory`.
3. Keep measured idle-CPU notes in CHANGELOG when caps change.

## Acceptance criteria

- [ ] New services must declare memory and CPU limits.
- [ ] Limit increases require measured rationale and portable impact.
- [ ] Tier 2 auto-start is not implied by a higher cap.
- [ ] Healthcheck interval changes are in scope for energy review.
- [ ] Local higher caps belong in overrides, not defaults.

## Rollback

Revert Compose/docs commits independently. Prior limits return. Docs-only publication needs no runtime rollback.

## Success metrics

- New sidecars ship with limits on the first review.
- Idle CPU stays in the documented low-single-digit range on portable hosts.
- Fewer “remove the memory limit” PRs without measurements.
