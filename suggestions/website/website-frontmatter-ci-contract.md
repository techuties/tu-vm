---
title: Website Frontmatter CI Contract
description: Constructional contract for validating publishable suggestions/website markdown frontmatter, required fields, and relative links before merge.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Website Frontmatter CI Contract

## Problem

Publishable website pages use YAML frontmatter (`title`, `description`, `last_updated`, `owner`, `status`, …) described in [`website-community-pages.md`](../website-community-pages.md), but nothing enforces it. Multi-stage PRs already risk broken relative links to “expected sibling” pages and inconsistent metadata. When a static docs framework (Astro Starlight / Docusaurus / MkDocs) eventually ingests `suggestions/website/`, schema drift becomes a broken build.

Day-to-day community publishing needs a small, boring CI contract—not a CMS.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`website-community-pages.md`](../website-community-pages.md) | Human metadata vocabulary |
| `.github/workflows/docs-links.yml` | Lychee link checks for docs |
| Stage 3 `docs-framework-adoption.md` (expected sibling) | Gates before moving content root |
| Stage 4 `stage-merge-playbook.md` (expected sibling) | Hub/sibling merge rules |
| Stage 6 suggestion corpus registry | Inventory of publishable paths |
| `git diff --check` | Catches trailing whitespace / conflict markers |
| GitHub Actions CI | Existing PR gates |

Out of scope:

- Full markdownlint rule explosion on all historical `suggestions/*.md` on day one
- Rendering the entire static site in CI before docs-framework adoption gates pass
- Requiring every archive file under `suggestions/` to adopt website frontmatter
- CMS-style draft/publish workflow inside the LAN dashboard

## Proposal

Treat `suggestions/website/**/*.md` as a **schema-checked content pack**.

### Required frontmatter (publishable pages)

| Field | Type | Notes |
|---|---|---|
| `title` | string | Non-empty; used as H1-equivalent in site nav |
| `description` | string | One or two sentences; ≤ 240 chars recommended |
| `last_updated` | date | `YYYY-MM-DD` |
| `owner` | string | Default `maintainers` |
| `status` | enum | `proposed` \| `accepted` \| `implemented` \| `deferred` \| `rejected` |
| `theme` | enum | `community` \| `tooling` \| `security` \| `docs` \| `integrations` \| `mcp` \| `operations` \| `observability` |
| `impact` | enum | `high` \| `medium` \| `low` (optional on hub `index.md`) |

Hub `index.md` may omit `theme`/`impact` but must include `title`, `description`, `last_updated`, `owner`, `status`.

### Validator

```text
scripts/validate-website-frontmatter.py
```

Behavior:

1. Parse frontmatter with a strict YAML subset (fail on tabs / duplicate keys).
2. Enforce required fields and enums.
3. Collect Markdown relative links to `.md` targets under `suggestions/website/`.
4. **Policy for missing siblings:** links to files not present on the branch are warnings if the target is listed in the corpus registry as `expected-sibling` / open Stage PR; **errors** if the target is claimed `publishable` on this branch but missing.
5. Forbid absolute `/suggestions/...` site paths until docs-framework adoption defines the final URL map.
6. Exit non-zero on errors; print a concise Actions summary.

### CI wiring

- Job `website-markdown` on changes to `suggestions/website/**` or the validator script.
- Keep docs-links Lychee separate; this contract is schema + intra-pack links.
- Optional later: markdownlint with a narrow rule set only on `suggestions/website/`.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Frontmatter | Existing YAML block convention | Inventing TOML/JSON sidecars per page |
| Link proof | Path existence + registry awareness | Fetching live GitHub HTML |
| Site build | Defer full Starlight build until Stage 3 gates | Premature framework lock-in in CI |
| Archive docs | Leave historical files alone | Big-bang reformatting 70+ archive pages |

## Rollout

1. Land this page; align Stage 6 pages to the schema (already using it).
2. Ship the validator with `--warn-missing-siblings` default; tighten to error after Stage merge.
3. Document the enum lists in CONTRIBUTING under a short “Website markdown” bullet.
4. After docs-framework adoption, point the same validator at `docs/community/` (one content root).

## Acceptance criteria

- [ ] Validator script exists and runs in CI for `suggestions/website/` changes.
- [ ] Missing required frontmatter fails the job.
- [ ] Relative links to same-branch publishable pages are verified.
- [ ] Historical archive Markdown outside `website/` is not blocked by this job.

## Rollback

Disable the workflow job; keep pages. Loosen enums if they prove too rigid—prefer extending the enum over removing validation.

## Success metrics

- Zero merged website pages without `last_updated` / `status`.
- Stage merges no longer land broken relative links among publishable siblings.
- Docs-framework import of `suggestions/website/` needs no emergency metadata cleanup.
