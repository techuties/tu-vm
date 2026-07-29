---
title: Suggestion Corpus Registry
description: Constructional contract for a machine-readable registry of historical and publishable suggestions so community automation reuses prior work instead of reinventing frameworks.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: community
impact: high
---

# Suggestion Corpus Registry

## Problem

The `suggestions/` tree already contains dozens of overlapping Markdown files from repeated `community-suggestions-*` automation runs. Historical themes (website IA, governance, day-to-day tooling, roadmaps) were rewritten many times because there was no **machine-readable inventory** of what already exists, what is canonical, and what is archive-only.

Without a registry, each cron run risks another parallel “community framework” document, contributors cannot dedupe before filing Issues, and maintainers cannot tell Stage website pages from superseded drafts.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`suggestions/`](../) historical Markdown | Archive of prior constructional ideas |
| [`suggestions/website/`](./index.md) | Publishable website content root (Stages 1–6) |
| [`implementation-backlog.md`](../implementation-backlog.md) | Trimmed execution priorities |
| [`website-community-pages.md`](../website-community-pages.md) | Lifecycle vocabulary and frontmatter guidance |
| Stage 1 `how-to-submit.md` / `status-board.md` (expected siblings) | Human dedupe and lifecycle views |
| Stage 4 `stage-merge-playbook.md` (expected sibling) | Merge order for website hubs |
| GitHub Issues suggestion form | Sole writable intake |
| Open PRs #23–#31 | Distinct stages already in flight |

Out of scope:

- A voting database or local suggestion queue API
- Auto-deleting historical Markdown without maintainer review
- Replacing GitHub Issues as the discussion surface
- Embedding full proposal bodies inside the registry (IDs + pointers only)

## Proposal

Add a single registry file that automation and humans both consult before authoring new suggestion docs:

```text
suggestions/registry.yaml
```

### Schema (v1)

```yaml
version: 1
canonical:
  - id: website-hub
    path: suggestions/website/index.md
    role: publishable-hub
    stage: 6
  - id: backlog
    path: suggestions/implementation-backlog.md
    role: execution-backlog
publishable:
  - id: corpus-registry
    path: suggestions/website/suggestion-corpus-registry.md
    theme: community
    status: proposed
    supersedes: []
archive:
  - id: hist-community-system-framework
    path: suggestions/community-system-framework.md
    theme: community
    note: Historical; prefer website/ + community-system-framework summary
open_prs:
  - number: 31
    stage: 5
    focus: day-to-day operating contracts
```

### Rules

1. **Publishable pages** under `suggestions/website/` must appear in `publishable` (or be rejected by CI).
2. **New root-level** `suggestions/*.md` files are discouraged; if added, they must register under `archive` or `canonical` with an explicit `note`.
3. Automation prompts must load `registry.yaml` and refuse to create a page whose `theme` + problem statement matches an existing `id` unless they **extend** that id (same path) or mark a deliberate `supersedes` edge.
4. Stage merge updates the hub `id: website-hub` once; stage-specific hub thrash is forbidden after merge.

### Companion validator

```text
scripts/validate-suggestions-registry.py
```

Checks:

- Every `path` exists
- No duplicate `id`
- Every `suggestions/website/*.md` (except generated digests if any) is listed under `publishable` or `canonical`
- Optional: warn when a new file’s title/description fuzzy-matches an archive entry above a threshold

Wire into CI beside existing docs/smoke jobs (docs-only PRs should still run this validator).

### Website placement

- Community → Integrity → Suggestion corpus registry
- Stage 1 how-to-submit should tell contributors to skim registry themes before opening Issues
- `suggestions/README.md` points here as the machine index

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Inventory format | YAML (already used across Compose/CI culture) | Custom binary index |
| Deduping | Registry + Issue search | Another narrative roadmap file |
| Publishing | Static website pages listed in registry | Shadow wikis |
| Automation memory | Point agents at registry + open PR list | Blind folder append |

## Rollout

1. Land this contract page and a starter `suggestions/registry.yaml` covering canonical + Stage 6 publishable paths (archive can be populated incrementally).
2. Add `scripts/validate-suggestions-registry.py` and a CI step.
3. Update automation memory / AGENTS notes to require registry consultation.
4. Extend Stage 4 merge playbook: “update registry in the same PR as hub reconcile.”

## Acceptance criteria

- [ ] `suggestions/registry.yaml` exists with versioned schema.
- [ ] Validator fails CI when a website page is missing from the registry.
- [ ] README/index link to the registry contract.
- [ ] No new parallel “community framework” root doc lands without a registry entry and supersedes note.

## Rollback

Keep historical Markdown as-is; disable the CI job if false positives block urgent docs. Registry file can remain advisory until the validator stabilizes.

## Success metrics

- Duplicate suggestion-doc creation rate drops across automation runs.
- Contributors cite existing `id`s when filing related Issues.
- Stage merges update one hub + registry instead of N competing indexes.
