---
title: Pre-Push Check Contribution Contract
description: Constructional contract for community contributions that extend scripts/pre-push-check.sh so contributors get a fast, local day-to-day gate without inventing a second CI platform.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Pre-Push Check Contribution Contract

## Problem

Contributors burn cycles on push/CI round-trips for failures that local scripts already catch. Historical suggestions invent heavyweight local CI runners, mandatory remote agents, or duplicate GitHub Actions on the laptop. The repo already has `scripts/pre-push-check.sh` as a thin preflight. Contributors need a **reuse-first contract** for extending that lane—distinct from CI workflow ownership and from interactive doctor triage.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/pre-push-check.sh` | Local contributor preflight (worktree + smoke + help) |
| `scripts/smoke-test.sh` | Static (and optional live) validation invoked by pre-push |
| `.pre-commit-config.yaml` | Optional hook framework (complementary, not a replacement) |
| Stage 5 `task-runner-wrapper.md` (expected sibling) | `just`/`make` facade over the same scripts |
| Stage 5 `devcontainer-contributor-environment.md` (expected sibling) | Repeatable contributor environment |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Mentions pre-push as evidence—does not own its rules |
| Stage 16 `smoke-test-contribution-contract.md` (sibling) | Ownership of smoke phases |
| Stage 16 `ci-workflow-contribution-contract.md` (sibling) | GitHub Actions CI ownership |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path |

Out of scope:

- Replacing GitHub Actions with a mandatory local Actions runner
- Requiring Docker Tier 1 up for every docs-only edit (keep static path default)
- Auto-pushing or auto-opening PRs from the check script
- Printing secrets, tokens, or `.env` contents in pre-push logs

## Proposal

Publish a **pre-push check contribution contract** for PRs that change local contributor gates.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Preflight orchestration | `pre-push-check.sh` | Ordered steps; clear `[pre-push]` labels |
| Deletion safety | tracked-delete guard | `ALLOW_TRACKED_DELETIONS` documented |
| Required roots | file presence checks | Keep the small critical set honest |
| Smoke handoff | calls `smoke-test.sh` | No forked copy of smoke logic |
| Docs | CONTRIBUTING / task runner | Same command names everywhere |

### Rules

1. **Thin wrapper.** Pre-push orchestrates; it does not re-implement compose/bash validation.
2. **Default is static.** Do not make `--live` mandatory for pre-push; live stays opt-in via smoke.
3. **One smoke entrypoint.** Call `scripts/smoke-test.sh`; do not maintain a second checker list here.
4. **Fail loud, log safe.** Errors name the step; logs never dump credentials.
5. **Deletion guard stays intentional.** Overrides require an explicit env flag and human judgment.
6. **Keep it fast.** New steps need a justification for contributor latency (prefer CI for slow jobs).
7. **GitHub remains intake.** “Adopt Tool X as mandatory local CI” starts as an Issue.

### Suggested contributor checklist

```text
1. Run ./scripts/pre-push-check.sh on a clean worktree
2. Ensure new steps delegate to existing scripts when possible
3. Document any new env overrides next to the check
4. Update CONTRIBUTING.md / task-runner docs if the command changes
5. Do not add network calls to third parties in the default path
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local gate | `pre-push-check.sh` | Laptop-hosted Actions runners by default |
| Validation body | `smoke-test.sh` + CI | Duplicating checks in three places |
| Formatting hooks | optional pre-commit | Replacing smoke with format-only hooks |
| Deep triage | Stage 12 doctor | Expanding pre-push into diagnose |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Keep Stage 5 task-runner wrappers pointing at the same script.
3. Prefer **code** that removes duplicated checks over new prose.

## Acceptance criteria

- [ ] Thin-wrapper / no duplicated smoke logic rule is stated.
- [ ] Static-default (live opt-in) rule is stated.
- [ ] Secret-free logging rule is stated.
- [ ] Deletion-guard override policy is stated.
- [ ] CONTRIBUTING / task-runner parity is required on command changes.

## Rollback

Revert script/docs commits independently. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer CI failures that pre-push could have caught locally.
- Stable contributor command names across docs and wrappers.
- Pre-push remains quick enough that people actually run it.
