---
title: Helper-Contract-Check Contribution Contract
description: Constructional contract for community contributions that extend scripts/helper-contract-check.sh—live helper JSON probes when ai_helper_index is running, without inventing a remote contract SaaS.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Helper-Contract-Check Contribution Contract

## Problem

When the helper is up, contributors need proof that JSON surfaces still match what the dashboard expects. Historical suggestions invent always-on contract platforms, mandatory live stacks for every PR, or duplicate assertions inside random scripts. The repository already has `scripts/helper-contract-check.sh` that **skips cleanly** when Docker/helper are unavailable, plus static fixtures for CI. Contributors need a **reuse-first contract** distinct from Stage 13 fixture validators and Stage 7 helper API design rules.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/helper-contract-check.sh` | Live probes against `ai_helper_index` |
| `helper/uploader.py` | Helper implementation |
| `fixtures/status-full-contract.json` + `validate_status_full_contract.py` | Static CI shape |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | API evolution rules |
| Stage 13 `fixture-and-contract-test-contribution.md` (expected sibling) | Offline fixture authorship |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | Optional live CI profile |
| Stage 16 `smoke-test-contribution-contract.md` (expected sibling) | Broader static/`--live` smoke |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Mentions helper-contract-check |

Out of scope:

- Failing default CI when the helper container is not running
- Shipping a hosted contract-monitoring service
- Asserting secret-bearing fields or dumping full responses into logs by default
- Replacing static `/status/full` fixture validation with live-only checks

## Proposal

Publish a **helper-contract-check contribution contract** for PRs that extend live helper probes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Skip semantics | script header / early exits | Docker missing or helper stopped → skip, not fail |
| Endpoint probes | `/status`, `/announcements`, future additive paths | Stable keys; clear assert messages |
| Live CI (optional) | Stage 5 profile | Opt-in; not the default PR tax |
| Parity with fixtures | Stage 13 | Live checks must not contradict static contract |
| Docs | CONTRIBUTING / playbooks | When to run locally |

### Rules

1. **Skip when offline.** Absence of Docker or `ai_helper_index` must remain a skip, not a hard failure, for default contributor laptops.
2. **One live probe script.** Prefer extending `helper-contract-check.sh` over parallel live checkers.
3. **Additive assertions.** New keys are fine; removing/renaming requires helper + fixture + dashboard follow-through.
4. **No secret echo.** Do not print tokens, allowlist contents, or `.env` values while asserting.
5. **Static CI stays primary.** Default PR gate uses fixtures; live probes are for operator/dev containers or optional profiles.
6. **Align with helper-api rules.** Endpoint shape changes follow Stage 7; this script only verifies.
7. **GitHub remains intake.** Requests for external contract SaaS stay Issues.

### Suggested contributor checklist

```text
1. With helper up: ./scripts/helper-contract-check.sh
2. With helper down: confirm clean SKIP behavior
3. If asserting new keys, update fixtures/validators in the same change window
4. Keep default CI green without requiring a live stack
5. Avoid logging full JSON bodies unless redacted and necessary
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Live probes | `helper-contract-check.sh` | Remote contract SaaS |
| Offline CI | Stage 13 fixtures | Live-only PR requirements |
| API design | Stage 7 helper-api contract | Quiet breaking JSON changes |
| Optional live CI | Stage 5 compose profile | Mandatory self-hosted runners |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Optionally widen probes to `/updates`, `/status/pdf-processing`, or `/status/full` with fixture parity.
3. Prefer **code** that keeps skip semantics honest over more prose.

## Acceptance criteria

- [ ] Skip-when-unavailable rule is stated.
- [ ] Single live probe script rule is stated.
- [ ] Static fixture CI remains the default gate.
- [ ] Secret-safe logging rule is stated.
- [ ] Alignment with Stage 7 helper-api and Stage 13 fixtures is stated.

## Rollback

Revert script/docs commits independently; prior probe behavior returns. Docs-only publication needs no runtime rollback.

## Success metrics

- Contributors know when live checks apply vs static CI.
- Helper JSON regressions are caught before dashboard breakage.
- Fewer proposals that require always-on remote contract platforms.
