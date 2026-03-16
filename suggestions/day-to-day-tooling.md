# Day-to-Day Tooling Framework

## Goal

Reduce daily operational friction for maintainers and contributors by standardizing proven tools for local development, validation, and collaboration.

## Tooling pillars

### 1) Developer environment consistency

Adopt repeatable local environments so contributors spend less time on setup issues:

- Dev container support (or documented Docker-based local profile)
- Task runner for common commands (`make` or `just`)
- Standardized environment checks (`doctor` command)

Suggested starter commands:
- `make setup` (bootstrap dependencies/config)
- `make check` (lint + static checks)
- `make test` (test suite)
- `make docs` (validate documentation)

### 2) Quality and safety automation

Use automated quality gates instead of manual policing:

- Pre-commit hooks for basic hygiene
  - trailing whitespace, EOF fix, YAML/JSON sanity checks
  - markdown lint and broken link detection
- CI pipeline stages:
  1. Lint and formatting checks
  2. Unit/integration tests
  3. Security checks (dependency and secret scanning)
  4. Docs validation

### 3) Operational toolchain reuse

Lean on existing platform strengths and avoid custom one-off scripts where possible:

- Use n8n for repeatable governance workflows (triage reminders, status updates)
- Use AFFiNE for proposal notes, decision logs, and working-group summaries
- Use helper API/dashboard announcements for visible project updates

### 4) Observability for contributors

Provide simple visibility into system health and CI quality:

- "Contributor health" dashboard:
  - open suggestion count by status
  - median review time
  - failing CI categories
  - stale proposal alerts
- Publish weekly automated summary to docs or dashboard

### 5) Reusable templates

Template-driven contribution reduces ambiguity:

- Suggestion template (problem, alternatives, impact, rollout)
- Implementation checklist template
- Retrospective template (what worked, what changed, follow-up actions)

## Suggested frameworks and tools

- **Task orchestration**: Make or Just
- **Pre-commit framework**: pre-commit
- **Markdown quality**: markdownlint + link checker
- **Security scanning**: Trivy (containers), dependency audit in CI
- **Workflow automation**: n8n
- **Knowledge management**: AFFiNE

These are mature ecosystems with strong community support, reducing maintenance burden.

## Adoption plan

### Phase 1: Baseline (2 weeks)
- Introduce task runner and pre-commit hooks
- Add docs validation in CI
- Define contribution templates

### Phase 2: Automation (2-4 weeks)
- Add n8n triage/reminder workflows
- Add contributor metrics summary job
- Standardize labels and status mapping

### Phase 3: Optimization (ongoing)
- Remove redundant custom scripts replaced by framework-native patterns
- Track lead-time improvements
- Collect contributor feedback quarterly and iterate

## Success criteria

- 30% reduction in setup-related contributor issues
- Faster first review turnaround for suggestions
- Lower duplicate proposal rate
- Improved merge confidence through automated checks
