# Website Foundation Suggestions

This document proposes an incremental website framework that builds on the current landing page architecture:

- Static UI in `nginx/html/index.html`
- Dynamic operational data from `helper/uploader.py`
- Reverse proxy and route control in Nginx

The goal is to keep operations fast and simple while adding a clear, community-friendly website structure.

## 1) Keep the current architecture, but separate concerns

Current approach is effective for VM operations (service controls, health checks, quick links).  
Recommendation: preserve it, but split responsibilities into layers.

### Suggested layers

1. **Operational dashboard layer** (existing)
   - Purpose: service controls, health, update alerts, allowlist management.
   - Audience: operators/admins.
2. **Website/community layer** (new section/pages)
   - Purpose: docs, roadmap, suggestions, contribution guide, release highlights.
   - Audience: contributors and adopters.
3. **API layer** (existing helper API)
   - Purpose: read-only public metadata + authenticated control endpoints.
   - Keep control endpoints token-protected.

## 2) Information architecture for website pages

Add website navigation that separates operational and community paths.

### Recommended top-level pages

- **Home**: concise value proposition and quick start.
- **Docs**: setup, security modes, command reference.
- **Community**: contribution flow, governance, support channels.
- **Suggestions**: prioritized improvement backlog and accepted proposals.
- **Changelog**: release history and migration notes.

### Suggested URL structure

- `/` -> existing operational landing page (keep)
- `/community/` -> community hub
- `/community/suggestions/` -> suggestions index
- `/community/roadmap/` -> roadmap snapshot
- `/docs/` -> links to README sections or generated docs

If introducing many pages is too heavy now, start with one `community` page and one `suggestions` page, then expand.

## 3) Reuse helper API for website status blocks

Do not rebuild data plumbing. Reuse existing endpoints and expose read-only UI blocks.

### Existing endpoints to reuse

- `/status/full` style status payload (currently used by dashboard refresh logic)
- `/status/announcements`
- `/status/updates`

### New lightweight endpoint suggestion

- `GET /status/community-summary`
  - counts: open suggestions, accepted suggestions, active contributors
  - latest accepted proposal title/date
  - does not require authentication

This avoids mixing control operations with community metadata and keeps UI logic simple.

## 4) Accessibility and UX improvements

The current interface is clear and compact, but can be more inclusive.

### High-impact improvements

1. Add a **skip-to-content** link for keyboard users.
2. Ensure dropdown/button states have proper `aria-expanded`, `aria-controls`, and focus outlines.
3. Add explicit labels for icon-only or symbolic UI elements.
4. Guarantee color contrast for badge states and muted text.
5. Ensure announcement updates in `aria-live` regions are not noisy.

### Content readability

- Keep heading hierarchy strict (`h1` -> `h2` -> `h3`).
- Limit paragraph width in community/docs sections for readability.
- Add "last updated" metadata on each community/suggestion page.

## 5) Performance and maintainability

Keep startup and runtime lightweight for laptop VM constraints.

### Suggested constraints

- Keep static pages framework-free unless dynamic complexity clearly requires one.
- Split large inline JS in `index.html` into dedicated files when complexity grows:
  - `dashboard.js` for operational controls
  - `announcements.js` for announcements behavior
  - `community.js` for community pages
- Minify static assets during release packaging.
- Cache static assets aggressively, but keep status endpoints uncached.

## 6) Security model (preserve existing strengths)

Existing allowlist and control token model should remain unchanged.

### Security recommendations

1. Keep `/control/*` and `/whitelist/*` restricted and audited.
2. Ensure community/suggestions pages are read-only by default.
3. Never expose secrets in rendered suggestion metadata.
4. Add a simple API response schema check to avoid accidental leakage in helper endpoints.

## 7) Delivery plan (incremental)

### Phase A: structure only

- Add community and suggestions page shells.
- Link them from the landing page footer/nav.
- Keep content static at first.

### Phase B: community metadata

- Add `/status/community-summary` endpoint.
- Render counts and latest accepted suggestion.

### Phase C: contribution workflow integration

- Connect suggestion intake process (template + triage + status labels).
- Publish accepted/implemented suggestion snapshots.

## 8) Acceptance checklist

- [ ] Operational dashboard remains fully functional.
- [ ] New community pages work on mobile and desktop.
- [ ] Keyboard navigation works for menus and controls.
- [ ] Status and announcements remain performant.
- [ ] No control endpoints become publicly writable.
- [ ] New page structure is documented in README.
