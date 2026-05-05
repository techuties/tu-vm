# Suggestion: Extensions and Integration Framework

## Goal

Create a stable extension model so community members can add capabilities without changing core TU-VM internals on every contribution.

## Why this matters

The platform already includes a broad stack (Open WebUI, n8n, MinIO, Tika, monitoring). As more people contribute, ad-hoc integrations can increase maintenance cost and break updates. A lightweight extension framework creates predictable integration quality.

## Existing assets to leverage

- Existing reverse proxy and routing patterns in `nginx/`
- Existing script-driven operations in `tu-vm.sh` and `scripts/`
- Existing service metadata and status surface from helper API
- Docker Compose as the runtime orchestration layer

## Proposed framework

### 1) Extension package contract

Each extension follows a small contract:

- `extension.yaml` metadata:
  - id, version, owner, summary
  - compatible TU-VM version range
  - required services (e.g., MinIO, Redis)
  - external network requirements
- optional `docker-compose.extension.yml` for service fragments
- optional migration hooks:
  - pre-install
  - post-install
  - pre-upgrade
  - post-upgrade

### 2) Capability declaration model

Each extension declares capabilities:

- UI surface (dashboard widget, route, API)
- data access patterns (read-only, write, admin)
- background jobs/schedulers
- storage requirements (volume and retention guidance)

This allows maintainers to review risk and dependencies quickly.

### 3) Compatibility and upgrade safety

- semantic versioning required for extensions
- compatibility matrix maintained in one index page
- extension validation command before activation:
  - dependency checks
  - route conflict checks
  - port collision checks
  - policy checks

### 4) Isolation and security baseline

- isolated containers and explicit networks
- no privileged mode unless explicitly approved
- secrets passed via environment and documented variables
- default deny for inbound routes until extension is enabled

## Implementation plan

1. Add extension metadata schema (`extension.yaml` specification in docs)
2. Add validation script (`scripts/validate-extension.sh`)
3. Add activation/deactivation commands:
   - `./tu-vm.sh extension enable <id>`
   - `./tu-vm.sh extension disable <id>`
   - `./tu-vm.sh extension list`
4. Add extension discovery endpoint to helper API
5. Add extension directory convention:
   - `/extensions/<id>/...`
6. Add one reference extension as implementation template

## Developer workflow

1. Copy template extension scaffold
2. Fill metadata and compatibility
3. Run local validation
4. Submit PR with:
   - extension package
   - docs
   - security notes
   - rollback steps

## Day-to-day benefits

- faster external contributions with less core code churn
- lower risk upgrades due to compatibility and validation checks
- easier feature experimentation without destabilizing base platform

## Risks and mitigations

### Risk: extension quality variance
- Mitigation: required metadata + validation + review checklist

### Risk: integration sprawl
- Mitigation: capability declarations + compatibility matrix + deprecation policy

### Risk: breaking core updates
- Mitigation: version range checks and explicit upgrade hooks

## Success metrics

- extension PR review time decreases
- fewer integration regressions after release
- percentage of community features delivered as extensions increases

## Suggested first milestones

1. Publish metadata schema and template
2. Implement validation command
3. Ship one pilot extension with docs
4. Integrate extension list in dashboard/helper API

## Definition of done

- Extension contract documented and enforced by tooling
- At least one extension works end-to-end via enable/disable flow
- Maintainers can verify compatibility and rollback path before merge
