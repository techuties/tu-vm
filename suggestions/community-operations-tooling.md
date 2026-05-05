# Community Operations Tooling Suggestions

## Goal
Introduce practical tooling that reduces maintainer overhead and makes contribution easier for everyone.

## Core Tooling Stack (Low Complexity, High Return)

### 1) GitHub-native Workflow
- **Issue forms** for bugs, feature requests, and suggestion proposals
- **Pull request template** with required sections:
  - Problem statement
  - Proposed change
  - Validation steps
  - Backward compatibility notes
- **Labels**:
  - `suggestion/proposed`
  - `suggestion/accepted`
  - `suggestion/deferred`
  - `good-first-issue`
  - `help-wanted`

### 2) Project Tracking
- Use **GitHub Projects** with views:
  - Community suggestions
  - Maintainer triage queue
  - In progress
  - Shipped
- Add lightweight fields: priority, impact, effort, owner.

### 3) Automation with GitHub Actions
Automations that avoid custom backend development:
- Auto-label by file paths and issue form type
- Stale discussion reminders (only for inactive proposals)
- Weekly digest generation:
  - Newly proposed suggestions
  - Accepted suggestions
  - Blocked items requiring input

### 4) Communication Integration
- Optional Slack/Discord webhook notification for:
  - New accepted suggestions
  - Calls for reviewers
  - Release notes publication
- Keep it one-way first (broadcast only) to avoid moderation complexity.

## Suggested Operational Cadence

### Daily
- Triage new proposals
- Tag owner and status
- Request missing context from author

### Weekly
- Review top-voted community suggestions
- Mark decisions with rationale
- Publish short weekly update (shipped/in progress/needs input)

### Monthly
- Review suggestion funnel health (proposal -> decision -> shipped)
- Archive closed/deferred proposals with final notes
- Refresh contributor onboarding docs

## Templates to Standardize Quality

### Suggestion Template Fields
- Problem being solved
- Who benefits
- Existing alternatives checked
- Proposed solution
- Risks/tradeoffs
- Rollout plan
- Success metrics

### Decision Record Template
- Suggestion ID and link
- Decision: accepted/rejected/deferred
- Why
- Preconditions
- Follow-up tasks

## Moderation and Safety Baseline
- Enforce code of conduct on suggestions and discussion threads.
- Define clear moderation rules for spam, abuse, and off-topic posts.
- Require rationale for rejected suggestions to keep trust high.

## Anti-Patterns to Avoid
- Building custom suggestion portals too early
- Requiring complex forms for first-time contributors
- Hiding decision rationale in private channels
- Running too many tools with overlapping purpose

## Practical First Increment
1. Add templates and labels.
2. Add GitHub Project board and basic views.
3. Add one workflow for auto-labeling + one weekly summary workflow.
4. Publish governance and decision policy in docs.

This gets a functional community framework quickly, while keeping long-term flexibility.
