---
title: Local Resource Usage History
description: Constructional contract for privacy-preserving local CPU and memory history snapshots that reuse existing status and monitoring paths instead of SaaS analytics.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: observability
impact: medium
---

# Local Resource Usage History

## Problem

CHANGELOG planned features include **resource usage history charts**. Historical suggestions often jump to product analytics platforms. TU-VM’s private-AI posture needs a **local-only history** contract that complements Prometheus/Grafana when monitoring is enabled, and still works lightly when it is not.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Helper `/status/full` and related status routes | Point-in-time operator view |
| `monitoring/` Prometheus + Grafana | Richer metrics when Tier monitoring is on |
| Stage 6 observability contribution contract | Rules for scrape jobs and dashboards |
| Stage 5 community health digest | GitHub community metrics (different domain) |
| Stage 7 battery/power signals | Related operator signal, not a substitute |
| `scripts/daily-checkup.sh` | Existing ritual that can emit a daily snapshot |

Out of scope:

- Mandatory remote_write or SaaS product analytics
- Tracking prompts, filenames, or user identities in history series
- Replacing Prometheus with a custom time-series database as a hard dependency
- Multi-tenant cloud billing metrics

## Proposal

Define two complementary paths; prefer the richer one when present.

### Path A — Monitoring stack (preferred when enabled)

- Use Prometheus retention + a Grafana dashboard for CPU/memory/container series.
- Community dashboard contributions follow the Stage 6 observability contract.
- Website docs tell operators how to enable monitoring Tier and open the dashboard.

### Path B — Lightweight local snapshots (always available)

When full monitoring is off, store a small ring buffer of daily/hourly snapshots on the host (not in git):

```text
var/resource-history/YYYY-MM-DD.json
```

Illustrative record:

```json
{
  "ts": "2026-07-31T08:00:00Z",
  "cpu_percent": 23.5,
  "mem_percent": 61.0,
  "mem_used_mb": 9800,
  "tier2_running": ["ollama"]
}
```

Expose a helper read endpoint (for example `/status/resources/history`) that returns the last N points for dashboard sparklines.

### Rules

1. **Local retention only** (configurable; suggest 30–90 days).
2. **Coarse labels only** (service names already on the status board—no prompt content).
3. **Additive helper contract** for any JSON consumed by the dashboard.
4. **No default upload** to GitHub Issues, digests, or third parties.
5. **Honest empty state** when history is disabled or too new for charts.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Rich metrics | Prometheus + Grafana | Building a custom TSDB |
| Light mode | JSON snapshots + helper | Embedding SQLite analytics product |
| Charts | Dashboard canvas / simple SVG after modularization | Heavy chart SaaS SDKs |
| Privacy | Local disk + LAN fetch | Phone-home usage analytics |

## Rollout

1. Land this page; decide Path A vs Path B priority per hardware class.
2. If Path B: add snapshot writer hooked from daily-checkup or a small timer; document disk paths.
3. Helper endpoint + optional dashboard sparkline behind a flag.
4. Path A: accept/link a Grafana dashboard JSON under `monitoring/`.
5. Mention in playbooks and persona paths for “homelab optimizer” operators.

## Acceptance criteria

- [ ] Default design never requires cloud analytics.
- [ ] History schema and retention are documented.
- [ ] Helper/fixture impact follows the helper API contribution contract.
- [ ] Observability path clearly preferred when monitoring is enabled.
- [ ] Community health digest remains separate from host resource history.

## Rollback

Disable snapshot writer and hide the widget; delete local history files if desired. Grafana dashboards can be removed without affecting Tier 1.

## Success metrics

- Operators can answer “was last night heavier than usual?” without external tools.
- Duplicate “add Datadog/Plausible for hosts” suggestions decline.
- Monitoring adopters reuse Grafana instead of a second charting stack.
