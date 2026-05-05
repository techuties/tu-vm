# Maintainer Tools Suggestions

This document focuses on practical tooling that helps maintainers and contributors work faster, with fewer regressions and less operational overhead.

---

## T1: Suggestion Lifecycle Tracker

- Status: proposed
- Impact: medium
- Effort profile: low (docs + small script)

### Problem

Suggestions can become stale, duplicated, or disconnected from implementation commits.

### Recommendation

Add a lightweight lifecycle tracker script that:
- Parses `suggestions/*.md`
- Extracts suggestion IDs and statuses
- Outputs a normalized table for maintainers
- Optionally warns on:
  - duplicate IDs
  - missing status fields
  - suggestions without review date

### Implementation sketch

- New script under existing scripts folder:
  - `scripts/suggestions-lint.sh` or `scripts/suggestions-lint.py`
- Output examples:
  - `OK: 14 suggestions, 6 proposed, 3 in-progress, 5 implemented`
  - `WARN: duplicate suggestion ID WF2 in website-framework-suggestions.md`

### Acceptance criteria

- Script runs locally with one command
- Non-zero exit code if structural issues are found
- Included in contributor docs as a pre-PR check

---

## T2: Dashboard Smoke Test Runner

- Status: proposed
- Impact: high
- Effort profile: medium

### Problem

The dashboard in `nginx/html/index.html` calls several status/control endpoints. Regressions in helper API or route changes can silently break UI behavior.

### Recommendation

Add a smoke test script for core routes and expected response shapes:
- `/status/full`
- `/status/updates`
- `/status/pdf-processing`
- `/status/oweb`, `/status/n8n`, `/status/minio`, etc.

### Implementation sketch

- Script could be curl + jq:
  - `scripts/smoke-dashboard-api.sh`
- Validate:
  - HTTP 200 for core endpoints
  - expected keys exist in JSON
  - response latency budget warning (not hard fail unless extreme)

### Acceptance criteria

- Fails fast when expected keys are missing
- Prints actionable error messages for maintainers
- Can be run after local stack start and in CI

---

## T3: Community Contribution Template Pack

- Status: proposed
- Impact: high
- Effort profile: low

### Problem

Community members need standardized ways to propose ideas, report issues, and submit implementation notes.

### Recommendation

Create reusable templates integrated into the website and repository docs:
- Suggestion template
- Feature request template
- Incident report template (for self-hosted ops issues)
- “Implementation note” template for merged changes

### Template fields

- Context and motivation
- Current behavior
- Proposed behavior
- Trade-offs
- Security/privacy impact
- Rollback path
- Validation steps

### Acceptance criteria

- At least 3 template types available
- Website links to template usage path
- Maintainer review uses same structured fields

---

## T4: Suggestion-to-Changelog Linker

- Status: proposed
- Impact: medium
- Effort profile: medium

### Problem

Implemented ideas in changelog are not explicitly tied back to suggestion documents, making historical traceability weaker.

### Recommendation

When a suggestion is implemented:
- add reference in `CHANGELOG.md` item like `(suggestion: WF2)`
- update suggestion status to `implemented`
- record commit SHA in `historical-suggestions.md`

### Implementation sketch

Use a small helper script:
- detect changelog entries without suggestion references
- suggest possible matching IDs based on keywords

### Acceptance criteria

- New changelog entries can include suggestion IDs
- At least one implemented suggestion is backfilled as example

---

## T5: Local “Maintainer Dashboard” Script

- Status: proposed
- Impact: medium
- Effort profile: medium

### Problem

Maintainers currently need several commands and manual checks to know project health (containers, routes, logs, updates).

### Recommendation

Add a single command script that prints a compact, actionable status report:
- core service states
- recent helper API errors
- disk/memory pressure warnings
- known high-priority announcements

### Implementation sketch

- Script under `scripts/maintainer-dashboard.sh`
- Reuse existing status endpoints where possible
- Keep output text-first for SSH-friendly use

### Acceptance criteria

- One command produces a readable summary in <10s
- Includes red/yellow/green style states in plain text
- Links to next actions (which script/endpoint to run)

---

## T6: Contributor Onboarding Flow Checker

- Status: proposed
- Impact: medium
- Effort profile: medium

### Problem

New contributors may struggle with setup quality, leading to inconsistent local environments and review churn.

### Recommendation

Create a setup verification script that checks:
- required command availability (docker, docker compose, bash tools)
- expected env variables or `.env` presence
- reachable local routes after stack boot

### Acceptance criteria

- Script produces pass/fail per check
- Output suggests exact fix commands for each failure
- Mentioned in README onboarding section
