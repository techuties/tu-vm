---
title: n8n Healthz When Started Contract
description: Constructional contract for enabling the commented n8n /healthz Compose probe so dependents can wait, without adding a watchdog or changing Tier 2 restart policy.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Healthz When Started Contract

## Problem

`n8n` already documents the right probe and then leaves it commented:

```yaml
# Healthcheck disabled for on-demand service (Tier 2)
# healthcheck:
#   test: ["CMD-SHELL", "node -e \"require('http').get('http://127.0.0.1:5678/healthz', ...
```

Tier 2 means **do not auto-start**, not **do not probe**. `n8n_mcp` and `mcp_gateway` talk to n8n as soon as they start. Without a probe, Stage 24 cannot use `condition: service_healthy`. Operators get connection errors for the first 20–40 seconds after “Start n8n”.

Stage 13 is the general healthcheck contribution contract. Stage 25 is Tika `/tika`. Stage 27 is helper `/health`. This page is the leftover **commented official route**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Commented n8n `/healthz` block in Compose | Ready-made probe |
| n8n upstream `/healthz` | Official liveness |
| `n8n_mcp` / `mcp_gateway` env `N8N_INTERNAL_URL` | Dependents |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | Honest probe rules |
| Stage 24 `compose-depends-on-health-contract.md` (expected sibling) | `service_healthy` when a probe exists |
| Dashboard / `tu-vm.sh start-service n8n` | How n8n is started |

Out of scope:

- Changing `restart: "no"`
- Inventing `/status/n8n` on the helper
- Enabling healthchecks on services with no official route
- n8n webhook vs login nginx zones (Stage 20)

## Proposal

Uncomment and keep the existing `/healthz` test. Add a `start_period` so first boot can install and migrate. Then point dependents at `service_healthy`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `n8n` | `healthcheck` | Uncomment; `start_period: 60s`; interval 60s (energy) |
| Compose dependents | `n8n_mcp`, `mcp_gateway` | `depends_on.n8n.condition: service_healthy` when those services start |
| Dashboard | no new API | Existing start button |
| Docs | this page + Stage 24 | Commented official probes are defects |

### Rules

1. **Use `/healthz`.** Do not probe `/` or the editor HTML.
2. **Keep `restart: "no"`.** A healthy probe does not make n8n always-on.
3. **Do not add a helper route.** Compose already execs inside the container.
4. **Interval stays energy-aware** (60s or the Stage 24 `HEALTH_CHECK_*` key if that lands first).
5. **GitHub remains intake.** Requests for “auto-start n8n when a webhook arrives” are Stage 7 idle policy, not this page.

### Suggested contributor checklist

```text
1. Uncomment the existing healthcheck block
2. Add start_period: 60s (or 90s if migrate is slow)
3. Do not change restart: "no"
4. Add depends_on service_healthy from n8n_mcp and mcp_gateway
5. Confirm docker compose config still renders
6. Start n8n and confirm docker inspect reports healthy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Liveness | Official n8n `/healthz` | Helper scrape or a watchdog container |
| Start order | Compose `service_healthy` | Sleep loops in `tu-vm.sh` |
| Energy | 60s interval + start_period | 5s polls while n8n is stopped |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: uncomment + `depends_on` in one PR.
3. If n8n is stopped, dependents must stay stopped (dashboard / `tu-vm.sh` already behave this way).

## Acceptance criteria

- [ ] `n8n.healthcheck.test` calls `127.0.0.1:5678/healthz`.
- [ ] `restart` remains `"no"`.
- [ ] `n8n_mcp` and `mcp_gateway` wait on `service_healthy` when started with n8n.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] A stopped n8n does not get restarted by the probe.

## Rollback

Re-comment the healthcheck and drop dependent `service_healthy` conditions. Workflow data is unchanged.

## Success metrics

- “Start n8n” then “Start n8n-mcp” no longer races the editor boot.
- Stage 24 reviews treat a commented official probe as incomplete.
- No new n8n status endpoint appears on the helper.
