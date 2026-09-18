---
title: n8n Execution Timeout Contract
description: Constructional contract to set official EXECUTIONS_TIMEOUT and EXECUTIONS_TIMEOUT_MAX so hung workflows stop, instead of adding a custom execution watchdog.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Execution Timeout Contract

## Problem

The `n8n` service does not set `EXECUTIONS_TIMEOUT`. Official n8n defaults that key to `-1` (no default timeout). A looping HTTP or LLM node on a 512M–2G LAN box can run until the container is OOM-killed, taking other Tier 2 work with it.

Community suggestions that “watch n8n jobs” often propose a cron sidecar, a helper API cancel button, or copying Stage 33 execution-*prune* work. Prune deletes old history; it does not stop a live runaway execution. The official timeout keys are already there.

This is distinct from:

- Stage 33 `n8n-executions-data-prune-contract.md` (retention of *finished* execution data)
- Stage 29 `n8n-binary-data-volume-contract.md` (binary blob storage)
- Stage 25 `compose-stop-grace-period-contract.md` (compose stop, not workflow cancel)
- Stage 7 idle container autostop (stop the *container*, not one workflow)
- Official `N8N_CONCURRENCY_PRODUCTION_LIMIT` (how many run at once; out of scope here)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | `N8N_BINARY_DATA_MODE=filesystem`; no timeout keys |
| Official n8n executions env | `EXECUTIONS_TIMEOUT` (seconds, `-1` disables), `EXECUTIONS_TIMEOUT_MAX` |
| Official n8n executions env | `N8N_AI_TIMEOUT_MAX` (ms for AI HTTP); mention only if local Ollama is slow |
| Stage 33 prune (expected sibling) | Disk/history, not runtime |

Out of scope:

- A custom watchdog cron or helper “kill execution” product
- Queue mode / Redis workers (`EXECUTIONS_MODE=queue`)
- Rewriting Stage 33 prune keys
- Rewriting Stage 7 container autostop

## Proposal

Set official runtime limits on the `n8n` service. Conservative LAN defaults:

```text
EXECUTIONS_TIMEOUT: "900"
EXECUTIONS_TIMEOUT_MAX: "3600"
```

Operators who run long local LLM chains may raise `EXECUTIONS_TIMEOUT` up to `EXECUTIONS_TIMEOUT_MAX`. If Ollama replies are slow, raise official `N8N_AI_TIMEOUT_MAX` in milliseconds rather than inventing a retry proxy. Do not add a TU-VM execution janitor.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official timeout seconds |
| Env schema | `env.example` | Optional interpolated keys with the same names |
| Docs | n8n playbook | Default 15 minutes; max 1 hour; raise via env, not a sidecar |

### Rules

1. **Official keys only.** Do not invent `TU_VM_N8N_JOB_WATCHDOG`.
2. **Do not confuse with prune.** Stage 33 owns `EXECUTIONS_DATA_PRUNE*`.
3. **Do not confuse with container autostop.** Stage 7 owns Tier 2 idle stop.
4. **Seconds vs milliseconds.** `EXECUTIONS_TIMEOUT*` is seconds; `N8N_AI_TIMEOUT_MAX` is ms.
5. **GitHub remains intake.** Requests for queue mode stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents EXECUTIONS_TIMEOUT
2. Set TIMEOUT=900 and TIMEOUT_MAX=3600 on the n8n service
3. Recreate n8n and confirm a sleeping workflow stops at the default
4. Document how to raise the limit for long local LLM workflows
5. Do not add a watchdog sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop hung workflows | Official `EXECUTIONS_TIMEOUT*` | A cron that SIGKILLs node |
| Long local LLM calls | Official `N8N_AI_TIMEOUT_MAX` | A custom retry proxy |
| History growth | Stage 33 official prune | Rewriting prune on this page |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: two Compose lines + one playbook sentence.
3. Call out newly failing long workflows in release notes.

## Acceptance criteria

- [ ] `n8n` sets `EXECUTIONS_TIMEOUT` to a positive second value (not `-1`).
- [ ] `EXECUTIONS_TIMEOUT_MAX` is set and is greater than or equal to the default timeout.
- [ ] Docs mention how operators raise the limit.
- [ ] No watchdog sidecar is added.
- [ ] Stage 33 prune and Stage 7 autostop pages are not rewritten.

## Rollback

Remove the keys (official default `-1` / `3600`). In-flight behavior returns to unlimited default timeout. Volume data remains.

## Success metrics

- A sample sleep/loop workflow stops at the configured default.
- Day-to-day incident notes cite timeout keys instead of a new janitor product.
