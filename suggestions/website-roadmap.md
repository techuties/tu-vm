# Website Suggestions Roadmap

This roadmap translates community and tooling suggestions into phased, low-risk implementation steps.

## Phase 1: Foundation (documentation and structure)

Goals:

- Make suggestions visible and standardized.
- Create clear ownership and decision paths.

Actions:

1. Stand up the `suggestions/` repository structure and baseline docs.
2. Define suggestion lifecycle states and minimum metadata requirements.
3. Publish a website Suggestions page that reads from repository-backed suggestion records.
4. Add a Roadmap page grouped by status and category.

Definition of done:

- Suggestion records use a consistent schema.
- Website shows status, owner, and last updated timestamps.
- Maintainer workflow for triage is documented.

## Phase 2: Automation and governance

Goals:

- Reduce manual process overhead.
- Improve consistency and traceability.

Actions:

1. Implement n8n intake validation workflow.
2. Implement stale suggestion reminder workflow.
3. Implement shipped-evidence verification workflow.
4. Add decision log entries for accepted/declined suggestions.

Definition of done:

- New suggestions are automatically validated and categorized.
- Stale items produce automated nudges.
- Shipped suggestions include evidence links (commit/changelog/checks).

## Phase 3: Community growth features

Goals:

- Improve contributor onboarding and participation quality.

Actions:

1. Add category templates (security, UX, docs, automation, performance).
2. Add newcomer-oriented contribution entry points.
3. Publish a weekly digest of suggestion movement.
4. Add website onboarding widget for first contributions.

Definition of done:

- New contributors can submit valid suggestions without maintainer intervention.
- Weekly digest is generated and published consistently.
- Suggestion quality improves (higher metadata completeness, lower triage churn).

## Phase 4: Operational maturity

Goals:

- Keep suggestion system healthy and aligned with real product delivery.

Actions:

1. Add KPI dashboard for community flow metrics.
2. Correlate shipped suggestions with release notes automatically.
3. Periodically prune/merge duplicate suggestions.
4. Review governance effectiveness and adjust thresholds/rules.

Definition of done:

- KPI metrics are visible and actionable.
- Duplicate/abandoned suggestion rates trend downward.
- Website roadmap and changelog remain synchronized.

## Prioritization guidance

Prioritize suggestions using this order:

1. Security and reliability impact
2. Community unblockers (high contributor friction reduction)
3. Maintenance effort reduction
4. UX polish and discoverability improvements

Use small, reversible increments and pair each shipped suggestion with changelog evidence.
