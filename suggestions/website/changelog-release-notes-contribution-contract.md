---
title: Changelog and Release-Notes Contribution Contract
description: Constructional contract for community contributions to CHANGELOG, Release Drafter labels, and tu-vm.sh release-notes that keeps human release communication accurate without inventing a second release CMS.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: community
impact: high
---

# Changelog and Release-Notes Contribution Contract

## Problem

Operators need trustworthy “what changed” narratives. Historical suggestions invent release microsites, Discord-only announcements, or dashboard CMS bodies that drift from git. The repository already has `CHANGELOG.md`, Release Drafter, and `./tu-vm.sh release-notes`. Contributors need a **reuse-first contract** for release communication—distinct from Stage 9 dashboard highlight *rendering*.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`CHANGELOG.md`](../../CHANGELOG.md) | Human narrative of notable releases |
| Release Drafter + workflow on `main` | Draft GitHub Releases from PR labels |
| `./tu-vm.sh release-notes` / `scripts/release-note-helper.sh` | Git-only bullets since a tag |
| PR template “Release notes” section | Maintainer label guidance |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Label meanings including `skip-changelog` |
| Stage 9 `dashboard-release-highlights-contract.md` (expected sibling) | Optional LAN dashboard bullets *consumer* |
| Stage 3 `implemented-showcase.md` (expected sibling) | Community idea → shipped proof |
| Stage 6 `deprecation-notice-framework.md` (expected sibling) | Breaking-change notices |
| Stage 8 `release-canary-community-program.md` (expected sibling) | Pre-release validation |

Out of scope:

- Building a marketing CMS or blog engine as a prerequisite
- Requiring dashboard network calls to GitHub for every LAN operator (Stage 9 stays optional)
- Putting secrets, hostnames, or customer paths into public release bodies
- Dual-maintaining a second changelog format that CI does not read

## Proposal

Publish a **changelog / release-notes contribution contract** with clear lanes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Narrative changelog | `CHANGELOG.md` | Operator-relevant bullets; version headers |
| Automated draft release | PR labels → Release Drafter | Correct section label; `skip-changelog` when needed |
| Git bullet helper | `release-note-helper.sh` | Runs without Docker; tag baseline documented |
| Dashboard highlights | Stage 9 contract | Curated subset of release truth—not a second source |
| Deprecations | Stage 6 `DEP-*` | Linked from changelog when breaking |

### Rules

1. **Git is the source of truth.** Release text must be reconstructable from commits/PRs/tags.
2. **Labels steer Drafter; humans steer CHANGELOG.** Do not assume Drafter output alone is enough for major operator stories.
3. **Operator impact first.** Prefer “what to run / what breaks / how to roll back” over internal refactors.
4. **No secrets in release bodies.** Tokens, `.env` samples with real values, and private URLs stay out.
5. **`skip-changelog` is intentional.** Use for chore/CI-only PRs; do not hide user-facing breaks.
6. **Dashboard bullets are derived.** Stage 9 highlights must cite Releases/CHANGELOG—not invent facts.
7. **Breaking changes link Stage 6 notices** and playbook updates in the same release window.
8. **GitHub remains intake.** Process changes to release automation start as Issues/PRs, not silent workflow forks.

### Suggested maintainer checklist

```text
1. PR labels set (enhancement/bug/documentation/breaking/skip-changelog)
2. User-facing behavior summarized for CHANGELOG if needed
3. ./tu-vm.sh release-notes <prev-tag>   # sanity scan
4. Breaking → DEP notice + playbook/README touch
5. Draft release reviewed before publish on main
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Draft assembly | Release Drafter | Manual copy from chat logs |
| Local bullets | `tu-vm.sh release-notes` | Scraping GitHub HTML |
| Operator narrative | `CHANGELOG.md` | Parallel “release DB” |
| LAN teaser | Stage 9 curated JSON/flag | Live unauthenticated GitHub scrape as hard dependency |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link CONTRIBUTING label table and Stage 9 highlights page.
3. Prefer **code**/docs polish that keeps Release Drafter categories aligned with CONTRIBUTING.
4. Keep implemented-showcase pointing at real changelog entries.

## Acceptance criteria

- [ ] Lanes distinguish CHANGELOG, Drafter, helper, and dashboard highlights.
- [ ] No-secrets and breaking-change linkage rules are explicit.
- [ ] `skip-changelog` guidance is present.
- [ ] Dashboard highlights are defined as derived, not authoritative.
- [ ] No release CMS prerequisite is introduced.

## Rollback

Revert changelog/workflow docs independently; prior GitHub Releases remain immutable history. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer releases missing operator-facing notes for behavior changes.
- Less drift between dashboard “What is new” and GitHub Releases.
- Decline in “build a release blog service” suggestions.
