# Website Suggestions - Community Features and Governance

## Objective
Build a community-based system where ideas are easy to submit, evaluate, prioritize, and track from proposal through delivery.

## Core Community Features

## 1) Structured suggestion intake
Every suggestion should capture:
- problem statement
- expected user/community impact
- affected area (docs, dashboard, API, tooling, security)
- effort estimate (S/M/L)
- success criteria
- risks and rollback notes

This improves suggestion quality and accelerates triage.

## 2) Public triage board with clear statuses
Recommended statuses:
- `New`
- `Needs Clarification`
- `Accepted`
- `Planned`
- `In Progress`
- `Completed`
- `Declined` (with rationale)

Each suggestion page should show:
- owner/reviewer
- next action
- links to implementation artifacts once available

## 3) Voting and prioritization model
- Allow lightweight upvotes to capture community demand.
- Combine votes with maintainer factors:
  - platform risk
  - implementation complexity
  - security impact
  - operational cost
- Show transparent score components to keep decisions explainable.

## 4) Decision transparency
Keep a visible decision log per suggestion:
- acceptance/decline rationale
- tradeoffs considered
- links to commits, changelog entries, and release notes

This builds trust and reduces repeated debates.

## 5) Contributor pathways
Use labels and workflow buckets:
- `good-first-suggestion` for low-risk starter work
- `needs-design` for UX/architecture discussion
- `needs-maintainer-input` for blocked items
- `ready-to-implement` when scope and acceptance criteria are clear

## 6) Governance pages to publish on the website
Minimum governance set:
1. Contributor guide
2. Code of conduct
3. Security reporting policy
4. Decision log policy
5. RFC/suggestion lifecycle policy

Keep these pages short, explicit, and actionable.

## 7) Moderation and trust model
- Merge duplicates into canonical discussions.
- Define inactivity/stale handling with reopen path.
- Enforce respectful communication standards.
- Publish moderation SLAs for response expectations.
- Keep sensitive infrastructure details out of public routes.

## 8) Community health and operational metrics
Track and publish:
- new suggestions per week
- median time to first maintainer response
- median triage time
- acceptance rate
- mean time from accepted to completed
- top requested categories

Use metrics for process improvement, not contributor gatekeeping.

## 9) Integration with existing platform capabilities
Leverage existing components instead of adding unnecessary systems:
- n8n for triage and notification workflows
- helper API for public-safe status metadata (if needed)
- changelog as source of truth for shipped outcomes
- existing dashboard as operations control plane (kept separate)

## Recommended MVP
1. Suggestion list + detail pages
2. Status workflow + decision log
3. Upvotes
4. Maintainer triage view
5. Read-only roadmap derived from suggestion statuses

## Success Criteria
- Community members can submit high-quality suggestions without maintainer back-and-forth.
- Maintainers can move suggestions through a visible lifecycle consistently.
- Implemented community suggestions are linked to concrete shipped outcomes.
