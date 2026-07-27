---
title: Stage Merge Playbook
description: Constructional playbook for merging Stage 1–3 suggestions/website trees into one publishable hub without duplicate editable copies.
last_updated: 2026-07-27
owner: maintainers
status: proposed
theme: community
impact: high
---

# Stage Merge Playbook

## Problem

Open community-suggestion PRs each add a `suggestions/website/index.md` hub plus sibling pages (Stage 1 submit/status/MCP, Stage 2 matrix/personas/profiles, Stage 3 decision/showcase/gates/extension/intake). Stage 4 adds implementation contracts. Naïve merges will thrash `index.md`, break relative links, or create two editable trees once a docs framework is adopted.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Stage 1 PR website pages | Submit, status board, day-to-day tools, MCP catalog |
| Stage 2 PR website pages | Hardware matrix, personas, operator profiles |
| Stage 3 PR website pages | Decision log, showcase, docs adoption, quality gates, extension contract, hardware intake |
| Stage 4 pages (this folder set) | Implementation contracts + this playbook |
| `website-community-pages.md` | Lifecycle vocabulary |
| Docs-framework adoption (Stage 3) | Single content root later (`docs/community/`) |
| GitHub-native Issues | Sole writable intake |

## Proposal

Treat `suggestions/website/` as the **staging content root** until docs-framework gates pass. Merge with a deliberate order and a single hub file.

### Merge order (recommended)

1. **Stage 1** — foundational contributor pages (how-to-submit, status-board, day-to-day tools, MCP catalog).
2. **Stage 2** — living operational artifacts (matrix, personas, profiles).
3. **Stage 3** — lifecycle transparency + constructional contracts.
4. **Stage 4** — implementation contracts (MCP CI, profile CLI, extension scaffold, supply-chain, dashboard smoke).
5. **Hub reconcile** — rewrite `website/index.md` once as the union map (do not keep Stage-specific hubs).

If PRs must land out of order, keep “expected sibling” prose (as Stages 2–4 already do) instead of inventing stub files that duplicate future pages.

### Hub reconcile checklist

When editing the merged `suggestions/website/index.md`:

- [ ] One frontmatter `title` / `description` covering the whole community website set.
- [ ] Boundaries table still forbids local voting DBs and dashboard intake.
- [ ] Page map lists **all** Stage 1–4 siblings with relative links that resolve.
- [ ] Framework reuse policy remains reuse-first (GitHub, Starlight-after-gates, Compose, MCP gateway).
- [ ] Navigation section maps to a future `docs/community/` **without** instructing maintainers to copy-paste indefinitely.
- [ ] Pointers to `../website-community-pages.md` and `../implementation-backlog.md` remain.

### Conflict resolution rules

| Conflict | Resolve by |
|---|---|
| Duplicate `index.md` hubs | Keep richest boundaries + union page map; drop stage-only marketing fluff |
| Divergent docs framework preference | Starlight default; Docusaurus/MkDocs only with Stage 3 gate rationale |
| Overlapping MCP guidance | Human catalog (Stage 1) + CI contract (Stage 4); one `catalog.yaml` later |
| Overlapping extension guidance | Contract (Stage 3) + scaffold (Stage 4); one `extensions/` tree |
| Overlapping profile guidance | Catalog (Stage 2) + CLI (Stage 4); one membership source |
| Historical archive vs website | Archive stays under `suggestions/*.md`; publishable pages under `suggestions/website/` |

### Link hygiene

After merge:

```bash
git diff --check origin/dev...HEAD
# Resolve every relative link among suggestions/website/*.md
python3 scripts/validate_status_full_contract.py
```

Prefer prose references to “expected siblings” over creating empty stubs. Avoid trailing two-space Markdown hard breaks (`git diff --check` flags them).

### After docs-framework adoption

1. Move or mount `suggestions/website/` → `docs/community/` (or configured content root).
2. Leave a short stub index under `suggestions/website/README` **or** update `suggestions/README.md` to point at the new root—**one** editable copy only.
3. Redirect CI link checks to the new paths.
4. Do not keep dual-maintained duplicates “for a while” without an owner and expiry.

### Maintainer day-to-day during the PR pile-up

1. Review Stage PRs for **distinct pages**, not restated roadmaps.
2. Request authors avoid rewriting `implementation-backlog.md` completed sections unless marking shipped work.
3. When two PRs touch the same hub, merge earlier stage first and rebase the later.
4. Close superseded consolidation PRs that only restate canonical paths already landed.

## Acceptance criteria

- [ ] Single `suggestions/website/index.md` after Stages 1–4 land.
- [ ] All sibling relative links resolve.
- [ ] No second editable community tree created pre-adoption.
- [ ] Backlog references Stage pages that exist on the default branch.
- [ ] Automation memory / maintainer notes updated when the merge completes.

## Rollout and rollback

1. Merge stages in order; hub reconcile commit is its own PR if needed.
2. Rollback of a bad hub = restore previous `index.md`; sibling pages can remain.

## Success signals

- Contributors find one navigation map instead of Stage-branded forks.
- Docs adoption migrates a single folder.
- New automation runs extend Stage 4+ contracts instead of opening parallel roadmap PRs.
