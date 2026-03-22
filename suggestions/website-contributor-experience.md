# Website Contributor Experience Suggestion

## Objective

Make contribution to TU-VM easy, rewarding, and predictable by improving website pathways for onboarding, contribution execution, and recognition.

## Current friction patterns (common in infra projects)

- first-time contributors cannot find “good first contribution” tasks,
- unclear acceptance criteria causes rework,
- contributors do not know who can review a change,
- contributions are merged but not visibly recognized.

## Suggested contributor experience model

### 1) Clear entry points by contributor persona

Provide separate “start here” paths:

- **Operator users** (run platform, report issues),
- **Automation builders** (n8n/workflow templates),
- **Infra contributors** (Docker/network/security),
- **Docs contributors** (guides, troubleshooting, examples).

Each path should include:

- prerequisite knowledge,
- first 3 tasks to try,
- expected review timeline range,
- examples of accepted contributions.

### 2) Task framing and contribution templates

Improve consistency via website-visible templates:

- bug report template with reproducibility checklist,
- feature suggestion template with problem/impact fields,
- docs improvement template with before/after outcomes,
- automation recipe template with inputs/outputs and safety notes.

### 3) “Definition of Done” checklists

For each contribution type, expose simple checklists:

- tests or manual validation steps included,
- security implications documented,
- rollback/recovery notes provided,
- docs updated where behavior changed.

This reduces back-and-forth and reviewer burnout.

### 4) Public recognition and trust signals

Add contributor acknowledgment components:

- monthly “community shipped” section,
- first-time contributor badges,
- subsystem contributor leaderboard by merged impact (not volume only),
- “maintainer thank-you” notes tied to release highlights.

## Practical website features

- searchable “good first tasks” board with filters:
  - skill level,
  - subsystem,
  - estimated scope.
- reviewer map with backup reviewers.
- FAQ for common review comments and how to address them.
- “request mentorship” form for first contributions.

## Operational workflow behind the pages

1. Maintainers tag items using a shared label taxonomy.
2. A sync job updates website task lists from repository metadata.
3. Stale tasks auto-flag for reassessment.
4. Closed/merged tasks feed recognition and release notes pages.

## Metrics to track

- first-time contributor conversion rate,
- median time to first maintainer response,
- median revision rounds before merge,
- repeat contribution rate over 90 days.

## Risks and mitigations

- **Risk**: too many entry pages cause confusion.  
  **Mitigation**: one central contributor hub linking all persona pages.
- **Risk**: recognition system gamed for low-impact changes.  
  **Mitigation**: weight quality/impact and maintainer endorsements.
