---
title: Community Operating Framework
description: A structured model for proposing, reviewing, and shipping community-driven improvements.
---

# Community Operating Framework

## Objective

Create a repeatable, low-friction framework so community members can suggest and implement improvements without maintainers carrying all coordination overhead.

## Current Gaps

- Suggestions are spread across release notes and ad-hoc discussions.
- No single lifecycle for idea -> proposal -> implementation -> validation.
- Contribution quality varies because acceptance criteria are not standardized.

## Proposed Framework

### 1) Suggestion Lifecycle

Each suggestion follows the same states:

1. **Intake** - Idea captured in `suggestions/historical-suggestions.md`.
2. **Scoping** - Technical scope and constraints documented.
3. **Review** - Maintainer/community review with explicit acceptance criteria.
4. **Build** - Implementation in small, testable PRs.
5. **Verify** - Functional checks + rollback validation.
6. **Adopt** - Documentation updates and release note entry.

### 2) Ownership Model

- **Maintainers:** final decision and release integration.
- **Contributors:** proposal drafting, implementation, and tests.
- **Operators/Users:** validate usability in real home-lab workflows.

Use clear labels in issue/PR workflows:

- `suggestion:approved`
- `suggestion:needs-scope`
- `suggestion:needs-tests`
- `suggestion:ready-to-ship`

### 3) Acceptance Criteria Standard

Every proposal should define:

- Problem statement with current pain point.
- Explicit behavior change.
- Security and reliability impact.
- Required docs/command updates.
- Rollback method.
- Test checklist (happy path + failure path).

### 4) Community Governance Rules

- Prefer backward-compatible defaults.
- New automation must be opt-in unless clearly safe.
- Every control-plane change (`tu-vm.sh`, helper API, Nginx routes) requires a rollback command.
- Keep privacy local-first: no mandatory external telemetry.

## Recommended First Deliverables

1. Add a lightweight suggestion intake section in main docs linking here.
2. Enforce suggestion acceptance checklist in PR reviews.
3. Add labels/workflow in repository management process.

## Success Metrics

- Reduced duplicate feature requests.
- Higher merge rate for external contributions.
- Lower regression rate in operations commands.
- Faster conversion from suggestion to shipped feature.
