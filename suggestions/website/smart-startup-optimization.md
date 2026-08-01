---
title: Smart Startup Optimization
description: Constructional contract for Tier-aware quick-start planning that reuses tu-vm.sh portable mode, operator profiles, and the service dependency map instead of inventing a new orchestrator.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Smart Startup Optimization

## Problem

[`CHANGELOG.md`](../../CHANGELOG.md) still lists **Smart Startup Optimization** as a planned feature. Operators repeatedly ask for “just start what I need” without launching the full stack. Historical suggestions proposed custom schedulers or always-on heavy services. Day-to-day life needs a **reuse-first planner** that stages Tier 1 first, defers Tier 2, and explains what stayed off—and why.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh start --portable` / `--tier1` | Already-on Tier 1 quick path |
| Stage 2 `operator-service-profiles.md` (expected sibling) | Named Work / AI / Energy profiles |
| Stage 4 `operator-profile-cli.md` (expected sibling) | `profile list\|show\|apply --plan` |
| Stage 7 `service-dependency-map.md` (expected sibling) | Declared deps and `--with-deps` |
| Stage 7 `tier2-idle-autostop-policy.md` (expected sibling) | Complementary idle shutdown |
| Stage 7 `battery-power-operator-signals.md` (expected sibling) | Energy-aware recommendations |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes and anchors |
| Helper `/status/full` | Post-start summary surface |

Out of scope:

- Kubernetes, Nomad, or another cluster orchestrator for a single host
- Auto-starting every Tier 2 service on boot
- Cloud wake-on-LAN control planes
- Replacing Compose healthchecks with a custom supervisor daemon

## Proposal

Treat smart startup as a **thin planner** over existing start modes and profiles.

### Behaviors

1. **Default to Tier 1.** Cold start brings Postgres, Redis, Qdrant, Tika, MinIO, processor, Open WebUI, Pi-hole, Nginx, helper—then stops.
2. **Remember last successful profile** (when Stage 2/4 profiles land) and offer `apply --plan` before mutating.
3. **Stage heavy services.** Ollama, n8n, MCP tools, and similar Tier 2 units start only when the selected profile or explicit flags request them.
4. **Explain deferred services** in CLI output and optionally in a `/status` summary object (`startup.last_plan`).
5. **Honor dependencies.** If AI Mode needs Qdrant + Ollama, use the Stage 7 dependency map rather than ad-hoc sleep loops.
6. **Battery-aware hinting.** When Stage 7 battery signals exist and capacity is low, prefer Energy Save / Tier 1-only plans.

### Suggested CLI shape

```text
./tu-vm.sh start --plan          # show staged plan, no changes
./tu-vm.sh start --portable      # Tier 1 (existing)
./tu-vm.sh start --profile work  # after profile CLI lands
./tu-vm.sh startup-summary       # last plan + deferred reasons
```

### Community contribution opportunities

- Device-class startup presets linked to the Stage 2 hardware matrix
- Playbook snippets for “first hour after reboot”
- Issue reports that attach `startup-summary` JSON (no secrets)

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Process model | Docker Compose + `tu-vm.sh` | New init system beside Compose |
| Resource control | Profiles + dependency map | Per-service custom agents |
| Operator UX | Plan/apply + dashboard badge | Silent background starts |
| Evidence | Smoke after Tier 1 healthy | “It looked up” without checks |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Implement `--plan` output before changing default start behavior.
3. Wire profile apply only after Stage 2/4 profile catalog stabilizes.
4. Add a playbook anchor `#playbook-smart-startup` once CLI lands.
5. Keep CHANGELOG “Smart Startup” item linked to the implementing PR.

## Acceptance criteria

- [ ] Cold start without flags does not pull every Tier 2 service by default.
- [ ] Plan mode prints what will start, what stays deferred, and why.
- [ ] Dependency-aware starts reuse the Stage 7 map when present.
- [ ] Post-start smoke/docs path remains the existing playbook safe-update / smoke-test flow.
- [ ] No new orchestrator binary or compose rewrite is required for the first milestone.

## Rollback

Keep planner flags advisory. Operators can always run explicit `docker compose up -d <service>` or full-stack start. Remove planner flags without changing Compose service definitions.

## Success metrics

- Fewer “machine unusable after reboot” support threads.
- Measurable reduction in default boot RAM vs full-stack start on common hardware classes.
- Community PRs contribute presets instead of forking `tu-vm.sh start`.
