# Day-to-Day Tooling Framework

## Goal

Reduce daily operational friction for maintainers and contributors by standardizing proven tools for local development, validation, and collaboration.

## Tooling pillars

### 1) Developer environment consistency

Adopt repeatable local environments so contributors spend less time on setup issues:

- Dev container support (or documented Docker-based local profile)
- Task runner for common commands (`make` or `just`) that wraps existing scripts rather than replacing them
- Standardized environment checks (`doctor` command)
- One documented "minimum local validation" path for docs-only, script-only, and service-level changes

Suggested starter commands (still optional — repo uses `./tu-vm.sh` + [`scripts/`](../scripts/) today):

- `make setup` (bootstrap dependencies/config)
- `make check` (lint + static checks)
- `make test` (test suite)
- `make docs` (validate documentation)

Implemented baseline: `./tu-vm.sh doctor`, `./scripts/check-config.sh`, `./scripts/smoke-test.sh`, `./scripts/helper-contract-check.sh`, [`scripts/pre-push-check.sh`](../scripts/pre-push-check.sh), and GitHub Actions CI ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)).

Recommended next wrapper commands:

```bash
./tu-vm.sh doctor
./scripts/pre-push-check.sh
./scripts/release-note-helper.sh vX.Y.Z
```

If a task runner is added, it should call those same commands so contributors do not need to learn two operational models.

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
  5. Suggestion frontmatter and required-section checks

### Suggested suggestion validator

Add a small script that scans canonical files in `suggestions/` and reports:

- Missing frontmatter fields (`title`, `summary`, `status`, `area`, `updated`)
- Unknown status or area values
- Missing required sections
- Broken relative links to root docs, playbooks, or related suggestions
- Potential duplicates by title keyword overlap

Start with warnings so contributors learn the format before enforcement. Promote only high-confidence structure checks to blocking CI.

### 3) Operational toolchain reuse

Lean on existing platform strengths and avoid custom one-off scripts where possible:

- Use n8n for repeatable governance workflows (triage reminders, status updates)
- Use AFFiNE for proposal notes, decision logs, and working-group summaries
- Use helper API/dashboard announcements for visible project updates
- Use Qdrant only when semantic duplicate search becomes worth the additional complexity; keyword matching is enough for early volume

### Suggested n8n community workflows

Keep workflows read-oriented until maintainers explicitly approve write automation:

1. **Triage reminder:** find issues labeled `suggestion` with no maintainer response and notify the maintainer channel.
2. **Stale draft reminder:** find proposal Markdown pages with `status: draft` and old `updated` dates.
3. **Release linkage check:** after a release draft, report accepted suggestions that appear implemented but lack a release/changelog link.
4. **New contributor welcome:** post links to `CONTRIBUTING.md`, playbooks, and the suggestion checklist.

### 4) Observability for contributors

Provide simple visibility into system health and CI quality:

- "Contributor health" dashboard:
  - open suggestion count by status
  - median review time
  - failing CI categories
  - stale proposal alerts
- Publish weekly automated summary to docs or dashboard
- Show counts on the website first; add the Nginx dashboard widget only after the generated data file is reliable

### 5) Reusable templates

Template-driven contribution reduces ambiguity:

- Suggestion template (problem, alternatives, impact, rollout)
- Implementation checklist template
- Retrospective template (what worked, what changed, follow-up actions)
- Decision note template (accepted, deferred, rejected, superseded)
- Rollback note template for changes touching control paths, networking, volumes, or backup/restore

## Suggested frameworks and tools

- **Task orchestration**: Make or Just
- **Pre-commit framework**: pre-commit
- **Markdown quality**: markdownlint + link checker
- **Security scanning**: Trivy (containers), dependency audit in CI
- **Workflow automation**: n8n
- **Knowledge management**: AFFiNE
- **Docs website**: Docusaurus for generated community and proposal pages
- **Local JSON generation**: Python standard library first; add dependencies only when the validation rules outgrow simple parsing

These are mature ecosystems with strong community support, reducing maintenance burden.

## Daily workflows this should make easier

### New contributor

1. Open the website and find the suggestion guide.
2. Search existing issues and generated proposal indexes.
3. Open an `Idea / suggestion` issue with acceptance constraints.
4. Run the documented local checks for the touched area.

### Maintainer triage

1. Filter by `suggestion` and `status:idea`.
2. Check duplicate hints from `suggestions/` and open issues.
3. Route to the correct `area:*` owner.
4. Move to `draft`, `review`, `accepted`, `deferred`, or `rejected` with a short decision note.

### Release steward

1. Review merged PRs grouped by labels.
2. Confirm community suggestions delivered are linked from release notes.
3. Update `CHANGELOG.md` when the release needs human-edited highlights.
4. Archive or update proposal status after release.

## Adoption plan

### Phase 1: Baseline

Done: contribution templates, compose/script validation and smoke checks in CI, `doctor`/config/smoke tooling.

Still open:

- Optional task runner (`make`/`just`) wrapping the same scripts
- Pre-commit hooks and markdown/link validation in CI
- Suggestion frontmatter and required-section validator

### Phase 2: Automation
- Add n8n triage/reminder workflows
- Add contributor metrics summary job
- Standardize labels and status mapping
- Generate suggestion indexes and dashboard-safe JSON from Markdown metadata

### Phase 3: Optimization
- Remove redundant custom scripts replaced by framework-native patterns
- Track lead-time improvements
- Collect contributor feedback quarterly and iterate
- Tighten only the checks that prove useful and low-noise

## Success criteria

- 30% reduction in setup-related contributor issues
- Faster first review turnaround for suggestions
- Lower duplicate proposal rate
- Improved merge confidence through automated checks
- Fewer accepted proposals missing rollout, rollback, or validation details
