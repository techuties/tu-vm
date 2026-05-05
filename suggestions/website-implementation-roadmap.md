# Website Implementation Roadmap (Community Suggestions System)

## Objective

Build a practical, low-maintenance community suggestions system for the TU-VM website by reusing existing infrastructure:

- `nginx/html/index.html` for landing UX
- `helper/uploader.py` for lightweight backend APIs
- Existing docs (`README.md`, `CHANGELOG.md`) for synchronization

This roadmap intentionally avoids introducing a heavy CMS or additional databases unless proven necessary.

## Design principles

1. Reuse first, build second.
2. Keep contribution flow simple for community members.
3. Keep moderation workload sustainable.
4. Ensure each accepted suggestion has clear implementation ownership.
5. Preserve transparency through visible statuses and changelog links.

## Phase 0 - Foundation and structure

### Deliverables

- `/suggestions/` folder with:
  - `README.md` (index)
  - `website-community-framework.md`
  - `website-tools-and-automation.md`
  - `website-community-governance.md`
  - this roadmap file

### Exit criteria

- Contributors know where to propose improvements.
- Maintainers have a documented lifecycle for decision-making.

## Phase 1 - Public-facing suggestions section

### Scope

Expose a “Community Suggestions” section in the website that links to:

- current suggestion categories
- accepted/rejected suggestions
- implementation status

### Implementation recommendation

- Add a new website section or page linked from `nginx/html/index.html`.
- Keep first version static (generated or manually updated) to reduce complexity.
- Pull content from curated markdown in `/suggestions/`.

### Exit criteria

- Community can discover and read suggestion status from website UI.
- No direct write access from anonymous users.

## Phase 2 - Submission API and moderation queue

### Scope

Create a lightweight intake path:

- endpoint in `helper/uploader.py` for suggestion submission
- strict schema validation
- simple moderation queue (file-backed or append-only log)

### Suggested payload schema

```json
{
  "title": "string",
  "summary": "string",
  "problem": "string",
  "proposedSolution": "string",
  "affectedArea": ["website", "docs", "automation", "security", "operations"],
  "submitter": "string-or-anonymous",
  "references": ["optional links"]
}
```

### Security controls

- Rate limiting by source IP (at Nginx and API levels).
- Input sanitization and length limits.
- Optional token-gated submission for trusted contributors.
- No code execution or dynamic template rendering based on user content.

### Exit criteria

- Suggestions can be submitted without editing repository files directly.
- Moderators can review and classify submissions efficiently.

## Phase 3 - Status workflow and transparency loop

### Scope

Introduce visible status transitions:

- `new`
- `triaged`
- `accepted`
- `in-progress`
- `implemented`
- `rejected`
- `deferred`

### Operational behavior

- Every status change must include rationale.
- Implemented suggestions should reference:
  - commit hash
  - changelog entry
  - feature location

### Exit criteria

- Community can see what happened to each suggestion and why.
- Maintainers can trace accepted ideas to actual changes.

## Phase 4 - Automation and maintainability improvements

### Scope

Add automation to reduce repetitive maintainer work:

- stale suggestion reminders
- duplicate detection hints
- weekly digest generation
- accepted-to-changelog sync checks

### Recommended integration points

- Cron-based scripts similar to existing operational scripts.
- Optional MCP-assisted triage summaries (read-only first).
- simple export to JSON for dashboard cards.

### Exit criteria

- Manual triage effort measurably decreases.
- Suggestion pipeline remains healthy under increased volume.

## Suggested KPIs

Track a small set of useful metrics:

1. Suggestions submitted per month
2. Median time to first triage decision
3. Acceptance rate
4. Implementation lead time (accepted -> implemented)
5. Reopen rate for previously rejected/deferred suggestions
6. Contributor retention (repeat submitters)

## Risks and mitigations

### Risk 1: Suggestion overload
- **Mitigation:** strict templates, category routing, and triage SLAs.

### Risk 2: Duplicates and idea fragmentation
- **Mitigation:** canonical suggestion IDs and merge policy.

### Risk 3: Community trust erosion due to silent rejections
- **Mitigation:** mandatory rejection rationale and periodic summary posts.

### Risk 4: Maintainer burnout
- **Mitigation:** automation for reminders/digests and role rotation.

### Risk 5: Feature creep in tooling
- **Mitigation:** phase-gate every automation addition with measurable benefit.

## Suggested first implementation slice

If implementing quickly with low risk, do this first:

1. Publish static “Community Suggestions” section in website.
2. Add `/suggestions/` docs and governance model.
3. Start manual triage board with statuses.
4. Add one API endpoint for structured submissions.

This yields immediate community value without introducing high operational overhead.

