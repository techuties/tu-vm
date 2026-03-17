# Website Suggestions - Framework and Architecture

## Goal
Introduce a community-focused website layer without destabilizing the existing VM dashboard and operations flow.

## Recommended Framework Direction

## Option A (recommended): Docusaurus
Best fit when the primary need is docs, guides, contributor content, and changelog-linked pages.

Why it is a strong default:
- Markdown-first authoring for low-friction contributions
- Versioned docs and structured sidebars
- Good plugin ecosystem for search and analytics
- Fast to launch and easy to maintain with small teams

## Option B: Astro + Starlight
Best when speed and lightweight output are top priority, with occasional custom UI components.

## Option C: Next.js (App Router)
Best when interactive community features (voting, dashboards, authenticated views) become primary.
Use this when dynamic product features outweigh docs-first simplicity.

## Incremental Architecture (No Big-Bang Rewrite)

### Phase 1 - Keep what works
- Keep `/` as the existing operations dashboard.
- Keep helper API as runtime-control/status backend.
- Add a new website/community route behind Nginx.

### Phase 2 - Add community web experience
- Serve a docs/community app at:
  - `/community` (path-based) or
  - `community.<domain>` (subdomain-based)
- Start with static content: docs, governance pages, suggestion process, and roadmap summaries.

### Phase 3 - Add dynamic community capabilities
- If needed, introduce a small `community-api` for suggestions, voting, and decision logs.
- Use existing PostgreSQL first; avoid introducing new databases early.

## URL and Information Layout
- `/` -> Operations dashboard (existing)
- `/community` -> Community home
- `/community/suggestions` -> Suggestion intake + public board
- `/community/roadmap` -> Accepted/planned/in-progress items
- `/community/contribute` -> Contributor onboarding
- `/community/governance` -> Roles, moderation, and decision policy

## Suggested Data Model (when dynamic features begin)

### Suggestion
- `id`
- `title`
- `problem_statement`
- `proposal_summary`
- `category` (docs, ux, infra, security, automation, performance)
- `status` (new, triaged, planned, in-progress, completed, declined)
- `author`
- `created_at`, `updated_at`

### Vote
- `id`
- `suggestion_id`
- `user_id` (or anonymous fingerprint in early mode)
- `value` (+1 or weighted score)

### Decision log item
- `id`
- `suggestion_id`
- `type` (comment, decision, status-change)
- `message`
- `author`
- `timestamp`

## Security and Operations Guardrails
- Keep public community routes strictly read/write for community data only.
- Keep runtime control endpoints protected by token + allowlist.
- Add rate limits to public suggestion endpoints.
- Keep moderation/status-change audit trails.

## Accessibility and UX Baseline
- Keyboard-navigable menus, dialogs, and forms.
- Proper heading hierarchy and semantic landmarks.
- Sufficient color contrast and visible focus states.
- Mobile-friendly layout with no clipped or overlapping text.

## Success Criteria
- New contributors can find onboarding and submit structured suggestions quickly.
- Community pages do not expose or weaken runtime control surfaces.
- Maintainers can trace ideas from suggestion to changelog/release with minimal manual effort.
