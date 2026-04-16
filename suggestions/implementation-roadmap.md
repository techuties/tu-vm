# Implementation Roadmap (Community Suggestions System)

## Scope

Deliver a community-focused suggestions framework in phases, minimizing risk and maximizing reuse of existing TU-VM components.

## Phase 0 - Baseline (already initiated)

Deliverables:

- Create `suggestions/` folder
- Add foundational strategy and governance docs
- Define template conventions and lifecycle statuses

Exit criteria:

- Folder exists in repo
- Team has a single reference for suggestion lifecycle and standards

## Phase 1 - Read-only discovery experience

Deliverables:

1. Helper API read endpoints:
   - `GET /suggestions/index`
   - `GET /suggestions/<id>`
   - `GET /suggestions/stats`
2. Landing page integration:
   - Community Suggestions card
   - links to index/detail pages
3. Suggestion metadata parser with validation errors surfaced in API output

Validation:

- Endpoint returns all suggestion metadata
- Invalid files are reported with actionable error details
- UI renders suggestion summaries and status badges

Risk controls:

- Read-only mode (no write endpoints)
- Fail-soft behavior when one suggestion file is malformed

## Phase 2 - Governance tooling

Deliverables:

1. Suggestion lint script in `scripts/`
2. Duplicate detection script
3. Status digest integrated into daily operational checks

Validation:

- Lint script fails on missing required fields
- Duplicate detector flags similar entries with confidence score
- Daily digest surfaces stale triage and accepted backlog

Risk controls:

- Scripts are optional and non-disruptive to core runtime
- No new persistent service required

## Phase 3 - Controlled interaction features

Deliverables:

1. Optional vote endpoint (`POST /suggestions/vote`)
2. Signed event log for votes (append-only)
3. Basic anti-abuse rate limiting

Validation:

- Votes update derived score correctly
- Event log remains auditable and tamper-evident
- Rate limits block rapid repetitive votes

Risk controls:

- Token-based access and route-level limits
- Feature flag to disable write interactions quickly

## Phase 4 - Suggestion-to-delivery traceability

Deliverables:

1. Metadata linkage between suggestion IDs and implementation artifacts
2. Automated cross-reference checks (suggestion ID appears in changelog or commit message conventions)
3. Dashboard tile for "community impact delivered"

Validation:

- Completed suggestions include implementation references
- Changelog includes suggestion IDs for delivered items

Risk controls:

- Soft warnings first, hard enforcement later

## Suggested acceptance criteria per phase

- Architecture reuse is explicit (helper API, landing page, scripts, changelog)
- Security model is unchanged or improved
- Rollback path documented
- Operational burden stays low (no mandatory new container)

## Non-goals (for now)

- Building a standalone external forum app
- Introducing heavy third-party dependencies for suggestion management
- Replacing Git-based review with database-only workflows

## Recommended ownership model

- Product/Community owner: triage quality and contributor experience
- Platform owner: helper API and dashboard integration
- Ops owner: script/tooling reliability and daily digest accuracy

## Success indicators

- Increased unique suggestion contributors
- Lower duplicate suggestion rate
- Improved accepted-to-completed flow
- Higher visibility of community-driven shipped improvements
