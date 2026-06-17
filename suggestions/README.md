# Suggestions Hub

This folder is the repository-backed home for constructive suggestions about the TU-VM website, contributor experience, and community operating model.

The goal is not to invent a custom community platform. The goal is to turn repeated historical ideas into website-ready Markdown pages that reuse proven frameworks, GitHub-native workflows, and the operational tools already present in this repository.

## What was checked

The current suggestion set was reviewed against:

1. Existing repository docs: `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `QUICK_REFERENCE.md`, and `docs/playbooks/`.
2. Existing runtime surfaces: `tu-vm.sh`, `helper/uploader.py`, `nginx/html/index.html`, and the Compose service model.
3. Historical `community-suggestions-*` direction already captured in this folder, especially repeated themes around docs, governance, tooling, and phased delivery.

## Canonical website suggestion bundle

Use these files as the primary website-ready suggestion set:

- [`website-historical-baseline.md`](./website-historical-baseline.md)  
  Consolidates recurring historical suggestions so the project does not repeat prior design work.

- [`website-information-architecture.md`](./website-information-architecture.md)  
  Defines the suggested docs/community website structure, framework selection rules, page taxonomy, and accessibility baseline.

- [`website-community-framework.md`](./website-community-framework.md)  
  Defines the community operating model, suggestion lifecycle, review lanes, ownership, and governance expectations.

- [`website-contributor-tooling.md`](./website-contributor-tooling.md)  
  Recommends practical tools that ease day-to-day contributor and maintainer work.

- [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md)  
  Converts historical suggestions into an incremental roadmap with dependencies and success signals.

- [`implementation-backlog.md`](./implementation-backlog.md)  
  Tracks what is already completed or superseded and lists the next implementation-ready items.

Older overlapping files in this folder are retained as historical context. When a proposal is promoted, link it from this canonical bundle instead of creating another duplicate suggestion page.

## Reuse-first decisions

Prefer these existing or mature systems before adding custom infrastructure:

1. **GitHub Issues, Discussions, pull request templates, labels, and Release Drafter** for public intake, triage, decisions, and release communication.
2. **A static docs framework** for the website layer rather than handwritten navigation and search.
3. **Existing TU-VM operations surfaces** (`tu-vm.sh`, helper status endpoints, Nginx dashboard) as the source of truth for runtime behavior.
4. **Existing validation scripts and CI checks** before adding new automation.
5. **Plain Markdown with light metadata** so suggestions remain reviewable in GitHub and portable to a future docs site.

## Suggested status model

Use a small set of statuses across suggestion pages:

| Status | Meaning |
| --- | --- |
| `proposed` | Idea is documented and awaiting triage. |
| `triaged` | Maintainers confirmed category, duplicate status, and risk level. |
| `accepted` | Maintainers agree this should be implemented. |
| `in-progress` | Work is actively underway. |
| `implemented` | Change has shipped and is linked to evidence. |
| `deferred` | Valid idea, but not a current priority. |
| `superseded` | Replaced by another suggestion or already covered by existing work. |

## Minimum shape for new website suggestions

New suggestion pages should include:

1. Problem statement
2. Historical context or duplicate check
3. Recommended framework, tool, or reuse path
4. Implementation steps
5. Security and resource impact
6. Validation approach
7. Success signals
8. Links to related files or shipped evidence

To submit an idea via GitHub, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root.
