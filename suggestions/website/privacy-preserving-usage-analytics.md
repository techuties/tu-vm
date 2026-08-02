---
title: Privacy-Preserving Usage Analytics
description: Constructional contract for local-only service usage patterns and operator recommendations that reuse helper status, Compose health, and optional resource history instead of inventing cloud product analytics.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Privacy-Preserving Usage Analytics

## Problem

[`CHANGELOG.md`](../../CHANGELOG.md) lists **Usage Analytics** (service usage patterns and recommendations) as a potential improvement. Historical suggestion branches often jump to SaaS product analytics, anonymous phoning-home, or dashboard heatmaps that leave the LAN. Operators still need day-to-day answers—“which Tier 2 services sit idle?” / “should I enable Energy Save?”—without reinventing a telemetry platform.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Helper `/status/full` + fixture contract | Current service health surface |
| Stage 7 `local-resource-history.md` (expected sibling) | Local CPU/memory trend snapshots |
| Stage 7 `tier2-idle-autostop-policy.md` (expected sibling) | Idle timeout signals for heavy services |
| Stage 7 `battery-power-operator-signals.md` (expected sibling) | Energy-aware recommendations |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Prometheus/Grafana host metrics lane |
| Stage 5 `community-health-digest.md` (expected sibling) | **GitHub** community metrics (separate lane) |
| PR #25 privacy-safe support bundle | Operator-local diagnostics export |
| Nginx landing dashboard | Place to show short local recommendations |

Out of scope:

- Default cloud telemetry, APM SaaS, or marketing analytics
- Tracking prompt contents, chat transcripts, document filenames, or user identities
- Mixing GitHub contributor metrics into host usage analytics
- Replacing Prometheus with a custom events warehouse

## Proposal

Treat usage analytics as a **local recommendation layer** over existing status and optional history.

### Behaviors

1. **Count starts/stops and healthy uptime** from Compose/helper observations already available on-box.
2. **Recommend profile changes** (Work / AI / Energy) when Stage 2/4 profiles exist and heavy services are idle.
3. **Surface three short tips** on the dashboard (or `./tu-vm.sh doctor` appendix)—never more than a glanceable list.
4. **Keep raw series local.** Retention defaults short; no mandatory export.
5. **Separate lanes clearly:** host usage ≠ Prometheus scrape cards ≠ GitHub community digest.

### Suggested data shape (local only)

```json
{
  "generated_at": "2026-08-02T08:00:00Z",
  "window_days": 7,
  "services": [
    {"name": "ollama", "tier": 2, "healthy_ratio": 0.12, "last_healthy_at": null}
  ],
  "recommendations": [
    {"id": "REC-idle-ollama", "severity": "info", "text": "Ollama idle most of the week; prefer AI Mode on demand."}
  ]
}
```

### Community contribution opportunities

- Recommendation rule PRs with unit-tested predicates (no PII inputs)
- Playbook snippets translating tips into `tu-vm.sh` commands
- Hardware-class thresholds linked to the Stage 2 matrix

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Signals | Helper status + optional Stage 7 history | Browser fingerprinting or third-party SDKs |
| Graphs | Stage 6 Grafana when deep dive needed | Custom charting framework in nginx HTML |
| Sharing | Redacted support bundle (PR #25) | Pasting full analytics JSON into public Issues |
| Community metrics | Stage 5 GitHub digest | Host uptime as a public scoreboard |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prototype recommendations as pure functions over fixture `/status/full` samples.
3. Gate any new helper slice behind the Stage 7 helper contribution contract and fixture-additive rules.
4. Add playbook anchor `#playbook-usage-recommendations` when CLI/dashboard tips land.
5. Keep CHANGELOG “Usage Analytics” item linked to the implementing PR.

## Acceptance criteria

- [ ] Default install sends **no** usage data off-LAN.
- [ ] Recommendations never include prompts, filenames, IPs of clients, or `.env` values.
- [ ] Tips degrade gracefully when history is absent (status-only mode).
- [ ] Host usage docs explicitly separate Prometheus and GitHub digest lanes.
- [ ] First milestone reuses helper/Compose signals—no new analytics database service.

## Rollback

Disable the recommendations panel/flag; retain status endpoints unchanged. Delete local history files if operators opt out. No cloud account cleanup required.

## Success metrics

- Fewer “which services should I stop?” support threads.
- Operators report tips as actionable (`profile` / `stop` / Energy Save) rather than vanity graphs.
- Community PRs add recommendation rules instead of proposing SaaS analytics.
