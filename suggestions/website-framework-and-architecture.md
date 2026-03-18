# Website Suggestions - Framework and Architecture

## Goal
Introduce a community-focused website layer while preserving stability of the existing operations dashboard and runtime controls.

## Framework Recommendation

### Option A (recommended first): Docusaurus
Best fit for documentation-first community systems.

Why this is the practical default:
- markdown-first contribution model
- easy sidebar and information architecture control
- versioned content support
- strong plugin ecosystem for search/analytics
- low maintenance overhead for maintainers

### Option B: Astro + Starlight
Best when static performance and lightweight output are top priority with occasional custom components.

### Option C: Next.js (App Router)
Use when dynamic community product features become primary, such as authenticated views, advanced voting, or personalized dashboards.

## Incremental Architecture (No Big-Bang Rewrite)

### Phase 1 - Preserve stable surfaces
- Keep `/` as the existing operations dashboard.
- Keep helper API as the runtime status/control backend.
- Introduce community content via scoped route or subdomain.

### Phase 2 - Launch docs/community website
- Route strategy:
  - `/community` (path-based) or
  - `community.<domain>` (subdomain)
- Initial content set:
  - suggestion process
  - governance pages
  - contributor onboarding
  - roadmap visibility
  - decision logs

### Phase 3 - Add dynamic community features
- Add a small `community-api` only when static workflow is no longer enough.
- Reuse existing database infrastructure where possible.
- Keep strict boundaries from privileged runtime-control services.

## Proposed Information Architecture
- `/` -> operations dashboard (existing)
- `/community` -> community home
- `/community/suggestions` -> submission guide + public board
- `/community/roadmap` -> accepted/planned/in-progress items
- `/community/contribute` -> onboarding and contribution flow
- `/community/governance` -> policy, moderation, and decision model

## Suggested Data Model (for Dynamic Stage)

### Suggestion entity
- `id`
- `title`
- `problem_statement`
- `proposal_summary`
- `category` (docs, ux, infra, security, automation, performance)
- `status` (new, triaged, planned, in-progress, completed, declined)
- `author`
- `created_at`
- `updated_at`

### Vote entity
- `id`
- `suggestion_id`
- `user_id` (or anonymous fingerprint in early phase)
- `value`

### Decision log entity
- `id`
- `suggestion_id`
- `type` (comment, decision, status-change)
- `message`
- `author`
- `timestamp`

## Security and Operations Guardrails
- Keep runtime control endpoints token-protected and allowlist-restricted.
- Keep community routes limited to community data operations.
- Add rate limiting and abuse protection for public suggestion endpoints.
- Keep auditable moderation and status-change logs.

## Success Criteria
- Contributors can submit and track suggestions with minimal friction.
- Community website does not weaken runtime control surfaces.
- Maintainers can trace accepted ideas to implementation and releases.
