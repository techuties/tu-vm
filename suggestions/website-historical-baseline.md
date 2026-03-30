# Website Historical Baseline

## Purpose

This document captures historical suggestion patterns from prior `community-suggestions-*` branches and turns them into a single baseline for implementation.

It exists to prevent duplicate design work and to keep the new website/community framework aligned with what has already been proposed multiple times.

## Historical branches reviewed

- `origin/cursor/community-suggestions-documentation-f01e`
- `origin/cursor/community-suggestions-documentation-e8a5`
- `origin/cursor/community-suggestions-documentation-c719`
- `origin/cursor/community-suggestions-framework-6ed8`
- `origin/cursor/community-suggestions-framework-e483`
- `origin/cursor/community-suggestions-framework-d644`
- `origin/cursor/community-suggestions-framework-c211`
- Additional `community-suggestions-framework-*` and `community-suggestions-documentation-*` variants

## Repeated themes across historical suggestions

### 1) Docs-first website structure
Almost every historical suggestion recommended a documentation-first website model with clear routes for:

- install and onboarding
- daily operations
- security and hardening
- contribution and governance
- archived and active suggestions

### 2) Community workflow formalization
Historical branches consistently suggested:

- lightweight contributor roles
- subsystem ownership
- issue/PR taxonomy
- a short RFC-style process for major changes

### 3) Day-to-day tooling for contributors
Frequently repeated tooling ideas:

- `doctor`-style diagnostics command
- pre-flight config checks
- smoke test scripts
- API contract checks for dashboard/helper endpoints
- changelog/release note helpers

### 4) Feature roadmap continuity
Most roadmap suggestions referenced existing project notes rather than introducing unrelated work, especially:

- quick profile switching
- battery-aware operations
- automatic stopping of idle heavy services
- resource history and visibility
- smart startup behavior

## What this means for current implementation

### Keep
- Existing operational center of gravity: `tu-vm.sh`
- Existing runtime surfaces: helper API + nginx landing/dashboard
- Existing docs assets: `README.md`, `QUICK_REFERENCE.md`, `CHANGELOG.md`

### Add
- A structured website information architecture
- Community governance and review framework
- Contributor tooling standards
- A phased roadmap tied to historical proposals already surfaced in changelog and prior branches

### Avoid
- Replacing functioning systems wholesale
- Introducing governance bureaucracy that blocks practical contribution
- New defaults that weaken secure-by-default/LAN-first behavior

## Baseline quality rules for all website suggestions

1. Every proposal must include implementation path and rollback notes.
2. Every proposal must identify security and resource impact.
3. Every proposal must reference existing components to be reused.
4. Every proposal must define measurable success signals.

## Cross-link

This baseline is operationalized in:

- `website-information-architecture.md`
- `website-community-framework.md`
- `website-contributor-tooling.md`
- `website-roadmap-from-historical-suggestions.md`
