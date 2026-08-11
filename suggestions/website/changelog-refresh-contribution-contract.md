---
title: Changelog-Refresh Contribution Contract
description: Constructional contract for community contributions that extend scripts/changelog-refresh.sh—local Unreleased section helpers without inventing a second release bot or overwriting Release Drafter.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Changelog-Refresh Contribution Contract

## Problem

Maintainers sometimes want a quick local preview or refresh of the markdown `CHANGELOG.md` Unreleased section from recent commits. Historical suggestions invent second changelog generators that fight Release Drafter, or bots that rewrite history silently. The repository already has `scripts/changelog-refresh.sh` (dry-run by default, `--write` to update). Contributors need a **reuse-first contract** distinct from Release Drafter draft releases and from `release-note-helper` / `tu-vm.sh release-notes`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/changelog-refresh.sh` | Preview/write Unreleased block from git log |
| [`CHANGELOG.md`](../../CHANGELOG.md) | Human-maintained project changelog |
| Stage 17 `release-drafter-contribution-contract.md` (sibling) | GitHub draft releases from PR labels |
| Stage 14 `changelog-release-notes-contribution-contract.md` (expected sibling) | Broader release communication rules |
| `scripts/release-note-helper.sh` / `tu-vm.sh release-notes` | Maintainer release-note helpers |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Release Drafter label guidance |

Out of scope:

- Making changelog-refresh the sole release authority over GitHub Releases
- Auto-committing `--write` results from CI without human review
- Dumping secret-bearing commit subjects into public changelog text uncritically
- Replacing Release Drafter categories with commit-subject scraping as the default

## Proposal

Publish a **changelog-refresh contribution contract** for PRs that extend the local Unreleased helper.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Preview mode | default script output | Safe dry-run remains default |
| Write mode | `--write` | Explicit; human-reviewed commits |
| Section shape | Unreleased block format | Compatible with existing CHANGELOG structure |
| Coordination | vs Release Drafter | Docs state which surface is authoritative for GitHub drafts |
| Filtering | commit selection | Avoid merge spam; allow COMMIT_COUNT overrides |

### Rules

1. **Dry-run by default.** Writing the file requires an explicit flag.
2. **One local helper.** Prefer extending `changelog-refresh.sh` over a parallel Unreleased rewriter.
3. **Human review before push.** `--write` output is a draft aid, not an unsupervised release.
4. **Do not fight Drafter.** GitHub draft release notes stay label-driven unless maintainers decide otherwise.
5. **Public-safe text.** Contributors must scrub secrets/PII from commit subjects before publishing changelog lines.
6. **Preserve structure.** Keep Keep-a-Changelog-style section compatibility already used in the file.
7. **GitHub remains intake.** Requests for proprietary release-note SaaS stay Issues.

### Suggested contributor checklist

```text
1. Run ./scripts/changelog-refresh.sh (preview) before proposing format changes
2. Keep dry-run default; document --write clearly
3. Explain interaction with Release Drafter in the PR body
4. Avoid CI jobs that commit changelog writes without review
5. Scrub sensitive commit subjects from samples/docs
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local Unreleased aid | `changelog-refresh.sh` | Second markdown bot |
| GitHub draft releases | Stage 17 Release Drafter contract | Commit-subject scraping as release API |
| Maintainer narrative | Stage 14 release-notes contract | Fully unattended changelog ownership |
| Labels | CONTRIBUTING + Stage 5 labels | Ignoring skip-changelog intent |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Release Drafter vs local refresh in CONTRIBUTING when useful.
3. Prefer **code** that improves preview clarity over more prose.

## Acceptance criteria

- [ ] Dry-run default rule is stated.
- [ ] Separation from Release Drafter authority is stated.
- [ ] Human review before publishing `--write` results is required.
- [ ] Public-safe changelog text rule is stated.
- [ ] Single local helper preference is stated.

## Rollback

Revert script/docs commits; prior helper behavior returns. Docs-only publication needs no runtime rollback. Revert mistaken `--write` edits via git.

## Success metrics

- Maintainers refresh Unreleased text without adopting a second bot.
- Release Drafter and CHANGELOG.md stop being treated as competing systems.
- Fewer accidental secret-bearing changelog lines from raw commit dumps.
