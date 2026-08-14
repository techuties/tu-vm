---
title: Grafana Dashboard-as-Code Contract
description: Constructional contract for community Grafana dashboards as provisioned JSON beside the existing Prometheus datasource—reuse monitoring/ instead of click-ops or a second observability product.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Grafana Dashboard-as-Code Contract

## Problem

The repo already has Grafana datasource provisioning (`monitoring/grafana/datasources/prometheus.yml`) pointing at `http://prometheus:9090`. There is **no** `monitoring/grafana/dashboards/` tree, no dashboard provider YAML, and no Grafana service in Compose. Community “add a dashboard” PRs therefore either paste screenshots into Markdown or assume a click-ops Grafana that is not in git.

Stage 6 covers observability contribution rules. Stage 19 Prometheus opt-in covers **when collectors run**. This page covers **how dashboards are stored and reviewed** so they remain community-reviewable and energy-honest.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `monitoring/grafana/datasources/prometheus.yml` | Provisioned Prometheus datasource |
| `monitoring/prometheus.yml` | Scrape config (exporters commented) |
| Nginx landing + helper `/status/*` | Default operator visibility |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Alerts and contribution hygiene |
| Stage 7 `local-resource-history.md` (expected sibling) | Local snapshots for hosts without Grafana |
| Stage 9 `dashboard-release-highlights-contract.md` (expected sibling) | LAN “What is new”—not Grafana |
| Stage 19 `prometheus-exporter-opt-in-contract.md` | Exporters stay profile-gated |

Out of scope:

- Grafana Cloud, Auth proxy SSO, or a public metrics site
- Replacing the Nginx operational dashboard with Grafana
- Dashboards that require always-on cAdvisor
- Checking binary `.json` exports that contain local API keys

## Proposal

When Grafana is enabled (opt-in profile), dashboards land as **code** under `monitoring/grafana/`.

### Suggested layout

```text
monitoring/grafana/
  datasources/prometheus.yml      # already exists
  dashboards/dashboards.yml       # provider (foldersFromFilesStructure)
  dashboards/json/
    energy-overview.json
    tier1-health.json
```

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| New dashboard | `monitoring/grafana/dashboards/json/*.json` | Uses the provisioned Prometheus datasource name |
| Provider | `dashboards.yml` | File provisioning, not UI-only folders |
| Queries | PromQL against jobs that exist when the observability profile is on | No hard-coded laptop hostnames |
| Docs | Playbook or README | How to open Grafana on LAN only |

### Rules

1. **Git is source of truth.** UI edits must be re-exported to JSON in the same PR or they will be overwritten on restart.
2. **No secrets in JSON.** Datasource passwords, tokens, or `.env` values are defects.
3. **Datasource name is `Prometheus`.** Match the existing provisioning file.
4. **Honor opt-in.** Dashboards that need node-exporter or cAdvisor must say so and must not imply those jobs are default.
5. **Keep the ops dashboard.** Grafana does not replace `nginx/html/index.html`.
6. **Four-panel discipline.** Prefer a few high-contrast panels (energy, memory, disk, service up) over a wall of graphs.
7. **GitHub remains intake.** Requests for a hosted Grafana stay Issues.

### Suggested contributor checklist

```text
1. Confirm the observability profile (or documented enable path) exists or is in the same PR
2. Add JSON under monitoring/grafana/dashboards/json/
3. Reference datasource name Prometheus
4. Strip unique IDs / local URLs that break other operators
5. Note required scrape jobs in the PR
6. Do not commit Grafana session cookies or API keys
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Dashboards | Grafana file provisioning | Click-ops only |
| Metrics backend | In-tree Prometheus | A second TSDB |
| Default visibility | Helper `/status/*` + landing page | Forcing Grafana on portable installs |
| Alerts | Stage 6 contract | PagerDuty as a prerequisite |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: dashboard provider YAML + one sample energy-overview JSON when Grafana is first composed.
3. Add a secret-scan note for `monitoring/grafana/**/*.json` in existing CI if needed.

## Acceptance criteria

- [ ] Provisioned JSON is the contribution surface.
- [ ] Datasource name stays `Prometheus`.
- [ ] Secrets in dashboard JSON are defined as defects.
- [ ] Dashboards declare required exporter jobs.
- [ ] Nginx landing page remains the default control plane.

## Rollback

Remove dashboard JSON and the provider file. Datasource provisioning can remain. Operators who never enabled Grafana see no change.

## Success metrics

- Community dashboards review as diffs, not screenshots.
- No Grafana secrets land in git.
- Portable default installs still skip Grafana.
