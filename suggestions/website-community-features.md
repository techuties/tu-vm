# Website Suggestions - Community Features and Governance

## Objective
Create a community-based system where ideas are easy to submit, easy to evaluate, and easy to track from proposal to delivery.

## Core Community Features

## 1) Suggestion intake with quality prompts
Every new suggestion should require:
- problem statement
- expected user impact
- rough effort estimate (small/medium/large)
- affected area (dashboard, API, docs, tooling, security)
- success criteria

This reduces low-context requests and speeds triage.

## 2) Public triage board
Use clear states:
- `New`
- `Needs Clarification`
- `Accepted`
- `Planned`
- `In Progress`
- `Completed`
- `Declined` (with rationale)

Each suggestion should show:
- owner/maintainer
- next action
- target milestone (if available)

## 3) Voting and prioritization
- Allow lightweight upvotes.
- Add maintainer weighting factors:
  - community demand (votes)
  - platform risk
  - implementation complexity
  - security impact
  - operational cost
- Show a transparent priority score breakdown.

## 4) Decision transparency
Each suggestion should keep a decision log:
- why accepted or declined
- tradeoffs considered
- links to implementation artifacts (commits/releases/changelog entries)

## 5) Contributor pathways
- "Good first suggestions" label for low-risk tasks.
- "Needs design" for proposals requiring UX/architecture.
- "Needs maintainer input" for blocked items.
- Ready-to-implement checklists for accepted suggestions.

## Suggested Review Cadence
- Weekly triage: classify all new items.
- Bi-weekly planning: move accepted items into planned milestones.
- Monthly retrospective: summarize completed community suggestions and impact.

## Suggested Moderation Rules
- No duplicate proposals: merge into canonical thread.
- Mark stale ideas after inactivity window (for example 30-45 days) with reopen option.
- Require respectful communication and actionable comments.
- Keep decline reasons explicit to maintain trust.

## Community KPI Dashboard (website page)
- New suggestions per week
- Triage lead time
- Acceptance rate
- Mean time from accepted to completed
- Reopened rate
- Top requested categories

## Integration with Existing Project Assets
- Link implemented suggestions into `CHANGELOG.md`.
- Pull operational data from existing helper status endpoints where relevant.
- Keep community pages informational; runtime control stays behind secured endpoints.

## Recommended First Iteration (MVP)
1. Suggestion list + detail page
2. Status workflow + decision log
3. Upvotes
4. Maintainer triage panel
5. Read-only roadmap page derived from suggestion statuses
