# Community System and Day-2 Tooling Suggestions

## Purpose

Create a community-based operating model around TU-VM so contributions are easier, safer, and faster to ship.

## Current strengths to build on

- Clear architecture and service boundaries already exist in `README.md`.
- Operational scripts already exist (`daily-checkup.sh`, `pre-push-check.sh`, `rollout-gates.sh`).
- Dashboard and helper API already expose real operational status.

These are excellent foundations for a contributor ecosystem.

## Community framework suggestions

### 1) Suggestion lifecycle in-repo

Use this folder as a lightweight proposal process:

- New idea enters as a markdown suggestion file.
- Maintainers label status in-file:
  - `proposed`
  - `accepted`
  - `in-progress`
  - `implemented`
  - `rejected` (with rationale)
- On implementation, link to commit(s) and changelog entries.

Why:

- Community can see what is already discussed.
- Reduces duplicate proposals.
- Keeps decision rationale searchable in git history.

### 2) Ownership map per subsystem

Define maintainers/reviewers by subsystem:

- Website/dashboard (`nginx/html`)
- Helper API (`helper/uploader.py`)
- Orchestration (`docker-compose.yml`, `tu-vm.sh`)
- AI pipeline (`mcp-gateway/`, `langgraph-supervisor/`)
- Document pipeline (`tika-minio-processor/`)

Even small teams benefit from explicit review routing.

### 3) Contribution templates for practical requests

Add issue/PR templates focused on operational quality:

- Bug report template with:
  - affected service
  - reproduction steps
  - expected/actual behavior
  - logs snippet
- Suggestion template with:
  - problem statement
  - impacted users/operators
  - current workaround
  - proposed change
  - rollback plan

This improves signal quality and triage speed.

### 4) "Operator quality" Definition of Done

For changes touching runtime operations, require:

- Service impact statement (Tier 1 or Tier 2 implications)
- Security impact statement (tokens, allowlist, exposed endpoints)
- Rollback path documented
- Smoke validation steps completed

The project is ops-heavy; this keeps community contributions safe.

## Day-to-day tooling suggestions

### 1) Standardized local checks command

Provide one contributor command that chains existing checks, for example:

- `./scripts/contributor-check.sh`
  - `bash -n` on modified shell scripts
  - `python3 -m py_compile` for modified Python files
  - optional `docker compose config --quiet`
  - optional dashboard endpoint smoke checks

This avoids each contributor inventing their own check process.

### 2) Fast docs drift detector

Common issue: docs and implementation diverge over time.

Add a simple check script that verifies:

- service names in docs match compose service names
- endpoint names in docs match helper route names

Run it in CI and pre-push.

### 3) Suggestion-to-changelog automation helper

When a suggestion is implemented, provide a helper script that:

- prompts for version bucket
- inserts a changelog bullet in the right section
- links implemented suggestion file

This keeps contributor recognition and release notes synchronized.

### 4) Community dashboard quality telemetry

Add non-invasive quality counters surfaced in `/status/full`:

- last successful update check timestamp
- failed control actions (count in last 24h)
- current number of unresolved critical announcements

These metrics help contributors prioritize practical fixes.

## Governance and quality gates

### Proposal acceptance rubric

Accept suggestions that:

- improve reliability, security, or maintainer efficiency
- are incremental and reversible
- reuse existing architecture where possible
- include validation steps

Reject or defer suggestions that:

- require broad rewrites without measured need
- increase runtime complexity without clear operator value
- duplicate existing tooling capabilities

### Release integration rule

Any implemented suggestion should include:

- code change
- docs update
- changelog note
- brief validation proof

This keeps community work visible and trustworthy.

## Success criteria

- New contributors can propose and ship changes with less back-and-forth.
- Fewer duplicate issues and repeated suggestions.
- Better correlation between community requests and shipped improvements.
