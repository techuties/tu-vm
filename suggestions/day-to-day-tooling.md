# Day-to-Day Tooling Framework

## Goal

Reduce daily operational friction for maintainers and contributors by standardizing proven tools for local development, validation, and collaboration.

## Tooling pillars

### 1) Developer environment consistency

Adopt repeatable local environments so contributors spend less time on setup issues:

- Dev container support (or documented Docker-based local profile)
- Task runner for common commands (`make`, `just`, or thin wrappers over existing scripts)
- Standardized environment checks (`doctor` command)

Suggested starter commands (still optional — repo uses `./tu-vm.sh` + [`scripts/`](../scripts/) today):

- `make setup` (bootstrap dependencies/config)
- `make check` (lint + static checks)
- `make test` (test suite)
- `make docs` (validate documentation)

Implemented baseline: `./tu-vm.sh doctor`, `./scripts/check-config.sh`, `./scripts/smoke-test.sh`, `./scripts/helper-contract-check.sh`, [`scripts/pre-push-check.sh`](../scripts/pre-push-check.sh), and GitHub Actions CI ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)).

Recommended next step: publish one canonical "common commands" page on the website that maps maintainer tasks to the existing command, for example:

| Task | Existing command or source |
|------|----------------------------|
| Diagnose local setup | `./tu-vm.sh doctor` |
| Validate configuration | `./scripts/check-config.sh` |
| Run smoke checks | `./scripts/smoke-test.sh` |
| Check helper API contract | `./scripts/helper-contract-check.sh` |
| Prepare release notes | `./tu-vm.sh release-notes` |
| Run pre-push checks | `./scripts/pre-push-check.sh` |

This avoids adding a new task runner before the website clearly documents what already exists.

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

Keep these integrations optional and clearly labeled as Tier 2 or community-operations helpers. TU-VM should remain usable when optional collaboration services are stopped.

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

Template recommendations:

- Store website-facing proposal templates as Markdown, not hidden form logic.
- Mirror the GitHub Issue suggestion fields so contributors do not learn two different workflows.
- Include "historical overlap checked" and "existing tool/framework reused" fields in every template.
- Require validation evidence for implemented suggestions before they move to `implemented`.

### 6) Suggestion index tooling

Small, transparent tools can improve daily maintainer work without creating a custom platform:

- `suggestions validate`: check required frontmatter and required sections.
- `suggestions index`: emit Markdown/JSON grouped by status, theme, owner, and updated date.
- `suggestions related`: show likely historical matches for a new proposal.
- `suggestions digest`: summarize new, changed, accepted, and implemented suggestions since a git ref.

These can be implemented as scripts later, but the contract should be documented first in the website framework so any tool remains replaceable.

## Suggested frameworks and tools

- **Task orchestration**: Make or Just
- **Pre-commit framework**: pre-commit
- **Markdown quality**: markdownlint + link checker
- **Security scanning**: Trivy (containers), dependency audit in CI
- **Workflow automation**: n8n
- **Knowledge management**: AFFiNE

These are mature ecosystems with strong community support, reducing maintenance burden.

## Adoption plan

### Phase 1: Baseline

Done: contribution templates, compose/script validation and smoke checks in CI, `doctor`/config/smoke tooling.

Still open:

- Optional task runner (`make`/`just`) wrapping the same scripts
- Pre-commit hooks and markdown/link validation in CI
- Website "common commands" page that maps daily contributor tasks to existing scripts

### Phase 2: Automation

- Add n8n triage/reminder workflows
- Add contributor metrics summary job
- Standardize labels and status mapping
- Generate suggestion indexes from Markdown frontmatter

### Phase 3: Optimization

- Remove redundant custom scripts replaced by framework-native patterns
- Track lead-time improvements
- Collect contributor feedback through issues/discussions and iterate

## Success criteria

- Fewer setup-related contributor issues
- Faster first review turnaround for suggestions
- Lower duplicate proposal rate
- Improved merge confidence through automated checks
- More implemented suggestions with clear changelog/release evidence
