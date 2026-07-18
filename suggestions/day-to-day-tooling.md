# Day-to-Day Tooling Framework

## Goal

Reduce daily operational friction for maintainers and contributors by standardizing proven tools for local development, validation, and collaboration.

## Current baseline

Do not recreate these capabilities:

| Need | Existing command/config |
|---|---|
| Environment diagnosis | `./tu-vm.sh doctor` |
| Configuration validation | `./scripts/check-config.sh` |
| Static/live smoke checks | `./scripts/smoke-test.sh` |
| Helper API contract | `./scripts/helper-contract-check.sh` and fixture validator |
| Contributor check wrapper | `./scripts/pre-push-check.sh` |
| Basic file hygiene | `.pre-commit-config.yaml` |
| Link validation | `.github/workflows/docs-links.yml` |
| Release note draft | `./scripts/release-note-helper.sh` |

New tools should compose these entrypoints and preserve their flags and exit codes.

## Tooling pillars

### 1) Developer environment consistency

Adopt repeatable local environments so contributors spend less time on setup issues:

- Dev container support (or documented Docker-based local profile)
- Task runner for common commands (`make` or `just`)
- Standardized environment checks (`doctor` command)

Potential future aliases (optional — the repository uses `./tu-vm.sh` + [`scripts/`](../scripts/) today):

- `make setup` (bootstrap dependencies/config)
- `make check` (lint + static checks)
- `make test` (only after a project test suite exists)
- `make docs` (validate documentation)

If a `Makefile` or `justfile` is adopted, it should be an alias layer only. Contributors and CI must still be able to call the underlying scripts directly.

### 2) Quality and safety automation

Use automated quality gates instead of manual policing:

- Existing pre-commit hooks cover trailing whitespace, EOF fixes, YAML sanity, merge conflicts, and Bash syntax.
- Proposed additions are narrow Markdown linting and an optional fast local link check; full link checking already runs in CI.
- Target CI pipeline stages:
  1. Lint and formatting checks
  2. Unit/integration tests
  3. Security checks (dependency and secret scanning)
  4. Docs validation

Next gaps, in priority order:

1. run a live helper contract without the full Tier 1 stack,
2. scan Compose images rather than configuration only,
3. validate canonical suggestion metadata and local links,
4. add browser/accessibility smoke tests after dashboard assets are modularized.

### 3) Operational toolchain reuse

Lean on existing platform strengths and avoid custom one-off services:

- Use GitHub Actions for repository gates and label-driven release automation.
- Use n8n only for optional maintainer reminders or digests that do not gate contributions.
- Use AFFiNE for working notes, while accepted decisions remain versioned in GitHub/repository docs.
- Use helper API/dashboard announcements for local operator updates, not public issue storage.

### 4) Observability for contributors

Provide simple visibility into system health and CI quality:

- "Contributor health" dashboard:
  - open suggestion count by status
  - median review time
  - failing CI categories
  - stale proposal alerts
- Publish aggregate summaries only when they drive a documented maintainer action.
- Avoid individual contributor rankings and avoid exporting private operator data.

### 5) Reusable templates

Template-driven contribution reduces ambiguity:

- Suggestion template (problem, alternatives, impact, rollout)
- Implementation checklist template
- Retrospective template (what worked, what changed, follow-up actions)

## Suggested frameworks and tools

- **Task aliases**: Make (ubiquitous) or Just (clearer recipes), only if aliases materially improve discoverability
- **Pre-commit framework**: pre-commit
- **Markdown quality**: markdownlint + link checker
- **Security scanning**: Trivy/Grype for container images, gitleaks for committed secrets
- **Browser checks**: Playwright plus axe-core after a stable frontend fixture exists
- **Workflow automation**: GitHub Actions first; n8n for optional local/community digests
- **Knowledge management**: repository decisions first; AFFiNE for drafts

These are mature ecosystems with strong community support, reducing maintenance burden.

## Adoption sequence

### Stage 1: Close validation gaps

- Add canonical suggestion metadata/link validation.
- Add a minimal live helper contract job.
- Add image-level vulnerability scanning in report mode, triage the baseline, then enforce agreed severities.

### Stage 2: Improve contributor feedback

- Add one documented `check` alias only if contributors repeatedly miss existing commands.
- Make every CI failure reproduce with a repository-local command.
- Add file/line diagnostics and machine-readable output to validators.

### Stage 3: Expand community delivery

- Pilot the extension manifest and validator.
- Generate a read-only compatibility catalog from extension metadata.
- Add Playwright/axe smoke coverage after frontend modularization.

### Stage 4: Add optional workflow automation

- Add digest/reminder workflows only for observed triage bottlenecks.
- Keep automation advisory until false positives and ownership are understood.
- Remove redundant steps when framework-native checks fully replace them.

## Success criteria

- Fewer setup-related contributor issues
- Faster first review turnaround for suggestions
- Lower duplicate proposal rate
- Improved merge confidence through automated checks
- Every CI failure has a documented local reproduction command
