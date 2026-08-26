---
title: CPU Shares and Blkio Weight Contract
description: Constructional contract for Compose cpu_shares and blkio_weight so Ollama and Tika cannot starve Pi-hole and Postgres, without a cgroup governor product and distinct from oom_score_adj.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# CPU Shares and Blkio Weight Contract

## Problem

Almost every service already has **hard** `deploy.resources` CPU and memory limits. Those caps stop a runaway container from taking the whole machine. They do **not** say who wins when two healthy containers want the same core or disk at the same time.

On a laptop-class host, OCR (Tika) or a local generate (Ollama) can delay Pi-hole's `dig` healthcheck and Postgres `COMMIT` even while each cgroup is "within limit". Operators see DNS timeouts and "DB is slow" while `docker stats` looks legal.

Stage 26 `oom_score_adj` is **kill order** when memory is gone. Stage 24/25 swappiness is **what gets paged**. Neither is the CFS/IO scheduler. Stage 18's resource-budget page says how to pick limits, not relative shares.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `deploy.resources.limits.cpus` | Hard cap (already set on most services) |
| Docker `cpu_shares` (default 1024) | Relative CPU weight under contention |
| Docker `blkio_config.weight` (10–1000, default 500) | Relative IO weight under contention |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | How to choose hard limits |
| Stage 24 `host-sysctl-tuning-contract.md` (expected sibling) | Host-wide knobs, not per-service shares |
| Stage 25 `compose-mem-swappiness-contract.md` (expected sibling) | Swap policy |
| Stage 26 `oom-score-adj-priority-contract.md` (expected sibling) | OOM kill order |

Out of scope:

- A userspace cgroup governor, `earlyoom`, or `nice` wrappers in `tu-vm.sh`
- Changing hard `deploy.resources` numbers on this page
- CPU pinning / cpuset (that is a different Issue)
- Applying shares to one-shot jobs (`affine_migration`)

## Proposal

Set relative weights so LAN-critical Tier 1 wins over inference and OCR when the host is busy.

### Contribution lanes

| Lane | Service | `cpu_shares` | `blkio_config.weight` |
|---|---|---|---|
| Protect | `pihole`, `nginx`, `postgres` | `2048` | `800` |
| Neutral | `redis`, `helper_index`, `open-webui` | default `1024` | default `500` |
| Sacrifice | `ollama`, `tika`, `browserless`, `mcp-playwright` | `256` | `200` |
| Docs | this page + Stage 18 checklist | New heavy services declare shares |

Compose accepts these as service-level keys (not only Swarm `deploy`). Prefer the keys the engine already honors on `docker compose up`.

### Rules

1. **Shares are not limits.** Do not replace `deploy.resources`. A share of 256 still allows a full reserved CPU when nobody else wants it.
2. **Do not invent a governor.** No `tu-vm.sh nice`, no sidecar that writes `cpu.weight`.
3. **Keep OOM distinct.** Do not "fix" scheduler delay by raising `oom_score_adj`. That is Stage 26.
4. **Protect DNS and the primary DB first.** Pi-hole and Postgres are the minimum protect set. Nginx is next (TLS + dashboard).
5. **Sacrifice inference and OCR.** Ollama, Tika, and Chromium are the minimum sacrifice set.
6. **GitHub remains intake.** Requests for "QoS profiles" or cpuset stay Issues (Stage 2 operator profiles).

### Suggested contributor checklist

```text
1. Set cpu_shares: 2048 on pihole, nginx, postgres
2. Set blkio_config.weight: 800 on the same three
3. Set cpu_shares: 256 and blkio_config.weight: 200 on ollama, tika, browserless, mcp-playwright
4. Do not change deploy.resources numbers in the same PR without evidence
5. Do not add a nice/governor script
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hard cap | Existing `deploy.resources` | Raising shares "instead of" a limit |
| Who wins the core | Compose `cpu_shares` | Host `nice` / a governor container |
| Who wins the disk | Compose `blkio_config.weight` | ionice wrappers |
| Who dies last | Stage 26 `oom_score_adj` | Using OOM to fake fairness |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: protect set first, then sacrifice set.
3. Tune numbers only after a recorded DNS/DB stall with default shares.

## Acceptance criteria

- [ ] `pihole`, `nginx`, and `postgres` have `cpu_shares` > 1024.
- [ ] `ollama` and `tika` have `cpu_shares` < 1024.
- [ ] Blkio weights follow the same protect/sacrifice split.
- [ ] Hard `deploy.resources` limits remain in place.
- [ ] No governor script or host `nice` is added.
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Remove `cpu_shares` and `blkio_config` keys. Images, volumes, and limits are unchanged.

## Success metrics

- Pi-hole healthcheck timeouts during Ollama generate drop.
- Contributors declare shares on new heavy services next to `deploy.resources`.
- QoS-profile Issues cite Stage 2 instead of adding a governor.
