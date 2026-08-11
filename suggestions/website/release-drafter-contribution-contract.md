---
title: Release Drafter Contribution Contract
description: Constructional contract for community contributions to Release Drafter configuration—label-driven draft releases without inventing a second changelog bot or release SaaS.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: community
impact: high
---

# Release Drafter Contribution Contract

## Problem

Maintainers and contributors need predictable draft release notes from merged PR labels. Historical suggestions invent parallel release bots, manual copy-paste rituals as the only path, or proprietary release SaaS. The repository already uses `.github/release-drafter.yml` plus `.github/workflows/release-drafter.yml` on `main`, with categories and `skip-changelog`. Contributors need a **reuse-first contract** distinct from human CHANGELOG editing helpers and release-note CLI wrappers.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/release-drafter.yml` | Categories, version resolver, exclude labels |
| `.github/workflows/release-drafter.yml` | Draft release automation on `main` |
| Stage 14 `changelog-release-notes-contribution-contract.md` (expected sibling) | Human + automation release communication |
| Stage 17 `changelog-refresh-contribution-contract.md` (sibling) | Local Unreleased section helper |
| Stage 16 `github-community-automation-contract.md` (expected sibling) | Stale/forms/triage (separate workflows) |
| Stage 5 `community-label-and-board-contract.md` (expected sibling) | Label vocabulary |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Label → Release Drafter notes |

Out of scope:

- Replacing Release Drafter with a second bot for the same job
- Auto-publishing GitHub Releases without maintainer review
- Putting secrets, private hostnames, or customer data into release templates
- Using Release Drafter as an image CVE or digest updater

## Proposal

Publish a **Release Drafter contribution contract** for PRs that change draft-release automation.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Categories / labels | `release-drafter.yml` | Maps to CONTRIBUTING label guidance |
| Version resolver | major/minor/patch labels | Breaking changes explicit |
| Exclusions | `skip-changelog` | Docs-only noise controllable |
| Workflow trigger | `release-drafter.yml` workflow | Stays on intended branches |
| Contributor docs | CONTRIBUTING / PR template | Authors know which labels matter |

### Rules

1. **One draft-release bot.** Prefer extending Release Drafter config over adding a peer changelog bot.
2. **Labels are the API.** Category changes require CONTRIBUTING/PR-template follow-through.
3. **Maintainer publish.** Draft generation ≠ automatic production release.
4. **Honor `skip-changelog`.** Docs/chore noise should remain excludable.
5. **No secrets in templates.** Release bodies stay public-safe.
6. **Separate from local refresh.** `changelog-refresh.sh` helps the markdown file; Drafter owns GitHub draft releases.
7. **GitHub remains intake.** Product swaps for release SaaS start as Issues.

### Suggested contributor checklist

```text
1. Describe category/label/version-resolver impact
2. Update CONTRIBUTING.md label tables if behavior changes
3. Keep skip-changelog semantics intact unless intentionally changing them
4. Do not auto-publish releases from the workflow without an accepted decision
5. Avoid combining unrelated bot refactors in the same PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Draft releases | Existing Release Drafter | Second changelog bot |
| Label OS | Stage 5 label/board contract | Ad-hoc undocumented labels |
| Local markdown help | Stage 17 changelog-refresh | Overwriting Drafter from laptops |
| Human narrative | Stage 14 release-notes contract | Ignoring maintainer voice |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Keep label docs and Drafter categories in lockstep.
3. Prefer **code**/config that clarifies categories over more prose.

## Acceptance criteria

- [ ] Single draft-release automation rule is stated.
- [ ] Label/CONTRIBUTING parity requirement is stated.
- [ ] Draft ≠ auto-publish rule is stated.
- [ ] Separation from changelog-refresh and CVE tooling is stated.
- [ ] Public-safe template rule is stated.

## Rollback

Revert config/workflow commits; prior draft behavior returns. Docs-only publication needs no runtime rollback.

## Success metrics

- Release drafts stay understandable from PR labels alone.
- Fewer duplicate “we need another release bot” suggestions.
- `skip-changelog` remains an effective noise control.
