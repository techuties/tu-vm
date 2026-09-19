---
title: n8n Concurrency Production Limit Contract
description: Constructional contract to set official N8N_CONCURRENCY_PRODUCTION_LIMIT so webhook and trigger executions queue instead of thrashing the event loop, distinct from Stage 34 execution timeouts and Stage 28 resource limits.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Concurrency Production Limit Contract

## Problem

The `n8n` service does not set `N8N_CONCURRENCY_PRODUCTION_LIMIT`. Official n8n defaults that value to `-1` in regular mode: unlimited concurrent **production** executions (webhook and trigger). On a LAN VM that also runs Open WebUI, Tika, and Postgres, a noisy community workflow or a retry storm can stall the editor, starve Postgres, and look like “n8n is down” to other contributors.

Community suggestions that “write a cron to kill busy n8n” or “add a custom queue sidecar” reinvent what official regular-mode concurrency already does: queue overflow FIFO until a slot frees.

This is distinct from:

- Stage 34 `n8n-execution-timeout-contract.md` (expected sibling): **per-run** wall-clock stop (`EXECUTIONS_TIMEOUT*`), not how many runs overlap
- Stage 33 `n8n-executions-data-prune-contract.md`: retention of finished data, not live concurrency
- Stage 28 `unbounded-tier2-resource-limits-contract.md`: Compose `deploy.resources` memory/CPU, not n8n’s execution queue
- Stage 7 idle autostop: stop the **container**, not queue production runs

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | No concurrency key today; `restart: "no"` Tier 2 |
| Official n8n scaling docs | `N8N_CONCURRENCY_PRODUCTION_LIMIT` (regular and queue mode) |
| `env.example` n8n block | Operator-facing keys; optional override |
| Stage 28 unbounded Tier 2 budgets (expected sibling) | Complementary Compose caps |
| GitHub Issues suggestion form | Intake if someone later wants queue-mode workers |

Out of scope:

- Switching this VM to n8n queue mode / redis workers as a new product
- A custom execution watchdog cron (Stage 34 already owns timeouts)
- Rewriting Stage 28 Compose memory/CPU tables
- `N8N_CONCURRENCY_EVALUATION_LIMIT` (evaluation UI; not production webhooks)

## Proposal

Set an official regular-mode cap sized for a shared household/community VM, overridable from `.env`:

```text
N8N_CONCURRENCY_PRODUCTION_LIMIT: ${N8N_CONCURRENCY_PRODUCTION_LIMIT:-5}
```

Five concurrent production executions is a starting point next to the current n8n image and shared Postgres. Operators who run heavy webhook farms raise the env; they do not add a sidecar.

Manual editor runs, error workflows, and sub-workflow executions stay outside this official limit (n8n’s documented behavior). Do not invent `TU_VM_N8N_MAX_JOBS` to cover those.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official concurrency key with a modest default |
| Env schema | `env.example` | Optional `N8N_CONCURRENCY_PRODUCTION_LIMIT=5` comment |
| Docs | n8n playbook | Overflow queues; raise the official key, do not add workers yet |

### Rules

1. **Official key only.** Do not invent a project-local job limiter.
2. **Do not confuse with timeouts.** Hung runs are Stage 34 `EXECUTIONS_TIMEOUT*`.
3. **Do not confuse with Compose RAM.** Stage 28 remains the cgroup lane.
4. **GitHub remains intake.** Queue-mode / worker requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_CONCURRENCY_PRODUCTION_LIMIT
2. Set a small positive default (suggested 5) interpolating from .env
3. Recreate n8n and fire more production webhooks than the limit
4. Confirm extras wait FIFO; editor stays responsive
5. Document how to raise the official key
6. Do not add a watchdog cron or rewrite Stage 28 / Stage 34 pages
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Cap overlapping webhooks | Official `N8N_CONCURRENCY_PRODUCTION_LIMIT` | A custom queue container |
| Stop hung runs | Stage 34 `EXECUTIONS_TIMEOUT*` | Killing PID 1 from cron |
| Cap RAM/CPU | Stage 28 Compose budgets | Treating cgroups as a job queue |
| Scale later | Official n8n queue mode (Issue first) | A TU-VM worker product |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one `env.example` comment.
3. Call out queued (not dropped) overflow in release notes.

## Acceptance criteria

- [ ] `n8n` sets `N8N_CONCURRENCY_PRODUCTION_LIMIT` to a positive value (default 5 unless operators override).
- [ ] Docs explain FIFO queue vs timeout vs Compose RAM.
- [ ] No custom queue sidecar or watchdog is added.
- [ ] Stage 28 / 33 / 34 pages are not rewritten.

## Rollback

Set the key to `-1` (official unlimited in regular mode) or remove it. Queued executions drain or resume per n8n’s documented startup behavior.

## Success metrics

- Burst webhooks no longer freeze the shared editor for other community users.
- PRs that want “n8n performance” cite this official key before proposing workers.
