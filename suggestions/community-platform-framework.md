# Community Platform Framework

## Objective

Establish a reusable framework that lets contributors build features quickly while preserving security, operational simplicity, and maintainability.

## Design principles

1. **Extend before adding**
   - Reuse existing services (`Open WebUI`, `n8n`, `MinIO`, `Qdrant`, monitoring stack) before introducing net-new infrastructure.
2. **Secure by default**
   - New components must respect current network and access control posture.
3. **Operational consistency**
   - Every community feature should be manageable via `tu-vm.sh` and observable through existing health checks.
4. **Low-friction onboarding**
   - Contributors should be able to run and validate changes with a minimal command set.

## Recommended framework architecture

### 1) Community feature modules

Define each feature as a module with:

- A clear purpose statement
- Service dependencies
- Environment variables
- Operational commands (`start`, `stop`, `status`, `diagnose`)
- Documentation and example workflow

Suggested module structure:

```text
community/
  modules/
    <feature-name>/
      module.yml
      docker-compose.override.yml
      scripts/
      docs/
```

### 2) Module manifest contract

Use a simple `module.yml` contract for consistency:

- `name`
- `description`
- `owner`
- `depends_on`
- `resource_profile` (light, medium, heavy)
- `commands`
- `health_checks`
- `security_notes`

This creates a predictable format for both maintainers and automation.

### 3) Integration points with existing stack

- **Dashboard integration**: expose module status/action buttons through helper API patterns.
- **Monitoring integration**: add module checks into daily checkup output and announcements.
- **Control script integration**: register module commands in `tu-vm.sh`.
- **Backup integration**: define module state and config backup rules.

## Priority framework capabilities

1. **Module registry**
   - A generated list of available modules and their state.
2. **Capability tags**
   - Example tags: `automation`, `rag`, `ingestion`, `security`, `ops`.
3. **Resource governance**
   - Enforce startup profiles aligned with battery and VM constraints.
4. **Version compatibility policy**
   - Define minimal supported versions for Docker, compose, and key services.

## Anti-patterns to avoid

- Adding one-off scripts that bypass `tu-vm.sh`
- Creating duplicate monitoring paths outside the existing checkup flow
- Introducing public endpoints without access-mode integration
- Shipping features without rollback instructions

## Success criteria

- New community modules can be scaffolded in under 15 minutes.
- All modules are controllable from one command surface.
- Every module contributes health signals to the same monitoring channel.
- No regressions in default secure posture.

