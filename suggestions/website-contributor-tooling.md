# Website Suggestion: Contributor Tooling and Day-to-Day Operations

## Objective

Improve daily contributor velocity and reliability with practical tools that align with the current stack:

- `tu-vm.sh` as the primary control plane
- helper API for runtime status/control surfaces
- existing service architecture and monitoring scripts

The goal is a lower-friction contribution path with predictable validation and release hygiene.

## Existing strengths to leverage

The repository already includes:

- Centralized operations through `tu-vm.sh`
- Health and monitoring flows (`scripts/daily-checkup.sh`, helper status endpoints)
- Clear service boundaries in Compose and Nginx config

This allows tooling to be added as thin wrappers and consistency checks, not as major platform rewrites.

## Tooling recommendations

### 1–4) Implemented in-repo

These are live: `./tu-vm.sh doctor` (human + `--json`), `./scripts/check-config.sh`, `./scripts/smoke-test.sh` (`--live` for HTTPS probes), `./scripts/helper-contract-check.sh`, CI wiring and [`CONTRIBUTING.md`](../CONTRIBUTING.md). Historical detail kept for context — see scripts and [`implementation-backlog.md`](./implementation-backlog.md).

Remaining helper contract breadth (optional): extend checks toward `/updates`, `/status/pdf-processing`, and `/status/full` shape validation in CI when the stack or fixtures allow.

### 5) Release note assistant (`scripts/release-note-helper.sh`)

#### Why

Community quality improves when contributors are guided to record impact consistently.

#### Behavior

- Collect commit subjects since the last release marker
- Prompt for change type (`feat`, `fix`, `security`, `perf`, `docs`)
- Prompt for operator impact and migration notes
- Print a formatted changelog block for easy inclusion

### 6) Docs quality gate

#### Why

A community-driven website depends on docs consistency and navigability.

#### Proposed checks

- Broken internal links
- Heading hierarchy sanity
- Required section presence for major pages (install, security, troubleshooting)

Can run in CI and optional local pre-commit flows.

### 7) Suggestion metadata checker

#### Why

As the `suggestions/` archive grows, contributors need fast feedback when a proposal is missing status, ownership, related links, or validation notes.

#### Behavior

- Scan `suggestions/*.md` for optional front matter.
- Warn when a proposal lacks:
  - `status`
  - `area`
  - related historical suggestion links
  - acceptance or deferral rationale
- Report duplicate titles or near-identical headings.
- Exit non-zero only for files touched in the current branch when used in CI, so historical files do not block incremental cleanup.

#### Community benefit

- Reduces maintainer triage time.
- Makes proposal pages more consistent.
- Helps new contributors find related historical work before opening a repeated idea.

### 8) Local website preview command

#### Why

Community contributors should be able to preview website/docs changes without understanding the whole Docker Compose stack.

#### Behavior

- Add a single documented command once the static site framework is chosen, for example:
  - `npm run docs:dev`
  - or `./tu-vm.sh docs-preview`
- Print the local URL and common troubleshooting hints.
- Keep preview independent from Tier 1 service startup.

#### Community benefit

- Faster review of Markdown and navigation changes.
- Lower barrier for docs-only contributions.
- Less need to run heavy services for website edits.

### 9) Community triage report

#### Why

Maintainers need a simple view of stale suggestions, missing owners, and shipped items that still need documentation updates.

#### Behavior

- Generate a Markdown or JSON report from:
  - GitHub Issues labeled `suggestion`
  - `suggestions/*.md` metadata
  - `CHANGELOG.md` release entries
- Highlight:
  - accepted suggestions without implementation links
  - implemented suggestions without changelog references
  - duplicate candidates
  - proposals touching security-sensitive areas

#### Community benefit

- Keeps the suggestion system transparent.
- Makes recurring triage work easier to delegate.
- Creates a durable weekly/monthly status artifact without a custom dashboard database.

## Integration pattern

To avoid script sprawl:

1. Keep helper scripts small and single-purpose.
2. Expose high-value workflows via `tu-vm.sh` aliases.
3. Ensure each tool has:
   - usage/help output
   - clear exit codes
   - stable, parseable output when appropriate

## Priority order

1. docs quality gate (links, headings for core docs)
2. `scripts/release-note-helper.sh`
3. deeper `/status/full` contract validation in CI (fixtures or narrow compose profile)
4. optional `--full` smoke tier / Tier 2 coverage where maintainable
5. suggestion metadata checker for new/changed proposal pages
6. local docs website preview command after framework selection
7. community triage report once proposal metadata exists

## Website/community impact

These tools directly support the community website model by:

- reducing contributor setup and debugging friction
- increasing reproducibility for issue reports
- improving confidence in website/docs updates
- creating standardized quality evidence for maintainers

## Success signals

- faster issue triage and reproduction
- fewer configuration-related runtime failures
- lower review churn for contributor pull requests
- improved release note consistency and traceability
