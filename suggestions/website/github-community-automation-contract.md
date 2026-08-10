---
title: GitHub Community Automation Contract
description: Constructional contract for community contributions to stale automation, issue forms, and triage labels that keep GitHub-native participation healthy without inventing a local suggestion queue or bot platform.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: community
impact: high
---

# GitHub Community Automation Contract

## Problem

Communities drown in idle issues and unclear intake. Historical suggestions invent in-app voting, local suggestion databases, or multi-bot stacks that bypass GitHub. TU-VM already uses Issue forms, stale automation, and documented labels. Contributors need a **reuse-first contract** for day-to-day triage automation—aligned with Phase 2 “acceleration” themes in the historical hub—without reinventing governance.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/workflows/stale.yml` | needs-info + idle issue hygiene |
| `.github/ISSUE_TEMPLATE/suggestion.yml` | Sole idea intake form |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Bug intake |
| `.github/ISSUE_TEMPLATE/config.yml` | Chooser / security link wiring |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Labels and participation path |
| Stage 1 `how-to-submit.md` / `status-board.md` (expected siblings) | Publishable guidance projecting GitHub state |
| Stage 5 `community-label-and-board-contract.md` (expected sibling) | Label + Projects vocabulary |
| Stage 3 `decision-log.md` (expected sibling) | Accepted/deferred rationale publishing |
| Stage 14 `changelog-release-notes-contribution-contract.md` (expected sibling) | Release Drafter labels (adjacent) |

Out of scope:

- Local voting databases, suggestion APIs, or dashboard auth for public participation
- Auto-closing security reports or bypassing [`SECURITY.md`](../../SECURITY.md)
- Third-party bot fleets that require org-level apps without an accepted Issue
- Using stale bots to silence controversial but active discussions

## Proposal

Publish a **GitHub community automation contract** for triage and intake PRs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Stale policy | `stale.yml` | Exempt labels (`pinned`, `security`, …); close vs mark-only choices documented |
| Intake forms | `ISSUE_TEMPLATE/*` | Required fields stay high-signal; no secret prompts |
| Chooser config | `config.yml` | Security path remains obvious |
| Labels docs | CONTRIBUTING / Stage 5 | Same names as automation |
| Publishable views | Stage 1 status board | Read-only projection—not a second queue |

### Rules

1. **GitHub is the OS.** Issues + forms remain the sole proposal intake.
2. **Exempt carefully.** `security` and `pinned` (and documented peers) must not be auto-noise-closed.
3. **Prefer mark over destroy.** Default stale behavior should favor labeling / nudging; closing needs explicit rationale in the workflow PR.
4. **Forms collect signal, not secrets.** Templates must not ask for raw `.env`, tokens, or private corpora.
5. **Label names are API.** Renames need CONTRIBUTING + workflow + Stage 5 updates together.
6. **No shadow bots.** New automation apps require an accepted Issue and least-privilege tokens.
7. **Website pages project, they do not replace.** Curated markdown must link back to GitHub state.

### Suggested maintainer checklist

```text
1. Describe triage pain (needs-info pile, idle bugs, form gaps)
2. Adjust stale.yml or issue forms with the smallest change
3. Keep security/private reporting path untouched unless intentional
4. Sync label vocabulary in CONTRIBUTING.md
5. Link Stage 1 how-to-submit if contributor guidance changes
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Idea intake | GitHub suggestion form | Local suggestion DB / voting API |
| Idle hygiene | `actions/stale` workflow | Custom bot platform |
| Labels/boards | Stage 5 contract + GitHub Projects | Parallel kanban SaaS as source of truth |
| Decisions | Stage 3 decision log | Discord-only outcomes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Implement form/stale tweaks as small PRs with CONTRIBUTING sync.
3. Prefer **code**/workflow edits over new community platforms.

## Acceptance criteria

- [ ] GitHub-native intake rule is stated.
- [ ] Security/pinned exemption expectations are stated.
- [ ] No-secrets-in-forms rule is stated.
- [ ] Label rename synchronization requirement is stated.
- [ ] Website-as-projection (not second queue) rule is stated.

## Rollback

Revert workflow/template/docs commits independently. Docs-only publication needs no runtime rollback.

## Success metrics

- Higher signal on new suggestions (complete forms, fewer duplicates).
- needs-info issues get nudged without losing security threads.
- Contributors see one participation path: GitHub.
