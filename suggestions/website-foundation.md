# Website Foundation and Framework Choices

## Objective

Create a maintainable website stack for TU-VM that avoids reinventing common features (docs, search, contributor pages, changelog rendering, release notes, community hub).

## Current baseline

- The project already has a functional operational dashboard at `nginx/html/index.html`.
- The dashboard is tightly coupled to runtime service controls and should remain stable.
- There is no dedicated contributor/community website framework yet.

## Recommendation: split "operations UI" from "community website"

Keep the current dashboard as the operational control plane, and add a separate static site for docs/community pages.

### Why this split works

- Prevents regressions in the production control dashboard.
- Enables fast improvements in documentation and onboarding without touching service control logic.
- Lets the community contribute content with low risk.

## Suggested stack (do not build from scratch)

## 1) Core website framework: Astro

Use Astro for a content-heavy, performance-first site.

Why Astro:
- Excellent static output (fits Nginx hosting model).
- Markdown/MDX native workflow for contributors.
- Easy component islands when interactivity is needed.
- Strong docs ecosystem and simple upgrade path.

## 2) Documentation layer: Starlight (Astro docs framework)

Use Starlight instead of building a custom docs system.

Benefits:
- Sidebar navigation, search integration, versioned content patterns.
- Built-in accessibility defaults.
- Fast contributor onboarding for docs PRs.

## 3) UI layer: Tailwind CSS + prebuilt component library

Use Tailwind with a component library pattern instead of custom CSS architecture from zero.

Benefits:
- Consistent spacing, typography, and responsive behavior.
- Faster design iteration.
- Easier contributor contributions with established utility conventions.

## 4) Search: Pagefind

Use Pagefind for static, client-side full-text search.

Benefits:
- No backend search service required.
- Works with static site deployment.
- Fast setup and low maintenance.

## Proposed information architecture

## Top-level pages

1. Home (value proposition and system overview)
2. Quickstart
3. Architecture
4. Operations Handbook
5. Community Hub
6. Changelog/Release Notes
7. Security Practices
8. Contribution Guide

## Community Hub page sections

- "Good first contributions"
- "Open proposals"
- "Community calls and decisions"
- "How to become a maintainer"

## Content model conventions

- Use one concept per page (avoid giant catch-all pages).
- Require frontmatter fields:
  - `title`
  - `description`
  - `lastReviewed`
  - `owner`
  - `status` (`draft`, `active`, `deprecated`)
- Keep operational runbooks separate from conceptual docs.

## Integration with existing TU-VM setup

- Keep existing dashboard at current route (`/` if unchanged).
- Serve docs/community site under a dedicated route (for example `/docs` or `/community`) through Nginx.
- Link both ways:
  - Dashboard -> Docs for "how to operate"
  - Docs -> Dashboard for "open control panel"

## Non-functional requirements

- Mobile-first responsive layout.
- Lighthouse accessibility target >= 90.
- Keyboard-navigable menus, search, and tabs.
- No blocking JS for core content rendering.

## Migration strategy

1. Scaffold Astro + Starlight site in a dedicated directory (for example `website/`).
2. Migrate README core sections into structured docs pages.
3. Add community hub and contribution pathways.
4. Wire static build artifacts into Nginx serving path.
5. Keep the existing dashboard untouched during the first rollout.

## Success criteria

- New contributors can find setup docs in under 2 minutes.
- Community pages are editable via Markdown PRs without UI code changes.
- Docs search returns relevant results for top operator queries.
- Dashboard operations continue to work with zero behavior change.
