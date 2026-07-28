---
title: Community Health Digest
description: Constructional contract for a privacy-safe, GitHub-native community health digest published as static markdown for day-to-day maintainer awareness.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Community Health Digest

## Problem

Community frameworks stall without lightweight feedback loops. Maintainers need to see suggestion cycle time, stale pressure, CI flake categories, and contributor throughput—without building an analytics product, instrumenting operator LAN traffic, or shipping personally identifiable dashboards. Historical suggestions floated “contributor health dashboards” inside Nginx; that mixes control-plane UX with public community metrics and risks privacy surprises.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| GitHub Issues / PRs / Actions | Raw community and CI signals |
| `.github/workflows/stale.yml` | Stale and needs-info pressure |
| Release Drafter + Releases | Ship cadence |
| Stage 1 status-board | Human lifecycle view |
| Stage 3 quality gates | Evidence expectations per change type |
| Stage 4 supply-chain gates | Security signal channel |
| PR #25 support bundle | Operator-local diagnostics (separate from community metrics) |

Out of scope:

- Telemetry from `tu.lan` dashboards or helper APIs to the public internet
- Third-party product analytics on documentation traffic by default
- Ranking individual contributors publicly in ways that encourage unhealthy competition
- Real-time WebSocket community dashboards

## Proposal

Add a **scheduled GitHub Action** that regenerates a static markdown digest using `gh` / GitHub API—publishable on the community website as read-only content.

### Output path

```text
suggestions/website/health-digest-latest.md
```

Later, after docs-framework adoption, the same generator writes into `docs/community/` (one editable/generated path only). Commit the file on a bot branch or attach it as a workflow artifact; prefer a PR or direct commit to `dev` only if the team accepts bot commits.

### Metrics (aggregate only)

| Metric | Definition | Privacy note |
|---|---|---|
| Open suggestions | Count of open issues with `suggestion` | Counts only |
| Median time to first triage | Open → first non-author label/comment | No user tables required in the page |
| Accepted / deferred / closed (30d) | Label outcomes | Aggregates |
| Stale pressure | Issues with `stale` or `needs-info` | Counts |
| PR lead time (30d) | Open → merge median for non-`skip-changelog` | Aggregates |
| CI failure categories | Top failing workflow names (not logs) | No secret logs |
| Good-first-issue availability | Open count | Counts |

Explicitly **omit**: email addresses, IP addresses, operator hostnames, LAN URLs, secret-bearing job logs.

### Page template

```markdown
---
title: Community Health Digest
last_updated: YYYY-MM-DD
generated: true
---

# Community Health Digest (week of YYYY-MM-DD)

## Snapshot
...

## Funnel
...

## CI reliability
...

## Maintainer actions this week
- [ ] Triage Inbox to zero
- [ ] Clear needs-info older than N days
- [ ] Refresh status-board curated rows
```

### Cadence

- Weekly schedule (`cron` in Actions), plus `workflow_dispatch`.
- Fail open: if API rate limits hit, keep previous digest and annotate the failure in the job summary.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Data source | GitHub API via Actions | Scraping the LAN dashboard |
| Publishing | Static markdown in docs/community site | Hosted BI tools for v1 |
| Auth | `GITHUB_TOKEN` / fine-scoped app | Long-lived PATs in `.env` of operators |
| Visualization | Tables in markdown (optional mermaid later) | Mandatory chart SaaS |

## Rollout

1. Implement generator script under `scripts/community-health-digest.py` (or shell + `gh`).
2. Add workflow with contents permissions limited to the digest path.
3. Link digest from community index and Stage 1 status-board.
4. Review first four digests manually before advertising widely.

## Acceptance criteria

- [ ] Weekly digest produces aggregate metrics without PII tables.
- [ ] No operator telemetry or helper API calls involved.
- [ ] Digest links back to GitHub searches/boards, not a parallel database.
- [ ] Failure mode preserves the last good digest.
- [ ] SECURITY: workflow cannot print secret values from other jobs.

## Rollback

Disable the workflow; delete or freeze `health-digest-latest.md`. Community process continues via Issues and the Project board.

## Success metrics

- Maintainers reference the digest in triage notes at least monthly.
- Stale/`needs-info` counts trend down after digest-driven attention.
- No privacy incidents related to digest content.
