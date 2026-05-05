# Website Platform and Framework Suggestions

This document focuses on practical website architecture decisions that build on the current TU-VM platform.

## 1) Do not re-build what already exists

Current strengths already present in this repository:
- Nginx reverse proxy and routing (`nginx/conf.d`, `nginx/html/index.html`)
- Helper API for live status and control surfaces (`helper/uploader.py`)
- Existing ecosystem services (Open WebUI, n8n, AFFiNE, MCP gateway, MinIO)

Recommendation:
- Keep the current landing page + helper API as the operational control plane.
- Add a dedicated community/documentation site as a separate static app behind Nginx.
- Reuse existing auth and routing patterns where possible.

## 2) Framework recommendation (in priority order)

### Option A (recommended): Docusaurus
Why:
- Designed for documentation + community content.
- Built-in versioning, search integrations, and blog/news features.
- Good contributor experience for markdown-first workflows.

Best use:
- Product docs, onboarding, community guides, release notes, governance pages.

### Option B: Astro + Starlight
Why:
- Very fast static output and lightweight runtime.
- Excellent markdown support with modern component flexibility.

Best use:
- Highly performance-focused docs and landing pages with occasional custom UI blocks.

### Option C: Next.js (App Router)
Why:
- Strong ecosystem and flexibility for dynamic pages.
- Useful when community features become highly interactive.

Tradeoff:
- More operational complexity than Docusaurus/Astro for docs-first needs.

## 3) Suggested website architecture

### Suggested split
1. **Operations Dashboard (existing)**  
   Keep at current landing route for service controls and health data.
2. **Community Website (new docs/community app)**  
   Serve a static build (or SSR if needed) behind Nginx on a dedicated host, for example:
   - `community.tu.lan` (self-host)
   - `docs.techuties.com` (public internet deployment)

### Nginx integration approach
- Keep `nginx/html/index.html` for operations entrypoint.
- Add an additional vhost config that proxies or serves the docs app.
- Keep TLS and existing security headers; avoid duplicating gateway logic.

## 4) Core website sections to implement first

1. **Getting Started**
   - Installation quickstart
   - Security-first setup
   - First workflow examples
2. **Service Playbooks**
   - Open WebUI, n8n, MinIO, Tika, AFFiNE, MCP gateway
   - "When to enable/disable" guidance for tiered power usage
3. **Community Hub**
   - Contribution guide
   - Feature request flow
   - Known issues and troubleshooting
4. **Release and Upgrade Notes**
   - Versioned changes mapped to `CHANGELOG.md`

## 5) Search, analytics, and discoverability

Recommended:
- Add docs search (Algolia DocSearch, Typesense, or self-hosted Meilisearch).
- Track docs effectiveness with privacy-respecting analytics (Plausible or Umami).
- Add "last updated" and edit links to each docs page.

Avoid:
- Heavy third-party trackers that conflict with the privacy-first project values.

## 6) Accessibility and UX baseline

Required baseline for all web pages:
- Semantic headings and landmarks.
- Keyboard navigation for menus and interactive controls.
- Sufficient color contrast and visible focus states.
- Clear mobile layout for low-resolution screens.

## 7) Suggested implementation path

Phase 1 (quick win):
- Choose Docusaurus.
- Create base docs structure and import existing README/quick reference content.
- Add Nginx route for docs site.

Phase 2:
- Add contributor and governance pages.
- Add searchable knowledge base and troubleshooting playbooks.

Phase 3:
- Add community spotlight and roadmap voting pages (read-only first, interactive later).

## 8) Success criteria

- New contributor can get local setup running in under 30 minutes.
- Documentation updates require only markdown edits and review.
- Common support questions are answered by docs/playbooks before opening new issues.
- Community-facing content is discoverable without exposing internal control endpoints.
