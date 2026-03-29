---
title: Website Information Architecture
purpose: Community-first documentation and operations portal
status: proposed
---

# 1) Goal

Create a clear website structure that supports:
- New users trying to install quickly
- Operators managing daily VM tasks
- Contributors improving code/docs/features
- Community members proposing and discussing changes

This should extend the current landing page and docs, not replace working parts.

# 2) Existing assets to reuse

Current project assets already provide strong building blocks:
- `nginx/html/index.html` (existing dashboard/landing surface)
- `helper/uploader.py` endpoints (`/status/*`, `/announcements`, `/updates`, `/control/*`)
- `README.md`, `QUICK_REFERENCE.md`, `CHANGELOG.md`
- Existing architecture around secure/public/locked access and tiered services

Recommendation: keep this stack and add a docs/content layer around it.

# 3) Recommended website framework

## Primary option: Docusaurus (docs-first, community-friendly)

Why this fits:
- Markdown-native docs authoring
- Versioned docs and changelog views
- Search, sidebar navigation, edit links, contributor-friendly PR flow
- Easy GitHub Pages/Netlify/Vercel deployment if desired

## Secondary option: Astro + Starlight

Why consider it:
- Lightweight and fast
- Modern docs UX
- Great markdown pipeline

Decision rule:
- If docs/versioning/community pages are the main objective, use Docusaurus.
- If long-term custom content/site composition matters more, use Astro.

# 4) Proposed website structure

## Top-level navigation

1. **Home**
   - Platform overview
   - Quick status explanations
   - "Get started in 10 minutes"

2. **Install**
   - Prerequisites
   - One-command setup
   - First secure startup checklist

3. **Operate**
   - Service control
   - Monitoring
   - Backup/restore
   - Troubleshooting

4. **Security**
   - Access modes (secure/public/locked)
   - Token and allowlist guidance
   - Production hardening

5. **Community**
   - Contribution guide
   - Governance model
   - Suggestion workflow
   - Community roadmap board

6. **Suggestions**
   - Historical suggestions archive
   - Active proposals
   - Accepted/rejected decisions with rationale

# 5) Content model for markdown pages

Use a consistent page template:

1. Problem statement
2. Current state
3. Proposed change
4. Implementation steps
5. Risks and mitigations
6. Success metrics
7. Ownership and review path

This improves quality and prevents vague requests.

# 6) Suggested docs taxonomy

- `docs/getting-started/*`
- `docs/operations/*`
- `docs/security/*`
- `docs/community/*`
- `docs/suggestions/*`
- `docs/architecture/*`

Each suggestion page should be mapped into `docs/suggestions/` and linked from a single index.

# 7) UX and accessibility standards

- Keep high-contrast color theme already present in `index.html`
- Add keyboard navigation and visible focus states across all interactive controls
- Ensure ARIA labels for control buttons and status indicators
- Ensure status text is not color-only (already partially done with explicit labels)
- Keep mobile-friendly layout and avoid over-dense cards

# 8) Implementation sequence

1. Stand up docs framework in a new `/website` or `/docs-site` directory.
2. Import existing markdown docs with minimal rewriting.
3. Create `Suggestions` section and load this folder's proposal pages.
4. Add cross-links from landing page footer to docs/community/suggestions.
5. Add CI checks for markdown lint + broken links.

# 9) Success criteria

- New contributors can find "how to contribute" in under 2 clicks.
- Operators can resolve common tasks from docs without reading full README.
- Suggestions can be tracked from idea to decision state.
- Website and docs remain maintainable by distributed community contributors.
