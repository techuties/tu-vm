---
title: Pre-Commit Hooks Contribution Contract
description: Constructional contract for community contributions to .pre-commit-config.yaml—optional local hooks that wrap shared syntax gates without inventing a mandatory laptop CI product.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Pre-Commit Hooks Contribution Contract

## Problem

Contributors benefit from fast local feedback before push. Historical suggestions invent mandatory heavy pre-commit suites, duplicate CI jobs on every laptop, or custom hook frameworks. The repository already ships an optional `.pre-commit-config.yaml` (whitespace/YAML basics + `bash -n` over `tu-vm.sh` and `scripts/*.sh`). Contributors need a **reuse-first contract** distinct from pre-push and Actions CI.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.pre-commit-config.yaml` | Optional installable hooks |
| `scripts/pre-push-check.sh` | Broader local gate (Stage 16) |
| `.github/workflows/ci.yml` | Authoritative PR validation (Stage 16) |
| Stage 5 `task-runner-wrapper.md` (expected sibling) | `just`/`make` facade over scripts |
| Stage 5 `devcontainer-contributor-environment.md` (expected sibling) | Repeatable contributor environment |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Mentions optional pre-commit |

Out of scope:

- Making pre-commit mandatory for all contributors without an accepted Issue
- Re-hosting full smoke/compose/live stacks inside commit hooks
- Pinning hooks to `@main` floating refs
- Printing secrets while formatting or linting

## Proposal

Publish a **pre-commit hooks contribution contract** for PRs that change local hook configuration.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Upstream hooks | `.pre-commit-config.yaml` | Pinned `rev:`; narrow ids |
| Local hooks | `repo: local` entries | Call existing commands; no secret echo |
| Docs | CONTRIBUTING / README | Install remains optional |
| Parity | vs CI / pre-push | Hooks stay a subset, not a fork |

### Rules

1. **Optional by default.** Document install; do not require hooks for contribution legitimacy.
2. **Keep hooks fast.** Prefer syntax/format checks measured in seconds; leave compose/smoke to pre-push/CI.
3. **Pin revisions.** Upstream hook repos use explicit `rev:` tags/SHAs.
4. **Reuse script logic.** Local hooks should invoke the same bash/python entrypoints maintainers already trust.
5. **Respect compose exclusions.** Do not blindly YAML-lint `docker-compose.yml` if the project already excludes it for compose-specific syntax.
6. **No secret-bearing formatters** that rewrite `.env` or certificate material.
7. **GitHub remains intake.** Proposals for mandatory enterprise hook meshes stay Issues.

### Suggested contributor checklist

```text
1. State whether the hook is optional and approximate runtime
2. Pin upstream rev; avoid @main
3. Prefer calling scripts/ or bash -n patterns already used in CI
4. Update CONTRIBUTING.md install blurb if steps change
5. Do not move smoke/live tests into commit hooks
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local quick checks | Optional pre-commit | Mandatory laptop CI clone |
| Broader local gate | Stage 16 pre-push | Duplicating pre-push inside hooks |
| Authoritative validation | Stage 16 CI | Divergent private hook suites |
| Task facade | Stage 5 Justfile/make | New hook-only DSLs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add hooks incrementally with pinned revs and CONTRIBUTING notes.
3. Prefer **code** that keeps the suite thin over more prose.

## Acceptance criteria

- [ ] Optional-install rule is stated.
- [ ] Fast-hook / subset-of-CI rule is stated.
- [ ] Pinned revision rule is stated.
- [ ] Separation from pre-push and Actions CI is stated.
- [ ] Secret-safe behavior is required.

## Rollback

Revert config/docs commits; contributors can `pre-commit uninstall`. Docs-only publication needs no runtime rollback.

## Success metrics

- New contributors can ignore hooks and still pass CI.
- Hook runtime stays short enough for daily use.
- Fewer proposals that duplicate the full CI matrix on commit.
