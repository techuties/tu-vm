# Website Historical Suggestions Baseline

This file consolidates prior suggestions already present in repository
documentation so future planning can build on prior work.

## Source Summary

- `CHANGELOG.md` (notably v2.0.0 and v2.3.0 "Future Enhancements")
- `README.md` feature sections and operational notes

## Historical Suggestions Inventory

## 1) Quick Action Profiles
- Status: proposed
- Source: `CHANGELOG.md` future enhancements
- Existing context:
  - Work Mode
  - AI Mode
  - Full Storage
  - Energy Save
- Website implication:
  - Community can vote and discuss profile presets and defaults.

## 2) Battery Status Integration
- Status: proposed
- Source: `CHANGELOG.md` future enhancements
- Existing context:
  - Battery-aware platform behavior already exists.
- Website implication:
  - Add community board for battery optimization ideas and telemetry opt-in design.

## 3) Auto-stop Inactive Services
- Status: proposed
- Source: `CHANGELOG.md` future enhancements
- Existing context:
  - Tiered services and manual controls already implemented.
- Website implication:
  - Proposal workflow should include safety guardrails and rollback strategy.

## 4) Resource Usage History Charts
- Status: proposed
- Source: `CHANGELOG.md` future enhancements
- Existing context:
  - Current monitoring has status and alerting, but long-term history UI can improve.
- Website implication:
  - Community can prioritize chart types and retention policy.

## 5) Smart Startup Optimization
- Status: proposed
- Source: `CHANGELOG.md` future enhancements
- Existing context:
  - Tier 1/Tier 2 architecture is already available.
- Website implication:
  - Candidate for "community requested defaults" and profile bundles.

## 6) Service Dependency Auto-start
- Status: potential improvement
- Source: `CHANGELOG.md` potential improvements
- Existing context:
  - Dependency orchestration exists at compose level but user-level experience can improve.
- Website implication:
  - Needs design RFC with failure-mode handling.

## 7) Usage Analytics and Recommendations
- Status: potential improvement
- Source: `CHANGELOG.md` potential improvements
- Existing context:
  - Monitoring and announcements are established.
- Website implication:
  - Requires privacy policy and transparent data collection controls.

## 8) Mobile Dashboard Optimization
- Status: potential improvement
- Source: `CHANGELOG.md` potential improvements + README mobile notes
- Existing context:
  - Basic mobile-friendly direction already stated.
- Website implication:
  - Community should prioritize mobile navigation, touch controls, and readability.

## Reuse Rules (to avoid re-inventing)

Before adding any new website suggestion:

1. Check this file for overlap.
2. If overlapping, append details under existing suggestion instead of creating a
   duplicate suggestion.
3. If replacing an old idea, mark the old one as `superseded` and link the new
   proposal.
4. If implemented, move status to `released` and reference the changelog entry.
