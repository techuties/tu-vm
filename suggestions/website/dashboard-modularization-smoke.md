---
title: Dashboard Modularization and Browser Smoke
description: Constructional plan to extract Nginx landing-page assets and add Playwright Tier-1 smoke tests using existing dashboard surfaces.
last_updated: 2026-07-27
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Dashboard Modularization and Browser Smoke

## Problem

The LAN landing dashboard in `nginx/html/index.html` is a high-value community surface (status, operator hub, playbook shortcuts) but remains a large monolith. Implementation backlog items P2-1 and P2-2 call for asset extraction and Playwright smoke tests. Without a published contract, contributors either fear touching the dashboard or propose full SPA frameworks that reinvent the control plane.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/html/index.html` | Operational dashboard (keep as control plane) |
| Helper API + `/status/*` | Data plane for status cards |
| `scripts/smoke-test.sh` / `--live` | HTTP-level smoke today |
| Stage 3 quality gates | Maps UI changes to evidence |
| Docs-framework adoption (Stage 3) | Separate static docs site—do not merge into Nginx CMS |
| Implementation backlog P2-1 / P2-2 / P2-3 | Prioritized engineering items |

Out of scope:

- Replacing the dashboard with React/Vue SPA by default
- Moving community suggestion intake into the dashboard
- Authenticated public social features on the LAN UI
- Full visual regression suite on day one

## Proposal

Two sequenced constructional tracks that share one acceptance mindset: **behaviorally equivalent UX** and **CI-proven Tier-1 flows**.

### Track 1 — Incremental asset extraction (P2-1)

1. Create `nginx/html/assets/css/` and `nginx/html/assets/js/`.
2. Extract CSS and JS in small PRs (layout → status polling → operator hub).
3. Keep `index.html` as the composition root served by Nginx (no bundler required for v1).
4. Add ESLint/stylelint only on extracted files to avoid boiling the ocean.
5. Preserve LAN-first relative paths; avoid CDN dependencies for core UI.

Optional later: a tiny build step only if tree-shaking becomes necessary—default remains static files Docker already serves.

### Track 2 — Playwright smoke (P2-2)

Reuse the Playwright ecosystem already present in spirit via `mcp-tools/playwright`, but for **CI browser tests** prefer the standard Playwright Test runner (mature framework—do not invent a browser harness).

Minimum Tier-1 flows:

| Flow | Assertion |
|---|---|
| Dashboard loads | Title/landmark visible over HTTPS fixture or `tu.lan` |
| Status region | Key services render a known state class or text |
| Community / operator hub links | Playbook anchors and Releases/CHANGELOG links resolve in-page |
| Control actions (read-only) | Unauthenticated control attempts still denied (401) where applicable |

CI options (pick one in implementation PR):

1. **Fixture mode** — serve static `nginx/html` with a stub helper; fastest, no full stack.
2. **Live mode** — optional job when secrets/stack exist; not required for every PR.

Document local run:

```bash
# illustrative
npx playwright test --config tests/playwright/playwright.config.ts
```

Keep tests few and stable; flake budgets kill community trust.

### Feature flags (P2-3, light touch)

Before large experimental panels:

- Gate with env-driven flags read by helper or static config injection.
- Default off; document rollback as “unset flag”.
- Do not build a flag management product.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Structure | Progressive extraction of static assets | Premature SPA rewrite |
| Lint | ESLint/stylelint on extracted files | Reformatting all historical HTML at once |
| Browser tests | Playwright Test | Custom Selenium wrappers |
| Docs site | Starlight/Docusaurus/MkDocs after gates | Teaching Nginx to be a CMS |
| Community intake | GitHub Issues | Dashboard suggestion forms |

### Contributor day-to-day

1. Touch only the extracted asset needed for the change.
2. Run `./scripts/smoke-test.sh` (and `--live` when stack is up).
3. Run Playwright fixture tests when UI structure changes.
4. Link evidence in the PR; cite Stage 3 quality gates matrix.

## Acceptance criteria

- [ ] CSS/JS extracted with equivalent UX for covered areas.
- [ ] Lint runs on extracted assets in CI or pre-commit.
- [ ] Playwright covers at least the Tier-1 flows table.
- [ ] Fixture mode runs without full Docker Tier 1 when possible.
- [ ] Control-plane allowlist / unauthenticated denial behavior unchanged.
- [ ] Website docs describe local test commands for newcomers.

## Rollout and rollback

1. Extract CSS only → extract JS modules → add Playwright fixture job.
2. Promote Playwright to required status after flake burn-down.
3. Rollback = restore monolithic HTML from git; disable Playwright job.

## Success signals

- Dashboard PRs shrink in diff size and review time.
- Regressions in hub links or status rendering fail CI before merge.
- Contributors stop proposing “rewrite the UI in X” as the first step.
