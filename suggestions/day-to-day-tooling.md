# Day-to-Day Tooling Framework

## Goal

Reduce daily operational friction for maintainers and contributors by standardizing proven tools for local development, validation, and collaboration.

## Tooling pillars

### 1) Developer environment consistency

Adopt repeatable local environments so contributors spend less time on setup issues:

- Dev container support (or documented Docker-based local profile)
- Task runner for common commands (`make` or `just`)
- Standardized environment checks (`doctor` command)
- One documented path for docs preview and suggestion validation

Suggested starter commands (still optional — repo uses `./tu-vm.sh` + [`scripts/`](../scripts/) today):

- `make setup` (bootstrap dependencies/config)
- `make check` (lint + static checks)
- `make test` (test suite)
- `make docs` (validate documentation)
- `make suggestions` (validate suggestion frontmatter, links, and duplicate IDs)

Implemented baseline: `./tu-vm.sh doctor`, `./scripts/check-config.sh`, `./scripts/smoke-test.sh`, `./scripts/helper-contract-check.sh`, [`scripts/pre-push-check.sh`](../scripts/pre-push-check.sh), and GitHub Actions CI ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)).

### 2) Quality and safety automation

Use automated quality gates instead of manual policing:

- Extend the existing pre-commit configuration beyond its current whitespace,
  EOF, YAML, and shell-syntax checks:
  - markdown lint and broken relative-link detection
  - suggestion frontmatter and duplicate-ID validation
- Target CI pipeline stages:
  1. Lint and formatting checks
  2. Unit/integration tests
  3. Security checks (dependency and secret scanning)
  4. Docs validation
  5. Suggestion schema and duplicate-ID validation

The current docs-links workflow checks the hub, index, and implementation
backlog. Expanding that scope to every canonical suggestion page is proposed
work.

For markdown suggestions, the minimum gate should catch:

- broken relative links
- missing required frontmatter
- invalid lifecycle status values
- duplicate suggestion IDs
- headings that skip levels or make generated navigation confusing
- placeholder owners on accepted or in-progress proposals

### 3) Operational toolchain reuse

Lean on existing platform strengths and avoid custom one-off scripts where possible:

- Use GitHub Issues, labels, PR templates, and Release Drafter as the default
  system of record.
- Use n8n for repeatable governance workflows only when GitHub-native
  automation becomes too manual (triage reminders, status updates).
- Use AFFiNE for proposal notes, decision logs, and working-group summaries
  when long-form collaboration outgrows issue comments.
- Use helper API/dashboard announcements for visible project updates on the
  LAN-facing operator surface.

### 4) Observability for contributors

Provide simple visibility into system health and CI quality:

- "Contributor health" dashboard:
  - open suggestion count by status
  - median review time
  - failing CI categories
  - stale proposal alerts
- Publish weekly automated summary to docs or dashboard
- Show suggestion status counts and recently shipped ideas on the website.
- Link validation failures to specific remediation commands.

### 5) Community suggestion operations

Keep the daily workflow boring and repeatable:

- Triage new `suggestion` issues with a checklist generated from the template.
- Add `needs-info` only when a concrete missing field blocks review.
- Mark duplicates as `superseded` and link to the canonical suggestion.
- Promote durable accepted ideas into website markdown pages.
- Move shipped ideas to release/changelog-linked summaries.

### 6) Reusable templates

Template-driven contribution reduces ambiguity:

- Suggestion template (problem, alternatives, impact, rollout)
- Implementation checklist template
- Retrospective template (what worked, what changed, follow-up actions)
- Decision-log entry template
- Website markdown suggestion template

## Suggested frameworks and tools

- **Task orchestration**: Make or Just
- **Pre-commit framework**: pre-commit
- **Markdown quality**: markdownlint + link checker
- **Security scanning**: Trivy (containers), dependency audit in CI
- **Workflow automation**: n8n
- **Knowledge management**: AFFiNE
- **Docs/static site**: Docusaurus, MkDocs Material, or Astro Starlight
- **Schema checks**: JSON Schema, Python frontmatter parser, or a small
  repository-local validator
- **Search**: framework-native local search before hosted search services

These are mature ecosystems with strong community support, reducing maintenance burden.

## Adoption plan

### Stage 1: Baseline

Done: contribution templates, compose/script validation and smoke checks in CI, `doctor`/config/smoke tooling.

Still open:

- Optional task runner (`make`/`just`) wrapping the same scripts
- Markdown/link hooks plus broader canonical-page coverage in CI
- Suggestion frontmatter validation and duplicate-ID checks
- Docs preview command for the selected website framework

### Stage 2: Automation
- Add n8n triage/reminder workflows
- Add contributor metrics summary job
- Standardize labels and status mapping
- Generate website status indexes from markdown metadata

### Stage 3: Optimization
- Remove redundant custom scripts replaced by framework-native patterns
- Track lead-time improvements
- Collect contributor feedback quarterly and iterate
- Retire duplicate historical suggestion pages after they are linked from the
  archive or marked superseded

## Success criteria

- 30% reduction in setup-related contributor issues
- Faster first review turnaround for suggestions
- Lower duplicate proposal rate
- Improved merge confidence through automated checks
