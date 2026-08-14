---
title: Prometheus Exporter Opt-In Contract
description: Constructional contract for optional Prometheus exporters so community observability does not undo energy budgets or promote cAdvisor to always-on Tier 1.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Prometheus Exporter Opt-In Contract

## Problem

`monitoring/prometheus.yml` already documents scrape jobs for node-exporter, postgres_exporter, redis_exporter, nginx-prometheus-exporter, pihole-exporter, and cAdvisor—and every job except Prometheus itself is **commented out**. The comment is explicit: core services do not expose Prometheus metrics by default.

Community PRs that “just add cAdvisor and node-exporter” put always-on collectors on laptop hosts. That fights CHANGELOG energy work (idle CPU targets) and Stage 18 resource budgets. Stage 6 describes **how to contribute** Grafana/Prometheus artifacts. This page states **when those exporters may run**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `monitoring/prometheus.yml` | Scrape interval 15s; exporter jobs commented with enable notes |
| `monitoring/grafana/datasources/prometheus.yml` | Provisioned Prometheus datasource |
| `docker-compose.yml` | No Prometheus, Grafana, or exporter services today |
| CHANGELOG 2.0 / 2.2 | Energy-first idle CPU and Tier model |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Dashboard/alert contribution rules |
| Stage 7 `local-resource-history.md` (expected sibling) | Local snapshots—not a Prometheus replacement, and not an excuse to skip opt-in |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling) | Cron health without a metrics SaaS |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | Exporters must declare `deploy.resources` if added |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | New exporter IPs must be unique on `172.20.0.0/16` |

Out of scope:

- Making Prometheus + a full exporter set part of default `./tu-vm.sh start`
- Hosted Grafana Cloud / remote_write as a prerequisite
- Scraping Pi-hole `/admin/api.php` instead of a dedicated exporter
- Using cAdvisor as a substitute for Stage 7 local resource history

## Proposal

Keep exporters **opt-in** and energy-accounted.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Uncomment a scrape job | `monitoring/prometheus.yml` | Matching Compose service exists and is profile-gated |
| Add an exporter service | `docker-compose.yml` | `profiles: [observability]` (or the agreed Stage 19 profile name) |
| Resource budget | `deploy.resources` | Memory/CPU limits on every exporter |
| Operator start | `tu-vm.sh` or compose `--profile` | Default start path does not pull exporters |
| Docs | README / playbook | How to enable and how to disable |

### Rules

1. **Default is off.** `./tu-vm.sh start` and `quickstart` must not start exporters.
2. **Pair scrape and service.** Do not uncomment a job whose target is not in Compose.
3. **Prefer official exporters** listed in the existing YAML comments. Do not scrape admin HTML/JSON APIs.
4. **Budget every collector.** cAdvisor and node-exporter are easy to underestimate; they still need limits.
5. **15s scrape is a ceiling for laptops.** Lower frequency (30s–60s) is preferred when enabling on portable hosts.
6. **No docker.sock without Stage 18 hardening review.** cAdvisor that mounts the socket is a privileged-host change.
7. **GitHub remains intake.** Requests for a hosted metrics product stay Issues.

### Suggested contributor checklist

```text
1. Read monitoring/prometheus.yml comments
2. Add exporter services only under an opt-in Compose profile
3. Assign unused ipv4_address values (Stage 18 registry)
4. Set deploy.resources limits
5. Uncomment the matching scrape job in the same PR
6. Document enable: docker compose --profile observability up -d
7. Confirm default tu-vm.sh start still skips exporters
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Metrics | Prometheus file already in-tree | Datadog / a second TSDB |
| Enablement | Compose profiles (this Stage) | Always-on sidecar “for convenience” |
| Energy | Stage 18 budgets + commented jobs | Unlimited cAdvisor |
| Day-to-day health | `daily-checkup` + helper `/status/*` | Replacing status endpoints with PromQL |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: a documented `observability` Compose profile and a one-line playbook anchor when the first exporter lands.
3. Keep scrape jobs commented until that profile exists.

## Acceptance criteria

- [ ] Default start path remains exporter-free.
- [ ] Scrape jobs stay paired with Compose services.
- [ ] Resource limits are required for any exporter.
- [ ] docker.sock / privileged collectors require hardening review.
- [ ] Hosted metrics products are out of scope.

## Rollback

Comment scrape jobs and remove the profile. Default Tier 1 behavior must return to today’s energy envelope.

## Success metrics

- No exporter starts on portable/default boot.
- Community observability PRs land behind a profile with budgets.
- Daily checkup and `/status/*` remain the default operator path.
