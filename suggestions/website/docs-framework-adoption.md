---
title: Docs Framework Adoption Runbook
description: Constructional website page for adopting a static docs framework for TU-VM community content without reinventing a CMS or moving the Nginx control plane.
last_updated: 2026-07-26
owner: maintainers
status: proposed
theme: docs
impact: high
---

# Docs Framework Adoption Runbook

## Problem

Historical suggestions repeatedly compared Docusaurus, MkDocs, custom HTML, and “docs inside Nginx.” Memory and Stage 1/2 pages already set a **reuse-first** policy, but the community still lacks a **constructional adoption runbook**: when to adopt, which default, how to migrate `suggestions/website/` once, and how to roll back.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`../website-and-docs-framework.md`](../website-and-docs-framework.md) | Earlier stack comparison and IA sketch |
| This `suggestions/website/` tree | Publishable Markdown content root candidate |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes that must remain linked |
| Nginx `nginx/html/index.html` | Operational dashboard (keep separate) |
| Docs link workflow + lychee | Link hygiene already in CI |
| GitHub Pages / any static host | Deployment options after build exists |

Do **not** turn the LAN dashboard into a documentation CMS, add SSR for curated Markdown, or maintain two editable copies of the same pages.

## Framework choice (constructional default)

| Option | Choose when | Trade-off |
|---|---|---|
| **Astro Starlight (default)** | Need polished docs UX, component escapes, and a modern Markdown content tree | Slightly more JS ecosystem surface than MkDocs |
| **MkDocs Material** | Prefer Python-only contributor tooling and fastest static build | Weaker component model if interactive widgets appear later |
| **Docusaurus** | Team already standardized on React docs elsewhere and needs its versioning plugins specifically | Heavier than Starlight/MkDocs for this repo’s current size |

**Decision aligned with community policy:** default to **Astro Starlight** unless MkDocs Material clearly wins on contributor tooling constraints. SSR frameworks are out of scope for community suggestion pages.

## Adoption gates (must pass before migration)

Do not create a `docs-site/` package until all gates are true:

1. **Single content root agreed:** `suggestions/website/` maps to `docs/community/` (or Starlight `src/content/docs/community/`) with one editable tree.
2. **Navigation IA frozen** for Community / Operate / Playbooks (see [`index.md`](./index.md) and expected Stage 1/2 siblings).
3. **Search requirement stated:** local search is enough for v1; Algolia only if operators need hosted search.
4. **Versioning requirement stated:** start unversioned; add docs versioning only when release docs diverge enough to confuse operators.
5. **CI budget exists:** build + link check on PRs that touch docs content.
6. **Dashboard boundary documented:** Nginx remains control plane; docs site is separate origin or path that does not require control tokens.

## Proposed construction sequence

### Phase A — Content freeze and inventory

1. Merge Stage 1 + Stage 2 + Stage 3 website pages carefully (shared `index.md`).
2. Mark overlapping root-level `suggestions/website-*.md` drafts as historical pointers to this folder where needed (do not rewrite all archives in one PR).
3. Confirm relative links resolve from the website folder.

### Phase B — Scaffold (after gates)

```text
docs-site/                 # or website/ at repo root if preferred
  package.json             # Starlight app
  src/content/docs/
    community/             # mapped from suggestions/website/
    operate/playbooks/     # thin stubs linking to docs/playbooks
```

Rules:

- Community pages move **or** are included via a single copy step in CI—not hand-duplicated forever.
- Playbooks stay authoritative under [`docs/playbooks/`](../../docs/playbooks/README.md).
- Prefer Markdown + Starlight asides over custom React islands for v1.

### Phase C — CI and preview

- PR workflow: install, build, lychee/markdown link check on output or source.
- Optional: deploy preview for docs-only PRs.
- Fail on broken internal links; warn on known flaky external domains already excluded in lychee config.

### Phase D — Cutover

1. Publish docs site URL in README and landing “Community” strip (link only).
2. Keep `suggestions/website/` as the editable source **or** relocate once and update all canonical pointers in the same PR.
3. Add a short operator note: docs site may be public/static; control plane remains LAN-allowlisted.

## Day-to-day contributor workflow (after adoption)

| Change type | Edit where | Validate with |
|---|---|---|
| Community suggestion pages | Content root (`suggestions/website/` or mapped path) | docs build + link check |
| Operator playbooks | `docs/playbooks/` | relative anchors + smoke docs-links |
| Control plane UX | `nginx/html/` | helper contract + live smoke when nginx up |
| Governance process | Decision log / status board pages | human review + GitHub links |

Optional sugar (never a second source of truth): `just docs-build` / `make docs-build` wrapping the Starlight build.

## Rollback

- Revert the docs-site package and CI workflow.
- Leave Markdown content intact in git.
- Landing page links fall back to GitHub-rendered Markdown paths.
- No data migration is required because there is no docs database.

## Out of scope

- Authenticating readers on the docs site for suggestion voting
- Hosting the docs site inside the Pi-hole/Nginx control allowlist by default
- Auto-generating pages from live `/status/full` (ops dashboards stay on Nginx)

## Success criteria

- A contributor can add a community page by editing Markdown and passing docs CI only
- Operators still use the Nginx dashboard for Tier controls without loading the docs framework
- There is exactly one editable copy of each community page after cutover
- Adoption is blocked publicly by the gate checklist until maintainers check it off
