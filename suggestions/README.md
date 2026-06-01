# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

The folder already includes historical community proposals. New recommendation work should start here, compare against the existing files, and update the closest matching page before adding another Markdown file.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs, operations, and community pages.
2. Community governance and contribution workflow.
3. Practical contributor tooling for day-to-day operations.
4. A phased roadmap built from already proposed feature directions.
5. Secure-by-default, LAN-first operations that keep TU-VM useful for private AI and home-lab use.

## Curated website suggestion set

Use these files as the canonical website proposal set:

- `website-historical-baseline.md`  
  Historical suggestion patterns and how they were merged into a single framework.

- `website-information-architecture.md`  
  Detailed website structure, docs taxonomy, content model, and static-site framework recommendation.

- `website-community-framework.md`  
  Community operating model, governance, ownership, review standards, and quality gates.

- `website-community-platform.md`
  Website-native suggestion system proposal covering intake, duplicate detection, lifecycle status, and helper API extensions.

- `website-tools-and-automation.md`
  Maintainer and contributor tooling ideas for daily operations, validation, summaries, and release traceability.

- `website-contributor-tooling.md`  
  Concrete tooling proposals that improve day-to-day contributor productivity.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced roadmap that maps historical suggestions to implementation milestones.

- `implementation-backlog.md`
  Trimmed backlog with shipped items removed and the next high-value recommendations listed.

## Recommended framework direction

The suggestions converge on a reuse-first architecture:

1. **GitHub-native community workflow first**: Issues, PR templates, Discussions, labels, CODEOWNERS, Release Drafter, and stale automation remain the lowest-friction public contribution layer.
2. **Markdown as the canonical source**: Suggestions should stay reviewable in Git and render cleanly into a website/docs section.
3. **Static docs website when scale requires it**: Prefer Docusaurus for docs, versioning, and contributor-friendly Markdown. Prefer Astro/Starlight only if the website must become a broader content and marketing surface.
4. **Existing landing dashboard for operator shortcuts**: Keep `nginx/html/index.html` as the local operations entrypoint and link to community/docs pages instead of rebuilding the dashboard as a separate app.
5. **Helper API for lightweight dynamic data**: Extend `helper/uploader.py` only for small local status, suggestion, or digest endpoints that benefit from runtime data.
6. **Automation before platforms**: Use small scripts, CI checks, and optional n8n workflows before introducing new long-running services.

## Day-to-day tools to prioritize

The most useful near-term tools are:

1. Suggestion structure validation for required sections and metadata.
2. Duplicate or overlap hints against this `suggestions/` folder.
3. Docs link and heading checks for website-ready Markdown.
4. Release-note helpers that connect shipped work back to suggestion IDs.
5. Lightweight dashboard or generated JSON summaries for proposal status.
6. Optional AI-assisted summarization using local TU-VM models, with maintainer review required for every decision.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.
5. Make community decisions traceable from suggestion to implementation to release notes.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).
