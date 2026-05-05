# Website Foundation and Framework Suggestions

## Purpose

Strengthen the TU-VM website/dashboard into a community-maintainable surface without discarding what already works.

## Current baseline (already good)

From the existing implementation:

- `nginx/html/index.html` already provides a fast, static, low-dependency dashboard.
- `helper/uploader.py` provides operational APIs (`/status/*`, `/control/*`, `/announcements`, allowlist endpoints).
- Nginx routing and token/IP controls are already integrated and production-minded.

This means the best path is **evolution**, not a full rewrite.

## Framework strategy (recommended)

### 1) Frontend: progressive enhancement first

Keep the static HTML-first dashboard as the core delivery model, then add structure:

- Introduce a minimal build step only if needed for maintainability (e.g. Vite + vanilla TypeScript).
- Avoid heavy SPA frameworks unless clear product requirements emerge (multi-route app, rich client state, plugin UI ecosystem).
- Keep first paint fast and self-hosted; avoid runtime framework overhead for operational dashboards.

Why:

- Lower operational risk for a Docker Compose platform.
- Easier community onboarding (plain HTML/CSS/JS remains understandable).
- Preserves current resilience when backend dependencies are down.

### 2) API contract: formalize helper endpoints

Define a lightweight API contract for helper endpoints used by the website:

- `/status/*` response schema consistency.
- `/announcements` object shape and priority taxonomy.
- `/control/*` error model (401/404/409/500) standardized for UI handling.

Suggested tooling:

- OpenAPI spec committed under `helper/` for public endpoint docs.
- Simple schema validation (Pydantic or marshmallow) in Flask routes for response consistency.

### 3) Componentization without framework lock-in

Refactor frontend into reusable UI modules while staying framework-agnostic:

- Status badge component
- Service card renderer
- Notification center
- Allowlist manager

Target structure:

- `nginx/html/js/components/*.js`
- `nginx/html/js/services/api.js`
- `nginx/html/js/app.js`

This improves maintainability and contributor velocity without forcing React/Vue migration.

### 4) Accessibility framework (must-have)

Adopt an explicit accessibility standard for website changes:

- Keyboard-accessible controls and dropdowns
- Focus-visible states
- Proper ARIA labeling for status badges and dynamic notifications
- Color contrast checks for success/warn/error badges

Suggested tool:

- Run `axe-core` checks in CI against the landing page snapshot.

### 5) Design token governance

Current CSS custom properties are a good start. Expand into documented tokens:

- Semantic colors: `--color-success`, `--color-warning`, etc.
- Spacing scale: `--space-1` to `--space-8`
- Typography scale for consistent hierarchy

Store in one source file and avoid hardcoded ad-hoc values.

## Suggested implementation sequence

1. **Stabilize contracts**: document helper API schemas and response guarantees.
2. **Modularize JS**: split inline script from `index.html` into focused modules.
3. **Add linting/tests**:
   - ESLint for frontend JS
   - Basic Playwright smoke for dashboard load + critical interactions
4. **Accessibility pass** with automated checks + manual keyboard test.
5. **Only then evaluate SPA migration** if community needs exceed static architecture.

## Guardrails to avoid re-inventing the wheel

- Reuse existing dashboard and helper API workflows.
- Reuse existing Nginx security model and `/control` gate.
- Prefer small incremental PRs over a redesign branch.
- Keep all additions Docker Compose-friendly and self-hosted by default.

## Success criteria

- Contributors can edit UI behavior without touching a 900+ line HTML file.
- Dashboard behavior remains backward-compatible with existing helper endpoints.
- No regression in load speed, service control reliability, or security posture.
