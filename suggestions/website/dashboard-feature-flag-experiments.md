---
title: Dashboard Feature-Flag Experiments
description: Constructional contract for env-driven dashboard experiments that reuse the Nginx landing page and helper config patterns instead of adopting a third-party feature-flag platform.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: frontend
impact: medium
---

# Dashboard Feature-Flag Experiments

## Problem

[`implementation-backlog.md`](../implementation-backlog.md) still lists feature-flagged dashboard rollouts (P2-3). Historical UI suggestions either merge large HTML changes darkly or propose LaunchDarkly-style platforms for a LAN control plane. Contributors need a **small, env-driven experiment contract** that keeps day-to-day rollback trivial.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/html/index.html` | Operator dashboard |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Asset extraction + Playwright smoke |
| Stage 7 `dashboard-accessibility-mobile.md` (expected sibling) | A11y/mobile acceptance |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | Additive `/status` fields for flag exposure |
| `env.example` | Operator-visible configuration surface |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Safety rules for control-plane changes |

Out of scope:

- Multi-tenant remote flag CDNs or SaaS evaluation APIs
- Per-user targeting / percentage rollouts across households (unnecessary for single-host LAN)
- Experimenting with auth/allowlist bypass behind flags
- Flags that change Tier 1 security defaults without RFC labeling

## Proposal

Use **named boolean (or enum) flags** sourced from env / helper config, defaulting to today’s behavior.

### Suggested conventions

```text
TU_UI_EXPERIMENT_<NAME>=false   # default off
```

Examples:

| Flag | Intent |
|---|---|
| `TU_UI_EXPERIMENT_USAGE_TIPS` | Stage 9 usage recommendation panel |
| `TU_UI_EXPERIMENT_RELEASE_HIGHLIGHTS` | Stage 9 “What is new” bullets |
| `TU_UI_EXPERIMENT_COMPACT_MOBILE` | Denser mobile layout trial |

### Rules

1. **Default off** (or default to current UX) so updates are safe.
2. **Document each flag** in `env.example` with one-line purpose and rollback (“unset / false”).
3. **No security boundary flags** without explicit security review (allowlist, tokens, TLS).
4. **Smoke both states** when Playwright extraction exists (Stage 4)—at least default-off path in CI.
5. **Time-box experiments:** promote to permanent UX or remove within a release or two; use Stage 6 deprecation notices if renaming.
6. **Keep flag reads boring**—simple `true`/`false` parsing; no remote evaluate endpoints.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Config | `.env` / helper-provided public config slice | SaaS flag consoles |
| UI structure | Stage 4 modular assets | More monolith branches without flags |
| Proof | Playwright / manual checklist | “Looks fine on my laptop” only |
| Cleanup | Stage 6 deprecation framework | Eternal dead flag branches |

## Rollout

1. Publish this page; require experiment PRs to cite a flag name.
2. Add two example flags only when the paired features (highlights / tips) are implemented.
3. Extend Stage 4 smoke docs with a “flags matrix” section.
4. Track active experiments in a short table on this page or the status board.

## Acceptance criteria

- [ ] New experimental UI ships behind a documented flag defaulting to current behavior.
- [ ] `env.example` lists the flag and rollback.
- [ ] Security-sensitive surfaces are not flag-gated without RFC/security notes.
- [ ] CI or checklist covers default-off path.
- [ ] No third-party feature-flag service is required.

## Rollback

Set flags false or unset; redeploy/reload dashboard assets. Remove flag branches in a follow-up PR using the deprecation notice pattern.

## Success metrics

- Large dashboard PRs ship with reversible flags more often than all-or-nothing merges.
- Abandoned experiments are deleted instead of lingering as half-dead UI.
- Operators can disable trials without rebuilding images (env change sufficient).
