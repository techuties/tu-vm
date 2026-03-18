# Website Suggestions - Historical Baseline (Reuse Before Rebuild)

## Purpose
This file documents existing platform capabilities and recurring historical suggestions so new community website work can extend what already exists instead of duplicating effort.

## Historical Suggestion Sources Reviewed
The following remote branches were reviewed to identify recurring patterns:
- `origin/cursor/community-suggestions-documentation-500c`
- `origin/cursor/community-suggestions-documentation-532b`
- `origin/cursor/community-suggestions-documentation-b331`
- `origin/cursor/community-suggestions-documentation-c719`
- `origin/cursor/community-suggestions-framework-4847`
- `origin/cursor/community-suggestions-framework-4fa7`
- `origin/cursor/community-suggestions-framework-d644`
- `origin/cursor/community-suggestions-framework-e483`

## Existing Foundation (Already in Repository)

### 1) Operations dashboard already exists
- Current path: `nginx/html/index.html`
- Existing dashboard value:
  - service cards and status indicators
  - container action controls (start/stop/restart style operations)
  - announcements and update notices
  - host-level KPI cards (CPU, memory, disk, IP)

### 2) Helper API already provides strong runtime primitives
- Current path: `helper/uploader.py`
- Existing API value:
  - status endpoints
  - service control endpoints
  - announcement and update endpoints
  - allowlist-related controls

### 3) Security model already established
- Nginx and helper flows already separate public versus privileged surfaces.
- Token and allowlist concepts already exist and should remain core guardrails.

### 4) Platform operations are already script-driven
- The repository has operational scripts and infrastructure config that should remain the source of truth for runtime behavior.
- Community website changes should link to these artifacts instead of replacing them.

## Reuse-First Constraints
1. Keep the existing operations dashboard as the control plane.
2. Keep helper API contracts stable and reuse them where practical.
3. Add community pages in a scoped route/subdomain without broad rewrites.
4. Preserve existing security boundaries for sensitive controls.
5. Prevent duplicate observability logic that already exists in scripts/endpoints.

## Constructional Gaps Worth Solving
- No single public community suggestion board with clear lifecycle states.
- Limited decision transparency from idea to shipped change.
- No standardized contributor path for proposing and refining suggestions.
- Missing templates for proposal quality, review, and release traceability.

## Baseline Recommendation
Treat the current dashboard and helper API as proven infrastructure.
Build a parallel community website layer for suggestion intake, governance, roadmap visibility, and release traceability.
