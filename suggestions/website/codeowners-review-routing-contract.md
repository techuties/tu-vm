---
title: CODEOWNERS Review Routing Contract
description: Constructional contract for community contributions to CODEOWNERS and review routing that keeps maintainership clear without inventing a custom review assignment service.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: community
impact: medium
---

# CODEOWNERS Review Routing Contract

## Problem

Critical paths (`docker-compose.yml`, nginx, helper, `.github/`) need predictable review routing. Historical suggestions invent round-robin bots, paid review SaaS, or undocumented “ping person X” folklore. The repository already has a `CODEOWNERS` template. Contributors need a **reuse-first contract** for expanding ownership maps once real GitHub teams/handles exist—without turning ownership into a gate that blocks good first issues.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`CODEOWNERS`](../../CODEOWNERS) | Path → owner mapping (template team placeholder today) |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Branch protection / code owner notes |
| Stage 5 `community-label-and-board-contract.md` (expected sibling) | Labels and project boards |
| Stage 16 `github-community-automation-contract.md` (sibling) | Intake/stale automation |
| Stage 14 `cli-subcommand-contribution-contract.md` (expected sibling) | High-impact script surfaces |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | Helper ownership adjacency |
| GitHub branch protection settings | Enforce owner reviews when ready |

Out of scope:

- Paid review-assignment SaaS as a prerequisite
- Requiring owner approval for every docs typo before teams exist
- Mapping ownership to personal emails in public files beyond GitHub handles/teams
- Using CODEOWNERS to hide security-sensitive paths from all contributors (use SECURITY process)

## Proposal

Publish a **CODEOWNERS review routing contract** for ownership map PRs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Path maps | `CODEOWNERS` | Narrow, high-value paths first |
| Team handles | GitHub teams / users | Placeholder replaced with real owners |
| Contributor docs | CONTRIBUTING | Explains when owner review is required |
| Protection rollout | org settings (not in git) | Documented checklist; no secrets |

### Rules

1. **Start narrow.** Own compose, nginx, helper, `.github/` before boiling the ocean.
2. **Real teams only.** Do not invent fake `@users` that cannot review; keep placeholders obvious until ready.
3. **Docs explain enforcement.** CONTRIBUTING must say whether branch protection requires owner reviews yet.
4. **Do not weaponize ownership.** Ownership routes review; it should not discourage linked Issues/PRs from newcomers.
5. **Security reports stay private.** Ownership files do not replace [`SECURITY.md`](../../SECURITY.md).
6. **Keep maps readable.** Prefer directory rules over hundreds of file-level exceptions.
7. **GitHub remains intake.** Process changes to review routing start as Issues/PRs.

### Suggested maintainer checklist

```text
1. Confirm GitHub team/handle exists and can be @mentioned
2. Update CODEOWNERS paths with a short comment why they matter
3. Sync CONTRIBUTING.md enforcement status
4. Optionally enable “require review from Code Owners” when ready
5. Watch for review bottlenecks on good-first-issue docs PRs
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Review routing | GitHub CODEOWNERS | Custom assignment bots by default |
| Protection | GitHub branch protection | Homegrown merge gates |
| Community process | CONTRIBUTING + Stage 5 labels | Folklore ping lists in chat only |
| Security | SECURITY.md private reporting | Public owner pings for vulns |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Replace placeholder team when org teams are ready.
3. Prefer **small** ownership expansions with CONTRIBUTING sync.

## Acceptance criteria

- [ ] Narrow-path-first rule is stated.
- [ ] Placeholder honesty / real-team rule is stated.
- [ ] CONTRIBUTING enforcement documentation requirement is stated.
- [ ] Security-reporting separation is stated.
- [ ] Readability / low-exception preference is stated.

## Rollback

Revert CODEOWNERS/docs commits; prior routing returns. Branch protection toggles are settings-level and should be reversed deliberately.

## Success metrics

- Critical path PRs get the right reviewers without chat archaeology.
- New contributors still land docs/help-wanted changes smoothly.
- Ownership file stays short enough to audit in one screen.
