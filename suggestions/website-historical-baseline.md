# Website Suggestions - Historical Baseline (Do Not Rebuild What Already Works)

## Purpose
This file captures existing capabilities already present in the project so new community website work can extend proven parts instead of replacing them.

## Already Implemented (Current Baseline)

### 1) Landing + Dashboard Experience (Nginx static page)
- A working service hub already exists in `nginx/html/index.html`.
- Includes:
  - service cards and health badges
  - start/stop actions for containers
  - announcements dropdown
  - update notifications
  - allowlist/token controls
  - basic KPI cards (IP, CPU, memory, disk)

### 2) Operational API Layer (Flask helper service)
- `helper/uploader.py` already provides:
  - status endpoints (`/status/*`)
  - service control endpoint (`/control/<service>/<action>`)
  - update status endpoint
  - announcements endpoint
  - IP allowlist CRUD + auto-bootstrap
- This is a strong foundation for a community-facing control/data API.

### 3) Security and access pattern
- Nginx routes sensitive endpoints through an allowlist include.
- Token auth exists for control operations (`X-Control-Token`).
- TLS and secure headers are already configured.

### 4) Proven operating model from changelog
- Tiered service architecture and energy optimization are in place.
- Real-time PDF processing notifications and status tracking exist.
- Daily health/update checks and smart alerts are already used in production.

## Reuse-First Constraints for New Website Work
1. **Keep current dashboard operational** while introducing community pages.
2. **Reuse helper API contracts** where possible before creating new services.
3. **Keep Nginx as front-door router** and add scoped routes (for example `/community`).
4. **Preserve security model** (allowlist + token for sensitive actions).
5. **Do not duplicate monitoring logic** that already exists in daily-checkup + helper.

## Key Gaps to Fill (Where New Suggestions Should Focus)
- Public community suggestion board/workflow does not exist yet.
- Structured voting/prioritization for proposals is missing.
- Contributor onboarding paths are not centralized in one web experience.
- No shared templates for proposal quality, implementation effort, and acceptance criteria.

## Recommendation
Treat existing dashboard + helper as the operational core, then add a separate community layer that reads from the same platform signals and documents decisions transparently.
