# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production
- Keeping the local dashboard, helper API, and secure-by-default operating model intact

## Why this exists

To avoid reinventing the wheel, the project should standardize on proven open-source patterns, then customize only where TU-VM has unique constraints: private AI, LAN-first operation, Docker Compose orchestration, and lightweight operator workflows.

## Historical suggestions reviewed

The current folder already contains multiple generations of community and website proposals. The recurring patterns are:

1. Create a website/docs structure that separates install, operate, security, community, and suggestions content.
2. Use a transparent suggestion lifecycle so contributors can see whether ideas are proposed, accepted, shipped, rejected, or merged with an existing item.
3. Prefer GitHub-native workflows, Markdown, CI, and helper scripts before introducing a new database-backed platform.
4. Improve day-to-day life through diagnostics, smoke tests, release-note helpers, link checks, and duplicate detection.
5. Keep security, resource usage, rollback, and documentation impact visible in every major proposal.

## Curated suggestion map

1. [Website Information Architecture](./website-information-architecture.md)
   Defines the proposed website sections, content taxonomy, docs framework options, and page templates.

2. [Website Community Framework](./website-community-framework.md)
   Defines community roles, ownership, review lanes, release communication, and security guardrails.

3. [Website Community Platform](./website-community-platform.md)
   Describes a website-native suggestion system that can start with GitHub and Markdown, then optionally extend into helper API endpoints.

4. [Website Tools and Automation](./website-tools-and-automation.md)
   Covers day-to-day tooling, duplicate checks, dashboards, AI-assisted review helpers, and release traceability.

5. [Contributor Tooling](./website-contributor-tooling.md)
   Focuses on diagnostics, validation, docs quality, and release support for contributors.

6. [Roadmap From Historical Suggestions](./website-roadmap-from-historical-suggestions.md)
   Sequences the historical proposals into website, governance, tooling, profile, and optimization phases.

7. [Implementation Backlog](./implementation-backlog.md)
   Tracks what is already implemented or superseded and lists the remaining high-value recommendations.

## Recommended framework stack

The best fit is a layered stack, not a single new platform:

| Layer | Recommended framework/tooling | Why it fits |
|---|---|---|
| Public contribution workflow | GitHub Issues, PR templates, labels, Discussions, CODEOWNERS | Contributors already know it; decisions are auditable. |
| Canonical suggestion content | Markdown in `suggestions/` with required sections | Reviewable, searchable, and easy to render into a docs site. |
| Docs website | Docusaurus first; Astro/Starlight if richer site composition is needed | Avoids writing a docs engine from scratch. |
| Local operator entrypoint | Existing Nginx landing page | Keeps TU-VM operations simple and LAN-local. |
| Runtime status and digest data | Existing Flask helper API | Small dynamic surfaces without adding a heavy service. |
| Automation | CI, small Python/Bash scripts, optional n8n workflows | Reduces repeated maintainer work while staying transparent. |
| AI assistance | Local TU-VM models for summaries and risk hints | Uses existing platform strengths while keeping humans responsible. |

## Suggested execution sequence

### Phase 1: Foundation

Already mostly complete on the GitHub-native path: suggestion and PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links, release automation, and security reporting.

Still useful:

- Publish explicit maintainer label and ownership conventions beside Issues.
- Normalize the curated website suggestion pages into a future docs website section.
- Add a compact "how to submit a good suggestion" page or section.

### Phase 2: Acceleration

- Add structure validation for suggestion Markdown.
- Add duplicate and overlap hints against historical suggestions.
- Generate a static suggestion index or JSON summary for the website.
- Surface playbooks and community links from the dashboard with stable anchors.
- Track lightweight adoption metrics such as open suggestions by status and release traceability.

### Phase 3: Scale

- Add optional helper API endpoints for suggestion statistics if static files become insufficient.
- Introduce optional n8n workflows for reminders, digests, and stale proposal nudges.
- Create plugin/integration curation criteria for community extensions.
- Publish periodic roadmap and retrospective summaries.

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and prioritized remaining recommendations.
