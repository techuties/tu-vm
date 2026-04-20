# Website Framework and Tooling Suggestions

These recommendations focus on maintainability and contributor velocity for a community-based website/dashboard, while respecting the current architecture (Nginx static page + helper API + Docker Compose stack).

## Current state summary

- Frontend is a single static HTML file with inline CSS/JS.
- Backend helper service provides status/control endpoints.
- No formal frontend testing pipeline for dashboard behavior.

This works for small scope but becomes harder to scale as features (alerts, controls, suggestion workflow, docs surfaces) grow.

---

## Framework suggestion A: Progressive enhancement first

### Recommendation
Keep server-side delivery simple (Nginx static assets), but split the UI into modular JavaScript files and reusable CSS components.

### Practical approach
- Move inline JS into `nginx/html/assets/js/*`
- Move inline CSS into `nginx/html/assets/css/*`
- Keep plain HTML as baseline for reliability
- Add optional progressive JS enhancement for dynamic sections

### Why this is good for community contributions
- Lower entry barrier than introducing a heavy framework immediately
- Easier diffs/reviews
- Better separation of concerns

---

## Framework suggestion B: Optional migration path to lightweight component framework

If UI complexity keeps growing (feedback panel, voting, richer analytics), adopt a lightweight framework in a staged manner.

### Candidates

1. **Preact + Vite** (preferred for size/performance)
   - React-like DX with very small runtime
   - Excellent ecosystem and strong contributor familiarity

2. **Vue 3 + Vite**
   - Very approachable for mixed-skill contributors
   - Strong SFC pattern for component isolation

3. **SvelteKit (static adapter)**
   - Great performance and concise components
   - Good fit if team prefers compile-time reactivity

### Selection criteria
- Small bundle footprint
- Strong accessibility tooling
- Simple local development for community contributors
- Minimal ops overhead in Docker/Nginx deployment

---

## Tooling suggestion A: Frontend quality gates

### Recommendation
Introduce baseline automated checks:

- **ESLint** for JavaScript consistency and unsafe patterns
- **Prettier** for formatting stability
- **Stylelint** (if CSS grows significantly)
- **HTMLHint** (optional) for static markup quality

### Minimum CI checks
- Lint step on every PR
- Build/asset validation (if framework build exists)
- Basic smoke test for key UI actions

---

## Tooling suggestion B: Browser-level smoke tests

### Recommendation
Use Playwright for critical website flows.

### Priority scenarios
- Dashboard loads and renders service cards
- Status refresh updates card badges
- Service start/stop buttons invoke expected endpoints
- Access token save flow works
- Announcements dropdown opens and content renders

### Why this matters
- Prevents regressions in core operator UX
- Gives contributors confidence for refactors

---

## Tooling suggestion C: API contracts for helper endpoints

### Recommendation
Define and validate a contract for helper endpoints used by the website.

### Options
- OpenAPI schema for helper endpoints
- JSON schema checks in test suite

### Benefit
- Frontend and helper API can evolve independently without breaking UI flows.

---

## Tooling suggestion D: Community contribution accelerators

### Proposal
- Add issue templates for:
  - suggestion proposal
  - dashboard bug report
  - UX/accessibility issue
- Add PR checklist focused on:
  - docs updated
  - accessibility considered
  - rollback impact checked

### Benefit
- More consistent contributions
- Faster reviews with less ambiguity

---

## Tooling suggestion E: Feature flags for safe rollout

### Recommendation
Implement lightweight feature flags (env-driven or config endpoint) for new website features like community feedback/voting.

### Why
- Enables gradual rollout
- Reduces risk to production operators
- Allows quick rollback without full redeploy

---

## Suggested phased adoption

1. **Phase 1 (low risk)**
   - Extract CSS/JS assets from monolithic HTML
   - Add lint + formatting checks
   - Add Playwright smoke tests for top 5 flows

2. **Phase 2 (medium risk)**
   - Add helper API contracts
   - Add feature flag scaffolding
   - Add suggestion panel backend primitives

3. **Phase 3 (higher impact)**
   - Optional migration to Preact/Vue componentized frontend
   - Add richer community interaction surfaces (votes, status filters, changelog links)
