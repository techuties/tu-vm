# Website Community Framework (Detailed Suggestions)

This document proposes a community-based website framework that supports open
suggestion intake, prioritization, transparent decisions, and release tracking.

## 1. Objectives

- Centralize community ideas in one public workflow.
- Reuse historical suggestions and existing project mechanisms.
- Turn informal feedback into actionable proposals with clear status.
- Keep maintainers in control while making decisions visible.

## 2. Core Website Information Architecture

Recommended top-level website sections:

1. **Home**
   - Project value proposition
   - Current release highlights
2. **Roadmap**
   - Planned, in progress, released suggestions
3. **Suggestions**
   - Searchable list of all suggestion records and decisions
4. **Docs**
   - Operational guides, security, setup
5. **Community**
   - Contribution process, governance, code of conduct
6. **Release Notes**
   - Structured changelog with links to implemented suggestions

## 3. Suggestion Lifecycle

Use a simple, consistent lifecycle:

`proposed -> triaged -> accepted -> in_progress -> released`

Alternate terminal states:

- `declined`
- `superseded`
- `needs_clarification`

Every suggestion entry should include:

- Problem statement
- Proposed solution
- Reuse of existing capabilities
- Trade-offs and risks
- Decision notes

## 4. Reuse Existing Components First

To avoid re-inventing, use existing components already in this repository:

- Monitoring and announcement concepts from README/changelog
- Existing control and status APIs as integration anchors
- Current changelog process as the source of truth for released work

Website should display "reused components" as a required field in proposals.

## 5. Community Prioritization Model

Recommended scoring model (simple and transparent):

- Impact (1-5)
- Effort (1-5)
- Risk (1-5)
- Community votes (1-5 normalized)

Priority score example:

`priority = impact + votes - effort - risk`

This keeps ranking transparent and easy to explain.

## 6. Governance and Moderation

Minimum governance roles:

- **Maintainer**: final decision maker
- **Reviewer**: validates technical feasibility
- **Community moderator**: manages duplicates and discussion hygiene

Moderation rules:

- Merge duplicates into canonical suggestion entries.
- Require a "what already exists" section on every new suggestion.
- Close stale discussions with clear rationale and next action.

## 7. MVP Delivery Sequence

1. Publish suggestion index and lifecycle definitions.
2. Import historical suggestions (`website-historical-suggestions.md`).
3. Add a lightweight submission template.
4. Add public roadmap view grouped by status.
5. Link released roadmap items to changelog entries.

## 8. Success Metrics

Track metrics that show process quality, not just volume:

- Percentage of new suggestions linked to historical items
- Duplicate suggestion rate (target: decreasing)
- Median time from proposed to triaged
- Accepted-to-released ratio
- Community participation per release cycle
