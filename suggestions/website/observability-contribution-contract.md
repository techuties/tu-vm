---
title: Observability Contribution Contract
description: Constructional contract for community contributions to Prometheus and Grafana monitoring that reuses the existing monitoring stack without SaaS telemetry.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: observability
impact: medium
---

# Observability Contribution Contract

## Problem

The repository already includes a `monitoring/` tree (Prometheus config, Grafana assets) and operational scripts such as `daily-checkup`. Historical suggestions often leap to “product analytics,” third-party APM, or dashboard widgets that exfiltrate LAN metrics. Community contributors who want better graphs lack a **reuse-first contribution path**, so proposals reinvent observability instead of extending Prometheus/Grafana.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `monitoring/prometheus.yml` | Scrape configuration |
| `monitoring/grafana/` | Dashboard provisioning assets |
| `scripts/daily-checkup.sh` | Operator health ritual |
| Stage 3 `community-quality-gates.md` (expected sibling) | Evidence expectations |
| Stage 5 `community-health-digest.md` (expected sibling) | **GitHub** community metrics (separate from host metrics) |
| PR #25 privacy-safe support bundle | Operator-local diagnostics |
| LAN-first security posture | No mandatory cloud telemetry |

Out of scope:

- Shipping operator host metrics to public SaaS by default
- Mixing GitHub community health digests into Prometheus
- Replacing Prometheus with a custom metrics database
- High-cardinality labels that include usernames, file paths, or prompt contents

## Proposal

Publish an **observability contribution contract** for PRs that touch monitoring.

### Allowed contribution types

| Type | Examples | Evidence |
|---|---|---|
| Scrape target | Add job for an existing Compose exporter | `prometheus.yml` diff + reload notes |
| Dashboard JSON | Grafana panel for helper latency / container health | Import path + screenshot optional |
| Alert rule | Disk/backup job failure (when alertmanager exists) | Runbook link + severity |
| Docs | How to enable monitoring Tier | Playbook anchor |

### Label hygiene

- Prefer `service`, `instance`, `job` labels already used by the stack.
- **Forbid** labels that may carry PII or document contents (`filename`, `user_email`, `prompt_hash` unless explicitly privacy-reviewed).
- Document retention assumptions; default local only.

### Contribution layout (v1)

```text
monitoring/
  prometheus.yml              # authoritative scrape config
  grafana/dashboards/         # one JSON file per dashboard id
  grafana/README.md           # import / provisioning instructions
```

Each dashboard JSON PR includes:

1. Purpose (one paragraph)
2. Data source assumptions (local Prometheus)
3. Rollout (`./tu-vm.sh` or compose service name for monitoring, if any)
4. Rollback (remove JSON / revert scrape job)

### Website placement

- Community → Observe → this contract
- Clear banner: **Community health digest (GitHub) ≠ host observability (Prometheus)**

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Metrics | Prometheus | Custom `/metrics` product for docs site |
| Dashboards | Grafana JSON over provisioning | Vendor-locked cloud dashboards as default |
| Community KPIs | Stage 5 GitHub digest | Scraping GitHub from the operator LAN forever |
| Privacy | Local retention + redaction | Default remote_write to the internet |

## Rollout

1. Land this page; add `monitoring/grafana/README.md` if missing with import steps.
2. Accept the first community dashboard PR under this contract as the template.
3. Link from day-to-day tooling docs and quality gates for `monitoring/**` changes.
4. Optionally add CI JSON syntax validation for `monitoring/grafana/dashboards/*.json`.

## Acceptance criteria

- [ ] Contract distinguishes host observability from GitHub community digests.
- [ ] Label/PII rules and rollback notes are explicit.
- [ ] Contribution paths point at existing `monitoring/` files.
- [ ] No suggestion page recommends mandatory SaaS APM for TU-VM cores.

## Rollback

Keep monitoring stack as-is; treat this page as advisory if CI JSON validation is too noisy.

## Success metrics

- Monitoring PRs cite this contract in the PR body.
- No merged scrape config ships remote_write without a Decision Log entry.
- Operators gain at least one community-maintained dashboard without new vendors.
