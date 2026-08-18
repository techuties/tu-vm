---
title: Nginx stub_status Exporter Pairing Contract
description: Constructional contract for enabling Nginx stub_status only as the paired scrape target for an opt-in nginx-prometheus-exporter, without exposing metrics on the public edge.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx stub_status Exporter Pairing Contract

## Problem

`monitoring/prometheus.yml` already comments:

```text
# - nginx: nginx-prometheus-exporter on :9113 (and Nginx stub_status enabled)
```

Today `nginx/nginx.conf` and `nginx/conf.d/default.conf` have **no** `stub_status` location. Community PRs that uncomment the nginx scrape job either scrape nothing, or they add `stub_status` on port 80/443 where LAN clients (and any public-mode host) can read connection counts.

Stage 19 says exporters stay **opt-in**. This page is the **missing pairing rule**: stub_status exists only for the exporter, on an internal listener.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `monitoring/prometheus.yml` | Commented `job_name: nginx` → `nginx-exporter:9113` |
| `nginx/nginx.conf` | No `stub_status`; `limit_req` zones only |
| `nginx/conf.d/default.conf` | Public vhosts on 80/443; `/health` returns `healthy` |
| `docker-compose.yml` `nginx` | Official `nginx:alpine`; no exporter sidecar |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Dashboard/alert contribution |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost/`proxy_pass` rules |
| Stage 19 `prometheus-exporter-opt-in-contract.md` (expected sibling) | When exporters may run |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | Unique exporter IPv4 |

Out of scope:

- Shipping Prometheus + nginx-exporter on default `./tu-vm.sh start`
- Scraping access logs with a log shipper as a substitute for stub_status
- Exposing `/nginx_status` on `tu.lan:443`
- Replacing the landing `/health` probe with stub_status

## Proposal

Pair **internal stub_status** with **profile-gated nginx-prometheus-exporter**.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| stub_status | New internal `server` in `nginx/conf.d/` | Listen on loopback or an internal port only |
| Exporter service | `docker-compose.yml` | `profiles: [observability]` (Stage 19 name) |
| Scrape job | `monitoring/prometheus.yml` | Uncomment `nginx` only in the same PR as the exporter |
| Allowlist | stub_status `allow` | Exporter IP / Unix socket; `deny all` |
| Health | Existing `/health` | Unchanged; smoke `--live` still uses it |

### Rules

1. **No public stub_status.** Do not add `location /nginx_status` on `listen 443` vhosts.
2. **Prefer nginx-prometheus-exporter.** Official image scrapes stub_status and exposes `:9113/metrics`. Do not scrape stub_status directly from Prometheus if the exporter is the documented job.
3. **Same PR pairing.** Adding stub_status without an opt-in exporter (or uncommenting the job without stub_status) is incomplete.
4. **Internal listen.** Typical shape: `listen 127.0.0.1:8080;` inside the nginx container, or a dedicated `server` on an unmapped port. Do not publish that port to the host.
5. **Allowlist the scraper.** `allow 172.20.0.0/16;` (or the exporter's static IP) plus `deny all`.
6. **Energy.** Exporter + scrape inherit Stage 19 opt-in and Stage 18 resource budgets.
7. **GitHub remains intake.** Requests for Datadog/nginx Plus stay Issues.

### Suggested contributor checklist

```text
1. Read monitoring/prometheus.yml nginx comment
2. Add stub_status on an internal listener (not 443)
3. allow exporter IP; deny all
4. Add nginx-prometheus-exporter under profiles: [observability]
5. Uncomment the nginx scrape job in the same PR
6. Confirm curl https://tu.lan/nginx_status is not world-readable
7. Confirm default tu-vm.sh start still skips the exporter
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Nginx metrics | stub_status + nginx-prometheus-exporter | Access-log parsers / SaaS APM |
| Enablement | Stage 19 observability profile | Always-on sidecar on laptops |
| Edge security | Internal listen + deny all | Public `/nginx_status` |
| Dashboards | Stage 19 Grafana as-code | Click-ops panels with no review |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: internal stub_status server + profile-gated exporter + uncommented scrape job together.
3. Optional CI: fail if `stub_status` appears under a `listen 443` server block.

## Acceptance criteria

- [ ] stub_status is forbidden on public 80/443 vhosts.
- [ ] Exporter and stub_status are paired in one change.
- [ ] Default start path does not enable either.
- [ ] Existing `/health` probes stay the smoke target.

## Rollback

Remove the internal server block and the exporter service independently. Re-comment the scrape job. Landing `/health` is unaffected.

## Success metrics

- nginx scrape jobs have a live stub_status target only when the observability profile is on.
- Public vhosts do not expose stub_status.
- Smoke `--live` continues to use `/health`.
