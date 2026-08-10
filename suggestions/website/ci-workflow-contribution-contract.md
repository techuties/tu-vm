---
title: CI Workflow Contribution Contract
description: Constructional contract for community contributions to .github/workflows/ci.yml that keep compose/smoke/config gates reliable without inventing a second CI product or shadow pipelines.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# CI Workflow Contribution Contract

## Problem

Community PRs need predictable automation. Historical suggestions invent parallel CI systems, mandatory self-hosted runners as a prerequisite, or duplicate the same bash checks in ad-hoc workflow files. The repository already has `.github/workflows/ci.yml` as the primary gate. Contributors need a **reuse-first contract** distinct from Docs-links Lychee, Trivy supply-chain scans, and local pre-push.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/workflows/ci.yml` | Primary PR/push validation |
| `scripts/smoke-test.sh` / `check-config.sh` | Shared validation body |
| `scripts/validate_status_full_contract.py` | Fixture contract check in CI |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVE / SBOM (separate workflow lane) |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | Optional live helper profile |
| Stage 15 `docs-link-ci-contribution-contract.md` (expected sibling) | Lychee docs workflow ownership |
| Stage 16 `smoke-test-contribution-contract.md` (sibling) | Smoke phase semantics |
| Stage 16 `pre-push-check-contribution-contract.md` (sibling) | Local mirror of CI intent |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Explains CI expectations |

Out of scope:

- Standing up a second CI brand (Circle/Buildkite/etc.) without an accepted Issue
- Requiring self-hosted runners for default community PRs
- Disabling failing gates with blanket `continue-on-error` to “go green”
- Printing repository secrets or `.env` values into Actions logs

## Proposal

Publish a **CI workflow contribution contract** for PRs that change the primary Actions gate.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Job graph | `ci.yml` | Clear job names; least-privilege permissions |
| Script invocation | calls into `scripts/` | No pasted duplicate bash bodies |
| Strict env gate | PR-oriented checks | Documented; matches CONTRIBUTING |
| Fixture validation | status-full contract | Additive schema rules respected |
| Docs for contributors | CONTRIBUTING | Mirrors actual jobs |

### Rules

1. **One primary gate.** Prefer extending `ci.yml` over adding a peer “also-CI” workflow for the same checks.
2. **Call scripts.** Workflow steps should invoke maintained `scripts/` entrypoints.
3. **Least privilege.** Workflow `permissions:` stay minimal for the job’s needs.
4. **No secret echo.** Debug steps must not dump env files or tokens.
5. **Separate concerns.** Docs-links, Trivy, stale, and release-drafter stay in their workflows (see sibling contracts).
6. **Fail honestly.** Do not paper over known flakes with broad ignores—file an Issue and fix or narrowly skip with a comment.
7. **GitHub remains intake.** CI product swaps and runner topology changes start as Issues/PRs.

### Suggested contributor checklist

```text
1. Describe which job/step changes and why
2. Prefer script edits when logic changes; keep YAML thin
3. Confirm permissions blocks stay minimal
4. Update CONTRIBUTING.md if contributor-visible behavior changes
5. Avoid combining unrelated workflow refactors in the same PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| PR validation | Existing `ci.yml` + scripts | Parallel CI products by default |
| Docs links | Stage 15 Lychee workflow | Folding link crawls into every CI job |
| Image CVEs | Stage 4 Trivy lane | Blocking all PRs on unscored noise without triage |
| Local parity | Stage 16 pre-push + smoke | Divergent private checklists |

## Rollout

1. Publish this page under `suggestions/website/`.
2. When adding live profiles, follow Stage 5 compose-ci-live guidance.
3. Prefer **code** that removes duplicated inline shell from YAML.

## Acceptance criteria

- [ ] Single primary CI gate rule is stated.
- [ ] Script-invocation preference is stated.
- [ ] Least-privilege and no-secret-echo rules are stated.
- [ ] Separation from docs-link / Trivy / stale workflows is stated.
- [ ] CONTRIBUTING parity on visible behavior changes is required.

## Rollback

Revert workflow commits; prior Actions behavior returns. Docs-only publication needs no runtime rollback.

## Success metrics

- CI stays understandable from CONTRIBUTING alone.
- Script logic has one home under `scripts/`.
- Community PRs fail for real regressions, not shadow-pipeline drift.
