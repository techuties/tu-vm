# Suggestions Hub

This folder contains detailed, implementation-oriented suggestions for building a community-driven website and contributor system without reinventing existing work.

## Historical baseline used

These suggestions are consolidated from previous `community-suggestions-*` branches so repeated ideas are reused instead of reauthored from scratch.

Recurring themes identified across historical branches:

1. Website information architecture for docs + operations + community
2. Community governance and contribution workflow
3. Practical contributor tooling for day-to-day operations
4. A phased roadmap built from already proposed feature directions

## Canonical recommendation from the historical review

The historical suggestions contain several valid framework options (Docusaurus, Astro/Starlight, VitePress, MkDocs Material), but the common requirement is more important than any single tool: keep Markdown as the source of truth, publish a static website, and make community proposals easy to review.

Recommended default path:

1. **Keep the current Nginx dashboard as the operator control plane.**
   It already owns live service status, controls, announcements, and LAN-first behavior.
2. **Add a separate static documentation/community site when implementation starts.**
   Use Docusaurus for a docs-first community portal, or Astro/Starlight if the project needs richer marketing pages and custom layouts. Do not rebuild search, routing, navigation, or docs versioning from scratch.
3. **Treat this `suggestions/` folder as the historical proposal archive.**
   New proposal pages should link to earlier related files and state whether they supersede, extend, or reject older ideas.
4. **Surface accepted suggestions through GitHub Issues, release notes, and the website.**
   GitHub remains the workflow system; the website should make the workflow discoverable.

This keeps the project community-based without adding a custom governance application before the existing GitHub and Markdown workflow has been fully used.

## Files in this folder

- `website-historical-baseline.md`  
  Historical suggestion patterns and how they were merged into a single framework.

- `website-information-architecture.md`  
  Detailed website structure, content model, and docs framework recommendation.

- `website-community-framework.md`  
  Community operating model, governance, ownership, and review standards.

- `website-contributor-tooling.md`  
  Concrete tooling proposals that improve day-to-day contributor productivity.

- `website-roadmap-from-historical-suggestions.md`  
  Sequenced roadmap that maps historical suggestions to implementation milestones.

- `implementation-backlog.md`
  Trimmed implementation backlog that removes already-shipped GitHub, CI, dashboard, and tooling work.

## Design principles for all suggestions

1. Reuse existing project surfaces first (`README.md`, `CHANGELOG.md`, `tu-vm.sh`, helper API, nginx landing page).
2. Add modular improvements over deep rewrites.
3. Keep secure defaults and LAN-first behavior as non-negotiable.
4. Prioritize contribution quality, reproducibility, and maintainability.

To submit an idea via GitHub only, see [CONTRIBUTING.md](../CONTRIBUTING.md) at the repository root (Issues + PR templates).

For the **trimmed backlog** (implemented items removed) and **ten prioritized next recommendations**, see [`implementation-backlog.md`](./implementation-backlog.md).
