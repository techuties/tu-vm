# Website Suggestion: Community Suggestions Platform

## Summary

Build a community-driven suggestion system directly into the existing website stack so contributors can propose improvements, vote on priorities, and track implementation status without leaving the platform.

This should **extend current components** (`nginx/html/index.html` + `helper/uploader.py`) rather than introduce a new web framework immediately.

## Problem Statement

Current dashboard capabilities are operational (status, control, announcements), but community collaboration is still ad hoc. There is no structured workflow for:

- submitting suggestions,
- detecting duplicates,
- discussing priority,
- showing lifecycle state from idea to delivery.

## Proposed Framework (Reuse-First)

The platform should be layered so the project can get value before adding new infrastructure:

1. **GitHub and Markdown as the system of record**
   - Keep proposal text in Issues, PRs, and `suggestions/` Markdown.
   - Use labels and linked pull requests for status changes.
   - Require suggestion IDs only after an idea is accepted or starts implementation.
2. **Static website rendering for discoverability**
   - Render curated Markdown into a docs website or link it from the existing landing page.
   - Generate a static index for categories, statuses, and related suggestions.
3. **Helper API for local dynamic views**
   - Add helper endpoints only when runtime status or generated summaries need to appear on the LAN dashboard.
   - Keep write operations maintainer-gated and auditable.
4. **Optional workflow automation**
   - Use CI and small scripts first.
   - Add n8n or scheduled jobs only for repeated reminders, digest generation, or stale proposal review.

This preserves existing community workflows while making the website more useful.

## Framework and tool choices

| Need | Recommended choice | Notes |
|---|---|---|
| Suggestion intake | GitHub Issues with an "Idea / suggestion" template | Lowest-friction public workflow and avoids custom auth. |
| Long-form proposals | Markdown files in `suggestions/` | Keeps history reviewable in Git and easy to publish. |
| Discussions | GitHub Discussions, if enabled | Best for exploratory conversations that are not implementation-ready. |
| Website/docs renderer | Docusaurus for docs-first; Astro/Starlight for richer site pages | Both support Markdown and avoid building a custom docs stack. |
| Status summary | Generated JSON from repository metadata | Can be rendered statically before adding runtime API. |
| Runtime API | Existing Flask helper service | Suitable for local dashboard summaries and admin-only status transitions. |
| Workflow automation | GitHub Actions, small scripts, optional n8n | Keeps automation explainable and incremental. |
| Search/deduplication | Keyword scan first; optional embeddings/Qdrant later | Avoid semantic infrastructure until historical volume warrants it. |

### 1) Data Model (MVP)

Add a simple generated JSON index first, then migrate to a JSON-backed store or Postgres only if write volume requires it.

`suggestion` fields:

- `id` (uuid)
- `title`
- `problem`
- `proposal`
- `category` (security, UX, automation, docs, reliability, performance)
- `source` (`issue`, `discussion`, `markdown`, `pull_request`)
- `impact_score` (1-5)
- `effort_score` (1-5)
- `risk_score` (1-5)
- `status` (`proposed`, `triaged`, `accepted`, `implemented`, `rejected`, `merged`)
- `author`
- `created_at`
- `updated_at`
- `duplicate_of` (nullable)
- `related` (array of suggestion IDs or file paths)
- `implementation_links` (issues, PRs, commits, changelog anchors)
- `notes`

### Status lifecycle

Use a small, public lifecycle:

1. `proposed`: submitted by a user or contributor.
2. `triaged`: maintainer confirmed the topic, area, and duplicate check.
3. `accepted`: the project agrees this should be implemented when capacity and risk allow.
4. `implemented`: linked code/docs have shipped.
5. `rejected`: declined with a short reason.
6. `merged`: superseded by or combined with a canonical suggestion.

Every terminal state should include a rationale and link to the decision source.

### 2) API Extensions (Helper Service)

Extend `helper/uploader.py` with endpoints:

- `GET /suggestions`  
  List with query filters (`status`, `category`, search text).
- `POST /suggestions`  
  Create new suggestion with required validation.
- `GET /suggestions/<id>`  
  Fetch detail.
- `POST /suggestions/<id>/vote`  
  Upvote/downvote (basic token/IP throttling in MVP).
- `POST /suggestions/<id>/status`  
  Maintainer-only transition with audit note.
- `GET /suggestions/stats`  
  Counts by category/status and top-voted items.

Start read-only if possible:

- `GET /suggestions/index`
- `GET /suggestions/stats`
- `GET /suggestions/related?title=...`

Add write endpoints only after moderation, authentication, and spam controls are clear.

### 3) Website UX (Landing Page Section)

Add a “Community Suggestions” module in `nginx/html/index.html`:

- **New Suggestion form** (title/problem/proposal/category).
- **Suggestion list** with filters:
  - status chips,
  - category chips,
  - sort by votes/updated.
- **Detail drawer/modal**:
  - lifecycle status,
  - rationale,
  - linked duplicate if applicable.
- **Top Priorities panel** driven by `/suggestions/stats`.

For a static-docs website, expose the same information as:

- suggestion list page grouped by lifecycle status,
- individual proposal pages,
- "related suggestions" blocks,
- "recently shipped from community" release section,
- beginner-friendly "make your first suggestion" guide.

### 4) Governance Flow

Define a simple moderation policy:

1. New submission lands in `proposed`.
2. Maintainer triage sets:
   - duplicate link, or
   - accepts with prioritization note.
3. Accepted work transitions to `implemented` when merged.
4. Rejected items require explicit reason to preserve transparency.

Major suggestions should use the RFC-lite shape from `website-community-framework.md`: problem, constraints, proposal, security impact, resource impact, migration/rollback, tests, and docs impact.

## Why This Avoids Re-inventing the Wheel

- Reuses **existing helper API** pattern and auth model.
- Reuses **existing dashboard UI style** and notification behaviors.
- Reuses **existing operational concepts** (status chips, announcements).
- Delays heavy framework migration until there is clear scaling need.
- Reuses GitHub's discussion, review, and audit features before adding custom accounts, voting, or moderation queues.

## Technical Risks and Mitigations

1. **JSON store concurrency risk**  
   Mitigation: atomic writes + file lock; move to Postgres when contention appears.
2. **Abuse/spam submissions**  
   Mitigation: token-gated submit mode or basic rate limiting by IP.
3. **Status drift from code reality**  
   Mitigation: require maintainer update note with PR/commit reference in status transitions.
4. **Community trust risk from opaque ranking**
   Mitigation: publish scoring rules and keep all prioritization advisory until maintainers record a decision.
5. **Overbuilding before need is proven**
   Mitigation: require measurable pain before moving from generated Markdown/JSON to a writable platform.

## Success Criteria

- Contributors can submit suggestions from the website in under 2 minutes.
- Duplicate suggestions are visibly linked to canonical items.
- Maintainers can change status with traceable reasoning.
- Community can see top priorities and what was recently implemented.
- No new infrastructure service is required for MVP.
- Accepted suggestions can be traced from proposal to issue/PR to release note.
