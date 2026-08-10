---
title: Smoke Test Contribution Contract
description: Constructional contract for community contributions that extend scripts/smoke-test.sh static and --live phases without inventing a parallel QA platform or flaky end-to-end suite.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Smoke Test Contribution Contract

## Problem

Regressions in compose render, shell syntax, config hygiene, and Tier 1 HTTPS health are expensive when discovered late. Historical suggestions invent Selenium farms, always-on synthetic monitors, or merge smoke into a giant e2e product. The repo already has `scripts/smoke-test.sh` with a static default and optional `--live`. Contributors need a **reuse-first contract** distinct from named scenario catalogs, Playwright dashboard smoke, and LangGraph trust-path smoke.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/smoke-test.sh` | Phase A compose/bash -n, Phase B check-config, optional Phase C live HTTPS |
| `scripts/check-config.sh` | Config hygiene invoked by smoke |
| `scripts/pre-push-check.sh` / CI | Primary callers of smoke |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Playwright Tier-1 UI smoke (complementary) |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | Minimal live helper profile for CI |
| Stage 8 `cross-service-e2e-scenario-catalog.md` (expected sibling) | Named multi-service scenarios |
| Stage 13 `fixture-and-contract-test-contribution.md` (expected sibling) | `/status/full` fixture validators |
| Stage 15 `langgraph-supervisor-smoke-contract.md` (expected sibling) | Supervised-write trust-path smoke |
| Stage 16 `ci-workflow-contribution-contract.md` (sibling) | How CI invokes smoke |

Out of scope:

- Replacing smoke with a full browser farm as the default gate
- Requiring GPU/Ollama/n8n up during static smoke
- Asserting Tier 2 services in the default `--live` path
- Embedding secrets in curl headers “to make health green”

## Proposal

Publish a **smoke test contribution contract** for PRs that change validation phases.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Static compose/shell | Phase A | `compose config --quiet`, `bash -n` coverage |
| Config hygiene | Phase B | `check-config.sh` non-strict by default |
| Live probes | Phase C `--live` | Host/SNI explicit; clear exit codes |
| Caller docs | pre-push / CI / CONTRIBUTING | Same flags and expectations |
| Scenario depth | Stage 8 catalog | Heavier flows stay out of default smoke |

### Rules

1. **Static must stay default.** Contributors without a running stack need a green path.
2. **Live is opt-in and Tier-1-shaped.** Default `--live` probes stay landing + Open WebUI health + `/status/full`.
3. **No secret headers.** Health probes use public health endpoints and documented Host headers only.
4. **Keep phases honest.** Do not hide compose failures behind `|| true` in Phase A.
5. **Delegate depth.** Cross-service journeys belong in Stage 8 scenarios; UI clicks in Stage 4 Playwright; LangGraph writes in Stage 15.
6. **Exit codes are API.** Changing pass/fail semantics needs caller doc updates (pre-push/CI).
7. **GitHub remains intake.** “Buy synthetic monitoring” stays an Issue; default is script + Actions.

### Suggested contributor checklist

```text
1. ./scripts/smoke-test.sh
2. ./scripts/smoke-test.sh --live   # only when Tier 1 is up
3. Confirm new asserts fail for the bug they target
4. Update CI/pre-push docs if flags or phases change
5. Keep runtime bounded—move slow checks to scenarios/CI jobs
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fast gate | `smoke-test.sh` | Mandatory full-stack e2e on every commit |
| UI flows | Stage 4 Playwright proposal | Scraping the dashboard via curl hacks |
| Multi-service journeys | Stage 8 scenario catalog | Inflating default smoke |
| Contract shape | Stage 13 fixtures | Asserting unstable JSON noise fields |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Align CI and pre-push docs with the same phase language.
3. Prefer **code** that clarifies Phase C Host/SNI and failure messages.

## Acceptance criteria

- [ ] Static-default / live-opt-in rule is stated.
- [ ] Tier-1-shaped live probe scope is stated.
- [ ] Secret-header prohibition is stated.
- [ ] Delegation to Stage 4/8/15 for deeper tests is stated.
- [ ] Exit-code/doc parity requirement is stated.

## Rollback

Revert script/workflow/docs commits independently. Docs-only publication needs no runtime rollback.

## Success metrics

- Static smoke remains the common contributor path.
- Live smoke catches Nginx/helper regressions without Tier 2 dependency.
- Deeper tests land in the right catalogs instead of slowing the default gate.
