---
title: Community Suggestion System Implementation Roadmap
status: proposed
priority: high
---

# Community Suggestion System Implementation Roadmap

This roadmap focuses on technical phases rather than date estimates.

## Phase 0 - Baseline and inventory

## Deliverables

- Confirm existing suggestion artifacts and normalize them in `/suggestions/`.
- Add metadata headers to all suggestion markdown files.
- Document current decision flow (who approves what).

## Exit criteria

- A clean, indexed suggestion repository exists.
- Historical decisions are discoverable and searchable.

## Phase 1 - Standardized intake and validation

## Deliverables

- Suggestion template with required metadata fields.
- Duplicate-check procedure against historical files.
- Basic lint checks for metadata and markdown validity.

## Exit criteria

- Every new suggestion follows one format.
- Duplicate suggestions are identified before review.

## Phase 2 - Community review and scoring

## Deliverables

- Public review process (labels/tags + discussion thread mapping).
- Lightweight prioritization scoring model.
- Visible status transitions (`proposed -> reviewing -> approved/rejected`).

## Exit criteria

- Community can observe and participate in review decisions.
- Prioritization is consistent and documented.

## Phase 3 - Website integration

## Deliverables

- Render `/suggestions/*.md` as searchable website pages.
- Add filters by status, tag, and owner.
- Expose machine-readable suggestions index for automation.

## Exit criteria

- Website reflects repo suggestions without manual copy-paste.
- New markdown suggestions appear automatically after deployment.

## Phase 4 - Operational automation

## Deliverables

- Weekly digest generation for new/updated/shipped suggestions.
- Stale backlog alerts.
- "Shipped from suggestions" mapping to changelog entries.

## Exit criteria

- Maintainer effort decreases while visibility increases.
- Backlog health is measurable and auditable.

## Phase 5 - Governance hardening

## Deliverables

- Role and permission boundaries (contributor/moderator/maintainer).
- Conflict handling and escalation path documentation.
- Security review for suggestion-related endpoints/pages.

## Exit criteria

- Community process is robust, fair, and operationally safe.

## Risks and mitigations

- **Risk:** process overhead discourages contributors  
  **Mitigation:** keep template short, automate checks

- **Risk:** scoring model becomes subjective  
  **Mitigation:** publish scoring weights and examples

- **Risk:** suggestions pile up without outcomes  
  **Mitigation:** stale-check automation + mandatory status updates

## Definition of done

The system is complete when:

1. Suggestions are easy to submit and hard to duplicate.
2. Decisions are transparent and attributable.
3. Approved suggestions are traceable to implementation artifacts.
4. Community and maintainers can monitor backlog health continuously.
