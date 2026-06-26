# Suggestions Hub

This folder is the historical memory and proposal workspace for constructive TU-VM website, tooling, and community-system suggestions.

The current direction is to build a community-based system by reusing proven frameworks and the repository's existing operational surfaces instead of inventing a custom process from scratch.

## How to use this folder

1. Start with this file and [`index.md`](./index.md).
2. Check [`historical-suggestions.md`](./historical-suggestions.md) and [`historical-patterns-from-project.md`](./historical-patterns-from-project.md) before proposing a new idea.
3. Extend an existing suggestion file when the idea overlaps with prior work.
4. Create a new suggestion file only when the idea has a distinct problem, owner path, and acceptance criteria.
5. Link accepted or implemented suggestions back to issues, PRs, and [`CHANGELOG.md`](../CHANGELOG.md).

This keeps the community from rediscovering the same ideas and gives maintainers a clear trail from proposal to delivery.

## Canonical suggestion set

Use these files as the primary website and community-system proposal set:

| File | Purpose |
|---|---|
| [`website-and-docs-framework.md`](./website-and-docs-framework.md) | Recommended website/documentation framework, content architecture, and publishing model. |
| [`community-system-framework.md`](./community-system-framework.md) | Suggestion lifecycle, governance model, roles, review lanes, and decision rules. |
| [`website-tools-and-automation.md`](./website-tools-and-automation.md) | Day-to-day tooling, quality checks, duplicate detection, dashboard metrics, and maintainer automation. |
| [`website-information-architecture.md`](./website-information-architecture.md) | Navigation model, docs taxonomy, accessibility baseline, and website UX expectations. |
| [`website-community-framework.md`](./website-community-framework.md) | Website-facing governance and contributor trust model. |
| [`website-contributor-tooling.md`](./website-contributor-tooling.md) | Contributor diagnostics, docs quality gates, and release hygiene tools. |
| [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md) | Sequenced roadmap derived from recurring historical suggestions. |
| [`implementation-backlog.md`](./implementation-backlog.md) | Trimmed implementation backlog with completed work separated from next recommendations. |

Other files in this folder are historical drafts or topic-specific expansions. Keep them for context, but update the canonical files above when refining the main plan.

## Historical baseline reused

Recurring themes from prior suggestion work and existing project documentation:

1. A website structure that separates install, operations, security, community, and suggestions.
2. A lightweight RFC-style suggestion lifecycle with visible status and decision rationale.
3. Practical day-to-day tools that make diagnostics, validation, release notes, and documentation checks easier.
4. A dashboard/community bridge that exposes suggestion status without coupling it to core service controls.
5. Resource-aware rollout patterns that preserve TU-VM's LAN-first and secure-by-default posture.

## Design principles for all suggestions

1. Reuse existing project surfaces first: [`README.md`](../README.md), [`CHANGELOG.md`](../CHANGELOG.md), [`tu-vm.sh`](../tu-vm.sh), [`helper/uploader.py`](../helper/uploader.py), and [`nginx/html/index.html`](../nginx/html/index.html).
2. Prefer mature frameworks such as Docusaurus, MkDocs Material, Astro Starlight, GitHub Issues/Discussions, and lightweight CI checks over custom systems.
3. Add modular improvements over deep rewrites.
4. Preserve secure defaults, LAN-first behavior, and clear rollback paths.
5. Treat community suggestions as traceable work items with owners, acceptance criteria, and verification evidence.

To submit an idea via GitHub, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root.
