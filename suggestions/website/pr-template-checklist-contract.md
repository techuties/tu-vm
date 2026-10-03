---
title: Pull Request Checklist Contract
description: Constructional contract to keep a single security section and a single verification section in the GitHub pull request template.
last_updated: 2026-10-03
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Pull Request Checklist Contract

## Problem

`.github/pull_request_template.md` is the form every contributor sees when they open a pull request. The file asks for the security checklist and the verification checklist twice.

Heading counts on 2026-10-03:

| Marker | Count |
|---|---|
| `## Security & RFC` | 1 |
| `## Verification` | 2 |
| Lines containing `smoke-test.sh` | 2 checkbox lines (the string appears twice on each line because of the `--live` example) |

After the first `## Verification` block, the three security checkboxes are repeated with no heading, and then `## Verification` starts again with the same two command checkboxes. GitHub renders that as one security section, a stray checkbox group, and two verification sections.

A contributor can tick the first copy and leave the second unchecked, or tick both and think they are different gates. Release Drafter and the security review both depend on this description being something a human can finish in one pass. `CONTRIBUTING.md` points at this file as the post-push checklist people should recognize.

Checked by reading `.github/pull_request_template.md`. No GitHub API call is required to see the duplicate.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/pull_request_template.md` | The form to edit |
| `CONTRIBUTING.md` local-checks section | The commands the boxes name |
| `scripts/smoke-test.sh` and `scripts/check-config.sh` | The checks themselves |
| Issue templates | Bug and suggestion intake, separate from this form |
| Stage 42 CI and pre-push contracts (expected siblings) | What the commands must keep doing |

Out of scope:

- A review bot that re-asks the same questions
- Changing smoke-test or check-config behavior
- New required status checks in branch protection
- Editing issue templates

## Proposal

Leave one security section and one verification section in the template that already exists.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Template | `.github/pull_request_template.md` | Delete the second security checkbox group and the second `## Verification` block |
| Order | Same file | Summary, Scope, Release notes, Security & RFC, Verification |
| Commands | Verification boxes | Keep `./scripts/smoke-test.sh` (and `--live` when Nginx is up) and `./scripts/check-config.sh` |
| Docs | `CONTRIBUTING.md` | The existing link stays valid because the file path does not change |

### Rules

1. **One heading, one list.** `## Security & RFC` appears once. `## Verification` appears once.
2. **Boxes stay unchecked in git.** The committed file uses `- [ ]`. GitHub stores the ticked copy on the pull request, not in the template.
3. **Commands stay the ones CONTRIBUTING already documents.** Do not add a third mandatory script in the same edit.
4. **Secrets stay out of the template.** The security box that forbids `.env` values and tokens stays in the single security section.
5. **Do not add a bot.** Deduplicating the Markdown is the whole change.

### Suggested contributor checklist

```text
1. Delete the repeated security checkboxes and the second Verification heading
2. Confirm rg -c "^## Verification" .github/pull_request_template.md prints 1
3. Confirm rg -c "^## Security" .github/pull_request_template.md prints 1
4. Open a draft pull request and confirm the form shows each box once
5. Leave CONTRIBUTING.md's link to the template path unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Review form | GitHub pull request template | A custom review app |
| Local proof | `smoke-test.sh` and `check-config.sh` | A new required CI job in this change |
| Intake | Existing issue templates | A second suggestion form |
| Policy text | `SECURITY.md` for vulnerabilities | Pasting exploit detail into the template |

## Acceptance criteria

- The template has one `## Security & RFC` section and one `## Verification` section.
- Each of those sections contains its checkboxes once.
- A new pull request description shows each box one time.
- `CONTRIBUTING.md` still points at `.github/pull_request_template.md`.

## Verification notes

Counted headings and `smoke-test.sh` lines in the file on `dev` on 2026-10-03. The duplicate is in the committed Markdown.

## Rollback

Restore the previous template text. GitHub uses whatever is on the base branch the next time someone opens a pull request. Open pull requests keep the description they already saved.
