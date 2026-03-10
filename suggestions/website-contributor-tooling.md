# Website Suggestion: Contributor Tooling and Daily Workflow

## Problem

Contributors often lose time on setup drift, inconsistent docs format, and unclear "what to do next" guidance.
This reduces momentum and raises the barrier for first-time contributors.

## Proposed Solution

Standardize contributor experience with ready-to-use tooling and automation tied to the website workflow.

## Reused Frameworks and Tools

Use mature tooling rather than custom scripts where possible:

- **GitHub Issue Forms** for structured bug reports and feature suggestions
- **PR Templates + CODEOWNERS** for review quality and ownership clarity
- **pre-commit** for local quality checks
- **Vale** for docs style consistency
- **Markdownlint** for markdown quality
- **GitHub Actions** for automated docs checks and link validation

## Suggested Workflow Improvements

### 1) Suggestion Intake

- Add "Website Suggestion" issue form with required fields:
  - problem statement
  - expected outcome
  - existing alternatives researched
  - rollout impact

### 2) Suggestion to Delivery Path

- Add labels:
  - `suggestion:website`
  - `suggestion:community`
  - `priority:now|next|later`
  - `status:reviewing|approved|deferred`
- Auto-post linked issue/discussion references in PR descriptions.

### 3) Contributor Onboarding Kit

- Add a single "Contributor Start" page containing:
  - setup steps
  - local checks
  - acceptance checklist
  - common pitfalls

### 4) Quality Gates

- CI checks on every PR:
  - markdown lint
  - spelling/style rules
  - internal/external link checks
  - docs build validation

## Implementation Phases

### Phase 1 (quick wins)

- Enable issue forms and PR templates.
- Add label taxonomy.
- Add markdown lint in CI.

### Phase 2

- Add pre-commit config with markdownlint and Vale.
- Add docs build check and broken link scan.
- Publish contributor onboarding page.

### Phase 3

- Add automated "stale suggestion follow-up" reminder after 14 days inactivity.
- Publish monthly contributor leaderboard/highlights.

## Risks and Mitigations

- **Risk**: contributors perceive too many process steps  
  **Mitigation**: keep checks fast and provide copy-paste local setup commands.

- **Risk**: false-positive lint failures  
  **Mitigation**: start with warning mode for one cycle, then enforce.

- **Risk**: ownership bottlenecks  
  **Mitigation**: use CODEOWNERS with at least two maintainers per area.

## Success Metrics

- 20% faster median PR review turnaround.
- 40% drop in markdown/style corrections requested during review.
- 30% increase in first-time contributor PRs merged per quarter.
