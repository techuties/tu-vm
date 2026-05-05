# Website Suggestions - Framework and Architecture

## Goal
Add a community-oriented website layer without destabilizing the current VM dashboard.

## Recommended Architecture (Incremental)

## Phase A - Keep current stack, add structure
- Keep `nginx/html/index.html` as the operational dashboard.
- Keep `helper/uploader.py` for operations/status control.
- Add a new **community web app route** behind Nginx (example: `/community`).

This avoids a risky rewrite and enables gradual adoption.

## Phase B - Community web app framework
- Use **Next.js (TypeScript)** for the community-facing site.
  - Reasons:
    - mature routing + layouts for docs, roadmap, and suggestion views
    - static generation and server rendering options
    - easy markdown/MDX content support
    - broad community support and plugin ecosystem
- Keep visual system simple with **Tailwind CSS** + accessible components.
- Add `pnpm` workspace support if frontend grows into multiple apps/packages.

## Phase C - API strategy (avoid reinvention)
- Continue using Flask helper for VM operations.
- Add a dedicated `community-api` service only for community data if needed
  (suggestions, votes, comments, statuses).
- Start with PostgreSQL already in the stack; avoid new databases initially.

## Proposed Service Boundaries

### Existing (unchanged)
- `helper_index`:
  - health/status probes
  - infra announcements
  - service control endpoints

### New (scoped)
- `community-web` (Next.js):
  - suggestion listing/search UI
  - voting UI
  - roadmap/status UI
  - contributor onboarding pages
- `community-api` (optional in first iteration):
  - suggestion CRUD
  - voting and moderation rules
  - public read APIs for roadmap states

## Suggested URL layout
- `/` -> existing operational dashboard
- `/community` -> community home
- `/community/suggestions` -> idea board
- `/community/roadmap` -> accepted/planned/in-progress items
- `/community/contribute` -> contributor onboarding and process

## Data Model (minimal first version)

### Suggestion
- `id`
- `title`
- `problem_statement`
- `proposal_summary`
- `category` (ux, docs, automation, security, performance)
- `status` (new, triaged, planned, in-progress, completed, rejected)
- `author`
- `created_at`, `updated_at`

### Vote
- `id`
- `suggestion_id`
- `user_id` (or anonymous fingerprint if auth is not yet introduced)
- `value` (+1 or priority score)

### Comment/Decision log
- `id`
- `suggestion_id`
- `type` (comment, decision, status-change)
- `message`
- `author`
- `timestamp`

## Operational guardrails
- Keep control endpoints separated from public community endpoints.
- Keep token/allowlist requirement for any action that can affect runtime services.
- Apply rate limiting on public suggestion endpoints.
- Add audit logs for moderation and status changes.

## Migration Rule
Never replace the current dashboard first. Introduce community capabilities in parallel, validate usage, then consolidate only when parity is proven.
