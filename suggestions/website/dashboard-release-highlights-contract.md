---
title: Dashboard Release Highlights Contract
description: Constructional contract for optional LAN dashboard “What is new” bullets that reuse GitHub Releases and CHANGELOG links instead of inventing a content CMS or mandatory cloud fetch.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: frontend
impact: medium
---

# Dashboard Release Highlights Contract

## Problem

The landing dashboard already links to GitHub Releases and [`CHANGELOG.md`](../../CHANGELOG.md). [`implementation-backlog.md`](../implementation-backlog.md) item **P1-1** asks for optional inline “What is new” bullets. Historical suggestions invent blog engines, CMS plugins, or always-on GitHub API polling from every operator browser. The community needs a **reuse-first highlights contract** that stays LAN-safe and fails closed to today’s static links.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Nginx landing “What is new” links | Current static behavior |
| GitHub Releases + Release Drafter | Canonical shipped notes on `main` |
| [`CHANGELOG.md`](../../CHANGELOG.md) | In-repo human history |
| Stage 9 `dashboard-feature-flag-experiments.md` | Gate the experiment |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Safe UI extraction + smoke |
| Stage 3 `implemented-showcase.md` (expected sibling) | Curated community wins (editorial, not automated) |
| Stage 5 `community-health-digest.md` (expected sibling) | Separate GitHub metrics lane |
| Helper API | Optional same-origin proxy/cache for metadata |

Out of scope:

- Turning the dashboard into a blog/CMS
- Requiring WAN access for the control plane to function
- Scraping third-party marketing sites
- Showing more than a tiny highlight list in the first viewport forever (keep glanceable)

## Proposal

Support **three short bullets** with layered data sources and a hard fallback.

### Source preference order

1. **Build-time or release-time JSON** committed or generated into the dashboard assets (best for air-gapped hosts).
2. **Same-origin helper endpoint** that returns cached highlights (optional; no browser talking to api.github.com).
3. **Static links only** (today)—always valid fallback.

### Suggested payload

```json
{
  "source": "release",
  "version": "x.y.z",
  "url": "https://github.com/techuties/tu-vm/releases/latest",
  "highlights": [
    "Short operator-facing bullet one",
    "Short operator-facing bullet two",
    "Short operator-facing bullet three"
  ]
}
```

### Rules

1. **Maximum three bullets**; truncate aggressively.
2. **No secrets, tokens, hostnames of private LAN, or `.env` values** in highlights.
3. **Feature-flag the UI** (`TU_UI_EXPERIMENT_RELEASE_HIGHLIGHTS`) per Stage 9 flag contract.
4. **Air-gap friendly:** offline hosts must still see static links; empty payloads must not error the whole dashboard.
5. **Do not block Tier 1 rendering** on network fetch timeouts.
6. **Editorial vs automated:** Release Drafter text may be noisy—prefer a maintainer-curated `highlights` field or a small `fixtures/release-highlights.json` updated at release time.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Source of truth | GitHub Releases / CHANGELOG | Custom news database |
| Delivery | Static JSON or helper cache | Browser-side GitHub API tokens |
| Gating | Env feature flag | Permanent untested HTML |
| Deep community stories | Stage 3 implemented showcase | Cramming RFC history into three bullets |

## Rollout

1. Publish this page; keep current static links as v0.
2. Add curated JSON path first (no runtime GitHub dependency).
3. Optionally add helper cache later under Stage 7 helper contract.
4. Enable UI behind flag; Playwright-check fallback when Stage 4 smoke exists.
5. Document release checklist item: “refresh highlights JSON.”

## Acceptance criteria

- [ ] Dashboard works offline/air-gapped with static link fallback.
- [ ] At most three highlights render when data exists.
- [ ] No GitHub token is embedded in frontend assets.
- [ ] Experiment is flag-gated and default-safe.
- [ ] Failure to load highlights does not break status/controls.

## Rollback

Disable the feature flag; remove JSON fetch; retain existing Releases/CHANGELOG anchors. No database migration.

## Success metrics

- Operators notice new releases without leaving the LAN UI, while air-gapped users see no regressions.
- Maintainers update highlights as part of release ritual instead of ad-hoc HTML edits.
- Support questions about “what changed?” decline for recent versions.
