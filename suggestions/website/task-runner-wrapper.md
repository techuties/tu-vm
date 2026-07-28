---
title: Task Runner Wrapper
description: Constructional contract for a thin just/make task runner that wraps existing tu-vm.sh and scripts without creating a second control plane.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Task Runner Wrapper

## Problem

Contributors discover commands through README walls, `./tu-vm.sh help`, and scattered `scripts/` entries. Day-to-day tooling docs already suggest `make` or `just` as optional facades, but nothing landed because the risk of a **second control plane** is real: duplicated flags, drifted semantics, and “which entrypoint is real?” confusion. The community needs shortcuts that stay honest about ownership: `tu-vm.sh` and `scripts/` remain authoritative.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh` | Primary operator CLI |
| `scripts/pre-push-check.sh` | Aggregate contributor checks |
| `scripts/doctor.sh`, `check-config.sh`, `smoke-test.sh` | Diagnostics |
| `scripts/helper-contract-check.sh` | Helper API contract |
| Stage 1 `day-to-day-community-tools.md` | Human tooling map |
| Stage 5 Dev Container page | Workspace that can install `just` |
| PR #26 change-aware `contribute-check` | Path-filtered checks to wrap later |

Out of scope:

- Rewriting `tu-vm.sh` into Make recipes
- Cross-platform PowerShell-first redesign
- Hiding security-sensitive operations behind short aliases without documentation
- Mandatory task runner install for all contributors

## Proposal

Add an optional **`Justfile`** (preferred) or **`Makefile`** that only shells out to existing entrypoints.

### Why `just` first

- Clear recipe syntax, no Make tab folklore for newcomers.
- Easy listing (`just --list`) for community discoverability.
- Still optional: README continues to show raw `./tu-vm.sh` commands.

If maintainers prefer zero new binary, use GNU Make with the same recipe names.

### Recipe set (v1)

| Recipe | Delegates to |
|---|---|
| `doctor` | `./tu-vm.sh doctor` |
| `check-config` | `./scripts/check-config.sh` |
| `check` | `./scripts/pre-push-check.sh` |
| `smoke` | `./scripts/smoke-test.sh` |
| `smoke-live` | `./scripts/smoke-test.sh --live` |
| `helper-contract` | `./scripts/helper-contract-check.sh` |
| `status-contract` | `python3 scripts/validate_status_full_contract.py` |
| `fmt-check` | pre-commit run (if installed) or documented subset |

Illustrative `Justfile` fragment:

```make
# Contributor checks — wrappers only; tu-vm.sh remains authoritative.
check:
    ./scripts/pre-push-check.sh

doctor:
    ./tu-vm.sh doctor

smoke:
    ./scripts/smoke-test.sh
```

### Hard rules

1. **No duplicated business logic** in recipes—only argument forwarding.
2. Breaking flag changes happen in `tu-vm.sh` / scripts first; recipes update in the same PR.
3. Dangerous operations (`update`, allowlist rewrites, disk extend) either get no short alias or require an explicit `CONFIRM=` style passthrough already enforced by the underlying script.
4. `just --list` output is linked from CONTRIBUTING as “optional aliases.”

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Task runner | `just` or Make | Custom Node task framework for shell ops |
| Source of truth | `tu-vm.sh` + `scripts/` | Copy-pasted bash inside recipes |
| Docs | CONTRIBUTING + Stage 1 tools page | Separate command encyclopedia |
| CI | Keep calling scripts directly | Requiring `just` in CI images unless already present |

## Rollout

1. Land `Justfile` with the v1 recipe set and a one-paragraph README pointer.
2. Install `just` in the Dev Container feature set (Stage 5 companion page).
3. After PR #26’s `contribute-check` exists, add `just contribute` as a wrapper only.
4. Reject PRs that add logic beyond passthrough.

## Acceptance criteria

- [ ] `just check` (or `make check`) equals `pre-push-check.sh` exit semantics.
- [ ] README/CONTRIBUTING state wrappers are optional.
- [ ] No privileged compose/allowlist mutation recipes without underlying confirmations.
- [ ] CI does not depend on the task runner unless the team explicitly standardizes it.

## Rollback

Delete `Justfile`/`Makefile`; all workflows already call scripts directly.

## Success metrics

- Contributor questions shift from “what do I run?” to substantive review.
- No divergence incidents where `just X` and the script disagree on flags.
