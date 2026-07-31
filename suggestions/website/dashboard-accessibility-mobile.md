---
title: Dashboard Accessibility and Mobile Baseline
description: Constructional acceptance baseline for keyboard accessibility, screen-reader basics, and touch-friendly LAN dashboard UX without rebuilding the control plane as a separate mobile app.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Dashboard Accessibility and Mobile Baseline

## Problem

Historical website roadmaps call out **accessibility** and **mobile optimization** for the operator dashboard. CHANGELOG lists expanded mobile UX as a potential improvement. Without a written baseline, contributors either ignore a11y or propose a full rewrite / native app. Community day-to-day use needs boring, testable rules on the existing Nginx landing page.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/html/index.html` | Operational control plane UI |
| Stage 4 dashboard modularization + Playwright smoke | Safe extraction and regression tests |
| Stage 2 persona entry paths | First-hour operator journeys |
| Stage 5 control-plane contribution contract | What may change in nginx/html |
| Existing community strip / playbook shortcuts | Patterns already on the landing page |
| Playwright (proposed) | Automated smoke for critical flows |

Out of scope:

- Building a separate React SPA as a prerequisite for a11y
- Pixel-perfect parity with desktop for every dense admin table on day one
- Replacing LAN auth/allowlist rules to “make mobile easier”
- Third-party overlay accessibility widgets that phone home

## Proposal

Adopt a **minimum acceptance baseline** for dashboard PRs that touch UI.

### Keyboard and semantics (v1)

- Interactive controls are reachable via Tab in a sensible order.
- Buttons/links are real `<button>` / `<a>` (or have correct roles/names).
- Status chips expose text equivalents (not color alone).
- Focus visible on interactive elements (no `outline: none` without a replacement).
- Control actions that change services announce result via visible status text (aria-live optional but encouraged after modularization).

### Touch / small viewport (v1)

- Primary actions meet a minimum touch target (~44px CSS px guidance).
- Critical Tier 1 status remains readable without horizontal scroll at 360px width.
- Destructive / power actions use clear confirmation; no accidental fat-finger starts/stops on the first paint.
- Sticky headers/nav do not cover action buttons on common phone heights.

### Testing expectations

| Check | When |
|---|---|
| Manual keyboard pass on changed controls | Every UI PR |
| Narrow viewport screenshot or Playwright viewport test | After Stage 4 smoke lands |
| Color-contrast spot check for new text/status colors | When introducing new tokens |
| Prefer extracted CSS/JS (Stage 4) for lintable changes | As modularization proceeds |

### Website placement

- Contributors → Dashboard UX baseline
- Link from persona paths for “operator on a phone at the rack”
- Reference from Playwright smoke docs once they exist

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| UI surface | Existing landing dashboard | Parallel mobile app |
| Tests | Playwright + manual keyboard checklist | Only visual QA on desktop Chrome |
| Components | Progressive enhancement after CSS/JS extract | Accessibility SaaS overlays |
| Docs | This baseline + playbooks | Undocumented “we will fix a11y later” |

## Rollout

1. Land this page; add a short checklist bullet to the PR template for `nginx/html/**` changes.
2. During Stage 4 modularization, fix the highest-traffic controls first (start/stop, status, playbook links).
3. Add one Playwright mobile viewport smoke for the status strip.
4. Track follow-ups as GitHub Issues labeled `good first issue` where safe.

## Acceptance criteria

- [ ] Baseline checklist is linked for dashboard UI PRs.
- [ ] Color is not the only status encoding for primary health states.
- [ ] Primary actions remain usable at a 360px-wide viewport.
- [ ] No PR under this contract weakens LAN control-plane security for convenience.
- [ ] Automated smoke gains at least one mobile viewport case when Playwright lands.

## Rollback

Keep the page as guidance; do not block unrelated helper/backend PRs on full a11y audits.

## Success metrics

- Fewer mobile “can’t tap stop” reports.
- Community UI PRs mention keyboard/touch checks in Verification.
- Accessibility improvements ship incrementally without a rewrite project.
