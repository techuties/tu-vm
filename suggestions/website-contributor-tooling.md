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

### 1-4) Implemented in-repo

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

### 7) Suggestion metadata validator

#### Why

Suggestion pages become easier to publish on a website when they share predictable metadata and required sections.

#### Behavior

- Validate allowed status values from [`README.md`](./README.md).
- Warn when required sections are missing:
  - problem statement,
  - historical context or duplicate check,
  - implementation steps,
  - security/resource impact,
  - validation approach,
  - success signals.
- Optionally emit JSON for a future static website index.

#### Reuse path

Start as a small script over `suggestions/*.md`. If a docs framework is adopted, the same metadata can feed VitePress/Docusaurus/Astro navigation rather than a custom registry service.

### 8) Duplicate suggestion scanner

#### Why

The folder already contains overlapping historical drafts. A lightweight overlap check helps maintainers merge related ideas instead of creating parallel plans.

#### Behavior

- Compare new suggestion titles/headings against existing `suggestions/*.md`.
- Report likely overlaps by keyword and file path.
- Suggest linking to the nearest canonical page when overlap is high.

This should be advisory at first. It should help reviewers, not block good community ideas.

### 9) Maintainer daily queue helper

#### Why

Day-to-day community work is easier when maintainers can see what needs attention without manually scanning every issue and document.

#### Behavior

- Show untriaged suggestions.
- Show accepted items without an owner.
- Show in-progress items without recent evidence.
- Show implemented items missing changelog or release-note links.

#### Reuse path

Use GitHub labels, Markdown metadata, and existing release/changelog files. Do not introduce a database unless the static files and GitHub API become insufficient.

### 10) Website preview and accessibility smoke

#### Why

A community website needs low-friction local preview plus basic accessibility confidence before review.

#### Behavior

- Provide a single preview command through package scripts or a thin `tu-vm.sh` alias once a framework is selected.
- Run link checks and heading checks.
- Add a focused browser smoke test for core pages once the site exists.
- Include keyboard navigation and color contrast checks for interactive pages.

## Integration pattern

To avoid script sprawl:

1. Keep helper scripts small and single-purpose.
2. Expose high-value workflows via `tu-vm.sh` aliases.
3. Ensure each tool has:
   - usage/help output
   - clear exit codes
   - stable, parseable output when appropriate
4. Keep tools non-interactive by default in CI, with explicit prompts only for local helper flows.
5. Prefer warnings before hard failures while the community process is being adopted.

## Recommended tool stack

Use mature tools before writing custom checks:

| Need | Suggested tool or framework | Notes |
| --- | --- | --- |
| Markdown link checks | Existing docs link workflow / Lychee-style checking | Keep same-repo links stable. |
| Markdown style | markdownlint with a narrow ruleset | Avoid noisy rules that discourage contributors. |
| YAML and workflow hygiene | Existing CI plus actionlint when needed | Useful for `.github/workflows/*`. |
| Website framework preview | VitePress, Docusaurus, or Astro/Starlight dev server | Select through `website-information-architecture.md`. |
| Browser smoke | Playwright | Add only after website pages or dashboard modules become interactive. |
| Release summaries | Existing `scripts/release-note-helper.sh` | Keep `CHANGELOG.md` canonical. |
| Suggestion metadata | Small repo script first | Reuse Markdown/front matter; no database for MVP. |

## Priority order

1. docs quality gate (links, headings for core docs)
2. `scripts/release-note-helper.sh`
3. deeper `/status/full` contract validation in CI (fixtures or narrow compose profile)
4. optional `--full` smoke tier / Tier 2 coverage where maintainable
5. suggestion metadata validator
6. duplicate suggestion scanner
7. website preview and accessibility smoke after the framework is selected

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
