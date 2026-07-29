---
title: Deprecation Notice Framework
description: Constructional framework for community-visible deprecations and breaking changes that ties CHANGELOG, website notices, and playbook version notes together.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Deprecation Notice Framework

## Problem

TU-VM evolves through Compose pins, helper contracts, CLI flags, and dashboard UX. Community contributors and operators learn about breaking changes late—via failed upgrades—because notices are split across commit messages, informal chat, and occasional CHANGELOG lines. Historical suggestions asked for “roadmaps” and “status boards,” but day-to-day trust needs a **boring deprecation protocol** that reuses CHANGELOG + playbooks + website pages instead of a separate status product.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`CHANGELOG.md`](../../CHANGELOG.md) | Human-readable shipped history |
| Release Drafter + GitHub Releases | Versioned ship channel |
| Stage 3 `decision-log.md` / `implemented-showcase.md` (expected siblings) | Why / what shipped |
| Stage 5 `playbook-version-matrix.md` (expected sibling) | Recipe vs release compatibility |
| Stage 1 `status-board.md` (expected sibling) | Suggestion lifecycle (not the same as runtime deprecations) |
| PR template “Breaking operational behavior” checkbox | Human gate on PRs |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor expectations |

Out of scope:

- Semantic-version enforcement bots as a prerequisite
- Silent compatibility shims forever without removal dates
- A second “status SaaS” for deprecation banners
- Deprecating LAN security defaults casually (those need Decision Log + security review)

## Proposal

Adopt a small **notice framework** with three synchronized surfaces:

1. **CHANGELOG** — authoritative “what changed / what breaks”
2. **Website deprecations page** — curated, still-active notices for operators
3. **Playbook version matrix** — which recipes still apply

### Notice record (website)

Add publishable page (living document):

```text
suggestions/website/deprecations.md   # generated or curated table
```

Each row:

| Field | Meaning |
|---|---|
| `id` | `DEP-YYYY-NN` |
| `surface` | `cli` \| `compose` \| `helper` \| `dashboard` \| `docs` |
| `summary` | One line |
| `introduced_in` | Version or date |
| `remove_after` | Target version or “not before YYYY-MM” |
| `migration` | Link to playbook / README section |
| `decision` | Link to Decision Log entry when applicable |

Until automation exists, maintainers edit the table manually in the same PR that introduces the deprecation.

### Severity

| Level | Meaning | Required surfaces |
|---|---|---|
| Soft | Warning only; old path still works | CHANGELOG + website row |
| Hard | Old path removed or default flipped | CHANGELOG + website + playbook matrix + Release notes |
| Security | Exposure/default-deny changes | Above + Decision Log + SECURITY review path |

### Contributor protocol

When a PR marks breaking behavior:

1. Check the PR template breaking box and describe operator impact.
2. Add a CHANGELOG fragment / ensure Release Drafter label (`breaking` if used).
3. Add or update a `DEP-*` row (or justify “not user-visible”).
4. Update playbook matrix if commands/recipes change.
5. Prefer compatibility window ≥ one minor/release train for Soft deprecations.

### Optional automation (later)

- CI grep for removed flags mentioned in `deprecations.md` still marked Soft past `remove_after`
- Release workflow fails if `breaking` label lacks a `DEP-*` id in the PR body

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| History | CHANGELOG + Releases | Shadow spreadsheets |
| Operator view | Static website table | Dashboard modal spam for every docs typo |
| Decisions | Stage 3 Decision Log | Rewriting rationale only in Slack |
| Recipes | Playbook version matrix | README-only tribal knowledge |

## Rollout

1. Land this framework page (contract).
2. Add empty `deprecations.md` table on Stage merge (or in a follow-up implementation PR).
3. Sync CONTRIBUTING with a five-line pointer.
4. Backfill 1–3 known recent breaking items as examples (if any), else leave the table header-only.

## Acceptance criteria

- [ ] Soft/Hard/Security levels defined with required surfaces.
- [ ] Notice row schema documented.
- [ ] PR/CHANGELOG/playbook synchronization steps are explicit.
- [ ] Status-board (suggestions) is not overloaded to track runtime deprecations.

## Rollback

Rely on CHANGELOG alone; remove website table if unused. Keep Decision Log for security-impacting changes.

## Success metrics

- Breaking PRs reference a `DEP-*` id.
- Operators find migration links before upgrading.
- Playbook matrix and deprecation table disagree less often over time.
