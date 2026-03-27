# Community Suggestions Hub

This folder contains structured, website-ready suggestion pages focused on:

- avoiding duplicate effort
- improving day-to-day operations
- growing a community-based system around TU-VM

## How to use this folder

1. Start with this index.
2. Review existing suggestions before proposing new work.
3. Link new ideas to existing suggestions instead of creating overlapping plans.
4. Keep each suggestion page implementation-oriented with clear outcomes.

## Current suggestion pages

| Suggestion | Focus | Priority | Status |
|---|---|---|---|
| [Community Governance Framework](./community-governance-framework.md) | Roles, decision model, release councils | High | Proposed |
| [Developer Experience Tooling](./developer-experience-tooling.md) | Local workflows, quality gates, task automation | High | Proposed |
| [Extensions and Integration Framework](./extensions-and-integration-framework.md) | Plugin model, API contracts, version compatibility | Medium | Proposed |
| [Community Operations Toolkit](./community-operations-toolkit.md) | Triage, onboarding, support, documentation operations | High | Proposed |

## Scope guardrails

- Reuse existing scripts and services first (`tu-vm.sh`, `scripts/`, helper API, monitoring).
- Avoid introducing duplicate orchestration layers where Docker Compose and existing control flows already work.
- Prefer thin frameworks that can be adopted incrementally.
- Every suggestion should include success metrics and rollback paths.
