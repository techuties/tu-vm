---
title: Check-Config Contribution Contract
description: Constructional contract for community contributions that extend scripts/check-config.sh—secret-safe compose/env/allowlist preflight without inventing a second configuration product.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Check-Config Contribution Contract

## Problem

Contributors and operators need a fast answer to “is this checkout deployable?” Historical suggestions invent separate config GUIs, SaaS validators, or scripts that print secret values for “easier debugging.” The repository already has `scripts/check-config.sh` with default/warn, `--strict`, and `--ci` modes. Contributors need a **reuse-first contract** distinct from env-schema authoring and interactive doctor flows.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/check-config.sh` | Preflight for required files, compose render, allowlist, insecure placeholders |
| `env.example` | Documented variable surface |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | Adding/changing env keys |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Interactive `doctor` / `diagnose` |
| Stage 16 `ci-workflow-contribution-contract.md` (expected sibling) | CI calls `--ci` mode |
| Stage 16 `pre-push-check-contribution-contract.md` (expected sibling) | Local gate wrapping check-config |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Allowlist / control-plane safety |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Explains check-config expectations |

Out of scope:

- Building a web-based config editor as a prerequisite for validation
- Printing `.env` secret values, tokens, or private hostnames in output
- Replacing compose’s own config render with a third YAML engine
- Making `--strict` the silent default for every developer laptop without docs

## Proposal

Publish a **check-config contribution contract** for PRs that extend preflight validation.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Required files | `check-config.sh` | Additive checks; clear error text |
| Compose render | `docker compose config` | Failures stay actionable |
| Mode flags | default / `--strict` / `--ci` | Behavior documented in script header + CONTRIBUTING |
| Secret hygiene | all output paths | Never echo secret values |
| CI/local wiring | ci.yml / pre-push | Call the script; do not fork logic |

### Rules

1. **One preflight entrypoint.** Prefer extending `check-config.sh` over a parallel config validator.
2. **Never print secrets.** Report missing/insecure *keys* or placeholder patterns, not values.
3. **Preserve modes.** `--ci` assumes prepared env; `--strict` escalates warnings; default stays contributor-friendly.
4. **Compose is source of truth.** Use compose config rendering rather than a second schema language for service graphs.
5. **Allowlist awareness.** Missing `nginx/dynamic/control_allowlist.conf` remains a warned/blocking concern consistent with Nginx startup needs.
6. **Call from gates.** CI and pre-push should invoke this script instead of re-coding the same checks.
7. **GitHub remains intake.** Requests for hosted config UIs stay Issues unless accepted as scoped work.

### Suggested contributor checklist

```text
1. Run ./scripts/check-config.sh and --ci / --strict as relevant
2. Confirm new messages never include secret values
3. Update CONTRIBUTING.md if contributor-visible modes change
4. Keep CI/pre-push calling the script (no duplicated inline checks)
5. Coordinate env key additions with Stage 12 env-schema rules
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Preflight | `check-config.sh` | Second config product |
| Env authorship | Stage 12 env-schema contract | Silent new required keys |
| Interactive triage | Stage 12 doctor/diagnose | Turning check-config into doctor |
| Gate wiring | Stage 16 CI + pre-push | Divergent private validators |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Keep CI `--ci` and local default/strict behaviors documented together.
3. Prefer **code** that improves actionable errors over more prose.

## Acceptance criteria

- [ ] Single preflight entrypoint rule is stated.
- [ ] Secret-safe output rule is stated.
- [ ] Mode flag semantics (default / strict / ci) are preserved as contribution rules.
- [ ] Compose render remains the service-graph check.
- [ ] CI/pre-push are expected to call the script.

## Rollback

Revert script/docs commits independently; prior preflight behavior returns. Docs-only publication needs no runtime rollback.

## Success metrics

- Contributors fix deployability issues from check-config output alone.
- CI and local gates share one implementation.
- Fewer PRs that add validators printing `.env` contents.
