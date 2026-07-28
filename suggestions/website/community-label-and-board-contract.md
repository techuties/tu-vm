---
title: Community Label and Board Contract
description: Constructional contract for GitHub-native labels and a Projects board that make community triage and day-to-day maintainer work visible without a custom tracker.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: community
impact: high
---

# Community Label and Board Contract

## Problem

TU-VM already uses GitHub Issues (suggestion + bug forms), Discussions links, stale automation, Release Drafter label groups, and CONTRIBUTING label notes. What is still fuzzy for day-to-day community operations is a **single, published taxonomy** and a **visible board** so triage does not depend on maintainer memory or private spreadsheets. Historical suggestions proposed custom status databases and dashboard voting; those reinvent GitHub. Stage 1 status-board pages should project GitHub state—not invent a second lifecycle store.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/ISSUE_TEMPLATE/suggestion.yml` | Applies `suggestion` |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Bug intake |
| `.github/workflows/stale.yml` | `needs-info` / stale cadence |
| `.github/release-drafter.yml` | Changelog sections from PR labels |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Label and PR expectations |
| Stage 1 `status-board.md` (open PR) | Curated read-only projection |
| Stage 3 `decision-log.md` / `implemented-showcase.md` | Decision and shipped records |
| PR #23 consolidation | Canonical lifecycle vocabulary |

Out of scope:

- Local suggestion queue, voting DB, or community API
- Replacing Release Drafter with a custom release UI
- Mandatory Projects for drive-by contributors (Issues alone remain enough to submit)
- Complex multi-repo portfolio boards on day one

## Proposal

Publish a **label taxonomy** and a **GitHub Projects (v2)** board contract that map 1:1 to the lifecycle in [`../website-community-pages.md`](../website-community-pages.md).

### Label taxonomy (v1)

| Label | Meaning | Applied by |
|---|---|---|
| `suggestion` | Idea intake | Issue form |
| `bug` | Defect | Bug form / triage |
| `needs-info` | Blocked on author | Maintainers; stale workflow |
| `duplicate` | Points to canonical issue | Triage |
| `accepted` | Approved for implementation | Maintainers after review |
| `deferred` | Not now; reopen conditions noted | Maintainers |
| `in-progress` | Active implementation | Assignee / maintainer |
| `blocked` | External or internal dependency | Maintainers |
| `security` | Security-sensitive (prefer private advisory when needed) | Maintainers |
| `good-first-issue` | Newcomer-sized | Maintainers |
| `documentation` | Docs/playbooks/suggestions site | Authors / triage |
| `operations` | `tu-vm.sh`, Compose, playbooks | Triage |
| `enhancement` | PR changelog section | PR authors |
| `breaking` | Operator-visible break | PR authors |
| `skip-changelog` | Omit from Release Drafter | Maintainers |
| `stale` / `pinned` | Hygiene | Stale bot / maintainers |

Keep names stable; document aliases only if renaming is unavoidable (Decision Log entry).

### Board columns (GitHub Projects v2)

| Column | Issue states |
|---|---|
| Inbox | Newly opened `suggestion` / `bug` |
| Triage | Under maintainer review |
| Needs info | `needs-info` |
| Accepted | `accepted` not yet started |
| In progress | `in-progress` |
| Done | Closed as completed (link showcase/CHANGELOG) |
| Deferred / declined | `deferred` or closed with decision-log pointer |

Automation preference: GitHub-native project workflows / Actions using `actions/add-to-project`—not a custom bot host.

### Status board projection rule

Stage 1 `status-board.md` (when merged) should state:

> Rows are curated from GitHub Issues and the Project board. GitHub remains writable source of truth.

Optional later: a scheduled Action that regenerates a markdown table into `suggestions/website/status-board.md` (or `docs/community/`) from `gh issue list`—read-only publish, no intake API.

### Day-to-day maintainer loop

1. Daily/ Pan: empty **Inbox** → Triage (labels + milestone optional).
2. Apply `accepted` only with owner + target milestone or linked implementation issue.
3. Move to **Done** only when PR merged and Release Drafter labels are correct.
4. For deferred/declined, add Decision Log pointer (Stage 3) in the issue comment.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tracker | GitHub Issues + Projects | Custom kanban in the LAN dashboard |
| Automation | GitHub Actions + stale.yml | Always-on third-party triage SaaS |
| Changelog | Release Drafter labels | Manual copy from board to CHANGELOG |
| Public view | Curated status-board markdown | Live embedding of private project fields |

## Rollout

1. Align CONTRIBUTING label list with this taxonomy (additive; do not break Release Drafter).
2. Create one public or org-visible Project board named `TU-VM Community`.
3. Add Issues with `suggestion` automatically via Actions.
4. Link board URL from Stage 1 status-board and community index.
5. After 30 days, prune unused labels rather than adding synonyms.

## Acceptance criteria

- [ ] Taxonomy published (this page + CONTRIBUTING sync).
- [ ] Project board exists with columns matching lifecycle.
- [ ] New suggestion issues appear in Inbox without manual paste.
- [ ] Status-board docs declare GitHub as source of truth.
- [ ] No new database or dashboard voting surface introduced.

## Rollback

Archive the Project board; labels remain useful for Release Drafter and stale workflows. Revert CONTRIBUTING sections that over-prescribe columns.

## Success metrics

- Median time from issue open → first triage label decreases.
- Duplicate suggestion rate drops as board + status-board make in-flight work visible.
- Fewer “what happened to my idea?” pings without a linked decision comment.
