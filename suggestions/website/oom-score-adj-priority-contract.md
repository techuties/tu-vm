---
title: OOM Score Adjustment Priority Contract
description: Constructional contract for Compose oom_score_adj so Ollama and other heavy Tier 2 jobs are killed before Pi-hole, Nginx, and Postgres.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# OOM Score Adjustment Priority Contract

## Problem

When a laptop hits memory pressure, the kernel OOM killer uses `oom_score`. Compose never sets `oom_score_adj`, so **Ollama (2G), Tika (unbounded today), and Pi-hole (256M)** are peers. The killer can reap **Pi-hole or Postgres first**. The community then sees "DNS is down" or "database is accepting no connections" — a control-plane outage caused by an optional inference job.

Stage 18 covers **cgroup memory limits** (who *may* use RAM). Stage 24 covers **host `vm.swappiness`**. Stage 25 covers **per-container `mem_swappiness`**. None of those pages say **who dies first** when limits and swap are not enough.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `oom_score_adj` | Engine-supported hint (−1000…1000) |
| `deploy.resources.limits.memory` | Hard ceiling; does not order kills across services |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | Limits |
| Stage 24 `host-sysctl-tuning-contract.md` (expected sibling) | Host swappiness |
| Stage 25 `compose-mem-swappiness-contract.md` (expected sibling) | Per-cgroup swap |

Out of scope:

- A userspace OOM daemon, earlyoom product, or custom killer script as the default
- `oom_kill_disable: true` (unkillable containers) on any service
- Setting `-1000` (unkillable) on Pi-hole — that can deadlock the host
- Changing memory limits on this page (Tika/MinIO limits are a sibling Stage 26 contract)

## Proposal

Set modest `oom_score_adj` so **optional / heavy** jobs are preferred victims and **Tier 1 control plane** is protected — without making anything unkillable.

### Contribution lanes

| Lane | Where | Suggested adj |
|---|---|---|
| Protect | `pihole`, `nginx`, `postgres`, `redis` | `−200` to `−100` |
| Neutral | `helper_index`, `open-webui`, `minio`, `qdrant` | `0` (default) or `+50` |
| Sacrifice | `ollama`, `tika`, `browserless`, `mcp-playwright`, `n8n` | `+200` to `+400` |
| Never | any service | `−1000` or `oom_kill_disable: true` |

### Rules

1. **Hints, not immunity.** Protect DNS/DB/proxy; do not freeze them at `-1000`.
2. **Tier 2 dies first.** Ollama and Playwright are optional. Pi-hole is not.
3. **Do not add earlyoom or a killer container.** The kernel plus Compose is the framework.
4. **Do not disable OOM kills.** `oom_kill_disable` is out of policy for community compose.
5. **Limits stay Stage 18 / Tika-MinIO Stage 26.** Score order is the last resort after cgroups.
6. **GitHub remains intake.** Requests for a "memory governor agent" stay Issues.

### Suggested contributor checklist

```text
1. Set oom_score_adj: -100 on pihole, nginx, postgres
2. Set oom_score_adj: 300 on ollama, tika, browserless
3. Leave helper/open-webui at 0 unless a ticket proves otherwise
4. Do not set oom_kill_disable or -1000
5. Confirm docker compose config still renders
6. Document that a forced OOM test is optional and destructive
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Kill order | Compose `oom_score_adj` | earlyoom / userspace killer |
| RAM ceiling | Existing `deploy.resources` | Raising Ollama to "avoid OOM" |
| Swap | Stage 24/25 swappiness | Mixing sysctl into this PR |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: adj on pihole/nginx/postgres (protect) and ollama/tika/browserless (sacrifice).
3. Do not run a host-wide `echo f > /proc/sysrq-trigger` in CI.

## Acceptance criteria

- [ ] `pihole`, `nginx`, and `postgres` set a negative `oom_score_adj` (not −1000).
- [ ] `ollama` sets a positive `oom_score_adj` ≥ 200.
- [ ] No service sets `oom_kill_disable: true`.
- [ ] No userspace OOM daemon is added.
- [ ] `docker compose config` still renders.

## Rollback

Remove `oom_score_adj` keys. Images, volumes, and limits are unchanged.

## Success metrics

- Memory-pressure tickets cite Ollama/Tika restarts instead of Pi-hole/Postgres death.
- Contributors set Compose adj instead of proposing a memory governor.
- LAN DNS stays up when an inference job overruns.
