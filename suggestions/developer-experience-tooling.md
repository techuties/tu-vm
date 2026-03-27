# Suggestion: Developer Experience Tooling

## Objective

Improve day-to-day contributor productivity by standardizing local development, validation, and maintenance workflows without replacing existing TU-VM scripts.

## Why this is needed

Current project operations are script-centric and strong operationally, but community contribution scales better when contributors can discover and run common tasks consistently.

## Guiding principle

Do not replace `tu-vm.sh` or existing operational scripts. Wrap and streamline them so contributors spend less time on setup and troubleshooting.

## Proposed framework

### 1) Unified task runner layer

Add a lightweight task runner (for example a `Makefile` or a justfile) that maps common workflows to existing commands:

- `make up` -> `./tu-vm.sh start`
- `make down` -> `./tu-vm.sh stop`
- `make check` -> health and endpoint checks
- `make logs SERVICE=...` -> service logs
- `make backup` -> backup flow

This acts as a contributor-friendly alias layer, not a second orchestration system.

### 2) Local quality gates

Standardize quality checks with scripts that are fast and composable:

- shell linting for scripts (e.g., ShellCheck)
- YAML validation for compose and config files
- markdown linting for docs consistency
- optional policy checks for env template drift

Provide:

- `scripts/check-all.sh` for local execution
- CI job parity using the same commands

### 3) Development container profile

Introduce an optional contributor profile with:

- reduced resource limits for laptops
- mock/minimal service startup path for doc and script changes
- deterministic test data fixtures for reproducibility

This lowers friction for new contributors who do not need the full stack running.

### 4) Preflight diagnostics command

Create one command (or task alias) to gather key diagnostics in one pass:

- Docker version and daemon health
- required ports and DNS prerequisites
- status of critical volumes
- script permissions and executable checks

This can reduce repetitive issue triage.

## Community impact

- Fewer setup-related support requests
- Faster first contribution cycle
- More consistent code quality across contributions
- Better confidence before opening pull requests

## Milestones

1. Define task-runner command map to existing scripts.
2. Implement check scripts and make CI call the same entrypoint.
3. Add development profile and preflight diagnostics.
4. Publish contributor quick-start path based on new commands.

## Success metrics

- Lower ratio of failed CI checks caused by formatting and lint issues
- Reduced average time from clone to first successful local check
- Fewer support requests for setup and environment mismatch problems

## Risks and mitigations

- **Risk:** Too many wrapper commands cause confusion.  
  **Mitigation:** Keep wrappers minimal and map directly to canonical `tu-vm.sh` flows.

- **Risk:** Added checks slow iteration.  
  **Mitigation:** Separate fast checks from full checks; run fast checks by default.

- **Risk:** Tooling drift between local and CI.  
  **Mitigation:** CI must call the same scripts used locally.

