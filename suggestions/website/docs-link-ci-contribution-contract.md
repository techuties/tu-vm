---
title: Docs Link CI Contribution Contract
description: Constructional contract for community contributions to the Docs links / Lychee workflow and markdown link hygiene—without inventing a custom link crawler platform.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Docs Link CI Contribution Contract

## Problem

Broken links erode contributor trust. Historical suggestions invent custom crawlers, SPA link graphs, or disable CI when flaky third-party docs 403. The repo already runs a Lychee-based **Docs links** workflow—community work should extend that lane with clear exclude rules and scoped file sets.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/workflows/docs-links.yml` | CI workflow for markdown link checks |
| `lychee.toml` | Exclude / accept configuration |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Explains Docs links job and flaky URL policy |
| Stage 3 `docs-framework-adoption.md` (expected sibling) | Future static site adoption gates |
| Stage 5 `community-quality-gates.md` (expected sibling) | Broader evidence map |
| Stage 6 `website-frontmatter-ci-contract.md` (expected sibling) | Frontmatter/schema checks for publishable pages |
| Stage 6 `airgap-docs-mirror.md` (expected sibling) | Offline docs pack (complementary) |

Out of scope:

- Building a bespoke link graph service
- Widening excludes to silence real broken same-repo links
- Requiring external Internet for every community PR when only relative links changed (document skip/path filters carefully)
- Using link CI as a substitute for security review

## Proposal

Publish a **docs link CI contribution contract** for workflow and markdown hygiene PRs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Workflow | `.github/workflows/docs-links.yml` | Clear file globs; Summary output preserved |
| Lychee config | `lychee.toml` | Excludes are justified and commented |
| Markdown fixes | `docs/`, `suggestions/`, root policy docs | Prefer relative links for in-repo targets |
| Contributor docs | `CONTRIBUTING.md` | Matches actual workflow behavior |

### Rules

1. **Reuse Lychee.** Do not replace with a custom crawler unless Stage 3 docs framework adoption explicitly requires it.
2. **Justify excludes.** Each exclude pattern needs a one-line reason (flaky third party, compare-range URLs, auth walls).
3. **Prefer relative links** for same-repo targets so airgap and mirrors keep working.
4. **Do not hide breakage.** Excluding `docs.example` because CI is red is not a fix—repair the link or document the upstream outage.
5. **Scope thoughtfully.** Expanding globs to `suggestions/website/**` is welcome when those pages merge; keep runtime cost bounded.
6. **No secrets in URLs.** Docs must not embed tokens in query strings to make links “work.”
7. **GitHub remains intake.** “Buy a SaaS docs QA product” stays an Issue; default is Lychee workflow.

### Suggested contributor checklist

```text
1. Reproduce with the same lychee version/flags as CI when possible
2. Prefer fixing relative paths over adding excludes
3. If exclude is required, comment why in lychee.toml
4. Update CONTRIBUTING.md if workflow behavior changes
5. Avoid unrelated markdown rewrites in the same PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Link checking | Existing Docs links + Lychee | Custom crawler service |
| Publishable pages | Stage 6 frontmatter CI | Duplicating schema checks here |
| Offline readers | Relative links + airgap mirror | Absolute GitHub URLs for every in-repo hop |
| Flaky third parties | Narrow documented excludes | Global `accept` of all HTTPS failures |

## Rollout

1. Publish this page under `suggestions/website/`.
2. When Stage pages merge, ensure `suggestions/website/**` is in the scanned set or intentionally deferred with a note.
3. Prefer **code** fixes for broken links and precise excludes over more prose.

## Acceptance criteria

- [ ] Lychee reuse is mandatory by default.
- [ ] Exclude justification rule is stated.
- [ ] Relative-link preference for in-repo targets is stated.
- [ ] Secret-in-URL prohibition is stated.
- [ ] CONTRIBUTING parity is required when workflow behavior changes.

## Rollback

Revert workflow/config/docs commits independently; prior CI behavior returns. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer flaky third-party failures without widening excludes blindly.
- Suggestions website pages stay link-clean as Stages merge.
- Contributors understand how to fix vs exclude.
