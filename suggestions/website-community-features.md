# Website Suggestions - Community Features and Governance

## Objective
Create a community-based website system where suggestions are easy to submit, evaluate, prioritize, and track from proposal to delivery.

## 1) Structured suggestion intake
Each suggestion should capture:
- problem statement
- expected community impact
- affected area (docs, dashboard, API, tooling, security)
- effort size (S/M/L)
- success criteria
- risks and rollback notes

Result:
- higher quality submissions
- faster triage
- fewer clarification loops

## 2) Public triage board with explicit statuses
Recommended lifecycle states:
- `New`
- `Needs Clarification`
- `Accepted`
- `Planned`
- `In Progress`
- `Completed`
- `Declined` (with rationale)

Each suggestion card/detail should show:
- owner/reviewer
- next action
- latest decision note
- implementation links when available

## 3) Voting + prioritization model
- Allow lightweight upvotes for demand signal.
- Combine votes with maintainer scoring factors:
  - security risk
  - operational impact
  - complexity
  - maintenance cost
- Display score components for transparent decision making.

## 4) Decision transparency
Maintain decision logs per suggestion:
- acceptance/decline rationale
- alternatives considered
- key tradeoffs
- links to commit/changelog/release artifacts

## 5) Contributor pathways
Use labels and workflow buckets:
- `good-first-suggestion`
- `needs-design`
- `needs-maintainer-input`
- `ready-to-implement`

This turns community interest into implementable work queues.

## 6) Governance pages for the website
Minimum governance set:
1. contributor guide
2. code of conduct
3. security reporting policy
4. decision logging policy
5. suggestion lifecycle policy

Keep these pages short, explicit, and operationally clear.

## 7) Moderation and trust model
- merge duplicates into canonical discussions
- define stale/inactive handling with reopen path
- enforce respectful communication standards
- publish response expectations for triage/moderation
- keep sensitive infrastructure details out of public pages

## 8) Community health metrics
Track and publish:
- new suggestions per week
- median time to first maintainer response
- median triage time
- acceptance rate
- mean time from accepted to completed
- top requested categories

Use metrics to improve process quality, not to gate contributor participation.

## 9) Integration with existing platform capabilities
Prefer extending current components:
- existing dashboard remains operations control plane
- helper services remain runtime status/control source
- changelog remains shipped-outcome source of truth
- automation stack handles triage and reminders

## Recommended MVP
1. Suggestion list + detail pages
2. Status workflow + decision logs
3. Upvote support
4. Maintainer triage view
5. Read-only roadmap derived from status

## Success Criteria
- Contributors can submit high-quality suggestions without repeated maintainer prompting.
- Maintainers can move suggestions through a visible lifecycle consistently.
- Completed suggestions are linked to concrete shipped outcomes.
