---
title: Compose Mem Swappiness Contract
description: Constructional contract for per-container mem_swappiness deploy knobs, distinct from host vm.swappiness sysctl, without a tuned daemon or privileged sysctl sidecar.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Compose Mem Swappiness Contract

## Problem

Stage 24 proposes an **optional host** `vm.swappiness` via `/etc/sysctl.d/99-tu-vm.conf`. That is a **machine-wide** knob. Compose also supports **per-container** `mem_swappiness` (cgroup) so a single noisy service can be told "do not swap" without changing the laptop's global policy.

Today no service sets `mem_swappiness`. Heavy Tier 2 guests (Ollama, Open WebUI, Tika, Playwright) can push **postgres / redis / pihole** into swap on an 8–16 GB host. Health probes then flap. The host sysctl contract cannot say "swap Ollama if you must, never swap Pi-hole."

Stage 18 covers **CPU/memory limits**. Stage 24 covers **host sysctl**. This page is only **cgroup swappiness on named services**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `deploy.resources.limits.memory` | Hard cap; still allows swap inside the cap |
| Compose `mem_swappiness` | 0–100 per container (cgroup) |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | CPU/memory numbers |
| Stage 24 `host-sysctl-tuning-contract.md` (expected sibling) | Host `vm.swappiness` + inotify |
| `tu-vm.sh doctor` | Read-only host facts |

Out of scope:

- `tuned`, `auto-cpufreq`, or a privileged sysctl sidecar (already rejected in Stage 24)
- Changing memory **limits** in the same PR
- Kubernetes `memory-stat` / QoS classes
- Disabling swap on the host (operator choice; not this contract)

## Proposal

Set low `mem_swappiness` on **latency-sensitive Tier 1** services (postgres, redis, pihole, nginx, qdrant). Leave Ollama / Tika / Playwright at default (or a higher value) so the kernel prefers them as swap victims when the laptop is under pressure.

### Contribution lanes

| Lane | Where | Suggested value |
|---|---|---|
| Keep hot | `postgres`, `redis`, `pihole`, `nginx`, `qdrant` | `mem_swappiness: 0` or `10` |
| May swap | `ollama`, `tika`, `open-webui`, `browserless`, `mcp-playwright` | omit (inherit) or `60` |
| Host default | Stage 24 sysctl | Optional `vm.swappiness=10` for the laptop |
| Docs | this page | Table beats a global "disable swap" FAQ |

### Rules

1. **Per-container first for service policy.** Host sysctl remains the laptop-wide energy default.
2. **Do not set 0 on Tika/Ollama** as a "performance tip." Those jobs cause the pressure; they should be the ones that swap.
3. **Memory limits stay Stage 18.** Swappiness is not a substitute for a 512M Postgres cap.
4. **No tuned profile.** If the engine ignores `mem_swappiness` (rootless/cgroup v1 quirks), document it in doctor; do not add a daemon.
5. **GitHub remains intake.** Requests for a userspace memory manager stay Issues.

### Suggested contributor checklist

```text
1. Add mem_swappiness: 10 (or 0) on postgres, redis, pihole, nginx, qdrant
2. Leave ollama/tika/open-webui/playwright unset
3. Do not change deploy.resources.memory in the same PR
4. Do not add tuned or a sysctl sidecar
5. Note in doctor if cgroup swappiness is unsupported
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Service swap policy | Compose `mem_swappiness` | Host-only sysctl for Pi-hole vs Ollama |
| Laptop default | Stage 24 `sysctl.d` | `tuned` / privileged sidecar |
| Size caps | Stage 18 resource budget | Raising limits to "avoid swap" |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: low swappiness on postgres/redis/pihole/nginx first.
3. Cross-link Stage 24 so operators do not apply both blindly without reading the table.

## Acceptance criteria

- [ ] At least postgres, redis, and pihole set a low `mem_swappiness`.
- [ ] Ollama/Tika are not forced to 0 in the same change.
- [ ] No `tuned` daemon or sysctl sidecar is added.
- [ ] Host Stage 24 sysctl remains optional and separate.
- [ ] `docker compose config` still renders.

## Rollback

Remove `mem_swappiness` keys. Host sysctl files are untouched.

## Success metrics

- Pi-hole/Postgres stay responsive when Ollama loads a model.
- Contributors ask "which service should swap?" instead of "disable swap globally."
- Doctor can report cgroup vs host swappiness without a new agent.
