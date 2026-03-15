# Community Tooling and Daily Workflow

## Objective

Improve day-to-day contributor productivity with practical tooling that fits the current architecture and reduces repetitive work.

## High-impact tooling suggestions

## 1) Community CLI layer on top of `tu-vm.sh`

Add namespaced commands for contributor workflows:

- `./tu-vm.sh community list-modules`
- `./tu-vm.sh community enable <module>`
- `./tu-vm.sh community disable <module>`
- `./tu-vm.sh community doctor`
- `./tu-vm.sh community scaffold <module-name>`

Why this helps:

- Single entrypoint, no command sprawl
- Easy discoverability for new contributors
- Shared operational patterns

## 2) Module scaffolding tool

Provide a scaffold generator that creates:

- module manifest (`module.yml`)
- script templates
- health-check template
- docs template

Scaffolding should include:

- default secure networking assumptions
- sample rollback notes
- testing checklist

## 3) Developer quality gates

Introduce lightweight local checks:

- shell script linting for `scripts/`
- compose config validation
- environment variable schema validation
- smoke checks for critical endpoints

Recommended command:

```bash
./tu-vm.sh community doctor
```

## 4) Reusable task automation

Create script aliases for frequent operations:

- service diagnostics bundle
- backup verification
- module dependency checks
- log summarization

This should reduce context switching and improve troubleshooting speed.

## 5) Community templates library

Ship templates for:

- n8n workflow starter packs
- Open WebUI pipeline presets
- MinIO bucket conventions
- Qdrant collection and embedding patterns

Each template should include:

- use case
- required resources
- expected performance profile

## Suggested daily contributor workflow

1. Pull latest changes and run `community doctor`
2. Start required base services in energy-aware mode
3. Enable only required module(s)
4. Validate health checks and dashboard status
5. Run local checklist before commit
6. Capture brief implementation notes for maintainers

## Contributor experience KPIs

- Time to first successful local run
- Time to scaffold and validate a new module
- Number of manual commands per contribution
- Frequency of avoidable setup/support issues

