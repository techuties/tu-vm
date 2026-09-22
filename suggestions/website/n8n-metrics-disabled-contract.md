---
title: n8n Metrics Endpoint Contract
description: Constructional contract to pin official N8N_METRICS=false so the n8n /metrics endpoint stays off on the public n8n vhost.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Metrics Endpoint Contract

## Problem

Official n8n endpoint configuration documents `N8N_METRICS` with default `false`. When `true`, n8n exposes `/metrics`. Related keys can add workflow-id, node-type, credential-type, API path, and status-code labels. Those labels describe community workflows to anyone who can scrape the endpoint.

Compose does not pin `N8N_METRICS`. Nginx `n8n.tu.lan` proxies `location /` to the n8n container, including whatever path n8n publishes. A later Compose edit that sets `N8N_METRICS=true` would put that endpoint on the same vhost as the editor.

Stage 19 `prometheus-exporter-opt-in-contract.md` is the platform Prometheus opt-in. This page is the n8n product endpoint only. Stage 35 version-notification and hiring-banner pages are editor chrome, not `/metrics`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official n8n endpoints reference | `N8N_METRICS` default `false` |
| `n8n` environment | `N8N_DIAGNOSTICS_ENABLED` and `N8N_TELEMETRY_ENABLED` already `false`; metrics key unset |
| Nginx `server_name n8n.tu.lan` | `location /` proxies the whole app, including a future `/metrics` |
| Stage 19 Prometheus opt-in (expected sibling) | Platform scrape path, separate decision |
| GitHub Issues | Place to request a private scrape later |

Out of scope:

- Enabling Prometheus, Grafana dashboards, or a new exporter
- Setting `N8N_METRICS_INCLUDE_*` label flags (they stay unused while metrics are off)
- Changing `N8N_DIAGNOSTICS_ENABLED` or `N8N_TELEMETRY_ENABLED` (already false)
- Rewriting the Stage 19 exporter contract

## Proposal

Pin the official default on the `n8n` service:

```text
N8N_METRICS: "false"
```

Do not invent `TU_VM_N8N_METRICS`. Do not set `N8N_METRICS_INCLUDE_WORKFLOW_ID_LABEL`, `N8N_METRICS_INCLUDE_CREDENTIAL_TYPE_LABEL`, or `N8N_METRICS_INCLUDE_API_PATH_LABEL`. If a later Issue needs queue health, scrape from a network that is not the public editor vhost, and keep workflow and credential labels off.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag false |
| Env schema | `env.example` | Comment that `/metrics` stays off |
| Docs | n8n playbook | Point platform metrics at Stage 19 |
| Nginx | `n8n.tu.lan` | Do not add a public `/metrics` location |

### Rules

1. **Official key only.** `N8N_METRICS=false` matches the endpoints reference.
2. **Leave label flags unset.** They matter only after metrics are turned on.
3. **Platform Prometheus stays Stage 19.** Do not register n8n as a default scrape target here.
4. **Diagnostics stay as they are.** Telemetry and diagnostics are already false in Compose.
5. **GitHub remains intake.** A private metrics endpoint is a new Issue.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_METRICS default false
2. Set N8N_METRICS=false on the n8n service
3. Restart n8n and request https://n8n.tu.lan/metrics
4. Confirm the endpoint is not a Prometheus scrape body
5. Do not set N8N_METRICS_INCLUDE_WORKFLOW_ID_LABEL
6. Do not rewrite the Stage 19 Prometheus contract
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Keep `/metrics` off | Official `N8N_METRICS=false` | An Nginx deny written only for this path |
| Platform metrics later | Stage 19 Prometheus opt-in | Turning on n8n metrics on the editor vhost |
| Workflow privacy | Leave `N8N_METRICS_INCLUDE_*` unset | Enabling metrics with workflow-id labels |
| Phone-home | Existing diagnostics and telemetry flags | A new telemetry filter |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an n8n recreate.
3. Operators use existing health and `tu-vm.sh` checks for day-to-day status.

## Acceptance criteria

- [ ] `n8n` sets `N8N_METRICS=false`.
- [ ] No `N8N_METRICS_INCLUDE_*` keys are added.
- [ ] Stage 19 Prometheus files are unchanged by this contract.

## Rollback

Remove the pin to restore the same official default, or set `true` only inside an Issue that names the scrape network and forbids workflow and credential labels.

## Success metrics

- `https://n8n.tu.lan/metrics` does not publish workflow or credential series.
- Diagnostics and telemetry remain false.
