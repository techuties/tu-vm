# Tooling and Day-2 Operations Suggestions

## Objective

Provide practical tooling that makes daily maintenance and contribution easier, while staying aligned with existing TU-VM scripts and services.

## 1) Suggestion linting tool (metadata + structure)

### Proposal

Add a lightweight script (future implementation) that validates all files in `suggestions/`:

- required YAML keys present,
- valid status enum,
- `updated >= created`,
- mandatory body sections included.

### Why it helps

- Maintains quality and consistency as community volume grows.
- Prevents malformed suggestions from entering triage.

### Reuse strategy

- Follow existing script style in `scripts/`.
- Integrate with current pre-push validation culture (`scripts/pre-push-check.sh`).

## 2) Duplicate detection helper

### Proposal

Add a script that computes fuzzy similarity across suggestion titles and problem statements and flags likely duplicates.

### Why it helps

- Reduces triage noise.
- Encourages canonical suggestions with merged context.

### Reuse strategy

- Leverage current local-first approach (no external SaaS dependency).
- Emit terminal-friendly reports similar to existing diagnostics scripts.

## 3) Suggestion index cache endpoint

### Proposal

Add helper API support for an index cache so the landing page can load suggestion summaries quickly:

- warm cache on boot,
- periodic refresh,
- manual refresh endpoint for maintainers.

### Why it helps

- Fast UI response without parsing every markdown file per request.
- Better experience on lower-power host devices.

### Reuse strategy

- Reuse in-memory caching pattern already used for status checks.

## 4) Community contributor starter kit

### Proposal

Provide a standard "starter kit" flow for contributors:

1. suggestion template,
2. naming convention (`SUG-xxxx-slug.md`),
3. local validation command,
4. pull request checklist for suggestion proposals.

### Why it helps

- Lowers friction for first-time contributors.
- Improves merge quality and review speed.

### Reuse strategy

- Keep process documentation adjacent to existing operational docs and scripts.

## 5) Status digest automation

### Proposal

Extend daily checkup output to include suggestion-system digest:

- new proposals,
- stale triage items,
- accepted but not started,
- completed this period.

### Why it helps

- Keeps maintainers aligned without manual audits.
- Supports predictable governance cadence.

### Reuse strategy

- Extend `scripts/daily-checkup.sh` reporting format.
- Expose digest in dashboard announcements if desired.

## 6) Suggestion-to-implementation traceability map

### Proposal

Track links between suggestion IDs and delivery artifacts:

- commit hashes,
- changelog entries,
- impacted files/components.

### Why it helps

- Improves trust and historical discoverability.
- Makes "what got delivered from community input" obvious.

### Reuse strategy

- Align with existing changelog discipline.
- Avoid additional database by storing links in suggestion front matter.

## 7) Suggested metrics for day-2 health

- Triage throughput (proposed -> triaged count)
- Acceptance conversion rate
- Completion latency for accepted suggestions
- Duplicate rate
- Reopened suggestion rate (signal of poor acceptance criteria)

## 8) Rollout guidance

1. Start with read-only index + linting.
2. Add duplicate detection and digest automation.
3. Add voting and richer governance only after stable baseline operations.
