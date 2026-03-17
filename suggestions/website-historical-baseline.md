# Website Suggestions - Historical Baseline (Reuse Before Rebuild)

## Purpose
This file captures high-value capabilities that already exist in this repository so new website/community work can extend proven systems rather than replacing them.

## Historical Sources Reviewed
To avoid re-inventing prior work, historical suggestion content was compared from previously published community-suggestion branches, including:
- `cursor/community-suggestions-documentation-500c`
- `cursor/community-suggestions-documentation-532b`
- `cursor/community-suggestions-documentation-c719`
- `cursor/community-suggestions-framework-4847`
- `cursor/community-suggestions-framework-4fa7`
- `cursor/community-suggestions-framework-d644`
- `cursor/community-suggestions-framework-e483`

The recommendations in this folder intentionally consolidate recurring guidance across those archives.

## Existing Foundation (Already Implemented)

### 1) Operations dashboard (Nginx static experience)
- A working service hub already exists in `nginx/html/index.html`.
- It already includes:
  - service cards and health badges
  - start/stop actions for key containers
  - announcements and update indicators
  - allowlist/token related controls
  - KPI-style system cards (CPU, memory, disk, IP)

### 2) Operational API layer (Flask helper service)
- `helper/uploader.py` already provides:
  - status endpoints (`/status/*`)
  - control endpoints (`/control/<service>/<action>`)
  - update and announcement endpoints
  - allowlist CRUD and bootstrap behavior
- This is a strong baseline for a community-aware website that needs trusted platform signals.

### 3) Security and access model
- Nginx routes sensitive surfaces through allowlist controls.
- Token-based protection exists for privileged operations.
- TLS and security headers are already configured in the stack.

### 4) Proven operating model
- Tiered service architecture and energy optimization are in place.
- Real-time PDF processing status and notifications exist.
- Daily health checks and update checks are already integrated.

## Reuse-First Constraints for New Website Work
1. Keep current dashboard behavior stable while adding community pages.
2. Reuse existing helper API contracts before adding new backend services.
3. Keep Nginx as the front door and add scoped routes for community content.
4. Preserve security boundaries for privileged runtime controls.
5. Avoid duplicating monitoring logic that already exists in scripts and helper endpoints.

## Gaps Worth Solving (Constructional Focus)
- No central public suggestion board with clear states.
- No transparent prioritization and decision logging for community ideas.
- Onboarding content is not unified in a single contributor journey.
- Limited reusable templates for proposals, RFC-style changes, and release communication.

## Baseline Recommendation
Treat dashboard + helper APIs as the operational core.
Add a parallel community/website layer for documentation, suggestions, and governance that links back to implementation artifacts (commits, changelog entries, releases).
